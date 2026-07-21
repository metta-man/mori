import SwiftUI

struct PomodoroPracticePresentation {
    let activeBreathing: MoriPomodoroBreakBreathing
    let isGuidedBreathing: Bool
    let isBreathingActive: Bool
    let breathingVisualState: MoriBreathingCycleVisualState
    let guidedBreathingContext: PomodoroGuidedBreathingRuntime.Context
    let phaseElapsedSeconds: Int
    let timeText: String
    let sessionLabel: String
    let primaryCueText: String
    let secondaryCueText: String
    let progress: CGFloat

    private let soundEnabled: Bool
    private let focusBreathing: MoriPomodoroBreakBreathing
    private let breakBreathing: MoriPomodoroBreakBreathing
    private let phase: MoriPomodoroPhase

    init(
        timerState: SettleTimerState,
        phase: MoriPomodoroPhase,
        secondsRemaining: Int,
        completedCycles: Int,
        cycles: Int,
        focusMinutes: Int,
        shortBreakMinutes: Int,
        longBreakMinutes: Int,
        focusBreathing: MoriPomodoroBreakBreathing,
        breakBreathing: MoriPomodoroBreakBreathing,
        soundEnabled: Bool,
        hapticsEnabled: Bool,
        hapticStyleRaw: String,
        breathingRuntime: PomodoroGuidedBreathingRuntime
    ) {
        self.soundEnabled = soundEnabled
        self.focusBreathing = focusBreathing
        self.breakBreathing = breakBreathing
        self.phase = phase

        let activeBreathing = Self.activeBreathing(
            phase: phase,
            focusBreathing: focusBreathing,
            breakBreathing: breakBreathing
        )
        let phaseDurationSeconds = phase.durationSeconds(
            focusMinutes: focusMinutes,
            shortBreakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes
        )
        let phaseElapsedSeconds = max(0, phaseDurationSeconds - secondsRemaining)
        let isGuidedBreathing = Self.isGuidedBreathing(
            phase: phase,
            focusBreathing: focusBreathing,
            breakBreathing: breakBreathing
        )
        let isBreathingActive = timerState == .running && isGuidedBreathing
        let breathingVisualState = breathingRuntime.visualState(for: activeBreathing)
        self.activeBreathing = activeBreathing
        self.isGuidedBreathing = isGuidedBreathing
        self.isBreathingActive = isBreathingActive
        self.breathingVisualState = breathingVisualState
        self.phaseElapsedSeconds = phaseElapsedSeconds
        timeText = formatTime(secondsRemaining)
        sessionLabel = phase.isBreak ? "Quiet pause" : "Deep Session"
        primaryCueText = Self.primaryCueText(
            timerState: timerState,
            phase: phase,
            isGuidedBreathing: isGuidedBreathing,
            breathingVisualState: breathingVisualState
        )
        secondaryCueText = Self.secondaryCueText(
            activeBreathing: activeBreathing,
            isGuidedBreathing: isGuidedBreathing
        )
        progress = Self.progress(
            secondsRemaining: secondsRemaining,
            phaseDurationSeconds: phaseDurationSeconds
        )
        guidedBreathingContext = PomodoroGuidedBreathingRuntime.Context(
            activeBreathing: activeBreathing,
            isActive: isBreathingActive,
            phaseDurationSeconds: phaseDurationSeconds,
            phaseElapsedSeconds: phaseElapsedSeconds,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            hapticStyle: MoriBreathingHapticStyle(rawValue: hapticStyleRaw) ?? .minimalist
        )
    }

    var shouldPlayCurrentBell: Bool {
        shouldPlayBell(for: phase)
    }

    func shouldPlayBell(for phase: MoriPomodoroPhase) -> Bool {
        guard soundEnabled else { return false }

        switch phase {
        case .focus:
            return !focusBreathing.hasTechnique
        case .shortBreak, .longBreak:
            return !breakBreathing.hasTechnique
        case .completed:
            return !focusBreathing.hasTechnique && !breakBreathing.hasTechnique
        }
    }

    private static func activeBreathing(
        phase: MoriPomodoroPhase,
        focusBreathing: MoriPomodoroBreakBreathing,
        breakBreathing: MoriPomodoroBreakBreathing
    ) -> MoriPomodoroBreakBreathing {
        switch phase {
        case .focus:
            return focusBreathing
        case .shortBreak, .longBreak:
            return breakBreathing
        case .completed:
            return .none
        }
    }

    private static func isGuidedBreathing(
        phase: MoriPomodoroPhase,
        focusBreathing: MoriPomodoroBreakBreathing,
        breakBreathing: MoriPomodoroBreakBreathing
    ) -> Bool {
        (phase == .focus && focusBreathing.hasTechnique) ||
            (phase.isBreak && breakBreathing.hasTechnique)
    }

    private static func primaryCueText(
        timerState: SettleTimerState,
        phase: MoriPomodoroPhase,
        isGuidedBreathing: Bool,
        breathingVisualState: MoriBreathingCycleVisualState
    ) -> String {
        if timerState == .paused {
            return MoriL10n.display("Paused")
        }

        if isGuidedBreathing {
            return breathingVisualState.label
        }

        return phase.isBreak
            ? MoriL10n.display("Rest softly")
            : MoriL10n.display("Stay in the forest")
    }

    private static func secondaryCueText(
        activeBreathing: MoriPomodoroBreakBreathing,
        isGuidedBreathing: Bool
    ) -> String {
        guard isGuidedBreathing else {
            return MoriL10n.display("Nothing else needs your attention.")
        }

        return MoriL10n.string(
            "deep_session.breathing.cue",
            defaultValue: "%@ · %@",
            arguments: [
                MoriL10n.display(activeBreathing.title),
                activeBreathing.timingDescription
            ]
        )
    }

    private static func progress(
        secondsRemaining: Int,
        phaseDurationSeconds: Int
    ) -> CGFloat {
        let total = max(1, phaseDurationSeconds)
        return CGFloat(total - secondsRemaining) / CGFloat(total)
    }
}
