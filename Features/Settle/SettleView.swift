import SwiftUI

struct SettleView: View {
    let launchRequest: MoriPracticeLaunchRequest?

    @Environment(\.moriOpenRoute) private var openRoute
    @Environment(\.moriOpenSettleRoute) private var openSettleRoute
    @AppStorage(
        MoriScreenTimeShared.beforeFeedDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedDurationSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedDurationSeconds
    @AppStorage(
        MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedBreathingTechniqueID: String = MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
    @AppStorage(
        MoriScreenTimeShared.beforeFeedPauseStyleKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedPauseStyleRaw: String = MoriBeforeFeedPauseStyle.guidedBreathing.rawValue
    @AppStorage(
        MoriScreenTimeShared.beforeFeedGuidedCycleCountKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedGuidedCycleCount: Int = MoriBeforeFeedPausePreferences.defaultGuidedCycleCount
    @State private var handledLaunchRequestID: UUID?
    @State private var showsFocusSupport = false
    @StateObject private var appLimitManager = AppLimitManager.shared
    @AppStorage("mori_essential_mode_duration") private var essentialDurationRaw = EssentialModeDuration.oneHour.rawValue

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
                duration: "10 min",
                scene: .quietMode,
                artwork: .asset("MoriDeepSessionForest"),
                height: 208,
                cornerRadius: 18,
                action: { openSettleRoute(.quietMode) }
            )

            MoriModeCard(
                title: "Essential Mode",
                description: "Keep only calls, maps,\nand the apps you choose.",
                duration: essentialModeCardStatus,
                scene: .offlineReset,
                artwork: .asset("MoriDeepSessionForest"),
                height: 208,
                cornerRadius: 18,
                quickAction: quickStartEssentialMode,
                action: { openSettleRoute(.essentialMode) }
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
                    subtitle: beforeFeedPauseSummary,
                    icon: .beforeFeedReset
                )
            }
            .buttonStyle(MoriV2PressButtonStyle())

            NavigationLink(value: SettleNavigationRoute.appLimits) {
                MoriV2QuietActionRow(
                    title: "App Limits",
                    subtitle: "Choose which apps stay quiet during a session.",
                    icon: .appLimit
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

    private var beforeFeedPauseSummary: String {
        let style = MoriBeforeFeedPauseStyle(rawValue: beforeFeedPauseStyleRaw) ?? .guidedBreathing
        return MoriL10n.string(
            "before_feed.focus.summary",
            defaultValue: "%@ · choose the feed window each time.",
            arguments: [
                MoriBeforeFeedPauseSettingsPresentation.summary(
                    style: style,
                    techniqueID: beforeFeedBreathingTechniqueID,
                    guidedCycleCount: beforeFeedGuidedCycleCount,
                    quietDurationSeconds: beforeFeedDurationSeconds
                )
            ]
        )
    }

    private var essentialModeCardStatus: String {
        let summary = appLimitManager.settingsSnapshot.profileSummary(for: .walkOfflineReset)
        guard appLimitManager.settingsSnapshot.isAuthorized, summary.hasEffectiveSelection else {
            return "Set up"
        }
        return EssentialModeDuration(rawValue: essentialDurationRaw)?.compactTitle ?? "1 hr"
    }

    private func quickStartEssentialMode() {
        let snapshot = appLimitManager.settingsSnapshot
        let summary = snapshot.profileSummary(for: .walkOfflineReset)
        guard snapshot.isAuthorized,
              summary.hasEffectiveSelection,
              appLimitManager.activeSession == nil
        else {
            openSettleRoute(.essentialMode)
            return
        }

        let duration = EssentialModeDuration(rawValue: essentialDurationRaw) ?? .oneHour
        if let seconds = duration.seconds {
            _ = appLimitManager.perform(
                .startTimedAppLimit(feature: .walkOfflineReset, remainingSeconds: seconds)
            )
        } else {
            _ = appLimitManager.perform(.startManualAppLimit(feature: .walkOfflineReset))
        }
        openSettleRoute(.essentialMode)
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
        case .deepSession:
            openSettleRoute(.focusCycle)
        case .quietMode:
            openSettleRoute(.quietMode)
        case .essentialMode:
            openSettleRoute(.essentialMode)
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
