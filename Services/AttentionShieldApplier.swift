import Foundation
import FamilyControls
import ManagedSettings

struct AttentionShieldApplier {
    private let managedStore: ManagedSettingsStore
    private let stateStore: AttentionShieldStateStore
    private let beforeFeedGateStore: BeforeFeedGateStore

    init(
        managedStore: ManagedSettingsStore = ManagedSettingsStore(),
        stateStore: AttentionShieldStateStore = AttentionShieldStateStore(),
        beforeFeedGateStore: BeforeFeedGateStore = BeforeFeedGateStore()
    ) {
        self.managedStore = managedStore
        self.stateStore = stateStore
        self.beforeFeedGateStore = beforeFeedGateStore
    }

    func apply(
        selection: FamilyActivitySelection,
        currentFeature: MoriScreenTimeFeature,
        displayNames: [String],
        beforeFeedHasSelection: Bool? = nil,
        beforeFeedApplicationTokenCount: Int? = nil,
        beforeFeedWebDomainTokenCount: Int? = nil
    ) {
        clearApplicationRestrictions()
        managedStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        managedStore.shield.applicationCategories = nil
        managedStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        stateStore.saveCurrentShield(feature: currentFeature, displayNames: displayNames)
        let isBeforeFeedShield = currentFeature == .beforeFeed
        MoriScreenTimeMonitorHealthStore.record(
            MoriScreenTimeMonitorHealthEvent(
                kind: .shieldApplied,
                featureRawValue: currentFeature.rawValue,
                action: "apply",
                beforeFeedNativeGateEnabled: beforeFeedGateStore.nativeGateEnabled(),
                beforeFeedInGraceWindow: beforeFeedGateStore.isInGraceWindow(),
                beforeFeedHasSelection: beforeFeedHasSelection ?? (isBeforeFeedShield ? hasTokens(selection) : nil),
                applicationTokenCount: beforeFeedApplicationTokenCount ?? (isBeforeFeedShield ? selection.applicationTokens.count : nil),
                webDomainTokenCount: beforeFeedWebDomainTokenCount ?? (isBeforeFeedShield ? selection.webDomainTokens.count : nil),
                displayNameCount: displayNames.count
            )
        )
    }

    func clear() {
        clearApplicationRestrictions()
        managedStore.shield.applications = nil
        managedStore.shield.applicationCategories = nil
        managedStore.shield.webDomains = nil
        stateStore.clearCurrentShield()
        MoriScreenTimeMonitorHealthStore.record(
            MoriScreenTimeMonitorHealthEvent(
                kind: .shieldCleared,
                action: "clear",
                beforeFeedNativeGateEnabled: beforeFeedGateStore.nativeGateEnabled(),
                beforeFeedInGraceWindow: beforeFeedGateStore.isInGraceWindow()
            )
        )
    }

    private func clearApplicationRestrictions() {
        managedStore.application.blockedApplications = nil
    }

    private func hasTokens(_ selection: FamilyActivitySelection) -> Bool {
        !selection.applicationTokens.isEmpty || !selection.webDomainTokens.isEmpty
    }
}
