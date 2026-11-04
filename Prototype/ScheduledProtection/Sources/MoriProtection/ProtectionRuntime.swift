import Foundation

public enum ProtectionCallback {
    case morningFirstUse(scheduledRevision: Int)
    case calendarBoundary
    case elapsedDeadline
    case foregroundReconcile
}

public protocol ProtectionRuntimeEffects {
    /// Synchronous, bounded and non-reentrant. Called under cross-process lock.
    func scheduleReconciliation(at: Date?) throws
    /// Replace only this contribution; preserve BeforeFeed/focus/PIN. Must not
    /// return until the OS write has completed; detached Tasks are not permitted.
    func applyScheduledContribution(_ rules: Set<ProtectionRule>) throws
    func recordRecovery(reason: String) throws
}

public extension ProtectionRuntimeEffects {
    func recordRecovery(reason: String) throws {}
}

public struct ProtectionRuntimeOutcome {
    public let plan: ProtectionPlan?
    public let grant: ProtectionGrant?
    public let effectsApplied: Bool
    public let errorDescription: String?
}

public struct ProtectionRuntime {
    private let storage: any ProtectionStorage
    private let effects: any ProtectionRuntimeEffects
    /// Sample after acquiring the lock, not at callback enqueue time.
    private let clock: (ProtectionState) -> ProtectionClockSample

    public init(storage: any ProtectionStorage, effects: any ProtectionRuntimeEffects,
                clock: @escaping () -> ProtectionClockSample) {
        self.storage = storage; self.effects = effects; self.clock = { _ in clock() }
    }

    public init(storage: any ProtectionStorage, effects: any ProtectionRuntimeEffects,
                clockWithState: @escaping (ProtectionState) -> ProtectionClockSample) {
        self.storage = storage; self.effects = effects; self.clock = clockWithState
    }
    public func callback(_ event: ProtectionCallback, at _: Date,
                         authorizedWithSelection: Bool) -> ProtectionRuntimeOutcome {
        perform(authorizedWithSelection: authorizedWithSelection) { state, logicalNow in
            if case .morningFirstUse(let revision) = event {
                ProtectionEngine.firstUseDelivered(state: &state, at: logicalNow,
                    scheduledRevision: revision, eligible: authorizedWithSelection)
            }
            return nil
        }
    }

    public func finishBreathing(_ ticket: ProtectionBreathTicket, completed: Bool,
                               allowanceSeconds: Int, at _: Date,
                               authorizedWithSelection: Bool) -> ProtectionRuntimeOutcome {
        perform(authorizedWithSelection: authorizedWithSelection) { state, logicalNow in
            if completed && authorizedWithSelection {
                return ProtectionEngine.confirmBreathing(state: &state, ticket: ticket,
                    completed: true, allowanceSeconds: allowanceSeconds, at: logicalNow)
            }
            ProtectionEngine.cancelBreathing(state: &state)
            return nil
        }
    }

