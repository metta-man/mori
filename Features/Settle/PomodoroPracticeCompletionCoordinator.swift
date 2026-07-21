import SwiftUI

@MainActor
final class PomodoroPracticeCompletionCoordinator {
    private let clarityStore: MoriClarityStore
    private let appLimitManager: AppLimitManager
    private var appLimitFocusWasActive = false

    init() {
        self.clarityStore = MoriClarityStore.shared
        self.appLimitManager = AppLimitManager.shared
    }

    init(clarityStore: MoriClarityStore, appLimitManager: AppLimitManager) {
        self.clarityStore = clarityStore
        self.appLimitManager = appLimitManager
    }

    func startAppLimitIfPossible(phase: MoriPomodoroPhase, remainingSeconds: Int) {
        guard phase == .focus else { return }

        if appLimitManager.perform(
            .startTimedAppLimit(
                feature: .pomodoroFocus,
                remainingSeconds: remainingSeconds
            )
        ) {
            appLimitFocusWasActive = true
        }
    }

    func endAppLimit() {
        appLimitManager.perform(.endAppLimit(feature: .pomodoroFocus))
    }

    func cancelSessionAppLimit() {
        appLimitFocusWasActive = false
        appLimitManager.perform(.endAppLimit(feature: .pomodoroFocus))
    }

    func recordCompletion(
        focusSecondsCompleted: Int,
        breakSecondsCompleted: Int,
        completedCycles: Int
    ) -> MindfulCompletionSummary? {
        guard focusSecondsCompleted > 0 else {
            appLimitFocusWasActive = false
            return nil
        }

        let actualMinutes = max(1, Int((Double(focusSecondsCompleted + breakSecondsCompleted) / 60.0).rounded(.up)))
        let focusMinutes = Int((Double(focusSecondsCompleted) / 60.0).rounded(.down))
        let seeds = min(12, max(2, focusMinutes / 10 + completedCycles))
        let action = clarityStore.record(
            kind: .pomodoroSession,
            title: "Deep Session",
            seeds: seeds,
            minutes: actualMinutes,
            note: "Protected a quiet focus session"
        )

        if appLimitFocusWasActive {
            clarityStore.record(
                kind: .screenTimeLimitKept,
                title: "App-Limited Deep Session",
                seeds: 1,
                minutes: focusMinutes,
                note: "Kept selected apps limited during a Deep Session"
            )
        }

        appLimitFocusWasActive = false
        return MindfulCompletionSummary(
            title: "One quiet session protected",
            seeds: action.seeds,
            minutes: actualMinutes,
            icon: .timer,
            tint: MoriColors.botanicalClay
        )
    }
}
