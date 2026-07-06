import Foundation

struct SettleTimerCompletionResult {
    let session: SettleSession
    let seeds: Int
}

@MainActor
final class SettleTimerCompletionCoordinator {
    private let clarityStore: MoriClarityStore
    private let settleStore: SettleSessionStore
    private let appLimitManager: AppLimitManager
    private var settleAppLimitWasActive = false

    init() {
        self.clarityStore = MoriClarityStore.shared
        self.settleStore = SettleSessionStore.shared
        self.appLimitManager = AppLimitManager.shared
    }

    init(
        clarityStore: MoriClarityStore,
        settleStore: SettleSessionStore,
        appLimitManager: AppLimitManager
    ) {
        self.clarityStore = clarityStore
        self.settleStore = settleStore
        self.appLimitManager = appLimitManager
    }

    func startAppLimitIfPossible(secondsRemaining: Int) {
        settleAppLimitWasActive = false
        settleAppLimitWasActive = appLimitManager.perform(
            .startTimedAppLimit(
                feature: .settle,
                remainingSeconds: secondsRemaining
            )
        )
    }

    @discardableResult
    func recordEndedEarly(
        startedAt: Date?,
        selectedMinutes: Int,
        secondsRemaining: Int,
        intervalBellMinutes: Int?
    ) -> SettleSession? {
        let totalSeconds = selectedMinutes * 60
        let actualSeconds = max(0, totalSeconds - secondsRemaining)

        guard actualSeconds > 0, let startedAt else { return nil }

        return settleStore.recordSession(
            startedAt: startedAt,
            plannedMinutes: selectedMinutes,
            actualSeconds: actualSeconds,
            completed: false,
            intervalBellMinutes: intervalBellMinutes
        )
    }

    func recordCompletion(
        startedAt: Date,
        selectedMinutes: Int,
        intervalBellMinutes: Int?
    ) -> SettleTimerCompletionResult {
        let totalSeconds = selectedMinutes * 60
        let session = settleStore.recordSession(
            startedAt: startedAt,
            plannedMinutes: selectedMinutes,
            actualSeconds: totalSeconds,
            completed: true,
            intervalBellMinutes: intervalBellMinutes
        )

        let action = clarityStore.record(
            kind: .settleSession,
            title: session.title,
            seeds: session.seedsEarned,
            minutes: session.actualMinutes,
            note: "Completed a Settle practice"
        )

        if settleAppLimitWasActive {
            clarityStore.record(
                kind: .screenTimeLimitKept,
                title: "App-Limited Settle",
                seeds: 1,
                minutes: session.actualMinutes,
                note: "Kept selected apps limited during Settle"
            )
        }

        settleAppLimitWasActive = false
        appLimitManager.perform(.endAppLimit(feature: .settle))

        return SettleTimerCompletionResult(session: session, seeds: action.seeds)
    }

    func endAppLimit() {
        settleAppLimitWasActive = false
        appLimitManager.perform(.endAppLimit(feature: .settle))
    }
}
