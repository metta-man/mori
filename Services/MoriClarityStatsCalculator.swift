import Foundation

@MainActor
enum MoriClarityStatsCalculator {
    static func metrics(
        settings: UserSettings,
        actions allActions: [MoriMindfulAction],
        latestPulse: MoriDailyPulse?
    ) -> MoriClarityMetrics {
        let todayActions = actionsOn(Date(), in: allActions)
        let actionSeeds = todayActions.reduce(0) { $0 + $1.seeds }
        let quietMinutes = todayActions
            .filter {
                $0.kind == .quietTimer ||
                    $0.kind == .replacementAction ||
                    $0.kind == .urgeCheckIn ||
                    $0.kind == .breathingSession ||
                    $0.kind == .pomodoroSession
            }
            .reduce(0) { $0 + $1.minutes }
        let settleActions = todayActions.filter {
            $0.kind == .settleSession ||
                $0.kind == .breathingSession ||
                $0.kind == .pomodoroSession
        }
        let settleMinutes = settleActions.reduce(0) { $0 + $1.minutes }
        let screenTimeAttempts = MoriScreenTimeAttemptStore.attempts().count
        let screenTimeSavedMinutes = MoriScreenTimeAttemptStore.savedMinutes()
        let pulse = latestPulse?.dateKey == MoriDateKey.value() ? latestPulse : nil
        let pulseMinutes = pulse?.reclaimedMinutes ?? 0
        let screenTimeSavedMinutesAlreadyInPulse = pulse?.screenTimeSavedMinutesAtGeneration ?? 0
        let screenTimeSavedMinutesAfterPulse = max(0, screenTimeSavedMinutes - screenTimeSavedMinutesAlreadyInPulse)
        let reclaimedMinutes = todayActions
            .filter { $0.kind == .pulseRead || $0.kind == .resetAction }
            .reduce(pulseMinutes + screenTimeSavedMinutesAfterPulse) { $0 + $1.minutes }
        let protectedFocusMinutes = todayActions
            .filter { $0.kind == .screenTimeLimitKept }
            .reduce(0) { $0 + $1.minutes }
        let screenTimeThresholdsReached = MoriScreenTimeSignalStore.signals().count +
            todayActions.filter { $0.kind == .screenTimeThresholdReached }.count

        let sparkBonus = DailySparkStore.shared.todayEntry == nil || todayActions.contains(where: { $0.kind == .dailySpark }) ? 0 : 2
        let habitBonus = HabitDataManager.shared.getTodayEntry() == nil || todayActions.contains(where: isDailyCheckInAction) ? 0 : habitScoreBonus()
        let seeds = actionSeeds + sparkBonus + habitBonus
        let screenTimeReward = min(10, protectedFocusMinutes / 5)
        let screenTimePenalty = min(12, screenTimeThresholdsReached * 4)
        let clarityScore = max(0, min(100, 46 + seeds * 4 + min(16, quietMinutes / 2) + min(12, reclaimedMinutes / 5) + min(10, settleMinutes / 3) + screenTimeReward - screenTimePenalty))
        let bloom = min(1, Double(seeds) / 24.0)

        return MoriClarityMetrics(
            clarityScore: clarityScore,
            seedsToday: seeds,
            bloomProgress: bloom,
            rootsStreak: rootsStreak(settings: settings, actions: allActions),
            quietMinutesToday: quietMinutes,
            settleMinutesToday: settleMinutes,
            settleSessionsToday: settleActions.count,
            reclaimedMinutesToday: reclaimedMinutes,
            screenTimeAttemptsToday: screenTimeAttempts,
            screenTimeSavedMinutesToday: screenTimeSavedMinutes,
            screenTimeThresholdsReachedToday: screenTimeThresholdsReached,
            protectedFocusMinutesToday: protectedFocusMinutes,
            mindfulActionsToday: todayActions.count +
                (DailySparkStore.shared.todayEntry == nil || todayActions.contains(where: { $0.kind == .dailySpark }) ? 0 : 1) +
                (HabitDataManager.shared.getTodayEntry() == nil || todayActions.contains(where: isDailyCheckInAction) ? 0 : 1)
        )
    }

