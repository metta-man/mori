import Foundation

enum AttentionShieldPassiveGateAction {
    case preserveActiveSession
    case apply([MoriScreenTimeFeature])
    case clear
}

struct AttentionShieldPassiveGateApplier {
    private let selectionStore: ScreenTimeSelectionStore
    private let shieldApplier: AttentionShieldApplier
    private let displayNames: (MoriScreenTimeFeature) -> [String]

    init(
        selectionStore: ScreenTimeSelectionStore,
        shieldApplier: AttentionShieldApplier,
        displayNames: ((MoriScreenTimeFeature) -> [String])? = nil
    ) {
        self.selectionStore = selectionStore
        self.shieldApplier = shieldApplier
        self.displayNames = displayNames ?? { feature in
            selectionStore.summary(for: feature).displayNames
        }
    }

    func apply(_ action: AttentionShieldPassiveGateAction) {
        switch action {
        case .preserveActiveSession:
            break
        case .apply(let features):
            apply(features: features)
        case .clear:
            shieldApplier.clear()
        }
    }

    func apply(features: [MoriScreenTimeFeature]) {
        let selection = selectionStore.mergedEffectiveSelection(for: features)
        let currentFeature = AttentionShieldPassiveGatePolicy.currentFeature(for: features)
        let beforeFeedSelection = features.contains(.beforeFeed)
            ? selectionStore.effectiveSelection(for: .beforeFeed)
            : nil
        shieldApplier.apply(
            selection: selection,
            currentFeature: currentFeature,
            displayNames: displayNames(currentFeature),
            beforeFeedHasSelection: features.contains(.beforeFeed)
                ? selectionStore.hasEffectiveSelection(for: .beforeFeed)
                : nil,
            beforeFeedApplicationTokenCount: beforeFeedSelection?.applicationTokens.count,
            beforeFeedWebDomainTokenCount: beforeFeedSelection?.webDomainTokens.count
        )
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
