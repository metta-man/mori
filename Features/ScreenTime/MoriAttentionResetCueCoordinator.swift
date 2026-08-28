import UIKit

enum MoriAttentionResetCuePolicy {
    static func completionTone(for context: MoriAttentionResetContext) -> SettleBellTone {
        switch context {
        case .beforeFeed:
            return .defaultChime
        case .morningGate:
            return .singingBowlA
        }
    }
}

final class MoriAttentionResetCueCoordinator {
    private let breathingFeedback = MoriBreathingSessionFeedbackCoordinator()

    deinit {
        stopResetCues()
    }

    func playStartCues(soundEnabled: Bool, hapticsEnabled: Bool, hasBreathingTechnique: Bool) {
        guard !hasBreathingTechnique else { return }

        if soundEnabled {
            SettleBellService.shared.playStartBell()
        }
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    func playCompletionCues(
        context: MoriAttentionResetContext,
        soundEnabled: Bool,
        hapticsEnabled: Bool
    ) {
        breathingFeedback.playCompletionFeedback(
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled,
            tone: MoriAttentionResetCuePolicy.completionTone(for: context)
        )
    }

    func beginBreathingCueTiming(
        segments: [MoriBreathingCycleSegment],
        elapsedTime: TimeInterval,
        phaseRemaining: TimeInterval,
        sessionRemaining: TimeInterval,
        hapticsEnabled: Bool,
        canPlaySound: @escaping () -> Bool
    ) -> Int {
        guard !segments.isEmpty else { return 0 }

        let phaseIndex = MoriBreathingCycle.phaseIndex(for: segments, elapsedTime: elapsedTime)
        playCurrentBreathingSound(segments: segments, currentPhaseIndex: phaseIndex, canPlay: canPlaySound)
        playCurrentBreathingHaptic(segments: segments, currentPhaseIndex: phaseIndex, hapticsEnabled: hapticsEnabled)
        scheduleSoundForNextPhase(
            segments: segments,
            currentPhaseIndex: phaseIndex,
            phaseRemaining: phaseRemaining,
            sessionRemaining: sessionRemaining,
            canPlay: canPlaySound
        )
        return phaseIndex
    }

    func syncBreathingCueTiming(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        elapsedTime: TimeInterval,
        phaseRemaining: TimeInterval,
        sessionRemaining: TimeInterval,
        hapticsEnabled: Bool,
        canPlaySound: @escaping () -> Bool
    ) -> Int {
        guard !segments.isEmpty else { return currentPhaseIndex }

        let nextPhaseIndex = MoriBreathingCycle.phaseIndex(for: segments, elapsedTime: elapsedTime)
        guard nextPhaseIndex != currentPhaseIndex else { return currentPhaseIndex }

        playCurrentBreathingHaptic(segments: segments, currentPhaseIndex: nextPhaseIndex, hapticsEnabled: hapticsEnabled)
        scheduleSoundForNextPhase(
            segments: segments,
            currentPhaseIndex: nextPhaseIndex,
            phaseRemaining: phaseRemaining,
            sessionRemaining: sessionRemaining,
            canPlay: canPlaySound
        )
        return nextPhaseIndex
    }

    func playCurrentBreathingSound(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        canPlay: () -> Bool
    ) {
        breathingFeedback.playCurrentSoundCue(
            segments: segments,
            currentPhaseIndex: currentPhaseIndex,
            canPlay: canPlay
        )
    }

    func scheduleSoundForNextPhase(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        phaseRemaining: TimeInterval,
        sessionRemaining: TimeInterval,
        canPlay: @escaping () -> Bool
    ) {
        breathingFeedback.scheduleSoundForNextPhase(
            segments: segments,
            currentPhaseIndex: currentPhaseIndex,
            phaseRemaining: phaseRemaining,
            sessionRemaining: sessionRemaining,
            canPlay: canPlay
        )
    }

    func stopResetCues() {
        breathingFeedback.cancelSound()
        breathingFeedback.stopBreathingCues()
    }

    private func playCurrentBreathingHaptic(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        hapticsEnabled: Bool
    ) {
        guard hapticsEnabled, segments.indices.contains(currentPhaseIndex) else { return }
        playBreathingHaptic(for: segments[currentPhaseIndex].phase)
    }

    private func playBreathingHaptic(for phase: MoriBreathingCyclePhase) {
        switch phase {
        case .inhale:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .holdAfterInhale, .holdAfterExhale:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .exhale:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .idle:
            break
        }
    }
}
