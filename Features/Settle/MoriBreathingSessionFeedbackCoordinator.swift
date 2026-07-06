import UIKit

final class MoriBreathingSessionFeedbackCoordinator {
    private enum TapStyle {
        case light
        case medium
    }

    private var scheduledHapticTimers: [Timer] = []
    private var scheduledSoundTimer: Timer?
    private var scheduledFadeTimer: Timer?

    deinit {
        cleanup(stopAudio: true)
    }

    func scheduleHapticsForCurrentPhase(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        hapticStyle: MoriBreathingHapticStyle,
        canPlay: @escaping () -> Bool
    ) {
        guard canPlay(), segments.indices.contains(currentPhaseIndex) else { return }
        let segment = segments[currentPhaseIndex]

        switch hapticStyle {
        case .symmetry:
            scheduleSymmetryHaptics(for: segment, canPlay: canPlay)
        case .minimalist:
            scheduleMinimalistHaptics(for: segment, canPlay: canPlay)
        }
    }

    func playCurrentSoundCue(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        canPlay: () -> Bool
    ) {
        guard canPlay(), segments.indices.contains(currentPhaseIndex), let cue = segments[currentPhaseIndex].phase.cue else { return }
        SettleBellService.shared.playBreathingCue(cue)
    }

    func scheduleSoundForNextPhase(
        segments: [MoriBreathingCycleSegment],
        currentPhaseIndex: Int,
        phaseRemaining: TimeInterval,
        canPlay: @escaping () -> Bool
    ) {
        guard canPlay(), !segments.isEmpty, segments.indices.contains(currentPhaseIndex) else { return }
        cancelSound()

        let nextPhaseIndex = (currentPhaseIndex + 1) % segments.count
        guard segments.indices.contains(nextPhaseIndex), let nextCue = segments[nextPhaseIndex].phase.cue else { return }

        let currentCue = segments[currentPhaseIndex].phase.cue
        let leadTime = nextCue.phaseLeadTime
        let fadeDuration = SettleBreathingCue.fadeDuration
        let fadeDelay = max(0, phaseRemaining - leadTime - fadeDuration)
        let soundDelay = max(0, phaseRemaining - leadTime)

        if let currentCue, currentCue.fadesBeforeNextCue {
            scheduledFadeTimer = Timer.scheduledTimer(withTimeInterval: fadeDelay, repeats: false) { _ in
                guard canPlay() else { return }
                SettleBellService.shared.fadeOutBreathingCue(currentCue)
            }
            if let scheduledFadeTimer {
                RunLoop.current.add(scheduledFadeTimer, forMode: .common)
            }
        }

        scheduledSoundTimer = Timer.scheduledTimer(withTimeInterval: soundDelay, repeats: false) { _ in
            guard canPlay() else { return }
            SettleBellService.shared.playBreathingCue(nextCue)
        }
        if let scheduledSoundTimer {
            RunLoop.current.add(scheduledSoundTimer, forMode: .common)
        }
    }

    func playCompletionFeedback(soundEnabled: Bool, hapticsEnabled: Bool) {
        if soundEnabled {
            SettleBellService.shared.playEndingBell()
        }
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func cancelHaptics() {
        scheduledHapticTimers.forEach { $0.invalidate() }
        scheduledHapticTimers.removeAll()
    }

    func cancelSound() {
        scheduledSoundTimer?.invalidate()
        scheduledFadeTimer?.invalidate()
        scheduledSoundTimer = nil
        scheduledFadeTimer = nil
    }

    func stopBreathingCues() {
        SettleBellService.shared.stopBreathingCues()
    }

    func cleanup(stopAudio: Bool) {
        cancelHaptics()
        cancelSound()
        if stopAudio {
            stopBreathingCues()
        }
    }

    private func scheduleMinimalistHaptics(for segment: MoriBreathingCycleSegment, canPlay: @escaping () -> Bool) {
        switch segment.phase {
        case .inhale:
            scheduleHapticTap(after: 0, style: .medium, canPlay: canPlay)
        case .exhale:
            scheduleHapticTap(after: 0, style: .light, canPlay: canPlay)
        case .holdAfterInhale, .holdAfterExhale:
            scheduleHapticTap(after: 0, style: .medium, canPlay: canPlay)
            scheduleHapticTap(after: 0.2, style: .medium, canPlay: canPlay)
        case .idle:
            break
        }
    }

    private func scheduleSymmetryHaptics(for segment: MoriBreathingCycleSegment, canPlay: @escaping () -> Bool) {
        switch segment.phase {
        case .inhale:
            scheduleSymmetryInhale(duration: segment.duration, canPlay: canPlay)
            scheduleHapticTap(after: max(0, segment.duration - 0.01), style: .medium, canPlay: canPlay)
        case .holdAfterInhale, .holdAfterExhale:
            scheduleHapticTap(after: 0, style: .medium, canPlay: canPlay)
            scheduleHapticTap(after: 0.15, style: .medium, canPlay: canPlay)
            scheduleHoldPreCueTapTap(duration: segment.duration, canPlay: canPlay)
        case .exhale, .idle:
            break
        }
    }

    private func scheduleSymmetryInhale(duration: Double, canPlay: @escaping () -> Bool) {
        guard duration > 0 else { return }
        let startInterval = 0.8
        let endInterval = 0.15
        var currentTime = 0.0

        while currentTime < duration {
            scheduleHapticTap(after: currentTime, style: .light, canPlay: canPlay)
            let progress = currentTime / duration
            let ratio = endInterval / startInterval
            currentTime += startInterval * pow(ratio, progress)
        }
    }

    private func scheduleHoldPreCueTapTap(duration: Double, canPlay: @escaping () -> Bool) {
        guard duration > 0 else { return }
        let firstLead = min(0.35, max(0, duration / 3))
        let secondLead = min(0.15, max(0, duration / 6))
        let times = Array(Set([max(0, duration - firstLead), max(0, duration - secondLead)])).sorted()
        for time in times where time > 0 {
            scheduleHapticTap(after: time, style: .light, canPlay: canPlay)
        }
    }

    private func scheduleHapticTap(after delay: Double, style: TapStyle, canPlay: @escaping () -> Bool) {
        guard canPlay() else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: max(0, delay), repeats: false) { _ in
            guard canPlay() else { return }
            let generator: UIImpactFeedbackGenerator
            switch style {
            case .light:
                generator = UIImpactFeedbackGenerator(style: .light)
            case .medium:
                generator = UIImpactFeedbackGenerator(style: .medium)
            }
            generator.impactOccurred()
        }
        scheduledHapticTimers.append(timer)
        RunLoop.current.add(timer, forMode: .common)
    }
}
