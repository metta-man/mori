import UIKit

final class PomodoroPracticeFeedbackCoordinator {
    private let guidedBreathingFeedback = MoriBreathingSessionFeedbackCoordinator()

    deinit {
        cleanupGuidedBreathing(stopAudio: true)
    }

    func playStartBellIfNeeded(_ shouldPlay: Bool) {
        guard shouldPlay else { return }
        SettleBellService.shared.playStartBell()
    }

    func playTransitionFeedback(shouldPlayBell: Bool, hapticsEnabled: Bool) {
        if shouldPlayBell {
            SettleBellService.shared.playIntervalBell()
        }
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func playCompletionFeedback(soundEnabled: Bool, hapticsEnabled: Bool) {
        guidedBreathingFeedback.playCompletionFeedback(
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled
        )
    }

    func stopSessionSounds() {
        SettleBellService.shared.stop()
        SettleBellService.shared.stopBreathingCues()
    }

    func scheduleGuidedBreathingHaptics(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        hapticStyle: MoriBreathingHapticStyle,
        canPlay: @escaping () -> Bool
    ) {
        guidedBreathingFeedback.scheduleHapticsForCurrentPhase(
            segments: segments,
            currentPhaseIndex: currentPhaseIndex,
            hapticStyle: hapticStyle,
            canPlay: canPlay
        )
    }

    func playCurrentGuidedBreathingCue(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        canPlay: () -> Bool
    ) {
        guidedBreathingFeedback.playCurrentSoundCue(
            segments: segments,
            currentPhaseIndex: currentPhaseIndex,
            canPlay: canPlay
        )
    }

    func scheduleGuidedBreathingSoundForNextPhase(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        phaseRemaining: TimeInterval,
        canPlay: @escaping () -> Bool
    ) {
        guidedBreathingFeedback.scheduleSoundForNextPhase(
            segments: segments,
            currentPhaseIndex: currentPhaseIndex,
            phaseRemaining: phaseRemaining,
            canPlay: canPlay
        )
    }

    func cancelGuidedBreathingHaptics() {
        guidedBreathingFeedback.cancelHaptics()
    }

    func cancelGuidedBreathingSound() {
        guidedBreathingFeedback.cancelSound()
    }

    func stopGuidedBreathingCues() {
        guidedBreathingFeedback.stopBreathingCues()
    }

    func cleanupGuidedBreathing(stopAudio: Bool) {
        guidedBreathingFeedback.cleanup(stopAudio: stopAudio)
    }
}