    private func perform(authorizedWithSelection: Bool,
        mutation: (inout ProtectionState, Date) -> ProtectionGrant?) -> ProtectionRuntimeOutcome {
        do {
            return try storage.exclusive { access in
                var state: ProtectionState
                do { state = try access.load() }
                catch {
                    try? effects.recordRecovery(reason: "Unreadable state; scheduled contribution removed")
                    try? effects.applyScheduledContribution([])
                    return .init(plan: nil, grant: nil, effectsApplied: false,
                                 errorDescription: "Unreadable state preserved; recovery is pending.")
                }
                func cleanupInvalidClock() {
                    state.effectsRecovery = .init(lastAppliedRules: [], lastAppliedWindowIDs: [], pending: true)
                    try? access.save(state)
                    try? effects.recordRecovery(reason: "Invalid clock; scheduled contribution removed")
                    try? effects.applyScheduledContribution([])
                }
                let sample = clock(state)
                guard var logicalNow = ProtectionEngine.advanceClock(state: &state, sample: sample) else {
                    // Cleanup stays under coordination even if persistence fails.
                    cleanupInvalidClock()
                    return .init(plan: nil, grant: nil, effectsApplied: false,
                                 errorDescription: "Invalid clock; scheduled recovery is pending.")
                }
                ProtectionEngine.reconcile(state: &state, at: logicalNow)
                if let reason = state.clockLedger?.recoveryReason { try? effects.recordRecovery(reason: reason) }
                let beforeGrant = state
                var grant = mutation(&state, logicalNow)
                let newGrant = grant.map { beforeGrant.confirmedGrants[$0.requestID.uuidString] == nil } ?? false
                let grantEpoch = state.flowEpoch
                func rollbackNewGrant(at time: Date) throws {
                    guard newGrant, let created = grant else { return }
                    let rollbackTime = max(time, state.clockLedger?.logicalNow ?? time)
                    // Restore only this operation's allowance/receipt mutation. Keep
                    // advanced clock, reboot retirement and independently rotated epoch.
                    state.confirmedGrants = beforeGrant.confirmedGrants
                    state.grantOrder = beforeGrant.grantOrder
                    for id in created.windowEnds.keys {
                        if state.clockLedger?.recoveryEndsAt == nil,
                           let previousEnd = beforeGrant.allowances[id], rollbackTime < previousEnd {
                            state.allowances[id] = previousEnd
                        } else {
                            state.allowances.removeValue(forKey: id)
                        }
                    }
                    if state.flowEpoch == grantEpoch { state.flowEpoch = beforeGrant.flowEpoch }
                    ProtectionEngine.reconcile(state: &state, at: rollbackTime)
                    state.effectsRecovery?.pending = true
                    grant = nil
                    try access.save(state)
                }
                ProtectionEngine.reconcile(state: &state, at: logicalNow)
                let priorRules = state.effectsRecovery?.lastAppliedRules ?? []
                let priorWindowIDs = state.effectsRecovery?.lastAppliedWindowIDs ?? []
                state.effectsRecovery = .init(lastAppliedRules: priorRules,
                                             lastAppliedWindowIDs: priorWindowIDs, pending: true)
                // Crash before OS effects leaves durable pending recovery.
                try access.save(state)
                var plan = authorizedPlan(state, at: logicalNow, authorized: authorizedWithSelection)
                var registeredWindowIDs = Set(plan.activeWindows.map(\.id))
                var registeredDeadline = plan.nextReconciliationAt
                var schedulingSucceeded = false
                do {
                    // Project a logical remaining duration into current wall-clock time.
                    let deadline = plan.nextReconciliationAt.map {
                        sample.wall.addingTimeInterval(max(0, $0.timeIntervalSince(logicalNow)))
                    }
                    try effects.scheduleReconciliation(at: deadline)
                    schedulingSucceeded = true
                } catch {
                    try rollbackNewGrant(at: logicalNow)
                    plan = authorizedPlan(state, at: logicalNow, authorized: authorizedWithSelection)
                }
                // Registration may take time. Re-read continuous time under the same
                // lock before applying, so an expired snapshot cannot add a shield.
                let freshSample = clock(state)
                guard let freshNow = ProtectionEngine.advanceClock(state: &state, sample: freshSample) else {
                    try? rollbackNewGrant(at: logicalNow)
                    cleanupInvalidClock()
                    return .init(plan: plan, grant: nil, effectsApplied: false,
                                 errorDescription: "Clock recovery is pending.")
                }
                logicalNow = freshNow
                ProtectionEngine.reconcile(state: &state, at: logicalNow)
                plan = authorizedPlan(state, at: logicalNow, authorized: authorizedWithSelection)
                if schedulingSucceeded && (plan.nextReconciliationAt != registeredDeadline ||
                    !Set(plan.activeWindows.map(\.id)).isSubset(of: registeredWindowIDs)) {
                    do {
                        try effects.scheduleReconciliation(at: plan.nextReconciliationAt.map {
                            freshSample.wall.addingTimeInterval(max(0, $0.timeIntervalSince(logicalNow)))
                        })
                        registeredDeadline = plan.nextReconciliationAt
                        registeredWindowIDs = Set(plan.activeWindows.map(\.id))
                    } catch { schedulingSucceeded = false }
                }
                let preApplySample = clock(state)
                guard let preApplyNow = ProtectionEngine.advanceClock(state: &state, sample: preApplySample) else {
                    try? rollbackNewGrant(at: logicalNow)
                    cleanupInvalidClock()
                    return .init(plan: plan, grant: nil, effectsApplied: false,
                                 errorDescription: "Clock recovery is pending.")
                }
                ProtectionEngine.reconcile(state: &state, at: preApplyNow)
                plan = authorizedPlan(state, at: preApplyNow, authorized: authorizedWithSelection)
                if !Set(plan.activeWindows.map(\.id)).isSubset(of: registeredWindowIDs) ||
                    (plan.nextReconciliationAt != nil && plan.nextReconciliationAt != registeredDeadline) {
                    schedulingSucceeded = false
                }
                if newGrant && state.clockLedger?.recoveryEndsAt != nil { schedulingSucceeded = false }
                if !schedulingSucceeded {
                    try rollbackNewGrant(at: preApplyNow)
                    plan = authorizedPlan(state, at: preApplyNow, authorized: authorizedWithSelection)
                }
                try access.save(state)
                // Cleanup never depends on scheduling success. Failed registration
                // may remove expired contributions, but cannot add new shields.
                let survivingPriorRules = Set(plan.activeWindows.filter {
                    priorWindowIDs.contains($0.id) && plan.shieldedRules.contains($0.rule)
                }.map(\.rule))
                let toApply = schedulingSucceeded ? plan.shieldedRules : priorRules.intersection(survivingPriorRules)
                do {
                    try effects.applyScheduledContribution(toApply)
                    var appliedRules = toApply
                    var appliedScopeIDs = schedulingSucceeded ? registeredWindowIDs : priorWindowIDs
                    // After the initial write: at most one grant compensation, plus
                    // two strictly removing writes (one per morning/bedtime rule).
                    // Every actual write is followed by a fresh sample before ack.
                    let maximumAdditionalWrites = 3
                    var writesRemaining = maximumAdditionalWrites
                    for _ in 0...maximumAdditionalWrites {
                        let afterEffects = clock(state)
                        guard let afterNow = ProtectionEngine.advanceClock(state: &state, sample: afterEffects) else {
                            try? rollbackNewGrant(at: logicalNow)
                            cleanupInvalidClock()
                            return .init(plan: plan, grant: nil, effectsApplied: false,
                                         errorDescription: "Clock recovery is pending.")
                        }
                        ProtectionEngine.reconcile(state: &state, at: afterNow)
                        var currentPlan = authorizedPlan(state, at: afterNow, authorized: authorizedWithSelection)
                        if !Set(currentPlan.activeWindows.map(\.id)).isSubset(of: registeredWindowIDs) ||
                            !currentPlan.shieldedRules.isSubset(of: appliedRules) ||
                            (currentPlan.nextReconciliationAt != nil &&
                             currentPlan.nextReconciliationAt != registeredDeadline) ||
                            (newGrant && state.clockLedger?.recoveryEndsAt != nil) {
                            schedulingSucceeded = false
                        }
                        let restoringNewGrant = !schedulingSucceeded && newGrant && grant != nil
                        if restoringNewGrant {
                            try rollbackNewGrant(at: afterNow)
                            currentPlan = authorizedPlan(state, at: afterNow, authorized: authorizedWithSelection)
                            appliedScopeIDs = priorWindowIDs
                        }
                        let survivingRules = Set(currentPlan.activeWindows.filter {
                            appliedScopeIDs.contains($0.id) && currentPlan.shieldedRules.contains($0.rule)
                        }.map(\.rule))
                        let cleanup = (restoringNewGrant ? priorRules : appliedRules).intersection(survivingRules)
                        plan = currentPlan
                        if cleanup != appliedRules {
                            guard writesRemaining > 0 else {
                                state.effectsRecovery?.pending = true
                                try access.save(state)
                                return .init(plan: plan, grant: nil, effectsApplied: false,
                                             errorDescription: "Bounded cleanup requires recovery.")
                            }
                            try effects.applyScheduledContribution(cleanup)
                            appliedRules = cleanup
                            writesRemaining -= 1
                            continue // Includes compensating writes: never ack their old plan.
                        }
                        let appliedIDs = Set(plan.activeWindows.filter {
                            appliedScopeIDs.contains($0.id) && appliedRules.contains($0.rule) &&
                                plan.shieldedRules.contains($0.rule)
                        }.map(\.id))
                        state.effectsRecovery = .init(lastAppliedRules: appliedRules,
                            lastAppliedWindowIDs: appliedIDs, pending: !schedulingSucceeded)
                        try access.save(state)
                        return .init(plan: plan, grant: schedulingSucceeded ? grant : nil,
                            effectsApplied: schedulingSucceeded,
                            errorDescription: schedulingSucceeded ? nil : "Expiry scheduling failed; cleanup applied and recovery is pending.")
                    }
                    // The two-rule monotonic-removal bound makes this unreachable;
                    // retain an explicit unsuccessful outcome if rules expand later.
                    state.effectsRecovery?.pending = true
                    try access.save(state)
                    return .init(plan: plan, grant: nil, effectsApplied: false,
                                 errorDescription: "Bounded cleanup requires recovery.")

                } catch {
                    // Persisted pending marker survives effect failure or acknowledgement
                    // failure. Next foreground/callback retries from freshly loaded state.
                    return .init(plan: plan, grant: nil, effectsApplied: false,
                                 errorDescription: "Protection effects require recovery.")
                }
            }
        } catch {
            return .init(plan: nil, grant: nil, effectsApplied: false,
                         errorDescription: "Protection state was not saved.")
        }
    }

    private func authorizedPlan(_ state: ProtectionState, at now: Date, authorized: Bool) -> ProtectionPlan {
        let plan = ProtectionEngine.plan(state, at: now)
        return authorized ? plan : .init(activeWindows: plan.activeWindows,
                                        shieldedRules: [], nextReconciliationAt: nil)
    }
}
