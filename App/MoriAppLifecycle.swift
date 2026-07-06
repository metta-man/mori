import SwiftUI

private struct MoriAppLifecycleModifier: ViewModifier {
    @ObservedObject private var userSettings: UserSettings
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastTrackedAppOpenAt: Date?

    init(userSettings: UserSettings) {
        self.userSettings = userSettings
    }

    func body(content: Content) -> some View {
        content
            .onAppear(perform: activateAppServices)
            .onChange(of: scenePhase, perform: handleScenePhase)
    }

    private func activateAppServices() {
        trackAppOpenedIfNeeded()
        BeforeFeedGate.normalizePersistedSettings()
        MorningGate.normalizePersistedSettings()
        QuietTimerCoordinator.reconcileExpiredSession()
        MindfulnessBellScheduler.shared.refreshIfNeeded()
        MoriWidgetContextPublisher.publish(settings: userSettings)
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            activateActiveScene()
        case .background:
            MoriWidgetContextPublisher.publish(settings: userSettings)
            AnalyticsManager.shared.endSession()
        default:
            break
        }
    }

    private func activateActiveScene() {
        trackAppOpenedIfNeeded()
        BeforeFeedGate.normalizePersistedSettings()
        MorningGate.normalizePersistedSettings()
        QuietTimerCoordinator.reconcileExpiredSession()
        MindfulnessBellScheduler.shared.refreshIfNeeded()
        AppLimitManager.shared.perform(.reconcileAppLimitState)
        MoriAppRouteStore.shared.requestPendingRouteDrain()
        AnalyticsManager.shared.trackScreenTimeAttemptsIfNeeded()
        MoriWidgetContextPublisher.publish(settings: userSettings)
    }

    private func trackAppOpenedIfNeeded() {
        let now = Date()
        if let lastTrackedAppOpenAt,
           now.timeIntervalSince(lastTrackedAppOpenAt) < 2 {
            return
        }

        lastTrackedAppOpenAt = now
        AnalyticsManager.shared.trackAppOpened()
        AnalyticsManager.shared.trackScreenTimeAttemptsIfNeeded()
    }
}

extension View {
    func moriAppLifecycle(userSettings: UserSettings) -> some View {
        modifier(MoriAppLifecycleModifier(userSettings: userSettings))
    }
}
