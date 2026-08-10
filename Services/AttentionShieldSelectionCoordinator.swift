import Foundation
import FamilyControls

struct AttentionShieldSelectionPayload {
    let selection: FamilyActivitySelection
    let displayNames: [String]
    let restrictionPolicy: MoriScreenTimeRestrictionPolicy
}

@MainActor
struct AttentionShieldSelectionCoordinator {
    private let selectionStore: ScreenTimeSelectionStore
    private let displayNameResolver: AttentionShieldDisplayNameResolver

    init(
        selectionStore: ScreenTimeSelectionStore = ScreenTimeSelectionStore(),
        displayNameResolver: AttentionShieldDisplayNameResolver = AttentionShieldDisplayNameResolver()
    ) {
        self.selectionStore = selectionStore
        self.displayNameResolver = displayNameResolver
    }

    var defaultSelectedCount: Int {
        selectionStore.defaultSelectedCount
    }

    var hasDefaultSelection: Bool {
        selectionStore.hasDefaultSelection
    }

    func profileSummaries(authorizationStatus: AuthorizationStatus) -> [MoriScreenTimeProfileSummary] {
        let canDisplaySelectionNames = AttentionShieldAuthorizationPolicy.canDisplaySelectionNames(
            for: authorizationStatus
        )
        return selectionStore.summaries().map { summary in
            privacyFilteredSummary(summary, canDisplaySelectionNames: canDisplaySelectionNames)
        }
    }

    func selectionDraft(for target: AttentionShieldSelectionTarget) -> AttentionShieldSelectionDraft {
        switch target {
        case .defaultList:
            return AttentionShieldSelectionDraft(
                target: target,
                selection: selectionStore.loadDefaultSelection()
            )
        case .feature(let feature):
            return AttentionShieldSelectionDraft(
                target: target,
                selection: selectionStore.loadSelection(for: feature)
            )
        }
    }

    @discardableResult
    func commitSelectionDraft(
        _ draft: AttentionShieldSelectionDraft,
        authorizationStatus: AuthorizationStatus
    ) -> AttentionShieldSelectionTarget {
        switch draft.target {
        case .defaultList:
            saveDefaultSelection(draft.selection, authorizationStatus: authorizationStatus)
        case .feature(let feature):
            saveEnabledCustomSelection(
                draft.selection,
                for: feature,
                authorizationStatus: authorizationStatus
            )
        }
        return draft.target
    }

    func updateProfile(
        for feature: MoriScreenTimeFeature,
        mutate: (inout MoriScreenTimeFeatureProfile) -> Void
    ) {
        var profile = selectionStore.profile(for: feature)
        mutate(&profile)
        selectionStore.saveProfile(profile, for: feature)
    }

    func hasEffectiveSelection(for feature: MoriScreenTimeFeature) -> Bool {
        selectionStore.hasEffectiveSelection(for: feature)
    }

    func defaultSelectionForMonitoring() -> FamilyActivitySelection {
        selectionStore.supportedSelection(selectionStore.loadDefaultSelection())
    }

    func shieldPayload(
        for feature: MoriScreenTimeFeature,
        authorizationStatus: AuthorizationStatus
    ) -> AttentionShieldSelectionPayload {
        AttentionShieldSelectionPayload(
            selection: selectionStore.supportedSelection(selectionStore.effectiveSelection(for: feature)),
            displayNames: displayNames(for: feature, authorizationStatus: authorizationStatus),
            restrictionPolicy: selectionStore.profile(for: feature).restrictionPolicy
        )
    }

    func applyPassiveGateAction(
        _ action: AttentionShieldPassiveGateAction,
        shieldApplier: AttentionShieldApplier,
        authorizationStatus: AuthorizationStatus
    ) {
        let canDisplaySelectionNames = AttentionShieldAuthorizationPolicy.canDisplaySelectionNames(
            for: authorizationStatus
        )
        let selectionStore = selectionStore
        AttentionShieldPassiveGateApplier(
            selectionStore: selectionStore,
            shieldApplier: shieldApplier,
            displayNames: { feature in
                guard canDisplaySelectionNames else { return [] }
                return selectionStore.summary(for: feature).displayNames
            }
        )
        .apply(action)
    }

