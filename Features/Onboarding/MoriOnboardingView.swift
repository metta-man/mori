//
//  MoriOnboardingView.swift
//  Mori
//
//  App Limit-first onboarding.
//

import SwiftUI

private enum MoriOnboardingLayout {
    static let maxContentWidth: CGFloat = 620
}

struct MoriOnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var onboardingStartTime = Date()
    @State private var hasTrackedOnboardingStart = false

    private let totalScreens = 1
    
    var body: some View {
        MoriPaperBackground(variant: .onboarding) {
            OnboardingAppLimitsScreen(onComplete: completeOnboarding)
                .frame(maxWidth: MoriOnboardingLayout.maxContentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.light)
        .onAppear(perform: trackOnboardingStarted)
    }
    
    private func completeOnboarding(completionMethod: String) {
        userSettings.hasCompletedOnboarding = true

        AnalyticsManager.shared.trackOnboardingCompleted(
            stepsCompleted: totalScreens,
            completionMethod: completionMethod
        )
        AnalyticsManager.shared.trackLoopEvent("onboarding_completed", properties: [
            "steps_completed": totalScreens,
            "completion_method": completionMethod,
            "time_spent": Date().timeIntervalSince(onboardingStartTime)
        ])
    }

    private func trackOnboardingStarted() {
        guard !hasTrackedOnboardingStart else { return }
        hasTrackedOnboardingStart = true
        onboardingStartTime = Date()
        AnalyticsManager.shared.trackOnboardingStarted()
    }
}

// MARK: - Preview
#Preview {
    MoriOnboardingView()
        .environmentObject(UserSettings())
}
