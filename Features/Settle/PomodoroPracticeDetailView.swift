import SwiftUI

struct PomodoroPracticeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("mori_deep_session_keep_screen_on") private var keepScreenOn = false
    @AppStorage("mori_settle_sound_enabled") private var soundEnabled: Bool = true
    @AppStorage("mori_settle_pomodoro_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("mori_settle_pomodoro_animation_enabled") private var animationEnabled: Bool = true
    @AppStorage("mori_settle_breathing_haptic_style") private var breathingHapticStyleRaw: String = MoriBreathingHapticStyle.minimalist.rawValue
    @AppStorage("mori_timer_dark_room_enabled") private var darkRoomEnabled: Bool = false
    @AppStorage("mori_timer_dark_room_dim") private var darkRoomDim: Double = 0.92
    @AppStorage("mori_settle_pomodoro_focus_minutes") private var pomodoroFocusMinutes: Int = 25
    @AppStorage("mori_settle_pomodoro_short_break_minutes") private var pomodoroShortBreakMinutes: Int = 5
    @AppStorage("mori_settle_pomodoro_long_break_minutes") private var pomodoroLongBreakMinutes: Int = 15
    @AppStorage("mori_settle_pomodoro_cycles") private var pomodoroCycles: Int = 4
    @AppStorage("mori_settle_pomodoro_focus_breathing") private var pomodoroFocusBreathingRaw: String = MoriPomodoroBreakBreathing.none.rawValue
    @AppStorage("mori_settle_pomodoro_break_breathing") private var pomodoroBreakBreathingRaw: String = MoriPomodoroBreakBreathing.none.rawValue

    @State private var pomodoroClock = PomodoroPracticeSessionClock()
    @State private var deepSessionCompletion: MoriDeepSessionCompletion?
    @State private var pomodoroBreathingRuntime = PomodoroGuidedBreathingRuntime()
    @State private var showLeaveDialog = false
    @State private var completionCoordinator = PomodoroPracticeCompletionCoordinator()
    @State private var feedbackCoordinator = PomodoroPracticeFeedbackCoordinator()
    @State private var handledAutoStartFixture = false
    @StateObject private var darkRoomCoordinator = SettleDarkRoomCoordinator()
    @StateObject private var appLimitManager = AppLimitManager.shared

    private var pomodoroDurations: PomodoroPracticeDurations {
        PomodoroPracticeDurations(
            focusMinutes: pomodoroFocusMinutes,
            shortBreakMinutes: pomodoroShortBreakMinutes,
            longBreakMinutes: pomodoroLongBreakMinutes,
            cycles: pomodoroCycles
        )
    }

    private var pomodoroState: SettleTimerState {
        pomodoroClock.timerState
    }

    private var pomodoroPhase: MoriPomodoroPhase {
        pomodoroClock.phase
    }

    private var pomodoroSecondsRemaining: Int {
        pomodoroClock.secondsRemaining
    }

    private var pomodoroCompletedCycles: Int {
        pomodoroClock.completedCycles
    }

    private var pomodoroFocusSecondsCompleted: Int {
        pomodoroClock.focusSecondsCompleted
    }

    private var pomodoroBreakSecondsCompleted: Int {
        pomodoroClock.breakSecondsCompleted
    }

    private var pomodoroBreakBreathing: MoriPomodoroBreakBreathing {
        get { MoriPomodoroBreakBreathing(rawValue: pomodoroBreakBreathingRaw) }
        nonmutating set { pomodoroBreakBreathingRaw = newValue.rawValue }
    }

    private var pomodoroFocusBreathing: MoriPomodoroBreakBreathing {
        get { MoriPomodoroBreakBreathing(rawValue: pomodoroFocusBreathingRaw) }
        nonmutating set { pomodoroFocusBreathingRaw = newValue.rawValue }
    }

    private var pomodoroPresentation: PomodoroPracticePresentation {
        PomodoroPracticePresentation(
            timerState: pomodoroState,
            phase: pomodoroPhase,
            secondsRemaining: pomodoroSecondsRemaining,
            completedCycles: pomodoroCompletedCycles,
            cycles: pomodoroCycles,
            focusMinutes: pomodoroFocusMinutes,
            shortBreakMinutes: pomodoroShortBreakMinutes,
            longBreakMinutes: pomodoroLongBreakMinutes,
            focusBreathing: pomodoroFocusBreathing,
            breakBreathing: pomodoroBreakBreathing,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            hapticStyleRaw: breathingHapticStyleRaw,
            breathingRuntime: pomodoroBreathingRuntime
        )
    }

    var body: some View {
        Group {
            if let deepSessionCompletion {
                MoriDeepSessionCompletionSurface(
                    completion: deepSessionCompletion,
                    onContinue: continueAfterDeepSession
                )
            } else if pomodoroState.isActive {
                activePomodoroSurface
            } else {
                setupPomodoroSurface
            }
        }
        .moriOnChange(of: scenePhase, perform: handleScenePhase)
        .moriOnChange(of: keepScreenOn) { _ in applyScreenPolicy() }
        .pomodoroPracticeChrome(
            isDarkRoomActive: darkRoomEnabled && pomodoroState.isActive,
            hidesNavigationChrome: deepSessionCompletion != nil || pomodoroState.isActive,
            onBack: requestClose
        )
        .pomodoroPracticeLifecycle(
            focusMinutes: pomodoroFocusMinutes,
            shortBreakMinutes: pomodoroShortBreakMinutes,
            longBreakMinutes: pomodoroLongBreakMinutes,
            cycles: pomodoroCycles,
            focusBreathingRaw: pomodoroFocusBreathingRaw,
            breakBreathingRaw: pomodoroBreakBreathingRaw,
            darkRoomEnabled: darkRoomEnabled,
            showLeaveDialog: $showLeaveDialog,
            onPrepare: preparePomodoroSession,
            onDurationSettingsChange: resetPomodoroClockIfEditable,
            onFocusBreathingChange: handlePomodoroFocusBreathingChange,
            onBreakBreathingChange: handlePomodoroBreakBreathingChange,
            onTick: { if scenePhase == .active { tickPomodoro() } },
            onBreathingTick: syncPomodoroBreakBreathingState,
            onDarkRoomEnabledChange: handleDarkRoomEnabledChange,
            onCleanup: cleanupPomodoroSession,
            onEndAndLeave: endPomodoroAndLeave
        )
    }

    private var setupPomodoroSurface: some View {
        PomodoroPracticeSetupSurface(
            focusMinutes: $pomodoroFocusMinutes,
            shortBreakMinutes: $pomodoroShortBreakMinutes,
            longBreakMinutes: $pomodoroLongBreakMinutes,
            cycles: $pomodoroCycles,
            soundEnabled: $soundEnabled,
            hapticsEnabled: $hapticsEnabled,
            animationEnabled: $animationEnabled,
            darkRoomEnabled: $darkRoomEnabled,
            keepScreenOn: $keepScreenOn,
            phase: pomodoroPhase,
            timerState: pomodoroState,
            progress: pomodoroPresentation.progress,
            timeText: pomodoroPresentation.timeText,
            focusBreathing: pomodoroFocusBreathing,
            breakBreathing: pomodoroBreakBreathing,
            isGuidedBreathing: pomodoroPresentation.isGuidedBreathing,
            activeBreathing: pomodoroPresentation.activeBreathing,
            currentPhaseElapsedSeconds: pomodoroPresentation.phaseElapsedSeconds,
            blockedAppsText: blockedAppsText,
            blockedAppsCount: blockedAppsCount,
            onSelectPhase: selectSetupPomodoroPhase,
            onStart: startPomodoro,
            onSelectFocusBreathing: selectPomodoroFocusBreathing,
            onSelectBreakBreathing: selectPomodoroBreakBreathing
        )
    }

    private var activePomodoroSurface: some View {
        PomodoroActiveSessionSurface(
            darkRoomEnabled: darkRoomEnabled,
            darkRoomDim: $darkRoomDim,
            keepScreenOn: $keepScreenOn,
            darkRoomOffScreen: darkRoomCoordinator.offScreen,
            darkRoomControlsVisible: darkRoomCoordinator.controlsVisible,
            timeText: pomodoroPresentation.timeText,
            sessionLabel: pomodoroPresentation.sessionLabel,
            blockedAppsText: blockedAppsText,
            blockedAppsCount: blockedAppsCount,
            primaryCueText: pomodoroPresentation.primaryCueText,
            secondaryCueText: pomodoroPresentation.secondaryCueText,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            animationEnabled: animationEnabled,
            phase: pomodoroPhase,
            timerState: pomodoroState,
            progress: pomodoroPresentation.progress,
            isGuidedBreathing: pomodoroPresentation.isGuidedBreathing,
            activeBreathing: pomodoroPresentation.activeBreathing,
            breathingVisualState: pomodoroPresentation.breathingVisualState,
            onRevealDarkRoomControls: revealDarkRoomControls,
            onExitDarkRoomOffScreen: exitDarkRoomOffScreen,
            onEnterDarkRoomOffScreen: enterDarkRoomOffScreen,
            onToggleSound: togglePomodoroSound,
            onToggleHaptics: togglePomodoroHaptics,
            onToggleAnimation: { animationEnabled.toggle() },
            onToggleDarkRoom: { darkRoomEnabled.toggle() },
            onBack: requestClose,
            onPause: pausePomodoro,
            onResume: resumePomodoro,
            onEnd: endIncompletePomodoro
        ) {
            PomodoroControlRow(
                timerState: pomodoroState,
                onStart: startPomodoro,
                onReset: resetCompletedPomodoro,
                onPause: pausePomodoro,
                onResume: resumePomodoro,
                onEnd: endIncompletePomodoro
            )
        }
    }

    private func preparePomodoroSession() {
        normalizePomodoroFocusBreathingSelection()
        normalizePomodoroBreakBreathingSelection()
        resetPomodoroClockIfEditable()

        if ProcessInfo.processInfo.arguments.contains("-MoriShowDeepSessionCompletionForUITest") {
            deepSessionCompletion = MoriDeepSessionCompletion(
                quietMinutes: 25,
                completedPlannedSession: true
            )
            return
        }

        guard !handledAutoStartFixture,
              ProcessInfo.processInfo.arguments.contains("-MoriAutoStartDeepSessionForUITest")
        else {
            return
        }

        handledAutoStartFixture = true
        DispatchQueue.main.async {
            startPomodoro()
        }
    }

    private func resetPomodoroClockIfEditable() {
        if pomodoroClock.canChangeDuration {
            resetPomodoroClock()
        }
    }

    private func handlePomodoroFocusBreathingChange() {
        normalizePomodoroFocusBreathingSelection()
        resetPomodoroBreakBreathingGuidance(stopAudio: true, resetElapsed: false)
        if pomodoroState == .running, pomodoroPhase == .focus {
            syncPomodoroBreakBreathingElapsedToClock()
            startPomodoroBreakBreathingGuidance()
        }
    }

    private func handlePomodoroBreakBreathingChange() {
        normalizePomodoroBreakBreathingSelection()
        resetPomodoroBreakBreathingGuidance(stopAudio: true, resetElapsed: false)
        if pomodoroState == .running, pomodoroPhase.isBreak {
            syncPomodoroBreakBreathingElapsedToClock()
            startPomodoroBreakBreathingGuidance()
        }
    }

    private func handleDarkRoomEnabledChange(_ isEnabled: Bool) {
        if isEnabled {
            hideDarkRoomControls()
        } else {
            clearDarkRoomTransientState()
        }
    }

    private func cleanupPomodoroSession() {
        resetPomodoroBreakBreathingGuidance(stopAudio: true)
        darkRoomCoordinator.resetIdleTimer()
        if scenePhase == .active { completionCoordinator.cancelSessionAppLimit() }
    }

    private func applyScreenPolicy() {
        darkRoomCoordinator.applyIdleTimerPolicy(
            keepScreenOn: keepScreenOn && scenePhase == .active,
            isRunning: pomodoroState == .running && deepSessionCompletion == nil,
            offScreenOverride: false
        )
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        if phase == .active {
            tickPomodoro()
            if pomodoroState == .running {
                syncPomodoroBreakBreathingElapsedToClock()
                startPomodoroBreakBreathingGuidance()
            }
            applyScreenPolicy()
        } else {
            tickPomodoro()
            resetPomodoroBreakBreathingGuidance(stopAudio: true, resetElapsed: false)
            darkRoomCoordinator.resetIdleTimer()
        }
    }

    private func endPomodoroAndLeave() {
        endPomodoro(recordCompletion: false)
        dismiss()
    }

    private func togglePomodoroSound() {
        soundEnabled.toggle()
        if pomodoroPresentation.isBreathingActive {
            if soundEnabled {
                playPomodoroBreakSoundFeedback()
                schedulePomodoroBreakSoundForNextPhase()
            } else {
                cancelPomodoroBreakBreathingSound()
                feedbackCoordinator.stopGuidedBreathingCues()
            }
        } else {
            feedbackCoordinator.stopGuidedBreathingCues()
        }
    }

    private func togglePomodoroHaptics() {
        hapticsEnabled.toggle()
        if !hapticsEnabled {
            cancelPomodoroBreakBreathingHaptics()
        } else if pomodoroPresentation.isBreathingActive {
            schedulePomodoroBreakHapticsForCurrentPhase()
        }
    }

    private func selectSetupPomodoroPhase(_ phase: MoriPomodoroPhase) {
        guard pomodoroClock.selectSetupPhase(phase, durations: pomodoroDurations) else { return }
        deepSessionCompletion = nil
    }

    private func selectPomodoroFocusBreathing(_ breathing: MoriPomodoroBreakBreathing) {
        pomodoroFocusBreathing = breathing
    }

    private func selectPomodoroBreakBreathing(_ breathing: MoriPomodoroBreakBreathing) {
        pomodoroBreakBreathing = breathing
    }

    private func resetCompletedPomodoro() {
        resetPomodoroClock()
        deepSessionCompletion = nil
    }

    private func pausePomodoro() {
        tickPomodoro()
        guard pomodoroState == .running else { return }
        pomodoroClock.pause()
        applyScreenPolicy()
        resetPomodoroBreakBreathingGuidance(stopAudio: true, resetElapsed: false)
    }

    private func resumePomodoro() {
        pomodoroClock.resume()
        applyScreenPolicy()
        // Restore the timed protection deadline after a manual pause.
        startPomodoroAppLimitIfPossible()
        if pomodoroPhase == .focus || pomodoroPhase.isBreak {
            startPomodoroBreakBreathingGuidance()
        }
    }

    private func endIncompletePomodoro() {
        tickPomodoro()
        guard deepSessionCompletion == nil else { return }
        endPomodoro(recordCompletion: false)
    }

    private func startPomodoro() {
        normalizePomodoroFocusBreathingSelection()
        normalizePomodoroBreakBreathingSelection()
        pomodoroClock.start(durations: pomodoroDurations)
        resetPomodoroBreakBreathingGuidance(stopAudio: true)
        completionCoordinator.cancelSessionAppLimit()
        deepSessionCompletion = nil
        startPomodoroAppLimitIfPossible()
        startPomodoroBreakBreathingGuidance(resetElapsed: true)

        applyScreenPolicy()
        feedbackCoordinator.playStartBellIfNeeded(pomodoroPresentation.shouldPlayCurrentBell)
    }

    private func resetPomodoroClock() {
        pomodoroClock.reset(durations: pomodoroDurations)
        resetPomodoroBreakBreathingGuidance(stopAudio: true)
        completionCoordinator.cancelSessionAppLimit()
    }

    private func tickPomodoro() {
        guard pomodoroState == .running else { return }
        let previouslyCountedFocus = pomodoroClock.focusSecondsCompleted
        let scheduledFocusRemaining = pomodoroPhase == .focus ? pomodoroSecondsRemaining : 0
        let transition = pomodoroClock.update(to: Date(), durations: pomodoroDurations)
        if pomodoroClock.focusSecondsCompleted > previouslyCountedFocus + scheduledFocusRemaining {
            completionCoordinator.invalidatePastAppLimitCoverage()
        }
        if transition != .none {
            handlePomodoroPhaseTransition(transition)
        }
        syncPomodoroBreakBreathingElapsedToClock()
    }

    private func handlePomodoroPhaseTransition(_ transition: PomodoroPracticePhaseTransition) {
        switch transition {
        case .none:
            break
        case .completed:
            resetPomodoroBreakBreathingGuidance(stopAudio: true)
            endPomodoro(recordCompletion: true)
        case .breakStarted(let phase):
            resetPomodoroBreakBreathingGuidance(stopAudio: true)
            playPomodoroTransitionBell(for: phase)
            completionCoordinator.endAppLimit()
            startPomodoroBreakBreathingGuidance(resetElapsed: true)
        case .focusStarted:
            resetPomodoroBreakBreathingGuidance(stopAudio: true)
            playPomodoroTransitionBell(for: .focus)
            startPomodoroAppLimitIfPossible()
            startPomodoroBreakBreathingGuidance(resetElapsed: true)
        }
    }

    private func playPomodoroTransitionBell(for phase: MoriPomodoroPhase) {
        guard scenePhase == .active else { return }
        feedbackCoordinator.playTransitionFeedback(
            shouldPlayBell: pomodoroPresentation.shouldPlayBell(for: phase),
            hapticsEnabled: hapticsEnabled
        )
    }

    private func endPomodoro(recordCompletion: Bool) {
        clearDarkRoomTransientState()
        let completedCycles = pomodoroCompletedCycles
        let protectedFocusSeconds = pomodoroFocusSecondsCompleted

        pomodoroClock.complete()
        darkRoomCoordinator.resetIdleTimer()
        completionCoordinator.endAppLimit()
        feedbackCoordinator.stopSessionSounds()
        resetPomodoroBreakBreathingGuidance(stopAudio: true)

        if recordCompletion,
           completionCoordinator.recordCompletion(
                focusSecondsCompleted: pomodoroFocusSecondsCompleted,
                breakSecondsCompleted: pomodoroBreakSecondsCompleted,
                completedCycles: completedCycles
            ) != nil
        {
            let quietMinutes = max(1, Int((Double(protectedFocusSeconds) / 60.0).rounded(.down)))
            deepSessionCompletion = MoriDeepSessionCompletion(
                quietMinutes: quietMinutes,
                completedPlannedSession: true
            )
            playPomodoroCompletionFeedback()
        } else if protectedFocusSeconds > 0 {
            let quietMinutes = Int((Double(protectedFocusSeconds) / 60.0).rounded(.down))
            deepSessionCompletion = MoriDeepSessionCompletion(
                quietMinutes: quietMinutes,
                completedPlannedSession: false
            )
            completionCoordinator.cancelSessionAppLimit()
        } else {
            deepSessionCompletion = nil
            resetPomodoroClock()
        }
    }

    private var blockedAppsSummary: MoriScreenTimeProfileSummary {
        appLimitManager.settingsSnapshot.profileSummary(for: .pomodoroFocus)
    }

    private var blockedAppsText: String {
        blockedAppsSummary.selectionStatusText
    }

    private var blockedAppsCount: Int {
        blockedAppsSummary.effectiveSelectedCount
    }

    private func continueAfterDeepSession() {
        deepSessionCompletion = nil
        resetPomodoroClock()
        dismiss()
    }

    private func startPomodoroAppLimitIfPossible() {
        completionCoordinator.startAppLimitIfPossible(
            phase: pomodoroPhase,
            remainingSeconds: pomodoroSecondsRemaining
        )
    }

    private func playPomodoroCompletionFeedback() {
        guard scenePhase == .active else { return }
        feedbackCoordinator.playCompletionFeedback(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
    }

    private func requestClose() {
        if pomodoroState == .running || pomodoroState == .paused {
            showLeaveDialog = true
        } else {
            dismiss()
        }
    }

    private func startPomodoroBreakBreathingGuidance(resetElapsed: Bool = false) {
        guard scenePhase == .active else { return }
        pomodoroBreathingRuntime.start(
            context: pomodoroPresentation.guidedBreathingContext,
            resetElapsed: resetElapsed,
            feedbackCoordinator: feedbackCoordinator
        )
    }

    private func syncPomodoroBreakBreathingState() {
        guard scenePhase == .active else { return }
        pomodoroBreathingRuntime.sync(
            context: pomodoroPresentation.guidedBreathingContext,
            feedbackCoordinator: feedbackCoordinator
        )
    }

    private func syncPomodoroBreakBreathingElapsedToClock() {
        guard pomodoroPhase == .focus || pomodoroPhase.isBreak else { return }
        pomodoroBreathingRuntime.syncElapsedToClock(
            phaseElapsedSeconds: pomodoroPresentation.phaseElapsedSeconds
        )
    }

    private func resetPomodoroBreakBreathingGuidance(stopAudio: Bool, resetElapsed: Bool = true) {
        pomodoroBreathingRuntime.reset(
            stopAudio: stopAudio,
            resetElapsed: resetElapsed,
            feedbackCoordinator: feedbackCoordinator
        )
    }

    private func schedulePomodoroBreakHapticsForCurrentPhase() {
        pomodoroBreathingRuntime.scheduleHaptics(
            context: pomodoroPresentation.guidedBreathingContext,
            feedbackCoordinator: feedbackCoordinator
        )
    }

    private func playPomodoroBreakSoundFeedback() {
        pomodoroBreathingRuntime.playCurrentSound(
            context: pomodoroPresentation.guidedBreathingContext,
            feedbackCoordinator: feedbackCoordinator
        )
    }

    private func schedulePomodoroBreakSoundForNextPhase() {
        pomodoroBreathingRuntime.scheduleSoundForNextPhase(
            context: pomodoroPresentation.guidedBreathingContext,
            feedbackCoordinator: feedbackCoordinator
        )
    }

    private func cancelPomodoroBreakBreathingHaptics() {
        pomodoroBreathingRuntime.cancelHaptics(feedbackCoordinator: feedbackCoordinator)
    }

    private func cancelPomodoroBreakBreathingSound() {
        pomodoroBreathingRuntime.cancelSound(feedbackCoordinator: feedbackCoordinator)
    }

    private func normalizePomodoroFocusBreathingSelection() {
        let migrated = MoriPomodoroBreakBreathing(rawValue: pomodoroFocusBreathingRaw).rawValue
        if migrated != pomodoroFocusBreathingRaw {
            pomodoroFocusBreathingRaw = migrated
        }
    }

    private func normalizePomodoroBreakBreathingSelection() {
        let migrated = MoriPomodoroBreakBreathing(rawValue: pomodoroBreakBreathingRaw).rawValue
        if migrated != pomodoroBreakBreathingRaw {
            pomodoroBreakBreathingRaw = migrated
        }
    }

    private func revealDarkRoomControls() {
        darkRoomCoordinator.revealControls(isDarkRoomEnabled: darkRoomEnabled, isSessionActive: pomodoroState.isActive)
    }

    private func hideDarkRoomControls() {
        darkRoomCoordinator.hideControls()
    }

    private func enterDarkRoomOffScreen() {
        darkRoomCoordinator.enterOffScreen(keepScreenOn: keepScreenOn, isRunning: pomodoroState == .running)
        applyScreenPolicy()
    }

    private func exitDarkRoomOffScreen() {
        darkRoomCoordinator.exitOffScreen(keepScreenOn: keepScreenOn, isRunning: pomodoroState == .running)
    }

    private func clearDarkRoomTransientState() {
        darkRoomCoordinator.clearTransientState(keepScreenOn: keepScreenOn, isRunning: pomodoroState == .running)
    }
}
