import Foundation
import FamilyControls
import ManagedSettings

struct AttentionShieldApplier {
    private let managedStore: ManagedSettingsStore
    private let stateStore: AttentionShieldStateStore

    init(
        managedStore: ManagedSettingsStore = ManagedSettingsStore(),
        stateStore: AttentionShieldStateStore = AttentionShieldStateStore()
    ) {
        self.managedStore = managedStore
        self.stateStore = stateStore
    }

    func apply(
        selection: FamilyActivitySelection,
        currentFeature: MoriScreenTimeFeature,
        displayNames: [String]
    ) {
        clearApplicationRestrictions()
        managedStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        managedStore.shield.applicationCategories = nil
        managedStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        stateStore.saveCurrentShield(feature: currentFeature, displayNames: displayNames)
    }

    func clear() {
        clearApplicationRestrictions()
        managedStore.shield.applications = nil
        managedStore.shield.applicationCategories = nil
        managedStore.shield.webDomains = nil
        stateStore.clearCurrentShield()
    }

    private func clearApplicationRestrictions() {
        managedStore.application.blockedApplications = nil
    }
}
