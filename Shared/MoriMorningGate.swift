import Foundation

struct MoriMorningGateWindow: Equatable {
    let start: Date
    let end: Date
    let dateKey: String
}

enum MorningGate {
    private static let store = MorningGateStore()

    static var isEnabled: Bool {
        get {
            store.isEnabled()
        }
        set {
            store.saveIsEnabled(newValue)
        }
    }

    static var startHour: Int {
        get {
            store.startHour()
        }
        set {
            store.saveStartHour(newValue)
        }
    }

    static var startMinute: Int {
        get {
            store.startMinute()
        }
        set {
            store.saveStartMinute(newValue)
        }
    }

    static var durationSeconds: Int {
        get {
            store.durationSeconds()
        }
        set {
            store.saveDurationSeconds(newValue)
        }
    }

    static var hiddenAppLockEnabled: Bool {
        get {
            store.hiddenAppLockEnabled()
        }
        set {
            store.saveHiddenAppLockEnabled(newValue)
        }
    }

    static var startComponents: DateComponents {
        DateComponents(hour: startHour, minute: startMinute)
    }

    static var endComponents: DateComponents {
        let startTotalMinutes = startHour * 60 + startMinute
        let durationMinutes = max(1, durationSeconds / 60)
        let endTotalMinutes = (startTotalMinutes + durationMinutes) % (24 * 60)
        return DateComponents(hour: endTotalMinutes / 60, minute: endTotalMinutes % 60)
    }

    static func activeWindow(now: Date = Date(), calendar: Calendar = .current) -> MoriMorningGateWindow? {
        guard isEnabled,
              let todayStart = startDate(containing: now, calendar: calendar)
        else {
            return nil
        }

        let starts = [
            todayStart,
            calendar.date(byAdding: .day, value: -1, to: todayStart)
        ].compactMap { $0 }

        return starts
            .map { start in
                MoriMorningGateWindow(
                    start: start,
                    end: start.addingTimeInterval(TimeInterval(durationSeconds)),
                    dateKey: MoriScreenTimeShared.dateKey(for: start)
                )
            }
            .first { now >= $0.start && now < $0.end }
    }

    static func shouldApplyShield(now: Date = Date()) -> Bool {
        guard let window = activeWindow(now: now) else { return false }
        return !store.hasCompletedWindow(dateKey: window.dateKey)
    }

    static func completeResetForActiveWindow(now: Date = Date()) {
        let key = activeWindow(now: now)?.dateKey ?? MoriScreenTimeShared.dateKey(for: now)
        store.saveCompletedWindow(dateKey: key)
    }

    static func normalizePersistedSettings() {
        store.normalizePersistedSettings()
    }

    static func requestResetLaunch(source: MoriPendingResetLaunchSource = .screenTimeGate) {
        store.requestResetLaunch(source: source)
    }

    static func consumePendingResetLaunch() -> MoriPendingResetLaunchSource? {
        store.consumePendingResetLaunch()
    }

    static func formattedDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return MoriL10n.string("duration.seconds", defaultValue: "%d seconds", arguments: [seconds])
        }

        let minutes = seconds / 60
        return MoriL10n.string(
            minutes == 1 ? "duration.minute_one" : "duration.minutes",
            defaultValue: minutes == 1 ? "%d minute" : "%d minutes",
            arguments: [minutes]
        )
    }

    private static func startDate(containing date: Date, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = startHour
        components.minute = startMinute
        components.second = 0
        return calendar.date(from: components)
    }
}

