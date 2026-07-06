import Foundation

struct HabitStatisticsCalculator {
    func streak(
        for entries: [HabitEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> HabitStreak {
        let sortedEntries = entries.sorted { $0.date > $1.date }

        guard !sortedEntries.isEmpty else {
            return HabitStreak(currentStreak: 0, longestStreak: 0, lastWeekTrend: .stable)
        }

        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: now)

        if sortedEntries.first(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) == nil {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        while hasCheckIn(on: checkDate, in: sortedEntries, calendar: calendar) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        let longestStreak = longestCheckInStreak(for: sortedEntries, calendar: calendar)
        let trend = weeklyTrend(for: sortedEntries, now: now, calendar: calendar)

        return HabitStreak(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastWeekTrend: trend
        )
    }

    func monthlyStats(
        for entries: [HabitEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> MonthlyStats {
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) ?? now
        let endOfMonth = calendar.date(
            byAdding: DateComponents(month: 1, day: -1),
            to: startOfMonth
        ) ?? now

        let monthEntries = entries.filter { entry in
            entry.date >= startOfMonth && entry.date <= endOfMonth
        }

        let positiveDays = monthEntries.filter { $0.isPositive }.count
        let neutralDays = monthEntries.filter { $0.tone == .neutral }.count
        let negativeDays = monthEntries.filter { $0.tone == .negative }.count
        let bestStreak = longestCheckInStreak(
            for: monthEntries.sorted { $0.date > $1.date },
            calendar: calendar
        )

        return MonthlyStats(
            month: startOfMonth,
            positiveDays: positiveDays,
            neutralDays: neutralDays,
            negativeDays: negativeDays,
            bestStreak: bestStreak,
            trend: monthlyTrend(
                entries: entries,
                monthEntries: monthEntries,
                positiveDays: positiveDays,
                startOfMonth: startOfMonth,
                calendar: calendar
            )
        )
    }

    private func longestCheckInStreak(
        for entries: [HabitEntry],
        calendar: Calendar
    ) -> Int {
        var longestStreak = 0
        var tempStreak = 0
        var previousDate: Date?

        for entry in entries {
            if let prev = previousDate {
                let daysDiff = calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: entry.date),
                    to: calendar.startOfDay(for: prev)
                ).day ?? 0
                if daysDiff == 1 {
                    tempStreak += 1
                } else {
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }

            longestStreak = max(longestStreak, tempStreak)
            previousDate = entry.date
        }

        return longestStreak
    }

    private func monthlyTrend(
        entries: [HabitEntry],
        monthEntries: [HabitEntry],
        positiveDays: Int,
        startOfMonth: Date,
        calendar: Calendar
    ) -> TrendDirection {
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? startOfMonth
        let lastMonthEntries = entries.filter { entry in
            entry.date >= lastMonthStart && entry.date < startOfMonth
        }
        let lastMonthPositive = lastMonthEntries.filter { $0.isPositive }.count
        let lastMonthTotal = lastMonthEntries.count

        guard lastMonthTotal > 0, !monthEntries.isEmpty else {
            return .stable
        }

        let thisMonthPercentage = Double(positiveDays) / Double(monthEntries.count)
        let lastMonthPercentage = Double(lastMonthPositive) / Double(lastMonthTotal)
        let diff = thisMonthPercentage - lastMonthPercentage

        if diff > 0.1 {
            return .improving
        } else if diff < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }

    private func weeklyTrend(
        for entries: [HabitEntry],
        now: Date,
        calendar: Calendar
    ) -> TrendDirection {
        let startOfThisWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        ) ?? now
        let thisWeekEntries = entries.filter {
            $0.date >= startOfThisWeek && $0.isPositive
        }.count

        let startOfLastWeek = calendar.date(
            byAdding: .weekOfYear,
            value: -1,
            to: startOfThisWeek
        ) ?? startOfThisWeek
        let lastWeekEntries = entries.filter {
            $0.date >= startOfLastWeek && $0.date < startOfThisWeek && $0.isPositive
        }.count

        if thisWeekEntries > lastWeekEntries {
            return .improving
        } else if thisWeekEntries < lastWeekEntries {
            return .declining
        } else {
            return .stable
        }
    }

    private func hasCheckIn(on date: Date, in entries: [HabitEntry], calendar: Calendar) -> Bool {
        entries.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
