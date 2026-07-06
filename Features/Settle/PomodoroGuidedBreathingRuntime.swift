import Foundation

struct PomodoroGuidedBreathingRuntime {
    struct Context {
        let activeBreathing: MoriPomodoroBreakBreathing
        let isActive: Bool
        let phaseDurationSeconds: Int
        let phaseElapsedSeconds: Int
        let soundEnabled: Bool
        let hapticsEnabled: Bool
        let hapticStyle: MoriBreathingHapticStyle

        var segments: [MoriBreathingCycleSegment] {
            activeBreathing.segments
        }

        var canPlayHaptics: Bool {
            hapticsEnabled && isActive
        }

        var canPlaySound: Bool {
            soundEnabled && isActive
        }
    }

    private(set) var elapsed: TimeInterval = 0
    private(set) var currentPhaseIndex = 0

    func visualState(for activeBreathing: MoriPomodoroBreakBreathing) -> MoriBreathingCycleVisualState {
        activeBreathing.visualState(at: elapsed)
    }

    mutating func start(
        context: Context,
        resetElapsed: Bool = false,
        feedbackCoordinator: PomodoroPracticeFeedbackCoordinator
    ) {
        guard context.isActive, !context.segments.isEmpty else {
            reset(stopAudio: true, feedbackCoordinator: feedbackCoordinator)
            return
        }

        if resetElapsed {
            elapsed = 0
        } else {
            syncElapsedToClock(phaseElapsedSeconds: context.phaseElapsedSeconds)
        }

        currentPhaseIndex = MoriBreathingCycle.phaseIndex(
            for: context.segments,
            elapsedTime: elapsed
        )
        cancelHaptics(feedbackCoordinator: feedbackCoordinator)
        cancelSound(feedbackCoordinator: feedbackCoordinator)
        scheduleHaptics(context: context, feedbackCoordinator: feedbackCoordinator)
        if context.soundEnabled {
            playCurrentSound(context: context, feedbackCoordinator: feedbackCoordinator)
            scheduleSoundForNextPhase(context: context, feedbackCoordinator: feedbackCoordinator)
        }
    }

    mutating func sync(
        context: Context,
        feedbackCoordinator: PomodoroPracticeFeedbackCoordinator
    ) {
        guard context.isActive, !context.segments.isEmpty else {
            return
        }

        let previousPhaseIndex = currentPhaseIndex
        let phaseDuration = TimeInterval(max(0, context.phaseDurationSeconds))
        let clockElapsed = TimeInterval(context.phaseElapsedSeconds)
        elapsed = min(
            phaseDuration,
            max(clockElapsed, elapsed + 0.25)
        )
        currentPhaseIndex = MoriBreathingCycle.phaseIndex(
            for: context.segments,
            elapsedTime: elapsed
        )

        if currentPhaseIndex != previousPhaseIndex {
            cancelHaptics(feedbackCoordinator: feedbackCoordinator)
            scheduleHaptics(context: context, feedbackCoordinator: feedbackCoordinator)
            if context.soundEnabled {
                scheduleSoundForNextPhase(context: context, feedbackCoordinator: feedbackCoordinator)
            }
        }
    }

    mutating func syncElapsedToClock(phaseElapsedSeconds: Int) {
        elapsed = max(elapsed, TimeInterval(phaseElapsedSeconds))
    }

    mutating func reset(
        stopAudio: Bool,
        resetElapsed: Bool = true,
        feedbackCoordinator: PomodoroPracticeFeedbackCoordinator
    ) {
        currentPhaseIndex = 0
        if resetElapsed {
            elapsed = 0
        }
        cancelHaptics(feedbackCoordinator: feedbackCoordinator)
        cancelSound(feedbackCoordinator: feedbackCoordinator)
        if stopAudio {
            feedbackCoordinator.stopGuidedBreathingCues()
        }
    }

    func scheduleHaptics(
        context: Context,
        feedbackCoordinator: PomodoroPracticeFeedbackCoordinator
    ) {
        feedbackCoordinator.scheduleGuidedBreathingHaptics(
            segments: context.segments,
            currentPhaseIndex: currentPhaseIndex,
            hapticStyle: context.hapticStyle,
            canPlay: { context.canPlayHaptics }
        )
    }

    func playCurrentSound(
        context: Context,
        feedbackCoordinator: PomodoroPracticeFeedbackCoordinator
    ) {
        feedbackCoordinator.playCurrentGuidedBreathingCue(
            segments: context.segments,
            currentPhaseIndex: currentPhaseIndex,
            canPlay: { context.canPlaySound }
        )
    }

    func scheduleSoundForNextPhase(
        context: Context,
        feedbackCoordinator: PomodoroPracticeFeedbackCoordinator
    ) {
        let phaseRemaining = MoriBreathingCycle.phaseRemaining(
            for: context.segments,
            elapsedTime: elapsed
        )
        feedbackCoordinator.scheduleGuidedBreathingSoundForNextPhase(
            segments: context.segments,
            currentPhaseIndex: currentPhaseIndex,
            phaseRemaining: phaseRemaining,
            canPlay: { context.canPlaySound }
        )
    }

    func cancelHaptics(feedbackCoordinator: PomodoroPracticeFeedbackCoordinator) {
        feedbackCoordinator.cancelGuidedBreathingHaptics()
    }

    func cancelSound(feedbackCoordinator: PomodoroPracticeFeedbackCoordinator) {
        feedbackCoordinator.cancelGuidedBreathingSound()
    }
}
