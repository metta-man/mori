import SwiftUI

struct SettleView: View {
    let launchRequest: MoriPracticeLaunchRequest?

    @Environment(\.moriOpenRoute) private var openRoute
    @Environment(\.moriOpenSettleRoute) private var openSettleRoute
    @AppStorage(
        MoriScreenTimeShared.beforeFeedDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedDurationSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedDurationSeconds
    @State private var handledLaunchRequestID: UUID?
    @State private var showsFocusSupport = false

    init(
        launchRequest: MoriPracticeLaunchRequest? = nil
    ) {
        self.launchRequest = launchRequest
    }

    var body: some View {
        MoriV2RootScrollScreen(
            title: "Focus",
            subtitle: "Protect your attention.\nChoose how you want to show up.",
            backgroundVariant: .focus,
            minimumTopInset: 66,
            headerTextSpacing: 5,
            headerTextLeadingInset: 8,
            settingsButtonStyle: .plain,
            showsBackground: false,
            animatesEntrance: false,
            onOpenSettings: openSettings
        ) {
            primaryModeCards
            focusSupportDisclosure
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .settleLaunchRequestLifecycle(
            launchRequestID: launchRequest?.id,
            onHandleLaunchRequest: handleLaunchRequestIfNeeded
        )
    }

    private var primaryModeCards: some View {
        VStack(spacing: 12) {
            MoriModeCard(
                title: "Deep Session",
                description: "Work, study, or create\nwith apps blocked.",
                duration: "25 min",
                scene: .deepSession,
                artwork: .asset("MoriTodayBeforeFeedForest"),
                emphasis: .primary,
                height: 215,
                cornerRadius: 18,
                action: { openSettleRoute(.focusCycle) }
            )

            MoriModeCard(
                title: "Quiet Mode",
                description: "Read, rest, meditate,\nor sit quietly.",
                duration: "15 min",
                scene: .quietMode,
                artwork: .asset("MoriDeepSessionForest"),
                height: 208,
                cornerRadius: 18,
                action: { openPracticeSheet(.quietMode) }
            )

            MoriModeCard(
                title: "Offline Reset",
                description: "Walk, stretch,\nmake tea, or\nleave the screen.",
                duration: "8 min",
                scene: .offlineReset,
                artwork: .asset("MoriDeepSessionForest"),
                height: 208,
                cornerRadius: 18,
                action: { openPracticeSheet(.verification(.walkReset)) }
            )
        }
        .padding(.leading, 3)
        .padding(.top, 3)
    }

    private var focusSupportDisclosure: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriV2QuietDisclosureRow(
                title: showsFocusSupport ? "Hide focus support" : "Focus support",
                subtitle: showsFocusSupport
                    ? "Return to the three focus modes."
                    : "Breathing, timers, bells, and app limits.",
                isExpanded: showsFocusSupport,
                action: { showsFocusSupport.toggle() }
            )

            if showsFocusSupport {
                quietToolRows
                    .transition(.opacity)
            }
        }
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsFocusSupport)
    }

    private var quietToolRows: some View {
        VStack(spacing: 10) {
            NavigationLink(value: SettleNavigationRoute.breathingLibrary) {
                MoriV2QuietActionRow(
                    title: "Breathing",
                    subtitle: "Choose a gentle guided rhythm.",
                    icon: .breathe
                )
            }
            .buttonStyle(MoriV2PressButtonStyle())

            NavigationLink(value: SettleNavigationRoute.settleTimer) {
                MoriV2QuietActionRow(
                    title: "Quiet Session",
                    subtitle: "A simple timer to settle and return.",
                    icon: .timer
                )
            }
            .buttonStyle(MoriV2PressButtonStyle())

            NavigationLink(value: SettleNavigationRoute.mindfulnessBellSettings) {
                MoriV2QuietActionRow(
                    title: "Mindfulness Bell",
                    subtitle: "Let one soft bell interrupt autopilot.",
                    icon: .bell
                )
            }
            .buttonStyle(MoriV2PressButtonStyle())

            Button {
                openPracticeSheet(.beforeFeed)
            } label: {
                MoriV2QuietActionRow(
                    title: "Before Feed",
                    subtitle: "Pause \(BeforeFeedGate.formattedDuration(beforeFeedDurationSeconds)) before the next feed.",
                    icon: .lockShield
                )
            }
            .buttonStyle(MoriV2PressButtonStyle())

            NavigationLink(value: SettleNavigationRoute.appLimits) {
                MoriV2QuietActionRow(
                    title: "App Limits",
                    subtitle: "Choose which apps stay quiet during a session.",
                    icon: .lockShield
                )
            }
            .buttonStyle(MoriV2PressButtonStyle())

            Button {
                openPracticeSheet(.dailyCheckIn)
            } label: {
                MoriV2QuietActionRow(
                    title: "Daily Check-In",
                    subtitle: "Notice how today feels without scoring it.",
                    icon: .journal
                )
            }
            .buttonStyle(MoriV2PressButtonStyle())

        }
    }

    private func openSettings() {
        openRoute(.settings)
    }

    private func openPracticeSheet(_ sheet: MoriPracticeSheet) {
        openRoute(.practiceSheet(sheet))
    }

    private func handleLaunchRequestIfNeeded() {
        guard let launchRequest,
              handledLaunchRequestID != launchRequest.id else {
            return
        }

        handledLaunchRequestID = launchRequest.id

        switch launchRequest.kind {
        case .mindfulnessBellBreathing:
            openMindfulnessBellBreathing()
        }
    }

    private func openMindfulnessBellBreathing() {
        let techniqueID = MindfulnessBellDefaults.selectedBreathingTechniqueID()
        let durationMinutes = MindfulnessBellDefaults.selectedBreathingDurationMinutes()

        DispatchQueue.main.async {
            openSettleRoute(
                .breathingSession(
                    techniqueID: techniqueID,
                    durationMinutes: durationMinutes,
                    autoStart: true
                )
            )
        }
    }

}

#Preview {
    SettleView()
        .environmentObject(UserSettings())
}