    func refreshDisplayNames(
        for target: AttentionShieldSelectionTarget,
        authorizationStatus: AuthorizationStatus
    ) async {
        switch target {
        case .defaultList:
            await refreshDefaultDisplayNames(authorizationStatus: authorizationStatus)
        case .feature(let feature):
            await refreshDisplayNames(for: feature, authorizationStatus: authorizationStatus)
        }
    }

    private func saveDefaultSelection(
        _ selection: FamilyActivitySelection,
        authorizationStatus: AuthorizationStatus
    ) {
        let supportedSelection = selectionStore.supportedSelection(selection)
        let names = displayNameResolver.immediateDisplayNames(
            for: supportedSelection,
            authorizationStatus: authorizationStatus
        )
        selectionStore.saveDefaultSelection(supportedSelection, displayNames: names)
    }

    private func saveEnabledCustomSelection(
        _ selection: FamilyActivitySelection,
        for feature: MoriScreenTimeFeature,
        authorizationStatus: AuthorizationStatus
    ) {
        saveSelection(selection, for: feature, authorizationStatus: authorizationStatus) { profile in
            profile.isEnabled = true
            profile.usesDefaultSelection = false
        }
    }

    private func saveSelection(
        _ selection: FamilyActivitySelection,
        for feature: MoriScreenTimeFeature,
        authorizationStatus: AuthorizationStatus,
        profileUpdate: (inout MoriScreenTimeFeatureProfile) -> Void
    ) {
        let supportedSelection = selectionStore.supportedSelection(selection)
        let names = displayNameResolver.immediateDisplayNames(
            for: supportedSelection,
            authorizationStatus: authorizationStatus
        )
        selectionStore.saveSelection(supportedSelection, for: feature, displayNames: names)
        updateProfile(for: feature, mutate: profileUpdate)
    }

    private func displayNames(
        for feature: MoriScreenTimeFeature,
        authorizationStatus: AuthorizationStatus
    ) -> [String] {
        guard AttentionShieldAuthorizationPolicy.canDisplaySelectionNames(for: authorizationStatus) else {
            return []
        }
        return selectionStore.summary(for: feature).displayNames
    }

    private func privacyFilteredSummary(
        _ summary: MoriScreenTimeProfileSummary,
        canDisplaySelectionNames: Bool
    ) -> MoriScreenTimeProfileSummary {
        guard !canDisplaySelectionNames else { return summary }

        return MoriScreenTimeProfileSummary(
            feature: summary.feature,
            isEnabled: summary.isEnabled,
            usesDefaultSelection: summary.usesDefaultSelection,
            customSelectedCount: summary.customSelectedCount,
            effectiveSelectedCount: summary.effectiveSelectedCount,
            displayNames: [],
            restrictionPolicy: summary.restrictionPolicy
        )
    }

    private func refreshDefaultDisplayNames(authorizationStatus: AuthorizationStatus) async {
        let selection = selectionStore.loadDefaultSelection()
        let names = await displayNameResolver.displayNames(
            for: selection,
            authorizationStatus: authorizationStatus
        )
        selectionStore.saveDefaultSelection(selection, displayNames: names)
    }

    private func refreshDisplayNames(
        for feature: MoriScreenTimeFeature,
        authorizationStatus: AuthorizationStatus
    ) async {
        let selection = selectionStore.loadSelection(for: feature)
        let names = await displayNameResolver.displayNames(
            for: selection,
            authorizationStatus: authorizationStatus
        )
        selectionStore.saveSelection(selection, for: feature, displayNames: names)
    }
}