private struct MorningGateStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = MoriAppGroup.defaults) {
        self.defaults = defaults
    }

    func isEnabled() -> Bool {
        guard defaults.object(forKey: MoriScreenTimeShared.morningGateEnabledKey) != nil else {
            return MoriScreenTimeShared.defaultMorningGateEnabled
        }
        return defaults.bool(forKey: MoriScreenTimeShared.morningGateEnabledKey)
    }

    func saveIsEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: MoriScreenTimeShared.morningGateEnabledKey)
    }

    func startHour() -> Int {
        let saved = defaults.object(forKey: MoriScreenTimeShared.morningGateStartHourKey) == nil
            ? MoriScreenTimeShared.defaultMorningGateStartHour
            : defaults.integer(forKey: MoriScreenTimeShared.morningGateStartHourKey)
        return min(23, max(0, saved))
    }

    func saveStartHour(_ hour: Int) {
        defaults.set(min(23, max(0, hour)), forKey: MoriScreenTimeShared.morningGateStartHourKey)
    }

    func startMinute() -> Int {
        let saved = defaults.object(forKey: MoriScreenTimeShared.morningGateStartMinuteKey) == nil
            ? MoriScreenTimeShared.defaultMorningGateStartMinute
            : defaults.integer(forKey: MoriScreenTimeShared.morningGateStartMinuteKey)
        return min(59, max(0, saved))
    }

    func saveStartMinute(_ minute: Int) {
        defaults.set(min(59, max(0, minute)), forKey: MoriScreenTimeShared.morningGateStartMinuteKey)
    }

    func durationSeconds() -> Int {
        let saved = defaults.integer(forKey: MoriScreenTimeShared.morningGateDurationSecondsKey)
        let normalized = normalizedDurationSeconds(saved > 0 ? saved : MoriScreenTimeShared.defaultMorningGateDurationSeconds)
        if saved != normalized {
            defaults.set(normalized, forKey: MoriScreenTimeShared.morningGateDurationSecondsKey)
        }
        return normalized
    }

    func saveDurationSeconds(_ seconds: Int) {
        defaults.set(normalizedDurationSeconds(seconds), forKey: MoriScreenTimeShared.morningGateDurationSecondsKey)
    }

    func hiddenAppLockEnabled() -> Bool {
        guard defaults.object(forKey: MoriScreenTimeShared.morningGateHiddenAppLockEnabledKey) != nil else {
            return MoriScreenTimeShared.defaultMorningGateHiddenAppLockEnabled
        }
        return defaults.bool(forKey: MoriScreenTimeShared.morningGateHiddenAppLockEnabledKey)
    }

    func saveHiddenAppLockEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: MoriScreenTimeShared.morningGateHiddenAppLockEnabledKey)
    }

    func hasCompletedWindow(dateKey: String) -> Bool {
        defaults.string(forKey: MoriScreenTimeShared.morningGateCompletedDateKey) == dateKey
    }

    func saveCompletedWindow(dateKey: String) {
        defaults.set(dateKey, forKey: MoriScreenTimeShared.morningGateCompletedDateKey)
    }

    func requestResetLaunch(source: MoriPendingResetLaunchSource) {
        defaults.set(true, forKey: MoriScreenTimeShared.morningGatePendingResetRequestKey)
        defaults.set(source.rawValue, forKey: MoriScreenTimeShared.morningGatePendingResetSourceKey)
    }

    func consumePendingResetLaunch() -> MoriPendingResetLaunchSource? {
        guard defaults.bool(forKey: MoriScreenTimeShared.morningGatePendingResetRequestKey) else {
            return nil
        }

        let source = defaults.string(forKey: MoriScreenTimeShared.morningGatePendingResetSourceKey)
            .flatMap(MoriPendingResetLaunchSource.init(rawValue:)) ?? .screenTimeGate
        clearPendingResetLaunch()
        return source
    }

    func normalizePersistedSettings() {
        if defaults.object(forKey: MoriScreenTimeShared.morningGateEnabledKey) == nil {
            saveIsEnabled(MoriScreenTimeShared.defaultMorningGateEnabled)
        }

        if defaults.object(forKey: MoriScreenTimeShared.morningGateStartHourKey) == nil {
            saveStartHour(MoriScreenTimeShared.defaultMorningGateStartHour)
        } else {
            saveStartHour(startHour())
        }

        if defaults.object(forKey: MoriScreenTimeShared.morningGateStartMinuteKey) == nil {
            saveStartMinute(MoriScreenTimeShared.defaultMorningGateStartMinute)
        } else {
            saveStartMinute(startMinute())
        }

        if defaults.object(forKey: MoriScreenTimeShared.morningGateHiddenAppLockEnabledKey) == nil {
            saveHiddenAppLockEnabled(MoriScreenTimeShared.defaultMorningGateHiddenAppLockEnabled)
        }

        _ = durationSeconds()
    }

    private func clearPendingResetLaunch() {
        defaults.set(false, forKey: MoriScreenTimeShared.morningGatePendingResetRequestKey)
        defaults.removeObject(forKey: MoriScreenTimeShared.morningGatePendingResetSourceKey)
    }

    private func normalizedDurationSeconds(_ seconds: Int) -> Int {
        min(2 * 60 * 60, max(5 * 60, seconds))
    }
}
