import Foundation

extension Notification.Name {
    static let moriBeforeFeedIntentDidRecord = Notification.Name("mori.beforeFeed.intentDidRecord")
}

enum MoriBeforeFeedIntentReason: String, Codable, CaseIterable, Identifiable {
    case replyToSomeone = "reply_to_someone"
    case learn
    case relax
    case habit
    case other

    var id: String { rawValue }
}

struct MoriBeforeFeedIntentEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let reason: MoriBeforeFeedIntentReason
    let confirmedAt: Date
    let routeSource: String?
}

struct BeforeFeedGateStore {
    private static let intentEventsKey = "mori_before_feed_intent_events_v1"

    private let defaults: UserDefaults
    private let legacyDefaults: UserDefaults

    init(
        defaults: UserDefaults = MoriAppGroup.defaults,
        legacyDefaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        self.legacyDefaults = legacyDefaults
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
        guard !isInGraceWindow(now: now) else {
            clearPendingResetLaunch()
            return false
        }

        requestResetLaunch(source: source)
        return true
    }

    func clearPendingResetLaunch() {
        defaults.set(false, forKey: MoriScreenTimeShared.beforeFeedPendingResetRequestKey)
        defaults.removeObject(forKey: MoriScreenTimeShared.beforeFeedPendingResetSourceKey)
    }

    func intentEvents() -> [MoriBeforeFeedIntentEvent] {
        guard let data = defaults.data(forKey: Self.intentEventsKey),
              let events = try? JSONDecoder().decode([MoriBeforeFeedIntentEvent].self, from: data)
        else {
            return []
        }

        return events.sorted { $0.confirmedAt < $1.confirmedAt }
    }

    @discardableResult
    func recordIntent(
        reason: MoriBeforeFeedIntentReason,
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
            reason: reason,
            confirmedAt: now,
            routeSource: routeSource
        )
        events.append(event)
        if let encodedEvents = try? JSONEncoder().encode(events) {
            defaults.set(encodedEvents, forKey: Self.intentEventsKey)
        }
        NotificationCenter.default.post(name: .moriBeforeFeedIntentDidRecord, object: event)
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
            if event.confirmedAt >= startOfToday && event.confirmedAt < startOfTomorrow {
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
