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
    @State private var showsSetup = false
    @State private var showsHandoff = false

    private let totalScreens = 2
    
    var body: some View {
        MoriPaperBackground(variant: .onboarding) {
            Group {
                if showsSetup {
                    OnboardingAppLimitsScreen(onComplete: completeOnboarding)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            MoriPageHeader(eyebrow: "MORI", title: "Less phone. More day.", subtitle: "Start with one small moment away from the screen.")
                            MoriLivingLandscape(motionEnabled: false)
                                .aspectRatio(1.8, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                            Text(MoriL10n.display("Put your phone down and notice something outside."))
                                .font(.body).foregroundColor(MoriV2Palette.stone)
                            MoriPrimaryButton(title: MoriL10n.display("Try putting my phone aside")) { showsHandoff = true }
                            Button(MoriL10n.display("Set up one app")) { showsSetup = true }
                                .frame(maxWidth: .infinity, minHeight: 44)
                            Button(MoriL10n.display("Explore Mori first")) { completeOnboarding(completionMethod: "explore_first") }
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .padding(24)
                    }
                    .tint(MoriV2Palette.forestInk)
                }
            }
                .frame(maxWidth: MoriOnboardingLayout.maxContentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showsHandoff) {
            MoriOfflineHandoffContent(onDone: { showsHandoff = false })
                .moriBotanicalSheetPresentation()
        }
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
