import Foundation

struct MindfulnessBellStateStore {
    private let defaults: UserDefaults
    private let now: () -> Date

    init(
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.now = now
    }

    func applyRecommendedDefaults() {
        defaults.set(false, forKey: MindfulnessBellDefaults.randomModeKey)
        defaults.set(30, forKey: MindfulnessBellDefaults.intervalMinutesKey)
        defaults.set(1, forKey: MindfulnessBellDefaults.bellsPerHourKey)
        defaults.set(9, forKey: MindfulnessBellDefaults.startHourKey)
        defaults.set(21, forKey: MindfulnessBellDefaults.endHourKey)
    }

    func shouldRefresh(within leadTime: TimeInterval = 60) -> Bool {
        guard defaults.bool(forKey: MindfulnessBellDefaults.isActiveKey) else { return false }

        guard let nextFireDate else { return true }
        return nextFireDate <= now().addingTimeInterval(leadTime)
    }

    func markActive() {
        defaults.set(true, forKey: MindfulnessBellDefaults.isActiveKey)
    }

    func scheduleSettings() -> MindfulnessBellScheduleSettings {
        MindfulnessBellScheduleSettings(
            randomMode: defaults.bool(forKey: MindfulnessBellDefaults.randomModeKey),
            intervalMinutes: intervalMinutes(),
            bellsPerHour: max(1, defaults.integer(forKey: MindfulnessBellDefaults.bellsPerHourKey)),
            startHour: hourValue(
                forKey: MindfulnessBellDefaults.startHourKey,
                defaultValue: 9
            ),
            endHour: hourValue(
                forKey: MindfulnessBellDefaults.endHourKey,
                defaultValue: 21
            ),
            randomSeed: stableRandomSeed()
        )
    }

    func saveNextFireDate(_ date: Date?) {
        defaults.set(date?.timeIntervalSince1970 ?? 0, forKey: MindfulnessBellDefaults.nextFireKey)
    }

    func clearAll() {
        [
            MindfulnessBellDefaults.isActiveKey,
            MindfulnessBellDefaults.randomModeKey,
            MindfulnessBellDefaults.intervalMinutesKey,
            MindfulnessBellDefaults.bellsPerHourKey,
            MindfulnessBellDefaults.startHourKey,
            MindfulnessBellDefaults.endHourKey,
            MindfulnessBellDefaults.nextFireKey,
            MindfulnessBellDefaults.randomSeedKey,
            MindfulnessBellDefaults.breathingTechniqueIDKey,
            MindfulnessBellDefaults.breathingDurationMinutesKey,
            MindfulnessBellDefaults.promptDismissedKey
        ].forEach { defaults.removeObject(forKey: $0) }
    }

    private var nextFireDate: Date? {
        let timestamp = defaults.double(forKey: MindfulnessBellDefaults.nextFireKey)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    private func intervalMinutes() -> Int {
        let storedMinutes = defaults.integer(forKey: MindfulnessBellDefaults.intervalMinutesKey)
        return storedMinutes == 0 ? 30 : storedMinutes
    }

    private func hourValue(forKey key: String, defaultValue: Int) -> Int {
        defaults.object(forKey: key) == nil ? defaultValue : defaults.integer(forKey: key)
    }

    private func stableRandomSeed() -> UInt64 {
        if let storedSeed = defaults.object(forKey: MindfulnessBellDefaults.randomSeedKey) as? NSNumber {
            return storedSeed.uint64Value
        }

        let seed = UInt64(now().timeIntervalSince1970)
        defaults.set(NSNumber(value: seed), forKey: MindfulnessBellDefaults.randomSeedKey)
        return seed
    }
}

struct MindfulnessBellScheduleSettings {
    let randomMode: Bool
    let intervalMinutes: Int
    let bellsPerHour: Int
    let startHour: Int
    let endHour: Int
    let randomSeed: UInt64
}
