import Foundation

struct AttentionShieldStateStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = MoriAppGroup.defaults) {
        self.defaults = defaults
    }

    func saveCurrentShield(feature: MoriScreenTimeFeature, displayNames: [String]) {
        saveCurrentFeature(feature)
        MoriScreenTimeSavedTimeEstimator.persistCurrentEstimate(
            feature: feature,
            displayNames: displayNames,
            defaults: defaults
        )
    }

    private func saveCurrentFeature(_ feature: MoriScreenTimeFeature) {
        defaults.set(feature.rawValue, forKey: MoriScreenTimeShared.currentShieldFeatureKey)
    }

    func loadCurrentFeature() -> MoriScreenTimeFeature? {
        guard let rawValue = defaults.string(forKey: MoriScreenTimeShared.currentShieldFeatureKey) else {
            return nil
        }
        return MoriScreenTimeFeature(rawValue: rawValue)
    }

    private func clearCurrentFeature() {
        defaults.removeObject(forKey: MoriScreenTimeShared.currentShieldFeatureKey)
    }

    func clearCurrentShield() {
        clearCurrentFeature()
        MoriScreenTimeSavedTimeEstimator.clearCurrentEstimate(defaults: defaults)
    }
}
