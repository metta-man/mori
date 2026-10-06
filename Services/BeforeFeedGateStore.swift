import Foundation

extension Notification.Name {
    static let moriBeforeFeedIntentDidRecord = Notification.Name("mori.beforeFeed.intentDidRecord")
    static let moriBeforeFeedDecisionDidRecord = Notification.Name("mori.beforeFeed.decisionDidRecord")
}

enum MoriBeforeFeedIntentReason: String, Codable, CaseIterable, Identifiable {
    case replyToSomeone = "reply_to_someone"
    case learn
    case relax
    case habit
    case other

    var id: String { rawValue }
}

enum MoriBeforeFeedDecisionOutcome: String, Codable, Equatable {
    case openWindowRequested = "open_window_requested"
    case keptClosed = "kept_closed"
}

struct MoriBeforeFeedIntentEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let reason: MoriBeforeFeedIntentReason?
    let confirmedAt: Date
    let routeSource: String?
    let enoughChoiceID: String?
    let openWindowSeconds: Int?
    let returnAnchorID: String?
    /// Optional so existing v1 history decodes without a migration. A legacy
    /// nil outcome represents the original open-window intent event.
    let outcome: MoriBeforeFeedDecisionOutcome?

    init(
        id: UUID,
        reason: MoriBeforeFeedIntentReason?,
        confirmedAt: Date,
        routeSource: String?,
        enoughChoiceID: String? = nil,
        openWindowSeconds: Int? = nil,
        returnAnchorID: String? = nil,
        outcome: MoriBeforeFeedDecisionOutcome? = nil
    ) {
        self.id = id
        self.reason = reason
        self.confirmedAt = confirmedAt
        self.routeSource = routeSource
        self.enoughChoiceID = enoughChoiceID
        self.openWindowSeconds = openWindowSeconds
        self.returnAnchorID = returnAnchorID
        self.outcome = outcome
    }

    var resolvedOutcome: MoriBeforeFeedDecisionOutcome {
        outcome ?? .openWindowRequested
    }
}

/// An allowance confirmation, not a measured target-app opening or usage interval.
struct MoriBeforeFeedAllowanceRepeat: Equatable {
    let previousEventID: UUID
    let eventID: UUID
    let secondsSincePreviousAllowance: TimeInterval
    let secondsSincePreviousPlannedEnd: TimeInterval?

    var requestedWithinPreviousPlannedWindow: Bool? {
        secondsSincePreviousPlannedEnd.map { $0 < 0 }
    }
}

struct MoriBeforeFeedFlowEligibility {
    let startedAt: Date
    let allowanceRevision: String
    let historyGeneration: String
}

struct MoriBeforeFeedAllowanceRequest {
    let eligibility: MoriBeforeFeedFlowEligibility?
    let reason: MoriBeforeFeedIntentReason
    let routeSource: String?
    let enoughChoiceID: String
    let openWindowSeconds: Int
    let returnAnchorID: String?
    let eventID: UUID
    let historyGeneration: String
    let now: Date
}

struct MoriBeforeFeedAllowanceConfirmation {
    let event: MoriBeforeFeedIntentEvent
    let endsAt: Date
    let isNew: Bool
}

/// One evaluation per presented entry. Background resume/redraw cannot retrigger.
struct MoriBeforeFeedReentryState: Equatable {
    private(set) var hasEvaluated = false
    private(set) var previousAllowance: MoriBeforeFeedIntentEvent?

    private(set) var allowanceEndsAt: Date?

    mutating func evaluate(events: [MoriBeforeFeedIntentEvent], now: Date, allowanceEndsAt: Date?) {
        guard !hasEvaluated else { return }
        hasEvaluated = true
        guard let allowanceEndsAt, allowanceEndsAt > now else { return }
        self.allowanceEndsAt = allowanceEndsAt
        previousAllowance = events.filter { $0.resolvedOutcome == .openWindowRequested && $0.confirmedAt <= now }
            .max(by: { $0.confirmedAt < $1.confirmedAt })
    }

}

