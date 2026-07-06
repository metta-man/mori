import Foundation
import FamilyControls

struct MoriScreenTimeFeatureProfile: Codable, Equatable {
    var isEnabled: Bool
    var usesDefaultSelection: Bool
    var displayNames: [String]

    init(
        isEnabled: Bool = false,
        usesDefaultSelection: Bool = true,
        displayNames: [String] = []
    ) {
        self.isEnabled = isEnabled
        self.usesDefaultSelection = usesDefaultSelection
        self.displayNames = displayNames
    }
}

struct MoriScreenTimeProfileSummary: Identifiable, Equatable {
    let feature: MoriScreenTimeFeature
    let isEnabled: Bool
    let usesDefaultSelection: Bool
    let customSelectedCount: Int
    let effectiveSelectedCount: Int
    let displayNames: [String]

    var id: String { feature.id }

    var hasEffectiveSelection: Bool {
        effectiveSelectedCount > 0
    }

    var selectionStatusText: String {
        guard hasEffectiveSelection else { return MoriL10n.string("screen_time.status.no_apps_selected", defaultValue: "No apps selected") }
        if !displayNames.isEmpty {
            return displayNames.prefix(3).joined(separator: ", ") +
                (displayNames.count > 3 ? " +\(displayNames.count - 3)" : "")
        }
        return MoriL10n.string(
            "screen_time.status.selected_count",
            defaultValue: "%d selected",
            arguments: [effectiveSelectedCount]
        )
    }

    var statusText: String {
        guard isEnabled else { return MoriL10n.string("screen_time.status.off", defaultValue: "Off") }
        return selectionStatusText
    }
}

struct ScreenTimeSelectionStore {
    private let persistence: ScreenTimeSelectionPersistence

    init(persistence: ScreenTimeSelectionPersistence = ScreenTimeSelectionPersistence()) {
        self.persistence = persistence
        migrateLegacySelectionIfNeeded()
    }

    func loadDefaultSelection() -> FamilyActivitySelection {
        loadSelection(forKey: MoriScreenTimeShared.defaultSelectionKey)
    }

    func saveDefaultSelection(_ selection: FamilyActivitySelection, displayNames: [String] = []) {
        saveSelection(supportedSelection(selection), forKey: MoriScreenTimeShared.defaultSelectionKey)
        saveDefaultDisplayNames(displayNames)
    }

    func loadSelection(for feature: MoriScreenTimeFeature) -> FamilyActivitySelection {
        loadSelection(forKey: selectionKey(for: feature))
    }

    func saveSelection(
        _ selection: FamilyActivitySelection,
        for feature: MoriScreenTimeFeature,
        displayNames: [String] = []
    ) {
        saveSelection(supportedSelection(selection), forKey: selectionKey(for: feature))
        var profile = profile(for: feature)
        profile.displayNames = displayNames
        saveProfile(profile, for: feature)
    }

    func supportedSelection(_ selection: FamilyActivitySelection) -> FamilyActivitySelection {
        var supported = FamilyActivitySelection()
        supported.applicationTokens = selection.applicationTokens
        supported.webDomainTokens = selection.webDomainTokens
        return supported
    }

    func effectiveSelection(for feature: MoriScreenTimeFeature) -> FamilyActivitySelection {
        let profile = profile(for: feature)
        return profile.usesDefaultSelection ? loadDefaultSelection() : loadSelection(for: feature)
    }

    func mergedEffectiveSelection(for features: [MoriScreenTimeFeature]) -> FamilyActivitySelection {
        let mergedSelection = features.reduce(into: FamilyActivitySelection()) { result, feature in
            let selection = effectiveSelection(for: feature)
            result.applicationTokens.formUnion(selection.applicationTokens)
            result.webDomainTokens.formUnion(selection.webDomainTokens)
        }

        return supportedSelection(mergedSelection)
    }

    func profile(for feature: MoriScreenTimeFeature) -> MoriScreenTimeFeatureProfile {
        profiles()[feature.rawValue] ?? defaultProfile(for: feature)
    }

