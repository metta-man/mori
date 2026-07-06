import SwiftUI

private enum MoriBreathingSessionSheet: Identifiable {
    case settings

    var id: String {
        switch self {
        case .settings:
            return "settings"
        }
    }
}

struct MoriBreathingSessionView: View {
    let techniqueID: String
    let autoStart: Bool

    @Environment(\.dismiss) private var dismiss

    @AppStorage("mori_settle_breathing_sound_enabled") private var soundEnabled: Bool = true
    @AppStorage("mori_settle_breathing_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("mori_settle_breathing_animation_enabled") private var animationEnabled: Bool = true
    @AppStorage("mori_timer_dark_room_enabled") private var darkRoomEnabled: Bool = false
    @AppStorage("mori_timer_dark_room_dim") private var darkRoomDim: Double = 0.92
    @AppStorage("mori_settle_breathing_keep_screen_on") private var keepScreenOn: Bool = true
    @AppStorage("mori_settle_breathing_haptic_style") private var hapticStyleRaw: String = MoriBreathingHapticStyle.minimalist.rawValue
    @AppStorage("mori_settle_breathing_custom_inhale") private var customInhaleSeconds: Double = 4
    @AppStorage("mori_settle_breathing_custom_hold") private var customHoldSeconds: Double = 0
    @AppStorage("mori_settle_breathing_custom_exhale") private var customExhaleSeconds: Double = 6
    @AppStorage("mori_settle_breathing_custom_uses_hold") private var customUsesHold: Bool = false

    @StateObject private var sessionClock: MoriBreathingSessionClock
    @State private var completedSummary: MoriBreathingCompletionSummary?
    @State private var completionCoordinator = MoriBreathingSessionCompletionCoordinator()
    @State private var feedbackCoordinator = MoriBreathingSessionFeedbackCoordinator()
    @StateObject private var darkRoomCoordinator = SettleDarkRoomCoordinator()
    @State private var showLeaveDialog = false
    @State private var activeSheet: MoriBreathingSessionSheet?
    @State private var hasAutoStarted = false

    init(techniqueID: String, durationMinutes: Int, autoStart: Bool = false) {
        self.techniqueID = techniqueID
        self.autoStart = autoStart
        _sessionClock = StateObject(wrappedValue: MoriBreathingSessionClock(durationMinutes: durationMinutes))
    }

    private var technique: MoriBreathingTechnique {
        MoriBreathingTechniqueRepository.getTechnique(id: techniqueID)
            ?? MoriBreathingTechniqueRepository.getTechnique(id: MoriBreathingTechniqueID.custom.rawValue)
            ?? MoriBreathingTechniqueRepository.techniques[0]
    }

    private var hapticStyle: MoriBreathingHapticStyle {
        MoriBreathingHapticStyle(rawValue: hapticStyleRaw) ?? .minimalist
    }

    private var sessionDuration: TimeInterval {
        sessionClock.sessionDuration
    }

    private var durationMinutes: Int {
        sessionClock.durationMinutes
    }

    private var runState: MoriBreathingRunState {
        sessionClock.runState
    }

    private var activeElapsed: TimeInterval {
        sessionClock.activeElapsed
    }

    private var currentPhaseIndex: Int {
        sessionClock.currentPhaseIndex
    }

    private var completedBreathCount: Int {
        sessionClock.completedBreathCount
    }

    private var currentPattern: MoriBreathPattern {
        if technique.id == MoriBreathingTechniqueID.custom.rawValue {
            return MoriBreathPattern(
                inhale: max(1, customInhaleSeconds),
                inhaleHold: customUsesHold && customHoldSeconds > 0 ? max(1, customHoldSeconds) : nil,
                exhale: max(1, customExhaleSeconds),
                exhaleHold: nil
            )
        }

        return technique.breathPattern
    }

    private var segments: [MoriBreathingCycleSegment] {
        currentPattern.segments
    }

    private var visualState: MoriBreathingCycleVisualState {
        MoriBreathingCycle.visualState(for: segments, elapsedTime: activeElapsed)
    }

    private var secondsRemaining: Int {
        sessionClock.secondsRemaining
    }

    private var phaseRemaining: TimeInterval {
        sessionClock.phaseRemaining(for: segments)
    }

    private var progress: CGFloat {
        sessionClock.progress
    }

    var body: some View {
        Group {
            if runState.isActive {
                activeSessionSurface
            } else {
                setupSessionSurface
            }
        }
        .navigationTitle("Reset")
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
                        opacity: darkRoomEnabled && runState.isActive ? 0.72 : 0.88
                    )
                    .rotationEffect(.degrees(180))
                }
                .accessibilityLabel("Back")
            }
            if !runState.isActive {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activeSheet = .settings
                    } label: {
                        MoriBitmapIconImage(icon: .settings, size: 18, opacity: 0.88)
                    }
                    .accessibilityLabel("Breathing settings")
                }
            }
        }
        .toolbarBackground(darkRoomEnabled && runState.isActive ? .black : MoriColors.botanicalPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(darkRoomEnabled && runState.isActive ? .dark : .light, for: .navigationBar)
        .toolbar(darkRoomChromeHidden ? .hidden : .visible, for: .navigationBar)
        .moriHidesMainTabBar()
        .moriBreathingSessionLifecycle(
            autoStart: autoStart,
            hasAutoStarted: $hasAutoStarted,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            keepScreenOn: keepScreenOn,
            darkRoomEnabled: darkRoomEnabled,
            showLeaveDialog: $showLeaveDialog,
            onPrepare: prepareBreathingSession,
            onAutoStart: startBreathing,
            onCleanup: cleanupBreathingSession,
            onTick: syncBreathingState,
            onSoundEnabledChange: handleSoundEnabledChange,
            onHapticsEnabledChange: handleHapticsEnabledChange,
            onKeepScreenOnChange: { applyIdleTimerPolicy() },
            onDarkRoomEnabledChange: handleDarkRoomEnabledChange,
            onEndAndLeave: endAndDismiss
        )
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                settingsSheet
            }
        }
    }

    private var setupSessionSurface: some View {
        MoriBreathingSessionSetupSurface(
            technique: technique,
            currentPattern: currentPattern,
            segments: segments,
            visualState: visualState,
            timeText: formatTime(secondsRemaining),
            progress: progress,
            durationMinutes: durationMinutes,
            currentPhaseIndex: currentPhaseIndex,
            completedBreathCount: completedBreathCount,
            completedSummary: completedSummary,
            runState: runState,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            hapticStyle: hapticStyle,
            keepScreenOn: keepScreenOn,
            onToggleSound: { soundEnabled.toggle() },
            onToggleHaptics: { hapticsEnabled.toggle() },
            onStart: startBreathing,
            onPause: pauseBreathing,
            onResume: resumeBreathing,
            onEnd: endWithoutRecording
        )
    }

    private var activeSessionSurface: some View {
        MoriBreathingSessionActiveSurface(
            technique: technique,
            visualState: visualState,
            timeText: formatTime(secondsRemaining),
            progress: progress,
            runState: runState,
            animationEnabled: animationEnabled,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            darkRoomEnabled: darkRoomEnabled,
            darkRoomDim: $darkRoomDim,
            darkRoomOffScreen: darkRoomCoordinator.offScreen,
            darkRoomControlsVisible: darkRoomCoordinator.controlsVisible,
            onToggleSound: { soundEnabled.toggle() },
            onToggleHaptics: { hapticsEnabled.toggle() },
            onToggleAnimation: { animationEnabled.toggle() },
            onToggleDarkRoom: { darkRoomEnabled.toggle() },
            onRevealDarkRoomControls: revealDarkRoomControls,
            onExitDarkRoomOffScreen: exitDarkRoomOffScreen,
            onEnterDarkRoomOffScreen: enterDarkRoomOffScreen,
            onStart: startBreathing,
            onPause: pauseBreathing,
            onResume: resumeBreathing,
            onEnd: endWithoutRecording
        )
    }

    private var darkRoomChromeHidden: Bool {
        darkRoomEnabled && runState.isActive
    }

    private var settingsSheet: some View {
        MoriBreathingSessionSettingsSheet(
            durationMinutes: Binding(
                get: { sessionClock.durationMinutes },
                set: { sessionClock.durationMinutes = $0 }
            ),
            soundEnabled: $soundEnabled,
            hapticsEnabled: $hapticsEnabled,
            keepScreenOn: $keepScreenOn,
            hapticStyleRaw: $hapticStyleRaw,
            customInhaleSeconds: $customInhaleSeconds,
            customHoldSeconds: $customHoldSeconds,
            customExhaleSeconds: $customExhaleSeconds,
            customUsesHold: $customUsesHold,
            isRunning: runState.isActive
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func prepareBreathingSession() {
        applyIdleTimerPolicy()
    }

    private func cleanupBreathingSession() {
        clearDarkRoomTransientState()
        cleanupSessionSideEffects(stopAudio: true)
        completionCoordinator.endAppLimit()
        darkRoomCoordinator.resetIdleTimer()
    }

    private func handleSoundEnabledChange(_ enabled: Bool) {
        if enabled, runState == .running {
            playSoundFeedback()
            scheduleSoundForNextPhase()
        } else {
            feedbackCoordinator.cancelSound()
            feedbackCoordinator.stopBreathingCues()
        }
    }

    private func handleHapticsEnabledChange(_ enabled: Bool) {
        feedbackCoordinator.cancelHaptics()
        if enabled, runState == .running {
            scheduleHapticsForCurrentPhase()
        }
    }

    private func handleDarkRoomEnabledChange(_ enabled: Bool) {
        if enabled {
            hideDarkRoomControls()
        } else {
            clearDarkRoomTransientState()
        }
    }

    private func endAndDismiss() {
        endWithoutRecording()
        dismiss()
    }

    private func startBreathing() {
        activeSheet = nil
        sessionClock.start()
        completedSummary = nil
        completionCoordinator.startAppLimitIfPossible(sessionDuration: sessionDuration)
        applyIdleTimerPolicy()
        scheduleHapticsForCurrentPhase()
        if soundEnabled {
            playSoundFeedback()
            scheduleSoundForNextPhase()
        }
    }

    private func pauseBreathing() {
        guard runState == .running else { return }
        syncBreathingState()
        guard sessionClock.pause() else { return }
        cleanupSessionSideEffects(stopAudio: true)
        applyIdleTimerPolicy()
    }

    private func resumeBreathing() {
        guard sessionClock.resume() else { return }
        applyIdleTimerPolicy()
        scheduleHapticsForCurrentPhase()
        if soundEnabled {
            playSoundFeedback()
            scheduleSoundForNextPhase()
        }
    }

    private func syncBreathingState(now: Date = Date()) {
        switch sessionClock.sync(now: now, segments: segments) {
        case .completed:
            completeBreathing()
        case .phaseChanged:
            feedbackCoordinator.cancelHaptics()
            scheduleHapticsForCurrentPhase()
            if soundEnabled {
                scheduleSoundForNextPhase()
            }
        case .inactive, .unchanged:
            break
        }
    }

    private func completeBreathing() {
        guard runState == .running else { return }
        sessionClock.complete()
        clearDarkRoomTransientState()
        cleanupSessionSideEffects(stopAudio: true)
        darkRoomCoordinator.resetIdleTimer()

        completedSummary = completionCoordinator.recordCompletion(
            techniqueName: technique.name,
            durationMinutes: durationMinutes
        )

        feedbackCoordinator.playCompletionFeedback(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        completionCoordinator.endAppLimit()
    }

    private func endWithoutRecording() {
        sessionClock.reset()
        completedSummary = nil
        clearDarkRoomTransientState()
        cleanupSessionSideEffects(stopAudio: true)
        completionCoordinator.endAppLimit()
        darkRoomCoordinator.resetIdleTimer()
    }

    private func requestClose() {
        if runState.isActive {
            showLeaveDialog = true
        } else {
            dismiss()
        }
    }

    private func scheduleHapticsForCurrentPhase() {
        feedbackCoordinator.scheduleHapticsForCurrentPhase(
            segments: segments,
            currentPhaseIndex: currentPhaseIndex,
            hapticStyle: hapticStyle,
            canPlay: { hapticsEnabled && runState == .running }
        )
    }

    private func playSoundFeedback() {
        feedbackCoordinator.playCurrentSoundCue(
            segments: segments,
            currentPhaseIndex: currentPhaseIndex,
            canPlay: { soundEnabled && runState == .running }
        )
    }

    private func scheduleSoundForNextPhase() {
        feedbackCoordinator.scheduleSoundForNextPhase(
            segments: segments,
            currentPhaseIndex: currentPhaseIndex,
            phaseRemaining: phaseRemaining,
            canPlay: { soundEnabled && runState == .running }
        )
    }

    private func cleanupSessionSideEffects(stopAudio: Bool) {
        feedbackCoordinator.cleanup(stopAudio: stopAudio)
    }

    private func applyIdleTimerPolicy(offScreenOverride: Bool? = nil) {
        darkRoomCoordinator.applyIdleTimerPolicy(
            keepScreenOn: keepScreenOn,
            isRunning: runState == .running,
            offScreenOverride: offScreenOverride
        )
    }

    private func revealDarkRoomControls() {
        darkRoomCoordinator.revealControls(isDarkRoomEnabled: darkRoomEnabled, isSessionActive: runState.isActive)
    }

    private func hideDarkRoomControls() {
        darkRoomCoordinator.hideControls()
    }

    private func enterDarkRoomOffScreen() {
        darkRoomCoordinator.enterOffScreen(keepScreenOn: keepScreenOn, isRunning: runState == .running)
    }

    private func exitDarkRoomOffScreen() {
        darkRoomCoordinator.exitOffScreen(keepScreenOn: keepScreenOn, isRunning: runState == .running)
    }

    private func clearDarkRoomTransientState() {
        darkRoomCoordinator.clearTransientState(keepScreenOn: keepScreenOn, isRunning: runState == .running)
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let seconds = max(0, seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
