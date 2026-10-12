import Foundation
import FamilyControls

/// One immutable checked read before any ManagedSettings write. No legacy
/// constructor/migration, normalizing getter, expired-session clear or fallback
/// decoder is used while collecting repair inputs.
struct MoriProtectionRepairSnapshot {
    let profiles: [String: MoriScreenTimeFeatureProfile]
    let defaultSelection: FamilyActivitySelection
    let selections: [String: FamilyActivitySelection]
    let defaultDisplayNames: [String]
    let activeSession: MoriScreenTimeActiveSession?
    let currentShieldFeature: MoriScreenTimeFeature?
    let beforeFeedGateEnabled: Bool
    let beforeFeedInGraceWindow: Bool
    let beforeFeedHiddenAppLockEnabled: Bool
    let morningShouldApply: Bool
    let morningHiddenAppLockEnabled: Bool

    static func load(defaults: UserDefaults, reader: ProtectionCheckedInputReader,
                     now: Date, scheduledOwnsMorning: Bool, calendar: Calendar = .current) throws -> Self {
        guard now.timeIntervalSince1970.isFinite else { throw ProtectionCheckedInputError.invalidValue("repair-now") }
        let persistence = ScreenTimeSelectionPersistence(defaults: defaults)
        var profiles = try persistence.loadProfilesChecked(using: reader)
        let names = try persistence.loadDefaultDisplayNamesChecked(using: reader)
        let migrated = try reader.boolean(MoriScreenTimeShared.featureMigrationKey, default: false)
        let dedicatedMigrated = try reader.boolean(MoriScreenTimeShared.beforeFeedDedicatedSelectionMigrationKey, default: false)
        let savedDefault = try persistence.loadSelectionChecked(forKey: MoriScreenTimeShared.defaultSelectionKey, using: reader)
        let legacy = try persistence.loadSelectionChecked(forKey: MoriScreenTimeShared.selectionKey, using: reader)
        var selections: [String: FamilyActivitySelection] = [:]
        for feature in MoriScreenTimeFeature.allCases {
            selections[feature.rawValue] = try persistence.loadSelectionChecked(
                forKey: MoriScreenTimeShared.featureSelectionKeyPrefix + feature.rawValue, using: reader) ?? FamilyActivitySelection()
            if profiles[feature.rawValue] == nil { profiles[feature.rawValue] = ScreenTimeSelectionStore.defaultProfile(for: feature) }
        }
        profiles[MoriScreenTimeFeature.walkOfflineReset.rawValue]?.usesDefaultSelection = false
        profiles[MoriScreenTimeFeature.walkOfflineReset.rawValue]?.restrictionPolicy = .allowSelected
        let defaultSelection = savedDefault ?? (!migrated ? legacy : nil) ?? FamilyActivitySelection()
        let feedEnabled = try reader.boolean(MoriScreenTimeShared.beforeFeedNativeGateEnabledKey, default: MoriScreenTimeShared.defaultBeforeFeedNativeGateEnabled)
        let feedHidden = try reader.boolean(MoriScreenTimeShared.beforeFeedHiddenAppLockEnabledKey, default: MoriScreenTimeShared.defaultBeforeFeedHiddenAppLockEnabled)
        let morningHidden = try reader.boolean(MoriScreenTimeShared.morningGateHiddenAppLockEnabledKey, default: MoriScreenTimeShared.defaultMorningGateHiddenAppLockEnabled)
        if !dedicatedMigrated, feedHidden,
           profiles[MoriScreenTimeFeature.beforeFeed.rawValue]?.usesDefaultSelection == true,
           let dedicated = selections[MoriScreenTimeFeature.beforeFeed.rawValue],
           !dedicated.applicationTokens.isEmpty || !dedicated.webDomainTokens.isEmpty {
            profiles[MoriScreenTimeFeature.beforeFeed.rawValue]?.usesDefaultSelection = false
        }
        let session = try AttentionShieldActiveSessionStore(defaults: defaults).loadChecked(using: reader)
        let rawCurrent = try reader.optional(MoriScreenTimeShared.currentShieldFeatureKey, as: String.self)
        var current: MoriScreenTimeFeature?
        if let rawCurrent {
            guard let parsed = MoriScreenTimeFeature(rawValue: rawCurrent) else { throw ProtectionCheckedInputError.invalidValue(MoriScreenTimeShared.currentShieldFeatureKey) }
            current = parsed
        }
        let grace = try reader.number(MoriScreenTimeShared.beforeFeedGraceUntilKey)
        if let grace, grace > now.addingTimeInterval(Double(MoriScreenTimeShared.maxBeforeFeedGraceWindowSeconds)).timeIntervalSince1970 {
            throw ProtectionCheckedInputError.invalidValue(MoriScreenTimeShared.beforeFeedGraceUntilKey)
        }
        let morningEnabled = try reader.boolean(MoriScreenTimeShared.morningGateEnabledKey, default: MoriScreenTimeShared.defaultMorningGateEnabled)
        let hour = try reader.integer(MoriScreenTimeShared.morningGateStartHourKey, default: MoriScreenTimeShared.defaultMorningGateStartHour, range: 0...23)
        let minute = try reader.integer(MoriScreenTimeShared.morningGateStartMinuteKey, default: MoriScreenTimeShared.defaultMorningGateStartMinute, range: 0...59)
        let duration = try reader.integer(MoriScreenTimeShared.morningGateDurationSecondsKey, default: MoriScreenTimeShared.defaultMorningGateDurationSeconds, range: 300...7200)
        let completed = try reader.optional(MoriScreenTimeShared.morningGateCompletedDateKey, as: String.self)
        _ = try reader.boolean(MoriShieldCoordination.morningOwnerKey, default: false)
        var morningApplies = false
        if morningEnabled && !scheduledOwnsMorning {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = hour; components.minute = minute; components.second = 0
            guard let today = calendar.date(from: components) else { throw ProtectionCheckedInputError.invalidValue("morning-start") }
            let starts = [today, calendar.date(byAdding: .day, value: -1, to: today)].compactMap { $0 }
            if let start = starts.first(where: { $0 <= now && now < $0.addingTimeInterval(Double(duration)) }) {
                morningApplies = completed != MoriScreenTimeShared.dateKey(for: start)
            }
        }
        return .init(profiles: profiles, defaultSelection: defaultSelection, selections: selections,
            defaultDisplayNames: names, activeSession: session.flatMap { $0.isExpired(at: now) ? nil : $0 },
            currentShieldFeature: current, beforeFeedGateEnabled: feedEnabled,
            beforeFeedInGraceWindow: grace.map { $0 > now.timeIntervalSince1970 } ?? false,
            beforeFeedHiddenAppLockEnabled: feedHidden, morningShouldApply: morningApplies,
            morningHiddenAppLockEnabled: morningHidden)
    }
    func profile(for feature: MoriScreenTimeFeature) -> MoriScreenTimeFeatureProfile {
        profiles[feature.rawValue] ?? ScreenTimeSelectionStore.defaultProfile(for: feature)
    }
    func selection(for feature: MoriScreenTimeFeature) -> FamilyActivitySelection {
        let selected = profile(for: feature).usesDefaultSelection ? defaultSelection : (selections[feature.rawValue] ?? FamilyActivitySelection())
        var supported = FamilyActivitySelection()
        supported.applicationTokens = selected.applicationTokens; supported.webDomainTokens = selected.webDomainTokens
        return supported
    }
    func hasSelection(for feature: MoriScreenTimeFeature) -> Bool {
        let profile = profile(for: feature); let selected = selection(for: feature)
        return profile.isEnabled && (!selected.applicationTokens.isEmpty || (profile.restrictionPolicy == .blockSelected && !selected.webDomainTokens.isEmpty))
    }
    func mergedSelection(for features: [MoriScreenTimeFeature]) -> FamilyActivitySelection {
        features.reduce(into: FamilyActivitySelection()) { merged, feature in
            let selected = selection(for: feature)
            merged.applicationTokens.formUnion(selected.applicationTokens); merged.webDomainTokens.formUnion(selected.webDomainTokens)
        }
    }
    func names(for feature: MoriScreenTimeFeature) -> [String] {
        let profile = profile(for: feature)
        return profile.usesDefaultSelection ? defaultDisplayNames : profile.displayNames
    }
}
