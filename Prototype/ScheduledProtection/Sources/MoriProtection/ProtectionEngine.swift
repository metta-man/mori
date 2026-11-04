import Foundation

public enum ProtectionEngine {
    /// Original absolute ends survive coherent process handoffs/reboots. Inside
    /// a live process, continuous elapsed time can expire earlier, never later.
    /// A material backward discrepancy without a live projection retires only
    /// currently dated scheduled scopes; it does not invent a handoff budget.
    public static func advanceClock(state: inout ProtectionState, sample: ProtectionClockSample) -> Date? {
        guard sample.isValid else { return nil }
        guard var ledger = state.clockLedger else {
            state.clockLedger = .init(processID: sample.processID, continuousSeconds: sample.continuousSeconds,
                logicalNow: sample.projectedNow.map { max($0, sample.wall) } ?? sample.wall,
                recoveryEndsAt: nil, recoveryWindowIDs: [], retiredWindowIDs: [])
            return state.clockLedger!.logicalNow
        }
        guard ledger.logicalNow.timeIntervalSince1970.isFinite else { return nil }
        let projected: Date
        if ledger.processID == sample.processID {
            guard sample.continuousSeconds >= ledger.continuousSeconds else { return nil }
            projected = max(ledger.logicalNow.addingTimeInterval(sample.continuousSeconds - ledger.continuousSeconds),
                            sample.projectedNow ?? sample.wall)
        } else {
            projected = sample.projectedNow ?? sample.wall
        }
        // Explicit two-minute tolerance covers small wall corrections; this is
        // a voluntary policy, not detection of undetected interprocess tampering.
        let incoherentHandoff = ledger.processID != sample.processID && sample.projectedNow == nil
            && ledger.logicalNow.timeIntervalSince(sample.wall) > 120
        if incoherentHandoff {
            let affected = Set(activeWindows(state, at: ledger.logicalNow).map(\.id))
            ledger.retiredWindowIDs.formUnion(affected)
            ledger.recoveryWindowIDs = affected; ledger.recoveryEndsAt = ledger.logicalNow
            ledger.recoveryReason = "Inconsistent wall date without a live elapsed anchor"
            for id in affected { state.allowances.removeValue(forKey: id) }
            if let morning = state.activeFirstUseMorning, affected.contains(morning.id) { state.activeFirstUseMorning = nil }
            state.flowEpoch = UUID()
        } else if ledger.recoveryEndsAt != nil && sample.wall >= ledger.logicalNow {
            ledger.recoveryEndsAt = nil; ledger.recoveryWindowIDs = []
        }
        ledger.logicalNow = max(ledger.logicalNow, max(sample.wall, projected))
        ledger.processID = sample.processID; ledger.continuousSeconds = sample.continuousSeconds
        // Dated tombstones are retained independently of process identity.
        state.clockLedger = ledger
        return ledger.logicalNow
    }
    public static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Delivery time is the anchor. This is never described as an unlock timestamp.
    @discardableResult
    public static func firstUseDelivered(state: inout ProtectionState, at now: Date,
                                         scheduledRevision: Int, eligible: Bool) -> Bool {
        let config = state.configuration
        guard state.clockLedger?.recoveryEndsAt == nil,
              eligible, config.morningEnabled, config.morningTrigger == .firstUse,
              scheduledRevision == config.revision,
              let band = config.detectionWindow.containing(now, calendar: config.calendar)
        else { return false }
        let cycle = dayKey(band.start, calendar: config.calendar)
        guard state.lastMorningCycle != cycle,
              state.nextMorningEligibleAt.map({ now >= $0 }) ?? true
        else { return false }
        let duration = min(7200, max(300, config.morningDurationSeconds))
        state.activeFirstUseMorning = .init(
            id: "morning|\(cycle)|\(config.revision)",
            rule: .morning, start: now, end: now.addingTimeInterval(TimeInterval(duration))
        )
        state.lastMorningCycle = cycle
        // A time-zone/config change cannot manufacture another start in this cycle.
        state.nextMorningEligibleAt = config.calendar.date(byAdding: .day, value: 1, to: band.start)
        return true
    }

    public static func activeWindows(_ state: ProtectionState, at now: Date) -> [ProtectionWindow] {
        let c = state.configuration
        var windows: [ProtectionWindow] = []
        if c.morningEnabled {
            if let persisted = state.activeFirstUseMorning,
               persisted.start <= now, now < persisted.end {
                windows.append(persisted)
            } else if c.morningTrigger == .fixedTime {
                let calendar = c.calendar
                let today = calendar.startOfDay(for: now)
                let days = [today, calendar.date(byAdding: .day, value: -1, to: today)].compactMap { $0 }
                for date in days {
                    guard let start = calendar.nextDate(
                        after: date.addingTimeInterval(-1),
                        matching: DateComponents(hour: c.morningStartMinute / 60,
                                                 minute: c.morningStartMinute % 60),
                        matchingPolicy: .nextTime, repeatedTimePolicy: .first
                    ) else { continue }
                    let day = dayKey(start, calendar: calendar)
                    let elapsedEnd = start.addingTimeInterval(TimeInterval(c.morningDurationSeconds))
                    if start <= now && now < elapsedEnd && day != state.legacyCompletedMorningDay
                        && state.lastMorningCycle != day
                        && (state.nextMorningEligibleAt.map { now >= $0 } ?? true) {
                        windows.append(.init(id: "morning|\(day)|\(c.revision)",
                                             rule: .morning, start: start, end: elapsedEnd))
                        break
                    }
                }
            }
        }
        if c.bedtimeEnabled, let band = c.bedtimeWindow?.containing(now, calendar: c.calendar) {
            windows.append(.init(id: "bedtime|\(dayKey(band.start, calendar: c.calendar))|\(c.revision)",
                                 rule: .bedtime, start: band.start, end: band.end))
        }
        if let ledger = state.clockLedger {
            windows.removeAll { window in
                ledger.retiredWindowIDs.contains(window.id) || ledger.retiredWindowIDs.contains { retired in
                    // Revision changes cannot resurrect the same retired dated scope.
                    retired.split(separator: "|").dropLast() == window.id.split(separator: "|").dropLast()
                }
            }
        }
        return windows
    }

