import ManagedSettings

final class MoriShieldActionExtension: ShieldActionDelegate {
    private let shieldStateStore = AttentionShieldStateStore()
    private let resetRequestRouter = MoriShieldResetRequestRouter()

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        recordAttempt(action: action, targetKind: .application)
        completionHandler(response(for: action))
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        recordAttempt(action: action, targetKind: .webDomain)
        completionHandler(response(for: action))
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        recordAttempt(action: action, targetKind: .category)
        completionHandler(response(for: action))
    }

    private func response(for action: ShieldAction) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            if currentShieldFeature == .beforeFeed {
                resetRequestRouter.requestResetLaunch(for: currentShieldFeature)
            }
            return .close
        case .secondaryButtonPressed:
            if currentShieldFeature != .beforeFeed {
                resetRequestRouter.requestResetLaunch(for: currentShieldFeature)
            }
            return .close
        default:
            return .none
        }
    }

    private func recordAttempt(action: ShieldAction, targetKind: MoriScreenTimeAttemptTargetKind) {
        guard let attemptAction = attemptAction(for: action) else { return }

        let feature = currentShieldFeature
        let estimate = MoriScreenTimeSavedTimeEstimator.currentEstimate(
            feature: feature,
            targetKind: targetKind
        )
        MoriScreenTimeAttemptStore.append(
            MoriScreenTimeAttempt(
                feature: feature,
                targetKind: targetKind,
                action: attemptAction,
                estimate: estimate
            )
        )
    }

    private func attemptAction(for action: ShieldAction) -> MoriScreenTimeAttemptAction? {
        switch action {
        case .primaryButtonPressed:
            return .primaryButtonPressed
        case .secondaryButtonPressed:
            return .secondaryButtonPressed
        default:
            return nil
        }
    }

    private var currentShieldFeature: MoriScreenTimeFeature? {
        shieldStateStore.loadCurrentFeature()
    }
}

private struct MoriShieldResetRequestRouter {
    private let beforeFeedGateStore: BeforeFeedGateStore

    init(beforeFeedGateStore: BeforeFeedGateStore = BeforeFeedGateStore()) {
        self.beforeFeedGateStore = beforeFeedGateStore
    }

    func requestResetLaunch(for feature: MoriScreenTimeFeature?) {
        switch feature {
        case .morningGate:
            MorningGate.requestResetLaunch(source: .screenTimeGate)
        case .beforeFeed:
            beforeFeedGateStore.requestResetLaunchIfNeeded(source: .screenTimeGate)
        default:
            break
        }
    }
}