struct BeforeFeedGateStore {
    private static let intentEventsKey = "mori_before_feed_intent_events_v1"
    // Preserve the entire pre-existing v1 history. Only new v2 writes have a cap.
    private static let recentIntentEventsKey = "mori_before_feed_intent_events_v2_recent"
    private static let recentHistoryTruncatedKey = "mori_before_feed_intent_events_v2_truncated"
    static let recentIntentEventLimit = 1000

    private let defaults: UserDefaults
    private static let historyGenerationKey = "mori_before_feed_history_generation"
    private let legacyDefaults: UserDefaults
    private let persistData: ((Data, String) -> Bool)?

    init(
        defaults: UserDefaults = MoriAppGroup.defaults,
        legacyDefaults: UserDefaults = .standard,
        persistData: ((Data, String) -> Bool)? = nil
    ) {
        self.defaults = defaults
        self.legacyDefaults = legacyDefaults
        self.persistData = persistData
    }

    private static let allowanceRevisionKey = "mori_before_feed_allowance_revision"

    /// Capture only when a fresh pause starts without an active allowance.
    func beginFreshAllowanceFlow(now: Date = Date()) -> MoriBeforeFeedFlowEligibility? {
        guard !isInGraceWindow(now: now) else { return nil }
        return MoriBeforeFeedFlowEligibility(startedAt: now, allowanceRevision: defaults.string(forKey: Self.allowanceRevisionKey) ?? "", historyGeneration: historyGeneration)
    }

    var historyGeneration: String { defaults.string(forKey: Self.historyGenerationKey) ?? "" }

    /// Save the decision and allowance before any shield/activity side effects.
    /// A failed local write preserves the previous allowance and is not confirmed.
    func confirmAllowance(_ request: MoriBeforeFeedAllowanceRequest) -> MoriBeforeFeedAllowanceConfirmation? {
        guard historyGeneration == request.historyGeneration else { return nil }
        if let existing = intentEvents().first(where: { $0.id == request.eventID }) {
            guard let seconds = existing.openWindowSeconds, existing.resolvedOutcome == .openWindowRequested else { return nil }
            return MoriBeforeFeedAllowanceConfirmation(event: existing, endsAt: existing.confirmedAt.addingTimeInterval(TimeInterval(seconds)), isNew: false)
        }
        guard let eligibility = request.eligibility,
              eligibility.startedAt <= request.now,
              eligibility.historyGeneration == historyGeneration,
              eligibility.allowanceRevision == (defaults.string(forKey: Self.allowanceRevisionKey) ?? ""),
              !isInGraceWindow(now: request.now) else { return nil }
        let seconds = resolvedGraceWindowSeconds(override: request.openWindowSeconds)
        let until = request.now.addingTimeInterval(TimeInterval(seconds))
        let event = MoriBeforeFeedIntentEvent(
            id: request.eventID, reason: request.reason, confirmedAt: request.now,
            routeSource: request.routeSource, enoughChoiceID: request.enoughChoiceID,
            openWindowSeconds: seconds, returnAnchorID: request.returnAnchorID, outcome: .openWindowRequested
        )
        let previousData = defaults.data(forKey: Self.recentIntentEventsKey)
        let previousGrace = defaults.object(forKey: MoriScreenTimeShared.beforeFeedGraceUntilKey)
        let recent = readEvents(key: Self.recentIntentEventsKey) + [event]
        guard let data = try? JSONEncoder().encode(Array(recent.suffix(Self.recentIntentEventLimit))) else { return nil }
        let wrote: Bool
        if let persistData { wrote = persistData(data, Self.recentIntentEventsKey) }
        else {
            defaults.set(data, forKey: Self.recentIntentEventsKey)
            wrote = defaults.data(forKey: Self.recentIntentEventsKey) == data
        }
        guard wrote, defaults.data(forKey: Self.recentIntentEventsKey) == data,
              historyGeneration == request.historyGeneration,
              eligibility.allowanceRevision == (defaults.string(forKey: Self.allowanceRevisionKey) ?? ""),
              !isInGraceWindow(now: request.now) else {
            if historyGeneration == request.historyGeneration {
                defaults.set(previousData, forKey: Self.recentIntentEventsKey)
            } else if defaults.data(forKey: Self.recentIntentEventsKey) == data {
                // A deletion during the write must not recreate deleted decisions.
                defaults.removeObject(forKey: Self.recentIntentEventsKey)
            }
            return nil
        }
        saveGraceUntil(until, now: request.now)
        guard defaults.double(forKey: MoriScreenTimeShared.beforeFeedGraceUntilKey) == until.timeIntervalSince1970 else {
            defaults.set(previousData, forKey: Self.recentIntentEventsKey)
            defaults.set(previousGrace, forKey: MoriScreenTimeShared.beforeFeedGraceUntilKey)
            return nil
        }
        if recent.count > Self.recentIntentEventLimit { defaults.set(true, forKey: Self.recentHistoryTruncatedKey) }
        NotificationCenter.default.post(name: .moriBeforeFeedIntentDidRecord, object: event)
        NotificationCenter.default.post(name: .moriBeforeFeedDecisionDidRecord, object: event)
        return MoriBeforeFeedAllowanceConfirmation(event: event, endsAt: until, isNew: true)
    }

