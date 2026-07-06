import UIKit

final class SettleTimerFeedbackCoordinator {
    func playStartFeedback(soundEnabled: Bool, hapticsEnabled: Bool) {
        if soundEnabled {
            SettleBellService.shared.playStartBell()
        }
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func stopSessionSounds() {
        SettleBellService.shared.stop()
    }

    func playCompletionFeedback(soundEnabled: Bool, hapticsEnabled: Bool) {
        if soundEnabled {
            SettleBellService.shared.playEndingBell()
        }
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func playIntervalBellIfNeeded(
        soundEnabled: Bool,
        intervalBellMinutes: Int?,
        timerState: SettleTimerState,
        selectedMinutes: Int,
        secondsRemaining: Int,
        lastIntervalBellElapsed: Int
    ) -> Int {
        guard soundEnabled,
              let interval = intervalBellMinutes,
              timerState == .running
        else {
            return lastIntervalBellElapsed
        }

        let totalSeconds = selectedMinutes * 60
        let elapsed = totalSeconds - secondsRemaining
        let intervalSeconds = interval * 60

        guard elapsed > 0,
              secondsRemaining > 0,
              elapsed.isMultiple(of: intervalSeconds),
              elapsed != lastIntervalBellElapsed
        else {
            return lastIntervalBellElapsed
        }

        SettleBellService.shared.playIntervalBell()
        return elapsed
    }
}
