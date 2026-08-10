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
        beforeFeedWebDomainTokenCount: Int? = nil,
        policy: MoriScreenTimeMonitorHealthPolicy? = nil,
        hiddenApplicationTokens: Set<ApplicationToken>? = nil,
        restrictionPolicy: MoriScreenTimeRestrictionPolicy = .blockSelected
    ) {
        let effectivePolicy = policy ?? (currentFeature == .beforeFeed ? .shieldLock : .shieldOnly)
        if effectivePolicy == .hiddenAppLock {
            applyApplicationRestrictions(hiddenApplicationTokens ?? selection.applicationTokens)
        } else {
            clearApplicationRestrictions()
        }
        switch restrictionPolicy {
        case .blockSelected:
            managedStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
            managedStore.shield.applicationCategories = nil
            managedStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        case .allowSelected:
            clearApplicationRestrictions()
            managedStore.shield.applications = nil
            managedStore.shield.applicationCategories = .all(except: selection.applicationTokens)
            managedStore.shield.webDomains = nil
        }
        stateStore.saveCurrentShield(feature: currentFeature, displayNames: displayNames)
        let isBeforeFeedShield = currentFeature == .beforeFeed
        let eventKind: MoriScreenTimeMonitorHealthEventKind = {
            if effectivePolicy == .hiddenAppLock {
                return .hiddenAppLockApplied
            }
            return effectivePolicy.isLockingPolicy ? .strictLockApplied : .shieldApplied
        }()
        MoriScreenTimeMonitorHealthStore.record(
            MoriScreenTimeMonitorHealthEvent(
                traceID: beforeFeedGateStore.currentWindowTraceID(),
                kind: eventKind,
                featureRawValue: currentFeature.rawValue,
                action: "apply",
                policy: effectivePolicy,
                beforeFeedNativeGateEnabled: beforeFeedGateStore.nativeGateEnabled(),
                beforeFeedInGraceWindow: beforeFeedGateStore.isInGraceWindow(),
                beforeFeedHasSelection: beforeFeedHasSelection ?? (isBeforeFeedShield ? hasTokens(selection) : nil),
                applicationTokenCount: beforeFeedApplicationTokenCount ?? (isBeforeFeedShield ? selection.applicationTokens.count : nil),
                webDomainTokenCount: beforeFeedWebDomainTokenCount ?? (isBeforeFeedShield ? selection.webDomainTokens.count : nil),
                displayNameCount: displayNames.count,
                displayNames: displayNames
            )
        )
    }

    func applyHiddenAppLock(
        selection: FamilyActivitySelection,
        currentFeature: MoriScreenTimeFeature,
        displayNames: [String],
        beforeFeedHasSelection: Bool? = nil,
        beforeFeedApplicationTokenCount: Int? = nil,
        beforeFeedWebDomainTokenCount: Int? = nil
    ) {
        apply(
            selection: selection,
            currentFeature: currentFeature,
            displayNames: displayNames,
            beforeFeedHasSelection: beforeFeedHasSelection,
            beforeFeedApplicationTokenCount: beforeFeedApplicationTokenCount,
            beforeFeedWebDomainTokenCount: beforeFeedWebDomainTokenCount,
            policy: .hiddenAppLock,
            hiddenApplicationTokens: selection.applicationTokens
        )
    }

    func clear(
        beforeFeedHasSelection: Bool? = nil,
        beforeFeedApplicationTokenCount: Int? = nil,
        beforeFeedWebDomainTokenCount: Int? = nil
    ) {
        clearApplicationRestrictions()
        managedStore.shield.applications = nil
        managedStore.shield.applicationCategories = nil
        managedStore.shield.webDomains = nil
        stateStore.clearCurrentShield()
        MoriScreenTimeMonitorHealthStore.record(
            MoriScreenTimeMonitorHealthEvent(
                traceID: beforeFeedGateStore.currentWindowTraceID(),
                kind: .shieldCleared,
                action: "clear",
                policy: .clear,
                beforeFeedNativeGateEnabled: beforeFeedGateStore.nativeGateEnabled(),
                beforeFeedInGraceWindow: beforeFeedGateStore.isInGraceWindow(),
                beforeFeedHasSelection: beforeFeedHasSelection,
                applicationTokenCount: beforeFeedApplicationTokenCount,
                webDomainTokenCount: beforeFeedWebDomainTokenCount
            )
        )
    }

    private func clearApplicationRestrictions() {
        managedStore.application.blockedApplications = nil
    }

    private func applyApplicationRestrictions(_ applicationTokens: Set<ApplicationToken>) {
        managedStore.application.blockedApplications = applicationTokens.isEmpty
            ? nil
            : Set(applicationTokens.map(Application.init(token:)))
    }

    private func hasTokens(_ selection: FamilyActivitySelection) -> Bool {
        !selection.applicationTokens.isEmpty || !selection.webDomainTokens.isEmpty
    }
}