    func saveProfile(_ profile: MoriScreenTimeFeatureProfile, for feature: MoriScreenTimeFeature) {
        var profiles = profiles()
        profiles[feature.rawValue] = profile
        saveProfiles(profiles)
    }

    func summaries() -> [MoriScreenTimeProfileSummary] {
        MoriScreenTimeFeature.allCases.map(summary(for:))
    }

    func summary(for feature: MoriScreenTimeFeature) -> MoriScreenTimeProfileSummary {
        let profile = profile(for: feature)
        let customCount = selectedCount(loadSelection(for: feature))
        let effectiveSelection = effectiveSelection(for: feature)
        let effectiveCount = selectedCount(effectiveSelection)
        let names = profile.usesDefaultSelection ? loadDefaultDisplayNames() : profile.displayNames

        return MoriScreenTimeProfileSummary(
            feature: feature,
            isEnabled: profile.isEnabled,
            usesDefaultSelection: profile.usesDefaultSelection,
            customSelectedCount: customCount,
            effectiveSelectedCount: effectiveCount,
            displayNames: names
        )
    }

    var hasDefaultSelection: Bool {
        selectedCount(loadDefaultSelection()) > 0
    }

    var defaultSelectedCount: Int {
        selectedCount(loadDefaultSelection())
    }

    func hasEffectiveSelection(for feature: MoriScreenTimeFeature) -> Bool {
        profile(for: feature).isEnabled && selectedCount(effectiveSelection(for: feature)) > 0
    }

    func effectiveSelectedCount(for feature: MoriScreenTimeFeature) -> Int {
        selectedCount(effectiveSelection(for: feature))
    }

    func selectedCount(_ selection: FamilyActivitySelection) -> Int {
        let selection = supportedSelection(selection)
        return selection.applicationTokens.count + selection.webDomainTokens.count
    }

    func loadDefaultDisplayNames() -> [String] {
        persistence.loadDefaultDisplayNames()
    }

    func saveDefaultDisplayNames(_ names: [String]) {
        persistence.saveDefaultDisplayNames(names)
    }

    private func profiles() -> [String: MoriScreenTimeFeatureProfile] {
        persistence.loadProfiles()
    }

    private func saveProfiles(_ profiles: [String: MoriScreenTimeFeatureProfile]) {
        persistence.saveProfiles(profiles)
    }

    private func defaultProfile(for feature: MoriScreenTimeFeature) -> MoriScreenTimeFeatureProfile {
        switch feature {
        case .quiet, .pomodoroFocus:
            return MoriScreenTimeFeatureProfile(isEnabled: true, usesDefaultSelection: true)
        case .morningGate:
            return MoriScreenTimeFeatureProfile(isEnabled: true, usesDefaultSelection: true)
        case .settle, .breathing, .beforeFeed, .walkOfflineReset, .journal, .dailyCheckIn, .manualPractice:
            return MoriScreenTimeFeatureProfile(isEnabled: false, usesDefaultSelection: true)
        }
    }

    private func loadSelection(forKey key: String) -> FamilyActivitySelection {
        supportedSelection(persistence.loadSelection(forKey: key) ?? FamilyActivitySelection())
    }

    private func saveSelection(_ selection: FamilyActivitySelection, forKey key: String) {
        persistence.saveSelection(selection, forKey: key)
    }

    private func selectionKey(for feature: MoriScreenTimeFeature) -> String {
        MoriScreenTimeShared.featureSelectionKeyPrefix + feature.rawValue
    }

    private func migrateLegacySelectionIfNeeded() {
        guard !persistence.hasCompletedFeatureMigration() else { return }
        persistence.migrateLegacyDefaultSelectionIfNeeded()

        var profiles = profiles()
        for feature in MoriScreenTimeFeature.allCases where profiles[feature.rawValue] == nil {
            profiles[feature.rawValue] = defaultProfile(for: feature)
        }
        saveProfiles(profiles)
        persistence.markFeatureMigrationCompleted()
    }
}