    func nativeGateEnabled() -> Bool {
        guard defaults.object(forKey: MoriScreenTimeShared.beforeFeedNativeGateEnabledKey) != nil else {
            return MoriScreenTimeShared.defaultBeforeFeedNativeGateEnabled
        }
        return defaults.bool(forKey: MoriScreenTimeShared.beforeFeedNativeGateEnabledKey)
    }

    func saveNativeGateEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: MoriScreenTimeShared.beforeFeedNativeGateEnabledKey)
    }

    func hiddenAppLockEnabled() -> Bool {
        guard defaults.object(forKey: MoriScreenTimeShared.beforeFeedHiddenAppLockEnabledKey) != nil else {
            return MoriScreenTimeShared.defaultBeforeFeedHiddenAppLockEnabled
        }
        return defaults.bool(forKey: MoriScreenTimeShared.beforeFeedHiddenAppLockEnabledKey)
    }

    func windowEndReminderEnabled() -> Bool {
        guard defaults.object(forKey: MoriScreenTimeShared.beforeFeedWindowEndReminderEnabledKey) != nil else {
            return MoriScreenTimeShared.defaultBeforeFeedWindowEndReminderEnabled
        }
        return defaults.bool(forKey: MoriScreenTimeShared.beforeFeedWindowEndReminderEnabledKey)
    }

    func saveWindowEndReminderEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: MoriScreenTimeShared.beforeFeedWindowEndReminderEnabledKey)
    }

    func durationSeconds() -> Int {
        migrateLegacyDurationIfNeeded()
        let saved = defaults.integer(forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey)
        let normalized = normalizedDurationSeconds(saved > 0 ? saved : MoriScreenTimeShared.defaultBeforeFeedDurationSeconds)
        if saved != normalized {
            defaults.set(normalized, forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey)
        }
        return normalized
    }

    func saveDurationSeconds(_ seconds: Int) {
        defaults.set(normalizedDurationSeconds(seconds), forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey)
    }

    func graceWindowSeconds() -> Int {
        let saved = defaults.integer(forKey: MoriScreenTimeShared.beforeFeedGraceWindowSecondsKey)
        let normalized = normalizedGraceWindowSeconds(saved > 0 ? saved : MoriScreenTimeShared.defaultBeforeFeedGraceWindowSeconds)
        if saved != normalized {
            defaults.set(normalized, forKey: MoriScreenTimeShared.beforeFeedGraceWindowSecondsKey)
        }
        return normalized
    }

    func saveGraceWindowSeconds(_ seconds: Int) {
        defaults.set(normalizedGraceWindowSeconds(seconds), forKey: MoriScreenTimeShared.beforeFeedGraceWindowSecondsKey)
    }

    /// Resolves a single Before Feed window without changing the person's
    /// saved default. A nil override retains the legacy/global behavior.
    func resolvedGraceWindowSeconds(override requestedSeconds: Int?) -> Int {
        guard let requestedSeconds else { return graceWindowSeconds() }
        return normalizedGraceWindowSeconds(requestedSeconds)
    }

    func graceUntil(now: Date = Date()) -> Date? {
        guard let storedGraceUntil = storedGraceUntil() else { return nil }
        guard storedGraceUntil > now else {
            clearGraceUntil()
            return nil
        }

        let latestAllowedGraceUntil = now.addingTimeInterval(TimeInterval(MoriScreenTimeShared.maxBeforeFeedGraceWindowSeconds))
        guard storedGraceUntil <= latestAllowedGraceUntil else {
            saveGraceUntil(latestAllowedGraceUntil, now: now)
            return latestAllowedGraceUntil
        }

        return storedGraceUntil
    }

    func isInGraceWindow(now: Date = Date()) -> Bool {
        graceUntil(now: now) != nil
    }

    /// Reusing never writes history or renews the deadline. Reject expired/replaced/stale windows.
    func canReuseAllowance(endsAt: Date, historyGeneration: String, now: Date = Date()) -> Bool {
        guard self.historyGeneration == historyGeneration, endsAt > now else { return false }
        return storedGraceUntil() == endsAt
    }

    /// A queued expiry belongs only to its captured window, never a replacement.
    func shouldReapplyExpiredAllowance(endsAt: Date, now: Date = Date()) -> Bool {
        endsAt <= now && storedGraceUntil() == endsAt
    }

    func secondsUntilGraceExpires(now: Date = Date()) -> TimeInterval? {
        guard let graceUntil = graceUntil(now: now) else { return nil }
        let remaining = graceUntil.timeIntervalSince(now)
        return remaining > 0 ? remaining : nil
    }

    func migrateLegacyDurationIfNeeded() {
        guard defaults.object(forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey) == nil else { return }

        let groupMinutes = defaults.integer(forKey: MoriScreenTimeShared.beforeFeedDurationMinutesKey)
        let standardMinutes = legacyDefaults.integer(forKey: MoriScreenTimeShared.beforeFeedDurationMinutesKey)
        let legacyMinutes = groupMinutes > 0 ? groupMinutes : standardMinutes
        let duration = legacyMinutes > 0
            ? normalizedDurationSeconds(legacyMinutes * 60)
            : MoriScreenTimeShared.defaultBeforeFeedDurationSeconds

        defaults.set(duration, forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey)
    }

    private func requestResetLaunch(source: MoriPendingResetLaunchSource) {
        defaults.set(true, forKey: MoriScreenTimeShared.beforeFeedPendingResetRequestKey)
        defaults.set(source.rawValue, forKey: MoriScreenTimeShared.beforeFeedPendingResetSourceKey)
    }

    @discardableResult
    func requestResetLaunchIfNeeded(
        now: Date = Date(),
        source: MoriPendingResetLaunchSource = .screenTimeGate
    ) -> Bool {
        requestResetLaunch(source: source)
        return true
    }

    func clearPendingResetLaunch() {
        defaults.set(false, forKey: MoriScreenTimeShared.beforeFeedPendingResetRequestKey)
        defaults.removeObject(forKey: MoriScreenTimeShared.beforeFeedPendingResetSourceKey)
    }

    func intentEvents() -> [MoriBeforeFeedIntentEvent] {
        var seen = Set<UUID>()
        return (readEvents(key: Self.intentEventsKey) + readEvents(key: Self.recentIntentEventsKey))
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.confirmedAt < $1.confirmedAt }
    }

    /// Derived from confirmed allowance requests only. Cancelled resets and kept-
    /// closed decisions grant no allowance and never become the previous window.
    /// The planned end is not an observed end: a reset can close the window early.
    func allowanceRepeats() -> [MoriBeforeFeedAllowanceRepeat] {
        let requests = intentEvents().filter { $0.resolvedOutcome == .openWindowRequested }
        let legacyIDs = Set(readEvents(key: Self.intentEventsKey).map(\.id))
        let hasGap = defaults.bool(forKey: Self.recentHistoryTruncatedKey)
        return zip(requests, requests.dropFirst()).compactMap { previous, current in
            // Do not report a direct repeat across a retention gap.
            if hasGap && legacyIDs.contains(previous.id) != legacyIDs.contains(current.id) { return nil }
            return
            MoriBeforeFeedAllowanceRepeat(
                previousEventID: previous.id,
                eventID: current.id,
                secondsSincePreviousAllowance: max(0, current.confirmedAt.timeIntervalSince(previous.confirmedAt)),
                secondsSincePreviousPlannedEnd: previous.openWindowSeconds.flatMap { seconds in
                    guard seconds > 0 else { return nil }
                    return current.confirmedAt.timeIntervalSince(previous.confirmedAt.addingTimeInterval(TimeInterval(seconds)))
                }
            )
        }
    }

    private func readEvents(key: String) -> [MoriBeforeFeedIntentEvent] {
        guard let data = defaults.data(forKey: key),
              let events = try? JSONDecoder().decode([MoriBeforeFeedIntentEvent].self, from: data)
        else { return [] }
        return events
    }

    @discardableResult
    func recordIntent(
        reason: MoriBeforeFeedIntentReason,
        routeSource: String?,
        enoughChoiceID: String? = nil,
        openWindowSeconds: Int? = nil,
        returnAnchorID: String? = nil,
        eventID: UUID = UUID(),
        now: Date = Date()
    ) -> MoriBeforeFeedIntentEvent {
        var events = intentEvents()
        if let existingEvent = events.first(where: { $0.id == eventID }) {
            return existingEvent
        }

        let event = MoriBeforeFeedIntentEvent(
            id: eventID,
            reason: reason,
            confirmedAt: now,
            routeSource: routeSource,
            enoughChoiceID: enoughChoiceID,
            openWindowSeconds: openWindowSeconds,
            returnAnchorID: returnAnchorID,
            outcome: .openWindowRequested
        )
        save(event, to: &events)
        NotificationCenter.default.post(name: .moriBeforeFeedIntentDidRecord, object: event)
        NotificationCenter.default.post(name: .moriBeforeFeedDecisionDidRecord, object: event)
        return event
    }

    /// Records the explicit choice to leave the protected feed closed. This is
    /// deliberately independent of reason and window selection because the
    /// choice is available immediately after the breath key.
    @discardableResult
    func recordKeptClosed(
        routeSource: String?,
        eventID: UUID = UUID(),
        now: Date = Date()
    ) -> MoriBeforeFeedIntentEvent {
        var events = intentEvents()
        if let existingEvent = events.first(where: { $0.id == eventID }) {
            return existingEvent
        }

        let event = MoriBeforeFeedIntentEvent(
            id: eventID,
            reason: nil,
            confirmedAt: now,
            routeSource: routeSource,
            outcome: .keptClosed
        )
        save(event, to: &events)
        NotificationCenter.default.post(name: .moriBeforeFeedDecisionDidRecord, object: event)
        return event
    }

    func todayIntentCount(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            return 0
        }

        return intentEvents().reduce(into: 0) { count, event in
            if event.resolvedOutcome == .openWindowRequested,
               event.confirmedAt >= startOfToday,
               event.confirmedAt < startOfTomorrow {
                count += 1
            }
        }
    }

    func todayKeptClosedCount(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            return 0
        }

        return intentEvents().reduce(into: 0) { count, event in
            if event.outcome == .keptClosed,
               event.confirmedAt >= startOfToday,
               event.confirmedAt < startOfTomorrow {
                count += 1
            }
        }
    }

    func consumePendingResetLaunch() -> MoriPendingResetLaunchSource? {
        guard defaults.bool(forKey: MoriScreenTimeShared.beforeFeedPendingResetRequestKey) else {
            return nil
        }

        let source = defaults.string(forKey: MoriScreenTimeShared.beforeFeedPendingResetSourceKey)
            .flatMap(MoriPendingResetLaunchSource.init(rawValue:)) ?? .screenTimeGate
        clearPendingResetLaunch()
        return source
    }

    @discardableResult
    func beginWindowTrace() -> String {
        let traceID = UUID().uuidString
        defaults.set(traceID, forKey: MoriScreenTimeShared.beforeFeedWindowTraceIDKey)
        return traceID
    }

    func currentWindowTraceID() -> String? {
        defaults.string(forKey: MoriScreenTimeShared.beforeFeedWindowTraceIDKey)
    }

    func saveGraceUntil(_ date: Date, now: Date = Date()) {
        guard date > now else {
            clearGraceUntil()
            return
        }

        defaults.set(UUID().uuidString, forKey: Self.allowanceRevisionKey)
        let latestAllowedGraceUntil = now.addingTimeInterval(TimeInterval(MoriScreenTimeShared.maxBeforeFeedGraceWindowSeconds))
        defaults.set(
            min(date, latestAllowedGraceUntil).timeIntervalSince1970,
            forKey: MoriScreenTimeShared.beforeFeedGraceUntilKey
        )
    }

    func clearGraceUntil() {
        defaults.removeObject(forKey: MoriScreenTimeShared.beforeFeedGraceUntilKey)
    }

    @discardableResult
    func clearExpiredGraceIfNeeded(now: Date = Date()) -> Bool {
        guard let storedGraceUntil = storedGraceUntil() else {
            return false
        }

        if storedGraceUntil <= now {
            clearGraceUntil()
            return true
        }

        _ = graceUntil(now: now)
        return false
    }

    func normalizePersistedSettings(now: Date = Date()) {
        _ = durationSeconds()
        _ = graceWindowSeconds()
        _ = graceUntil(now: now)
    }

    func clearIntentHistory() {
        defaults.set(UUID().uuidString, forKey: Self.historyGenerationKey)
        defaults.removeObject(forKey: Self.intentEventsKey)
        defaults.removeObject(forKey: Self.recentIntentEventsKey)
        defaults.removeObject(forKey: Self.recentHistoryTruncatedKey)
        NotificationCenter.default.post(name: .moriBeforeFeedDecisionDidRecord, object: nil)
    }

    private func save(
        _ event: MoriBeforeFeedIntentEvent,
        to events: inout [MoriBeforeFeedIntentEvent]
    ) {
        var recentEvents = readEvents(key: Self.recentIntentEventsKey)
        recentEvents.append(event)
        if recentEvents.count > Self.recentIntentEventLimit {
            defaults.set(true, forKey: Self.recentHistoryTruncatedKey)
        }
        recentEvents = Array(recentEvents.suffix(Self.recentIntentEventLimit))
        if let encodedEvents = try? JSONEncoder().encode(recentEvents) {
            defaults.set(encodedEvents, forKey: Self.recentIntentEventsKey)
        }
    }

    private func normalizedDurationSeconds(_ seconds: Int) -> Int {
        min(
            MoriScreenTimeShared.maxBeforeFeedDurationSeconds,
            max(MoriScreenTimeShared.minBeforeFeedDurationSeconds, seconds)
        )
    }

    private func normalizedGraceWindowSeconds(_ seconds: Int) -> Int {
        min(
            MoriScreenTimeShared.maxBeforeFeedGraceWindowSeconds,
            max(MoriScreenTimeShared.minBeforeFeedGraceWindowSeconds, seconds)
        )
    }

    private func storedGraceUntil() -> Date? {
        let timestamp = defaults.double(forKey: MoriScreenTimeShared.beforeFeedGraceUntilKey)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
}
