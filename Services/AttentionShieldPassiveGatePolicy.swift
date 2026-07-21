import Foundation
import FamilyControls
import ManagedSettings

enum AttentionShieldPassiveGateAction {
    case preserveActiveSession
    case apply([MoriScreenTimeFeature])
    case clear
}

struct AttentionShieldPassiveGateApplier {
    private let selectionStore: ScreenTimeSelectionStore
    private let shieldApplier: AttentionShieldApplier
    private let displayNames: (MoriScreenTimeFeature) -> [String]
    private let usesHiddenAppLock: (MoriScreenTimeFeature) -> Bool

    init(
        selectionStore: ScreenTimeSelectionStore,
        shieldApplier: AttentionShieldApplier,
        displayNames: ((MoriScreenTimeFeature) -> [String])? = nil,
        usesHiddenAppLock: ((MoriScreenTimeFeature) -> Bool)? = nil
    ) {
        self.selectionStore = selectionStore
        self.shieldApplier = shieldApplier
        self.displayNames = displayNames ?? { feature in
            selectionStore.summary(for: feature).displayNames
        }
        self.usesHiddenAppLock = usesHiddenAppLock ?? { feature in
            switch feature {
            case .beforeFeed:
                return BeforeFeedGateStore().hiddenAppLockEnabled()
            case .morningGate:
                return MorningGate.hiddenAppLockEnabled
            default:
                return false
            }
        }
    }

    func apply(_ action: AttentionShieldPassiveGateAction) {
        switch action {
        case .preserveActiveSession:
            break
        case .apply(let features):
            apply(features: features)
        case .clear:
            // Record why the before-feed gate did not apply (which term of
            // shouldApplyBeforeFeedGate is false) so the health log can diagnose
            // "cleared but never re-locked" cases.
            let beforeFeedSelection = selectionStore.effectiveSelection(for: .beforeFeed)
            shieldApplier.clear(
                beforeFeedHasSelection: selectionStore.hasEffectiveSelection(for: .beforeFeed),
                beforeFeedApplicationTokenCount: beforeFeedSelection.applicationTokens.count,
                beforeFeedWebDomainTokenCount: beforeFeedSelection.webDomainTokens.count
            )
        }
    }

    func apply(features: [MoriScreenTimeFeature]) {
        let selection = selectionStore.mergedEffectiveSelection(for: features)
        let currentFeature = AttentionShieldPassiveGatePolicy.currentFeature(for: features)
        let beforeFeedSelection = features.contains(.beforeFeed)
            ? selectionStore.effectiveSelection(for: .beforeFeed)
            : nil
        let beforeFeedHasSelection = features.contains(.beforeFeed)
            ? selectionStore.hasEffectiveSelection(for: .beforeFeed)
            : nil
        let names = displayNames(currentFeature)
        let hiddenApplicationTokens = hiddenApplicationTokens(for: features)
        if !hiddenApplicationTokens.isEmpty {
            shieldApplier.apply(
                selection: selection,
                currentFeature: currentFeature,
                displayNames: names,
                beforeFeedHasSelection: beforeFeedHasSelection,
                beforeFeedApplicationTokenCount: beforeFeedSelection?.applicationTokens.count,
                beforeFeedWebDomainTokenCount: beforeFeedSelection?.webDomainTokens.count,
                policy: .hiddenAppLock,
                hiddenApplicationTokens: hiddenApplicationTokens
            )
        } else {
            shieldApplier.apply(
                selection: selection,
                currentFeature: currentFeature,
                displayNames: names,
                beforeFeedHasSelection: beforeFeedHasSelection,
                beforeFeedApplicationTokenCount: beforeFeedSelection?.applicationTokens.count,
                beforeFeedWebDomainTokenCount: beforeFeedSelection?.webDomainTokens.count,
                policy: features.contains(.beforeFeed) ? .shieldLock : .shieldOnly
            )
        }
    }

    private func hiddenApplicationTokens(for features: [MoriScreenTimeFeature]) -> Set<ApplicationToken> {
        features.reduce(into: Set<ApplicationToken>()) { result, feature in
            guard usesHiddenAppLock(feature) else { return }
            result.formUnion(selectionStore.effectiveSelection(for: feature).applicationTokens)
        }
    }
}

struct AttentionShieldPassiveGatePolicy {
    let morningGateShouldApply: Bool
    let morningGateHasSelection: Bool
    let beforeFeedGateEnabled: Bool
    let beforeFeedInGraceWindow: Bool
    let beforeFeedHasSelection: Bool

    var shouldApplyMorningGate: Bool {
        morningGateShouldApply && morningGateHasSelection
    }

    var shouldApplyBeforeFeedGate: Bool {
        beforeFeedGateEnabled && !beforeFeedInGraceWindow && beforeFeedHasSelection
    }

    var features: [MoriScreenTimeFeature] {
        var features: [MoriScreenTimeFeature] = []
        if shouldApplyMorningGate {
            features.append(.morningGate)
        }
        if shouldApplyBeforeFeedGate {
            features.append(.beforeFeed)
        }
        return features
    }

    var refreshAction: AttentionShieldPassiveGateAction {
        action(for: features)
    }

    func refreshAction(
        activeSession: MoriScreenTimeActiveSession?,
        now: Date = Date()
    ) -> AttentionShieldPassiveGateAction {
        guard let activeSession else { return refreshAction }
        return activeSession.isExpired(at: now) ? refreshAction : .preserveActiveSession
    }

    func morningGateEndedAction(
        activeSession: MoriScreenTimeActiveSession?,
        now: Date = Date()
    ) -> AttentionShieldPassiveGateAction {
        guard activeSession?.isExpired(at: now) != false else {
            return .preserveActiveSession
        }
        return action(for: shouldApplyBeforeFeedGate ? [.beforeFeed] : [])
    }

    static func currentFeature(for features: [MoriScreenTimeFeature]) -> MoriScreenTimeFeature {
        if features.contains(.beforeFeed) {
            return .beforeFeed
        }
        if features.contains(.morningGate) {
            return .morningGate
        }
        return features.first ?? .manualPractice
    }

    private func action(for features: [MoriScreenTimeFeature]) -> AttentionShieldPassiveGateAction {
        features.isEmpty ? .clear : .apply(features)
    }
}
