import Foundation
import FamilyControls

struct MoriScreenTimeFeatureProfile: Codable, Equatable {
    var isEnabled: Bool
    var usesDefaultSelection: Bool
    var displayNames: [String]
    var restrictionPolicy: MoriScreenTimeRestrictionPolicy

    init(
        isEnabled: Bool = false,
        usesDefaultSelection: Bool = true,
        displayNames: [String] = [],
        restrictionPolicy: MoriScreenTimeRestrictionPolicy = .blockSelected
    ) {
        self.isEnabled = isEnabled
        self.usesDefaultSelection = usesDefaultSelection
        self.displayNames = displayNames
        self.restrictionPolicy = restrictionPolicy
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case usesDefaultSelection
        case displayNames
        case restrictionPolicy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        usesDefaultSelection = try container.decodeIfPresent(Bool.self, forKey: .usesDefaultSelection) ?? true
        displayNames = try container.decodeIfPresent([String].self, forKey: .displayNames) ?? []
        restrictionPolicy = try container.decodeIfPresent(
            MoriScreenTimeRestrictionPolicy.self,
            forKey: .restrictionPolicy
        ) ?? .blockSelected
    }
}

struct MoriScreenTimeProfileSummary: Identifiable, Equatable {
    let feature: MoriScreenTimeFeature
    let isEnabled: Bool
    let usesDefaultSelection: Bool
    let customSelectedCount: Int
    let effectiveSelectedCount: Int
    let displayNames: [String]
    let restrictionPolicy: MoriScreenTimeRestrictionPolicy

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
        var profile = profiles()[feature.rawValue] ?? defaultProfile(for: feature)
        if feature == .walkOfflineReset {
            profile.usesDefaultSelection = false
            profile.restrictionPolicy = .allowSelected
        }
        return profile
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
        let customSelection = loadSelection(for: feature)
        let customCount = selectedCount(customSelection, policy: profile.restrictionPolicy)
        let effectiveSelection = effectiveSelection(for: feature)
        let effectiveCount = selectedCount(effectiveSelection, policy: profile.restrictionPolicy)
        let names = profile.usesDefaultSelection ? loadDefaultDisplayNames() : profile.displayNames

        return MoriScreenTimeProfileSummary(
            feature: feature,
            isEnabled: profile.isEnabled,
            usesDefaultSelection: profile.usesDefaultSelection,
            customSelectedCount: customCount,
            effectiveSelectedCount: effectiveCount,
            displayNames: names,
            restrictionPolicy: profile.restrictionPolicy
        )
    }

    var hasDefaultSelection: Bool {
        selectedCount(loadDefaultSelection()) > 0
    }

    var defaultSelectedCount: Int {
        selectedCount(loadDefaultSelection())
    }

    func hasEffectiveSelection(for feature: MoriScreenTimeFeature) -> Bool {
        let profile = profile(for: feature)
        return profile.isEnabled && selectedCount(
            effectiveSelection(for: feature),
            policy: profile.restrictionPolicy
        ) > 0
    }

    func effectiveSelectedCount(for feature: MoriScreenTimeFeature) -> Int {
        let profile = profile(for: feature)
        return selectedCount(effectiveSelection(for: feature), policy: profile.restrictionPolicy)
    }

    func selectedCount(_ selection: FamilyActivitySelection) -> Int {
        let selection = supportedSelection(selection)
        return selection.applicationTokens.count + selection.webDomainTokens.count
    }

    private func selectedCount(
        _ selection: FamilyActivitySelection,
        policy: MoriScreenTimeRestrictionPolicy
    ) -> Int {
        let selection = supportedSelection(selection)
        switch policy {
        case .blockSelected:
            return selection.applicationTokens.count + selection.webDomainTokens.count
        case .allowSelected:
            return selection.applicationTokens.count
        }
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
        case .walkOfflineReset:
            return MoriScreenTimeFeatureProfile(
                isEnabled: false,
                usesDefaultSelection: false,
                restrictionPolicy: .allowSelected
            )
        case .settle, .breathing, .beforeFeed, .journal, .dailyCheckIn, .manualPractice:
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
