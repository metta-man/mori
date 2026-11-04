#if os(iOS)
import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

/// Single inactive gate. Changing this constant is NOT sufficient to activate:
/// a valid reviewed native clock sample is also required before creating a store.
/// No UserDefaults/debug flag can enable production eligibility.
enum MoriProtectionIntegration {
    static let nativeEligibilityReviewed = MoriShieldCoordination.nativeEligibilityReviewed
    static var isEligible: Bool {
        guard nativeEligibilityReviewed && MoriAppGroup.hasFreshProtectionPreferences else { return false }
        return MoriProtectionNativeClock.isAvailable
    }
    static func host(callbackName: DeviceActivityName? = nil) throws -> ProtectionHost? {
        guard isEligible else { return nil }
        return try MoriShieldCoordination.exclusive {
            let file = try MoriProtectionMigration.store()
            let storage = ProtectionCoordinatedStorage(file, coordinationURL: try MoriShieldCoordination.url())
            let configuration = try storage.load().configuration
            let driver = MoriProtectionNativeDriver(revision: configuration.revision, callbackName: callbackName,
                selectedApps: { ScreenTimeSelectionStore().effectiveSelection(for: .morningGate) },
                independent: {
                    let existing = ManagedSettingsStore()
                    return existing.shield.applications?.isEmpty == false
                        || existing.shield.webDomains?.isEmpty == false
                        || existing.shield.applicationCategories != nil
                        || existing.shield.webDomainCategories != nil
                        || existing.application.blockedApplications?.isEmpty == false
                })
            return ProtectionHost(storage: storage, driver: driver, clockWithState: { try MoriProtectionNativeClock().sample(state: $0) })
        }
    }
    static func breathingHost() -> ProtectionHost? {
        guard isEligible else { return nil }
        return try? MoriShieldCoordination.exclusive {
            guard let host = try host() else { return nil }
            try recoverJoint(host: host)
            let outcome = host.reconcile(authorized: authorizedSelection())
            guard outcome.effectsApplied, outcome.plan?.shieldedRules.isEmpty == false else { return nil }
            return host
        }
    }
    static func foreground() {
        guard isEligible else { try? MoriProtectionNativeDriver.removeOwnedContribution(); return }
        _ = try? MoriShieldCoordination.exclusive {
            guard let host = try host() else { return }
            try recoverJoint(host: host)
            _ = host.reconcile(authorized: authorizedSelection())
        }
    }
    static func callback(_ name: DeviceActivityName, started: Bool) -> Bool {
        guard name.rawValue.hasPrefix("mori.protection.") else { return false }
        // Own names are consumed while ineligible; removal remains allowed.
        guard isEligible else { try? MoriProtectionNativeDriver.removeOwnedContribution(); return true }
        _ = try? MoriShieldCoordination.exclusive {
            guard let host = try host(callbackName: name) else { return }
            let configuration = try MoriProtectionMigration.store().load().configuration
            let event: ProtectionCallback
            if name.rawValue.hasPrefix("mori.protection.expiry.r\(configuration.revision).") {
                event = .elapsedDeadline
            } else {
                event = try ProtectionRegistration.delivered(name.rawValue, configuration: configuration, intervalStarted: started)
            }
            try recoverJoint(host: host)
            _ = host.reconcile(event, authorized: authorizedSelection())
        }
        return true
    }
    static func save(_ configuration: ProtectionConfiguration) throws -> Bool {
        guard isEligible else { return false }
        return try MoriShieldCoordination.exclusive {
            guard let host = try host() else { return false }
            try recoverJoint(host: host)
            try host.configure(configuration)
            let acknowledged = host.reconcile(authorized: authorizedSelection()).effectsApplied
            return try ProtectionOwnershipTransition.takeOwnership(acknowledged: acknowledged, recordOwner: {
                MoriAppGroup.defaults.set(true, forKey: MoriShieldCoordination.morningOwnerKey)
                guard MoriAppGroup.defaults.bool(forKey: MoriShieldCoordination.morningOwnerKey),
                      let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier) else { throw ProtectionWriterError.unavailable }
                try Data("1".utf8).write(to: group.appendingPathComponent("ScheduledProtection/native-owner-v1"), options: .atomic)
            }, retireLegacyMorning: {
                DeviceActivityCenter().stopMonitoring([.moriMorningGate])
                if AttentionShieldActiveSessionStore().load()?.feature == .morningGate {
                    AttentionShieldActiveSessionStore().clear()
                }
            }, recomposeIndependent: { repairExistingContribution() })
        }
    }
    static func repairExistingContribution() {
        let selection = ScreenTimeSelectionStore()
        let before = BeforeFeedGateStore()
        let policy = AttentionShieldPassiveGatePolicy(morningGateShouldApply: MorningGate.shouldApplyShield(),
            morningGateHasSelection: selection.hasEffectiveSelection(for: .morningGate),
            beforeFeedGateEnabled: before.nativeGateEnabled(), beforeFeedInGraceWindow: before.isInGraceWindow(),
            beforeFeedHasSelection: selection.hasEffectiveSelection(for: .beforeFeed))
        AttentionShieldPassiveGateApplier(selectionStore: selection, shieldApplier: AttentionShieldApplier())
            .apply(policy.refreshAction(activeSession: AttentionShieldActiveSessionStore().loadUnexpiredSession()))
    }
    static func repairExistingContributionAcknowledged() throws {
        try MoriShieldCoordination.exclusive {
            guard let preferences = MoriAppGroup.defaults as? MoriCoordinatedPreferences,
                  let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier) else { throw ProtectionWriterError.unavailable }
            try preferences.validateSnapshot()
            let reader = ProtectionCheckedInputReader(read: preferences.objectChecked(forKey:))
            let markerURL = group.appendingPathComponent("ScheduledProtection/native-owner-v1")
            let marker = try ProtectionFileIO.system.optionalData(at: markerURL)
            if let marker, marker != Data("1".utf8) { throw ProtectionCheckedInputError.invalidValue("native-owner-v1") }
            let ownerMarker = marker != nil
            let ownerPreference = try reader.boolean(MoriShieldCoordination.morningOwnerKey, default: false)
            let ownsMorning = MoriShieldCoordination.nativeEligibilityReviewed && (ownerMarker || ownerPreference)
            let now = Date()
            try ProtectionCheckedRepair.perform(load: {
                try MoriProtectionRepairSnapshot.load(defaults: preferences, reader: reader,
                    now: now, scheduledOwnsMorning: ownsMorning)
            }, apply: { snapshot in
                // All critical selection/profile/session/preferences were decoded
                // before constructing or writing any framework contribution.
                let policy = AttentionShieldPassiveGatePolicy(morningGateShouldApply: snapshot.morningShouldApply,
                    morningGateHasSelection: snapshot.hasSelection(for: .morningGate),
                    beforeFeedGateEnabled: snapshot.beforeFeedGateEnabled, beforeFeedInGraceWindow: snapshot.beforeFeedInGraceWindow,
                    beforeFeedHasSelection: snapshot.hasSelection(for: .beforeFeed))
                let action = policy.refreshAction(activeSession: snapshot.activeSession, now: now)
                let applier = AttentionShieldApplier()
                let feed = snapshot.selection(for: .beforeFeed)
                var expectedFeature = snapshot.currentShieldFeature
                switch action {
                case .preserveActiveSession:
                    break // Keep the independent Focus/PIN contribution exactly.
                case .clear:
                    applier.clear(beforeFeedHasSelection: snapshot.hasSelection(for: .beforeFeed),
                        beforeFeedApplicationTokenCount: feed.applicationTokens.count,
                        beforeFeedWebDomainTokenCount: feed.webDomainTokens.count)
                    guard applier.matchesClearedState() else { throw ProtectionHostError.independentRestriction }
                    expectedFeature = nil
                case .apply(let features):
                    let current = AttentionShieldPassiveGatePolicy.currentFeature(for: features)
                    let merged = snapshot.mergedSelection(for: features)
                    let hidden = features.reduce(into: Set<ApplicationToken>()) { tokens, feature in
                        let isHidden = feature == .beforeFeed ? snapshot.beforeFeedHiddenAppLockEnabled : snapshot.morningHiddenAppLockEnabled
                        if isHidden { tokens.formUnion(snapshot.selection(for: feature).applicationTokens) }
                    }
                    let enforcement: MoriScreenTimeMonitorHealthPolicy = hidden.isEmpty
                        ? (current == .beforeFeed ? .shieldLock : .shieldOnly) : .hiddenAppLock
                    applier.apply(selection: merged, currentFeature: current, displayNames: snapshot.names(for: current),
                        beforeFeedHasSelection: snapshot.hasSelection(for: .beforeFeed),
                        beforeFeedApplicationTokenCount: feed.applicationTokens.count,
                        beforeFeedWebDomainTokenCount: feed.webDomainTokens.count,
                        policy: enforcement, hiddenApplicationTokens: hidden)
                    guard applier.matchesAppliedState(selection: merged, currentFeature: current,
                        policy: enforcement, hiddenApplicationTokens: hidden) else { throw ProtectionHostError.independentRestriction }
                    expectedFeature = current
                }
                let freshFeature = try reader.optional(MoriScreenTimeShared.currentShieldFeatureKey, as: String.self)
                guard freshFeature == expectedFeature?.rawValue else { throw ProtectionHostError.independentRestriction }
                if policy.shouldApplyBeforeFeedGate {
                    let store = ManagedSettingsStore()
                    let shieldedApps = store.shield.applications ?? []
                    let blockedApps = store.application.blockedApplications ?? []
                    guard feed.applicationTokens.allSatisfy({ shieldedApps.contains($0) || blockedApps.contains(Application(token: $0)) }),
                          feed.webDomainTokens.isSubset(of: store.shield.webDomains ?? []) else { throw ProtectionHostError.independentRestriction }
                    if #available(iOS 26.5, *), !store.isActive { throw ProtectionHostError.independentRestriction }
                }
            })
        }
    }
    private static func recoverJoint(host: ProtectionHost) throws {
        try MoriJointAllowanceJournal.recover(host: host, authorized: authorizedSelection()) { try repairExistingContributionAcknowledged() }
    }
    static func deleteProtectionData() {
        _ = try? MoriShieldCoordination.exclusive {
            guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier) else { return }
            try MoriProtectionNativeDriver.removeOwnedContribution()
            let directory = group.appendingPathComponent("ScheduledProtection")
            for file in ["state-v1.json", "joint-allowance-v1.json", "native-owner-v1", "recovery-v1.json"] {
                let url = directory.appendingPathComponent(file)
                try ProtectionFileIO.system.removeIfPresent(at: url)
            }
            MoriAppGroup.defaults.removeObject(forKey: MoriShieldCoordination.morningOwnerKey)
        }
    }
    private static func authorizedSelection() -> Bool {
        AuthorizationCenter.shared.authorizationStatus == .approved
            && ScreenTimeSelectionStore().hasEffectiveSelection(for: .morningGate)
    }
}
#endif
