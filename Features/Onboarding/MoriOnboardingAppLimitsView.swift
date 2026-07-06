import SwiftUI

struct OnboardingAppLimitsScreen: View {
    @StateObject private var appLimitManager = AppLimitManager.shared

    let onComplete: (String) -> Void

    var body: some View {
        GeometryReader { proxy in
            FirstAppLimitSetupSurface(
                appLimitManager: appLimitManager,
                copy: .onboarding,
                routeSource: nil,
                primaryTitle: { isReady in
                    isReady ? "Finish with App Limit on" : "Turn App Limit On"
                },
                primaryAnalyticsAction: { _ in
                    appLimitManager.settingsSnapshot.isAppLimitReady(for: .beforeFeed)
                        ? "finish_onboarding"
                        : "turn_app_limit_on"
                },
                isPrimaryDisabled: { summary in
                    !appLimitManager.settingsSnapshot.isAuthorized || !summary.hasEffectiveSelection
                },
                primaryAction: complete,
                secondaryTitle: "Skip App Limit for now",
                secondaryAction: { onComplete("skipped_app_limit") }
            )
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func complete(_ summary: MoriScreenTimeProfileSummary) {
        let snapshot = appLimitManager.settingsSnapshot

        if snapshot.isAppLimitReady(for: .beforeFeed) {
            FirstAppLimitSetupMorningGateActivation.activate(using: appLimitManager)
            onComplete("first_app_limit_ready")
            return
        }

        guard snapshot.isAuthorized, summary.hasEffectiveSelection else { return }

        appLimitManager.perform(.setFeatureEnabled(true, .beforeFeed))
        FirstAppLimitSetupMorningGateActivation.activate(using: appLimitManager)
        guard trackCompletedIfReady() else { return }
        onComplete("first_app_limit_ready")
    }

    @discardableResult
    private func trackCompletedIfReady() -> Bool {
        let snapshot = appLimitManager.settingsSnapshot
        guard snapshot.isAppLimitReady(for: .beforeFeed) else { return false }

        AnalyticsManager.shared.trackFirstAppLimitSetupEvent(
            action: "app_limit_completed",
            context: FirstAppLimitSetupCopy.onboarding.analyticsContext,
            snapshot: snapshot,
            summary: snapshot.profileSummary(for: .beforeFeed)
        )

        return true
    }
}
