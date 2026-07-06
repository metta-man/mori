import SwiftUI

@MainActor
final class MoriBreathingSessionCompletionCoordinator {
    private let clarityStore: MoriClarityStore
    private let appLimitManager: AppLimitManager
    private var breathingAppLimitWasActive = false

    init() {
        self.clarityStore = MoriClarityStore.shared
        self.appLimitManager = AppLimitManager.shared
    }

    init(clarityStore: MoriClarityStore, appLimitManager: AppLimitManager) {
        self.clarityStore = clarityStore
        self.appLimitManager = appLimitManager
    }

    func startAppLimitIfPossible(sessionDuration: TimeInterval) {
        breathingAppLimitWasActive = false
        breathingAppLimitWasActive = appLimitManager.perform(
            .startTimedAppLimit(
                feature: .breathing,
                duration: sessionDuration
            )
        )
    }

    func recordCompletion(techniqueName: String, durationMinutes: Int) -> MoriBreathingCompletionSummary {
        let seeds = max(1, durationMinutes / 2)
        let action = clarityStore.record(
            kind: .breathingSession,
            title: techniqueName,
            seeds: seeds,
            minutes: durationMinutes,
            note: "Completed \(techniqueName)"
        )

        if breathingAppLimitWasActive {
            clarityStore.record(
                kind: .screenTimeLimitKept,
                title: "App-Limited Breathing",
                seeds: 1,
                minutes: durationMinutes,
                note: "Kept selected apps limited during Breathing"
            )
        }

        breathingAppLimitWasActive = false
        return MoriBreathingCompletionSummary(
            title: "Breath settled",
            seeds: action.seeds,
            minutes: durationMinutes,
            icon: .breathe,
            tint: MoriColors.botanicalMist
        )
    }

    func endAppLimit() {
        breathingAppLimitWasActive = false
        appLimitManager.perform(.endAppLimit(feature: .breathing))
    }
}
