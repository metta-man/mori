import Foundation
import FamilyControls

struct ScreenTimeSelectionPersistence {
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = MoriAppGroup.defaults,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.encoder = encoder
        self.decoder = decoder
    }

    func loadDefaultDisplayNames() -> [String] {
        defaults.stringArray(forKey: MoriScreenTimeShared.defaultSelectionDisplayNamesKey) ?? []
    }

    func saveDefaultDisplayNames(_ names: [String]) {
        defaults.set(names, forKey: MoriScreenTimeShared.defaultSelectionDisplayNamesKey)
    }

    func loadProfiles() -> [String: MoriScreenTimeFeatureProfile] {
        guard let data = defaults.data(forKey: MoriScreenTimeShared.featureProfilesKey),
              let decoded = try? decoder.decode([String: MoriScreenTimeFeatureProfile].self, from: data)
        else {
            return [:]
        }

        return decoded
    }

    func saveProfiles(_ profiles: [String: MoriScreenTimeFeatureProfile]) {
        guard let data = try? encoder.encode(profiles) else { return }
        defaults.set(data, forKey: MoriScreenTimeShared.featureProfilesKey)
    }

    func loadSelection(forKey key: String) -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(FamilyActivitySelection.self, from: data)
    }

    func saveSelection(_ selection: FamilyActivitySelection, forKey key: String) {
        guard let data = try? encoder.encode(selection) else { return }
        defaults.set(data, forKey: key)
    }

    func hasCompletedFeatureMigration() -> Bool {
        defaults.bool(forKey: MoriScreenTimeShared.featureMigrationKey)
    }

    func migrateLegacyDefaultSelectionIfNeeded() {
        guard defaults.data(forKey: MoriScreenTimeShared.defaultSelectionKey) == nil,
              let legacyData = defaults.data(forKey: MoriScreenTimeShared.selectionKey) else {
            return
        }

        defaults.set(legacyData, forKey: MoriScreenTimeShared.defaultSelectionKey)
    }

    func markFeatureMigrationCompleted() {
        defaults.set(true, forKey: MoriScreenTimeShared.featureMigrationKey)
    }

    func hasCompletedBeforeFeedDedicatedSelectionMigration() -> Bool {
        defaults.bool(forKey: MoriScreenTimeShared.beforeFeedDedicatedSelectionMigrationKey)
    }

    func markBeforeFeedDedicatedSelectionMigrationCompleted() {
        defaults.set(true, forKey: MoriScreenTimeShared.beforeFeedDedicatedSelectionMigrationKey)
    }

    func clearAll() {
        defaults.removeObject(forKey: MoriScreenTimeShared.selectionKey)
        defaults.removeObject(forKey: MoriScreenTimeShared.defaultSelectionKey)
        defaults.removeObject(forKey: MoriScreenTimeShared.defaultSelectionDisplayNamesKey)
        defaults.removeObject(forKey: MoriScreenTimeShared.featureProfilesKey)
        defaults.removeObject(forKey: MoriScreenTimeShared.featureMigrationKey)
        defaults.removeObject(forKey: MoriScreenTimeShared.beforeFeedDedicatedSelectionMigrationKey)
        for feature in MoriScreenTimeFeature.allCases {
            defaults.removeObject(forKey: MoriScreenTimeShared.featureSelectionKeyPrefix + feature.rawValue)
        }
    }
}