    public static func plan(_ state: ProtectionState, at now: Date) -> ProtectionPlan {
        let windows = activeWindows(state, at: now)
        let shielded = windows.filter { state.allowances[$0.id].map { now < $0 } != true }
        let deadlines = windows.map(\.end) + windows.compactMap { state.allowances[$0.id] }
        return .init(activeWindows: windows, shieldedRules: Set(shielded.map(\.rule)),
                     nextReconciliationAt: deadlines.filter { $0 > now }.min())
    }

    public static func beginBreathing(_ state: ProtectionState, at now: Date,
                                     requestID: UUID = UUID()) -> ProtectionBreathTicket? {
        guard state.clockLedger?.recoveryEndsAt == nil else { return nil }
        let current = plan(state, at: now)
        guard !current.shieldedRules.isEmpty else { return nil }
        let ids = current.activeWindows.filter { current.shieldedRules.contains($0.rule) }.map(\.id)
        return .init(requestID: requestID, revision: state.configuration.revision,
                     flowEpoch: state.flowEpoch, startedAt: now, windowIDs: Set(ids))
    }

    /// No side effect is allowed until the caller persists the returned mutation.
    @discardableResult
    public static func confirmBreathing(state: inout ProtectionState,
                                       ticket: ProtectionBreathTicket, completed: Bool,
                                       allowanceSeconds: Int, at now: Date) -> ProtectionGrant? {
        guard state.clockLedger?.recoveryEndsAt == nil else { return nil }
        let key = ticket.requestID.uuidString
        if let receipt = state.confirmedGrants[key] {
            return Set(receipt.windowEnds.keys).isSubset(of: ticket.windowIDs) ? receipt : nil
        }
        guard state.clockLedger?.recoveryEndsAt == nil,
              completed, ticket.startedAt <= now,
              ticket.revision == state.configuration.revision,
              ticket.flowEpoch == state.flowEpoch
        else { return nil }
        let seconds = min(900, max(60, allowanceSeconds))
        let windows = activeWindows(state, at: now).filter { ticket.windowIDs.contains($0.id) }
        guard !windows.isEmpty else { return nil }
        var ends: [String: Date] = [:]
        for window in windows {
            ends[window.id] = min(window.end, now.addingTimeInterval(TimeInterval(seconds)))
        }
        let grant = ProtectionGrant(requestID: ticket.requestID, confirmedAt: now, windowEnds: ends)
        for (id, end) in ends { state.allowances[id] = end }
        state.confirmedGrants[key] = grant
        state.grantOrder.append(key)
        while state.grantOrder.count > 32 {
            state.confirmedGrants.removeValue(forKey: state.grantOrder.removeFirst())
        }
        state.flowEpoch = UUID()
        return grant
    }

    public static func cancelBreathing(state: inout ProtectionState) {
        state.flowEpoch = UUID()
    }

    public static func reconcile(state: inout ProtectionState, at now: Date) {
        if let morning = state.activeFirstUseMorning,
           !morning.start.timeIntervalSince1970.isFinite || !morning.end.timeIntervalSince1970.isFinite
            || morning.start > now || morning.end <= morning.start || morning.end.timeIntervalSince(morning.start) > 7200 {
            state.clockLedger?.retiredWindowIDs.insert(morning.id)
            state.clockLedger?.recoveryReason = "Invalid persisted morning dates"
            if morning.start.timeIntervalSince1970.isFinite {
                state.lastMorningCycle = dayKey(morning.start, calendar: state.configuration.calendar)
                state.nextMorningEligibleAt = state.configuration.calendar.date(byAdding: .day, value: 1, to: morning.start)
            }
            state.activeFirstUseMorning = nil
            state.allowances.removeValue(forKey: morning.id)
            state.flowEpoch = UUID()
        }
        if state.configuration.morningEnabled, state.configuration.morningTrigger == .fixedTime,
           state.activeFirstUseMorning == nil, let morning = activeWindows(state, at: now).first(where: { $0.rule == .morning }) {
            state.activeFirstUseMorning = morning
            state.lastMorningCycle = dayKey(morning.start, calendar: state.configuration.calendar)
            state.nextMorningEligibleAt = state.configuration.calendar.date(byAdding: .day, value: 1, to: morning.start)
        }

        let ids = Set(activeWindows(state, at: now).map(\.id))
        state.allowances = state.allowances.filter { ids.contains($0.key) && $0.value.timeIntervalSince1970.isFinite && now < $0.value }
        if let morning = state.activeFirstUseMorning, now >= morning.end {
            state.activeFirstUseMorning = nil
        }
    }

    @discardableResult
    public static func updateConfiguration(state: inout ProtectionState,
                                           to newValue: ProtectionConfiguration) -> Bool {
        guard newValue.isValid else { return false }
        let old = state.configuration
        var config = newValue
        config.revision = old.revision + 1
        state.configuration = config
        state.flowEpoch = UUID()
        state.allowances.removeAll()
        if !config.morningEnabled {
            state.activeFirstUseMorning = nil
        }
        // Keep cycle/next-eligible history and an already-started elapsed deadline.
        // Bedtime remains independent and is never enabled by a migration.
        return true
    }
}
