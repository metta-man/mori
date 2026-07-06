import Foundation

struct AttentionShieldThresholdStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = MoriAppGroup.defaults) {
        self.defaults = defaults
    }

    func loadDailyThresholdMinutes() -> Int {
        let saved = defaults.integer(forKey: MoriScreenTimeShared.dailyThresholdMinutesKey)
        return saved > 0
            ? normalizedDailyThresholdMinutes(saved)
            : MoriScreenTimeShared.defaultDailyThresholdMinutes
    }

    @discardableResult
    func saveDailyThresholdMinutes(_ minutes: Int) -> Int {
        let normalized = normalizedDailyThresholdMinutes(minutes)
        defaults.set(normalized, forKey: MoriScreenTimeShared.dailyThresholdMinutesKey)
        return normalized
    }

    func normalizedDailyThresholdMinutes(_ minutes: Int) -> Int {
        min(240, max(5, minutes))
    }
}