    static func weeklyStats(
        settings: UserSettings,
        actions allActions: [MoriMindfulAction],
        latestPulse: MoriDailyPulse?
    ) -> MoriWeeklyStats {
        let recent = allActions.filter { action in
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return true }
            return action.createdAt >= cutoff
        }
        let metrics = metrics(settings: settings, actions: allActions, latestPulse: latestPulse)
        return MoriWeeklyStats(
            seeds: recent.reduce(0) { $0 + $1.seeds },
            quietMinutes: recent.reduce(0) { $0 + ($1.kind == .quietTimer ? $1.minutes : 0) },
            reclaimedMinutes: recent.reduce(0) { $0 + ($1.kind == .pulseRead ? $1.minutes : 0) },
            rootsStreak: metrics.rootsStreak,
            clarityAverage: metrics.clarityScore
        )
    }

    static func growthSummaries(
        settings: UserSettings,
        actions allActions: [MoriMindfulAction],
        latestPulse: MoriDailyPulse?
    ) -> [MoriGrowthPeriodSummary] {
        [
            growthSummary(
                title: MoriL10n.string("Today", defaultValue: "Today"),
                detail: MoriL10n.string("growth.summary.today.detail", defaultValue: "Current daily Bloom"),
                days: 1,
                settings: settings,
                actions: allActions,
                latestPulse: latestPulse
            ),
            growthSummary(
                title: MoriL10n.string("growth.summary.week.title", defaultValue: "This Week"),
                detail: MoriL10n.string("growth.summary.week.detail", defaultValue: "Last 7 days"),
                days: 7,
                settings: settings,
                actions: allActions,
                latestPulse: latestPulse
            ),
            growthSummary(
                title: MoriL10n.string("growth.summary.month.title", defaultValue: "This Month"),
                detail: MoriL10n.string("growth.summary.month.detail", defaultValue: "Last 30 days"),
                days: 30,
                settings: settings,
                actions: allActions,
                latestPulse: latestPulse
            )
        ]
    }

    static func clarityTrend(
        days: Int = 7,
        settings: UserSettings,
        actions allActions: [MoriMindfulAction],
        latestPulse: MoriDailyPulse?
    ) -> [MoriClarityTrendPoint] {
        let calendar = Calendar.current
        let clampedDays = max(1, days)

        return (0..<clampedDays).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(clampedDays - offset - 1), to: Date()) else {
                return nil
            }

            let dayActions = actionsOn(date, in: allActions)
            let seeds = seeds(in: dayActions)
            let quietMinutes = quietMinutes(in: dayActions)
            let score = clarityScore(seeds: seeds, quietMinutes: quietMinutes)

            return MoriClarityTrendPoint(date: date, score: score, seeds: seeds)
        }
    }

    static func isDailyCheckInAction(_ action: MoriMindfulAction) -> Bool {
        action.kind == .dailyCheckIn || action.kind == .dailyFocus
    }

    private static func rootsStreak(
        settings: UserSettings,
        actions allActions: [MoriMindfulAction]
    ) -> Int {
        var streak = 0
        var date = Date()

        while hasPractice(on: date, settings: settings, actions: allActions) {
            streak += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }

        return streak
    }

    private static func hasPractice(
        on date: Date,
        settings: UserSettings,
        actions allActions: [MoriMindfulAction]
    ) -> Bool {
        if !actionsOn(date, in: allActions).isEmpty {
            return true
        }

        if Calendar.current.isDateInToday(date) {
            return DailySparkStore.shared.todayEntry != nil ||
                HabitDataManager.shared.getTodayEntry() != nil
        }

        return false
    }

    private static func habitScoreBonus() -> Int {
        guard let entry = HabitDataManager.shared.getTodayEntry() else { return 0 }
        switch entry.tone {
        case .positive: return 3
        case .neutral: return 1
        case .negative: return 1
        }
    }

    private static func growthSummary(
        title: String,
        detail: String,
        days: Int,
        settings: UserSettings,
        actions allActions: [MoriMindfulAction],
        latestPulse: MoriDailyPulse?
    ) -> MoriGrowthPeriodSummary {
        let cutoff = Calendar.current.date(byAdding: .day, value: -(max(1, days) - 1), to: Date()) ?? Date()
        let periodActions = allActions.filter { $0.createdAt >= Calendar.current.startOfDay(for: cutoff) }
        let seeds = seeds(in: periodActions)
        let quietMinutes = quietMinutes(in: periodActions)

        return MoriGrowthPeriodSummary(
            id: title,
            title: title,
            detail: detail,
            seeds: seeds,
            quietMinutes: quietMinutes,
            mindfulActions: periodActions.count,
            clarityScore: days == 1 ? metrics(settings: settings, actions: allActions, latestPulse: latestPulse).clarityScore : clarityScore(seeds: seeds, quietMinutes: quietMinutes)
        )
    }

    private static func actionsOn(
        _ date: Date,
        in actions: [MoriMindfulAction]
    ) -> [MoriMindfulAction] {
        let key = MoriDateKey.value(for: date)
        return actions.filter { $0.dateKey == key }
    }

    private static func seeds(in actions: [MoriMindfulAction]) -> Int {
        actions.reduce(0) { $0 + $1.seeds }
    }

    private static func quietMinutes(in actions: [MoriMindfulAction]) -> Int {
        actions
            .filter(isQuietGrowthAction)
            .reduce(0) { $0 + $1.minutes }
    }

    private static func clarityScore(seeds: Int, quietMinutes: Int) -> Int {
        max(0, min(100, 46 + seeds * 4 + min(24, quietMinutes / 2)))
    }

    private static func isQuietGrowthAction(_ action: MoriMindfulAction) -> Bool {
        switch action.kind {
        case .quietTimer, .replacementAction, .urgeCheckIn, .breathingSession, .pomodoroSession, .settleSession:
            return true
        case .pulseRead, .resetAction, .dailyFocus, .dailyCheckIn, .dailySpark, .weekArchiveProof, .journal, .screenTimeLimitKept, .screenTimeThresholdReached:
            return false
        }
    }
}
