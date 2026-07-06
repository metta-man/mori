import Foundation

struct UserSettingsSnapshot {
    let archiveStartDate: Date
    let archiveSpanYears: Int
    let localePreference: MoriLocalePreference
    let hasCompletedOnboarding: Bool
    let weeklyIntentions: [WeeklyIntention]
}

struct UserSettingsStore {
    private enum Key {
        static let archiveStartDate = "archiveStartDate"
        static let archiveStartDateLegacyKey = "birthDate"
        static let archiveSpanYears = "archiveSpanYears"
        static let legacyLifeExpectancy = "lifeExpectancy"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let weeklyIntentions = "weeklyIntentions"
        static let legacyWeeklyIntention = "weeklyIntention"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UserSettingsSnapshot {
        return UserSettingsSnapshot(
            archiveStartDate: defaults.object(forKey: Key.archiveStartDate) as? Date ??
                defaults.object(forKey: Key.archiveStartDateLegacyKey) as? Date ??
                Calendar.current.date(byAdding: .year, value: -30, to: Date())!,
            archiveSpanYears: positiveInteger(
                forKey: Key.archiveSpanYears,
                fallback: positiveInteger(forKey: Key.legacyLifeExpectancy, fallback: 80)
            ),
            localePreference: defaults.string(forKey: MoriLocalePreference.defaultsKey)
                .flatMap(MoriLocalePreference.init(rawValue:)) ?? MoriLocalePreference.load(),
            hasCompletedOnboarding: screenshotAuditOnboardingOverride ?? defaults.bool(forKey: Key.hasCompletedOnboarding),
            weeklyIntentions: loadWeeklyIntentions()
        )
    }

    func saveArchiveStartDate(_ archiveStartDate: Date) {
        defaults.set(archiveStartDate, forKey: Key.archiveStartDate)
    }

    func saveArchiveSpanYears(_ archiveSpanYears: Int) {
        defaults.set(archiveSpanYears, forKey: Key.archiveSpanYears)
    }

    func saveLocalePreference(_ preference: MoriLocalePreference) {
        defaults.set(preference.rawValue, forKey: MoriLocalePreference.defaultsKey)
        MoriLocalePreference.save(preference)
    }

    func saveHasCompletedOnboarding(_ hasCompletedOnboarding: Bool) {
        defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding)
    }

    func saveWeeklyIntentions(_ intentions: [WeeklyIntention]) {
        if let data = try? encoder.encode(intentions) {
            defaults.set(data, forKey: Key.weeklyIntentions)
        } else {
            defaults.removeObject(forKey: Key.weeklyIntentions)
        }
    }

    private func positiveInteger(forKey key: String, fallback: Int) -> Int {
        let value = defaults.integer(forKey: key)
        return value > 0 ? value : fallback
    }

    private var screenshotAuditOnboardingOverride: Bool? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-MoriForceOnboardingForUITest") {
            return false
        }
        if arguments.contains("-MoriSkipOnboardingForUITest") {
            return true
        }
        #endif

        return nil
    }

    private func loadWeeklyIntentions() -> [WeeklyIntention] {
        if let data = defaults.data(forKey: Key.weeklyIntentions),
           let decoded = try? decoder.decode([WeeklyIntention].self, from: data) {
            return decoded
        }

        guard let data = defaults.data(forKey: Key.legacyWeeklyIntention),
              let legacy = try? decoder.decode(WeeklyIntention.self, from: data) else {
            return []
        }

        return [legacy]
    }
}
