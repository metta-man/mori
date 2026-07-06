import SwiftUI

struct SettleTimerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settleStore = SettleSessionStore.shared

    @AppStorage("mori_settle_last_duration") private var selectedMinutes: Int = 10
    @AppStorage("mori_settle_sound_enabled") private var soundEnabled: Bool = true
    @AppStorage("mori_settle_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("mori_settle_animation_enabled") private var animationEnabled: Bool = true
    @AppStorage("mori_timer_dark_room_enabled") private var darkRoomEnabled: Bool = false
    @AppStorage("mori_timer_dark_room_dim") private var darkRoomDim: Double = 0.92
    @AppStorage("mori_settle_interval_enabled") private var intervalBellEnabled: Bool = false
    @AppStorage("mori_settle_interval_minutes") private var intervalBellMinutes: Int = 5
    @AppStorage(MindfulnessBellDefaults.isActiveKey) private var mindfulnessBellEnabled = false
    @AppStorage(MindfulnessBellDefaults.nextFireKey) private var mindfulnessBellNextFireTimestamp: Double = 0
    @AppStorage(MindfulnessBellDefaults.promptDismissedKey) private var mindfulnessBellPromptDismissed = false

    @State private var timerState: SettleTimerState = .idle
    @State private var secondsRemaining: Int = 10 * 60
    @State private var sessionStartedAt: Date?
    @State private var lastIntervalBellElapsed = 0
    @State private var completedSession: SettleSession?
    @State private var completedSettleSeeds: Int?
    @State private var showLeaveDialog = false
    @State private var completionCoordinator = SettleTimerCompletionCoordinator()
    @State private var feedbackCoordinator = SettleTimerFeedbackCoordinator()
    @StateObject private var darkRoomCoordinator = SettleDarkRoomCoordinator()
    @State private var mindfulnessBellAuthorizationDenied = false

    private let baseDurations = [5, 10, 15, 20, 30, 45]
    private let intervalOptions = [5, 10, 15]

    private var weeklySummary: SettleWeeklySummary {
        settleStore.weeklySummary()
    }

    private var recommendedMinutes: Int {
        settleStore.recommendedDurationMinutes()
    }

    private var durationOptions: [Int] {
        Array(Set(baseDurations + [recommendedMinutes])).sorted()
    }

    var body: some View {
        Group {
            if timerState.isActive {
                activeTimerSurface
            } else {
                setupTimerSurface
            }
        }
        .navigationTitle("Settle")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    requestClose()
                } label: {
                    MoriBitmapIconImage(
                        icon: .chevron,
                        size: 15,
                        opacity: darkRoomEnabled && timerState.isActive ? 0.72 : 0.88
                    )
                    .rotationEffect(.degrees(180))
                }
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(darkRoomEnabled && timerState.isActive ? .black : MoriColors.botanicalPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(darkRoomEnabled && timerState.isActive ? .dark : .light, for: .navigationBar)
        .toolbar(darkRoomChromeHidden ? .hidden : .visible, for: .navigationBar)
        .moriHidesMainTabBar()
        .settleTimerLifecycle(
            selectedMinutes: selectedMinutes,
            darkRoomEnabled: darkRoomEnabled,
            showLeaveDialog: $showLeaveDialog,
            onPrepare: prepareTimerSession,
            onSelectedMinutesChange: handleSelectedMinutesChange,
            onTick: tick,
            onDarkRoomEnabledChange: handleDarkRoomEnabledChange,
            onCleanup: clearDarkRoomTransientState,
            onEndAndLeave: endAndDismiss
        )
    }

    private var setupTimerSurface: some View {
        SettleTimerSetupSurface(
            recommendedMinutes: recommendedMinutes,
            weeklySummary: weeklySummary,
            intervalBellEnabled: $intervalBellEnabled,
            intervalBellMinutes: $intervalBellMinutes,
            intervalOptions: intervalOptions,
            onUseRecommendation: applyRecommendedDuration,
            onStartRecommendation: startRecommendedDuration
        ) {
            timerCard
        }
    }

    private var activeTimerSurface: some View {
        SettleTimerActiveSurface(
            timeText: timeText,
            timerState: timerState,
            soundEnabled: $soundEnabled,
            hapticsEnabled: $hapticsEnabled,
            animationEnabled: $animationEnabled,
            darkRoomEnabled: $darkRoomEnabled,
            darkRoomDim: $darkRoomDim,
            darkRoomOffScreen: darkRoomCoordinator.offScreen,
            darkRoomControlsVisible: darkRoomCoordinator.controlsVisible,
            onRevealDarkRoomControls: revealDarkRoomControls,
            onExitDarkRoomOffScreen: exitDarkRoomOffScreen,
            onEnterDarkRoomOffScreen: enterDarkRoomOffScreen,
            onStart: startTimer,
            onPause: pauseTimer,
            onResume: resumeTimer,
            onEnd: endTimer
        )
    }

    private var darkRoomChromeHidden: Bool {
        darkRoomEnabled && timerState.isActive
    }

    private var timerCard: some View {
        SettleTimerCard(
            timerState: timerState,
            durationOptions: durationOptions,
            recommendedMinutes: recommendedMinutes,
            timerProgress: timerProgress,
            timeText: timeText,
            completedSession: completedSession,
            completedSettleSeeds: completedSettleSeeds,
            soundEnabled: $soundEnabled,
            selectedMinutes: $selectedMinutes,
            onStart: startTimer,
            onPause: pauseTimer,
            onResume: resumeTimer,
            onEnd: endTimer
        ) {
            SettleMindfulnessBellCompletionPrompt(
                mindfulnessBellEnabled: mindfulnessBellEnabled,
                nextFireTimestamp: mindfulnessBellNextFireTimestamp,
                promptDismissed: mindfulnessBellPromptDismissed,
                authorizationDenied: mindfulnessBellAuthorizationDenied,
                onSetBell: enableRecommendedMindfulnessBell,
                onDismiss: {
                    mindfulnessBellPromptDismissed = true
                }
            )
        }
    }

    private var timerProgress: CGFloat {
        let total = max(1, selectedMinutes * 60)
        return CGFloat(total - secondsRemaining) / CGFloat(total)
    }

    private var timeText: String {
        formatTime(secondsRemaining)
    }

    private func prepareTimerSession() {
        guard timerState.canChangeDuration else { return }
        secondsRemaining = selectedMinutes * 60
    }

    private func handleSelectedMinutesChange(_ newValue: Int) {
        guard timerState.canChangeDuration else { return }
        secondsRemaining = newValue * 60
        completedSession = nil
        completedSettleSeeds = nil
    }

    private func handleDarkRoomEnabledChange(_ enabled: Bool) {
        if enabled {
            hideDarkRoomControls()
        } else {
            clearDarkRoomTransientState()
        }
    }

    private func endAndDismiss() {
        endTimer()
        dismiss()
    }

    private func startTimer() {
        sessionStartedAt = Date()
        secondsRemaining = selectedMinutes * 60
        timerState = .running
        lastIntervalBellElapsed = 0
        completedSession = nil
        completedSettleSeeds = nil
        completionCoordinator.startAppLimitIfPossible(secondsRemaining: secondsRemaining)
        feedbackCoordinator.playStartFeedback(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
    }

    private func pauseTimer() {
        guard timerState == .running else { return }
        timerState = .paused
    }

    private func resumeTimer() {
        guard timerState == .paused else { return }
        timerState = .running
    }

    private func applyRecommendedDuration() {
        guard timerState.canChangeDuration else { return }
        selectedMinutes = recommendedMinutes
        secondsRemaining = recommendedMinutes * 60
        completedSession = nil
        completedSettleSeeds = nil
    }

    private func startRecommendedDuration() {
        guard timerState.canChangeDuration else { return }
        selectedMinutes = recommendedMinutes
        startTimer()
    }

    private func endTimer() {
        guard timerState == .running || timerState == .paused else { return }
        clearDarkRoomTransientState()

        completionCoordinator.recordEndedEarly(
            startedAt: sessionStartedAt,
            selectedMinutes: selectedMinutes,
            secondsRemaining: secondsRemaining,
            intervalBellMinutes: activeIntervalBellMinutes
        )
        feedbackCoordinator.stopSessionSounds()
        completionCoordinator.endAppLimit()

        sessionStartedAt = nil
        secondsRemaining = selectedMinutes * 60
        timerState = .idle
        completedSession = nil
        completedSettleSeeds = nil
        lastIntervalBellElapsed = 0
    }

    private func tick() {
        guard timerState == .running else { return }

        if secondsRemaining > 0 {
            secondsRemaining -= 1
            playIntervalBellIfNeeded()
        }

        if secondsRemaining == 0 {
            completeTimer()
        }
    }

    private func completeTimer() {
        guard timerState == .running, let startedAt = sessionStartedAt else { return }

        timerState = .completed
        clearDarkRoomTransientState()
        let completion = completionCoordinator.recordCompletion(
            startedAt: startedAt,
            selectedMinutes: selectedMinutes,
            intervalBellMinutes: activeIntervalBellMinutes
        )

        completedSession = completion.session
        completedSettleSeeds = completion.seeds
        sessionStartedAt = nil
        lastIntervalBellElapsed = 0
        feedbackCoordinator.playCompletionFeedback(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
    }

    private func playIntervalBellIfNeeded() {
        lastIntervalBellElapsed = feedbackCoordinator.playIntervalBellIfNeeded(
            soundEnabled: soundEnabled,
            intervalBellMinutes: activeIntervalBellMinutes,
            timerState: timerState,
            selectedMinutes: selectedMinutes,
            secondsRemaining: secondsRemaining,
            lastIntervalBellElapsed: lastIntervalBellElapsed
        )
    }

    private var activeIntervalBellMinutes: Int? {
        guard intervalBellEnabled, intervalBellMinutes > 0, intervalBellMinutes < selectedMinutes else {
            return nil
        }
        return intervalBellMinutes
    }

    private func revealDarkRoomControls() {
        darkRoomCoordinator.revealControls(isDarkRoomEnabled: darkRoomEnabled, isSessionActive: timerState.isActive)
    }

    private func hideDarkRoomControls() {
        darkRoomCoordinator.hideControls()
    }

    private func enterDarkRoomOffScreen() {
        darkRoomCoordinator.enterOffScreen(keepScreenOn: false, isRunning: timerState == .running)
    }

    private func exitDarkRoomOffScreen() {
        darkRoomCoordinator.exitOffScreen(keepScreenOn: false, isRunning: timerState == .running)
    }

    private func clearDarkRoomTransientState() {
        darkRoomCoordinator.clearTransientState(keepScreenOn: false, isRunning: timerState == .running)
    }

    private func requestClose() {
        if timerState == .running || timerState == .paused {
            showLeaveDialog = true
        } else {
            dismiss()
        }
    }

    private func enableRecommendedMindfulnessBell() {
        mindfulnessBellAuthorizationDenied = false
        MindfulnessBellScheduler.shared.applyRecommendedDefaults()
        MindfulnessBellScheduler.shared.requestAuthorization { granted in
            if granted {
                mindfulnessBellPromptDismissed = false
                mindfulnessBellEnabled = true
                MindfulnessBellScheduler.shared.scheduleUpcomingBells()
            } else {
                mindfulnessBellEnabled = false
                mindfulnessBellAuthorizationDenied = true
            }
        }
    }
}
