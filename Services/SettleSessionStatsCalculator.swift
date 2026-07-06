import Foundation

struct SettleSessionStatsCalculator {
    func weeklySummary(
        for sessions: [SettleSession],
        containing date: Date = Date(),
        calendar: Calendar = .current
    ) -> SettleWeeklySummary {
        let weekly = sessionsInWeek(sessions, containing: date, calendar: calendar).filter(\.completed)
        let totalMinutes = weekly.reduce(0) { $0 + $1.actualMinutes }
        let days = Set(weekly.map { calendar.startOfDay(for: $0.startedAt) }).count
        let sessionProgress = min(1.0, Double(weekly.count) / 5.0)
        let minuteProgress = min(1.0, Double(totalMinutes) / 90.0)
        let consistencyProgress = min(1.0, Double(days) / 5.0)
        let bloom = min(1.0, sessionProgress * 0.35 + minuteProgress * 0.40 + consistencyProgress * 0.25)

        return SettleWeeklySummary(
            completedSessions: weekly.count,
            totalMinutes: totalMinutes,
            consistencyDays: days,
            bloomProgress: bloom
        )
    }

    func recommendedDurationMinutes(
        for sessions: [SettleSession],
        containing date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let summary = weeklySummary(for: sessions, containing: date, calendar: calendar)

        if summary.completedSessions == 0 {
            return 10
        }

        if summary.consistencyDays >= 4 {
            return 15
        }

        if summary.totalMinutes < 20 {
            return 8
        }

        return 12
    }

    func seeds(for plannedMinutes: Int) -> Int {
        max(2, min(12, plannedMinutes / 5 + 1))
    }

    private func sessionsInWeek(
        _ sessions: [SettleSession],
        containing date: Date,
        calendar: Calendar
    ) -> [SettleSession] {
        var weekCalendar = calendar
        weekCalendar.firstWeekday = 2

        guard
            let startOfWeek = weekCalendar.date(
                from: weekCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            ),
            let endOfWeek = weekCalendar.date(byAdding: .day, value: 7, to: startOfWeek)
        else {
            return []
        }

        return sessions.filter { $0.startedAt >= startOfWeek && $0.startedAt < endOfWeek }
    }
}
