import SwiftUI

enum WeekArchiveDetailMode: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return MoriL10n.display("Week")
        case .month: return MoriL10n.display("Month")
        }
    }
}

struct WeekArchiveData {
    let settings: UserSettings
    let dailySparks: [DailySparkEntry]
    let journalEntries: [GratitudeEntry]
    let actions: [MoriMindfulAction]
    let sessions: [SettleSession]
    let habitEntries: [HabitEntry]
    let weeklyIntentions: [WeeklyIntention]

    var recordedWeekIndexes: Set<Int> {
        var indexes = Set<Int>()

        for date in recordedDates {
            if let index = moriVisualWeekIndex(for: date, archiveStartDate: settings.archiveStartDate, archiveSpanYears: settings.archiveSpanYears) {
                indexes.insert(index)
            }
        }

        for intention in weeklyIntentions {
            if let date = Self.date(fromWeekKey: intention.weekKey),
               let index = moriVisualWeekIndex(for: date, archiveStartDate: settings.archiveStartDate, archiveSpanYears: settings.archiveSpanYears) {
                indexes.insert(index)
            }
        }

        return indexes
    }

    func weekSummary(for coordinate: WeekCoordinate) -> WeekArchiveWeekSummary {
        let startDate = moriMondayWeekStart(for: coordinate, archiveStartDate: settings.archiveStartDate)
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        let endExclusive = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? endDate
        let weekKey = Self.weekKey(for: startDate)

        return WeekArchiveWeekSummary(
            coordinate: coordinate,
            startDate: startDate,
            endDate: endDate,
            weeklyIntentions: weeklyIntentions.filter { $0.weekKey == weekKey },
            dailySparks: dailySparks.filter { spark in
                guard let date = Self.date(fromDateKey: spark.dateKey) else { return false }
                return Self.contains(date, start: startDate, endExclusive: endExclusive)
            },
            journalEntries: journalEntries.filter { Self.contains($0.date, start: startDate, endExclusive: endExclusive) },
            actions: actions.filter { Self.contains($0.createdAt, start: startDate, endExclusive: endExclusive) },
            sessions: sessions.filter { Self.contains($0.startedAt, start: startDate, endExclusive: endExclusive) },
            habitEntries: habitEntries.filter { Self.contains($0.date, start: startDate, endExclusive: endExclusive) }
        )
    }

    func daySummary(for date: Date) -> WeekArchiveDaySummary {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let actionsForDay = actions.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }
        let sessionsForDay = sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }

        return WeekArchiveDaySummary(
            date: day,
            dailySpark: dailySparks.first { spark in
                guard let sparkDate = Self.date(fromDateKey: spark.dateKey) else { return false }
                return calendar.isDate(sparkDate, inSameDayAs: day)
            },
            journalEntries: journalEntries.filter { calendar.isDate($0.date, inSameDayAs: day) },
            actions: actionsForDay,
            sessions: sessionsForDay,
            habitEntry: habitEntries.first { calendar.isDate($0.date, inSameDayAs: day) }
        )
    }

    private var recordedDates: [Date] {
        dailySparks.compactMap { Self.date(fromDateKey: $0.dateKey) } +
            journalEntries.map(\.date) +
            actions.map(\.createdAt) +
            sessions.map(\.startedAt) +
            habitEntries.map(\.date)
    }

    static func contains(_ date: Date, start: Date, endExclusive: Date) -> Bool {
        date >= start && date < endExclusive
    }

    static func weekKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? components.year ?? 0
        let week = components.weekOfYear ?? 0
        return "\(year)-\(week)"
    }

    static func date(fromWeekKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return Calendar.current.date(from: DateComponents(weekday: 2, weekOfYear: parts[1], yearForWeekOfYear: parts[0]))
    }

    static func date(fromDateKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}

struct WeekArchiveWeekSummary: Identifiable {
    let coordinate: WeekCoordinate
    let startDate: Date
    let endDate: Date
    let weeklyIntentions: [WeeklyIntention]
    let dailySparks: [DailySparkEntry]
    let journalEntries: [GratitudeEntry]
    let actions: [MoriMindfulAction]
    let sessions: [SettleSession]
    let habitEntries: [HabitEntry]

    var id: String { "\(coordinate.year)-\(coordinate.week)" }

    var seedsPlanted: Int {
        actions.reduce(0) { $0 + $1.seeds } + sessions.reduce(0) { $0 + $1.seedsEarned }
    }

    var quietMinutes: Int {
        actions
            .filter { $0.kind.isQuietArchiveAction }
            .reduce(0) { $0 + $1.minutes }
    }

    var quietActionCount: Int {
        actions.filter { $0.kind.isQuietArchiveAction }.count
    }

    var practiceMinutes: Int {
        sessions.reduce(0) { $0 + $1.actualMinutes } +
            actions
            .filter { $0.kind.isPracticeArchiveAction }
            .reduce(0) { $0 + $1.minutes }
    }

    var hasRecords: Bool {
        !weeklyIntentions.isEmpty ||
            !dailySparks.isEmpty ||
            !journalEntries.isEmpty ||
            !actions.isEmpty ||
            !sessions.isEmpty ||
            !habitEntries.isEmpty
    }

    var trendPoints: [WeekArchiveTrendPoint] {
        (0..<7).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: startDate) ?? startDate
            let dayActions = actions.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
            let seeds = dayActions.reduce(0) { $0 + $1.seeds }
            let quiet = dayActions.filter { $0.kind.isQuietArchiveAction }.reduce(0) { $0 + $1.minutes }
            let score = max(0, min(100, 46 + seeds * 4 + min(16, quiet / 2)))
            return WeekArchiveTrendPoint(label: WeekArchiveTrendPoint.weekdayLabels[offset], score: score)
        }
    }
}

struct WeekArchiveTrendPoint: Identifiable, Equatable {
    static let weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    static let previewWeek = [
        WeekArchiveTrendPoint(label: "Mon", score: 46),
        WeekArchiveTrendPoint(label: "Tue", score: 46),
        WeekArchiveTrendPoint(label: "Wed", score: 46),
        WeekArchiveTrendPoint(label: "Thu", score: 46),
        WeekArchiveTrendPoint(label: "Fri", score: 46),
        WeekArchiveTrendPoint(label: "Sat", score: 66),
        WeekArchiveTrendPoint(label: "Sun", score: 73)
    ]

    let label: String
    let score: Int

    var id: String { label }
}

struct WeekArchiveDaySummary: Identifiable {
    let date: Date
    let dailySpark: DailySparkEntry?
    let journalEntries: [GratitudeEntry]
    let actions: [MoriMindfulAction]
    let sessions: [SettleSession]
    let habitEntry: HabitEntry?

    var id: String { MoriDateKey.value(for: date) }

    var seedsPlanted: Int {
        actions.reduce(0) { $0 + $1.seeds } + sessions.reduce(0) { $0 + $1.seedsEarned }
    }

    var quietMinutes: Int {
        actions
            .filter { $0.kind.isQuietArchiveAction }
            .reduce(0) { $0 + $1.minutes }
    }

    var quietActionCount: Int {
        actions.filter { $0.kind.isQuietArchiveAction }.count
    }

    var practiceMinutes: Int {
        sessions.reduce(0) { $0 + $1.actualMinutes } +
            actions
            .filter { $0.kind.isPracticeArchiveAction }
            .reduce(0) { $0 + $1.minutes }
    }

    var clarityScore: Int {
        max(0, min(100, 46 + seedsPlanted * 4 + min(16, quietMinutes / 2)))
    }

    var hasRecords: Bool {
        dailySpark != nil ||
            !journalEntries.isEmpty ||
            !actions.isEmpty ||
            !sessions.isEmpty ||
            habitEntry != nil
    }
}

extension MoriMindfulActionKind {
    var archiveIcon: MoriBitmapIcon {
        switch self {
        case .pulseRead:
            return .pulse
        case .resetAction:
            return .refresh
        case .quietTimer:
            return .quiet
        case .settleSession:
            return .leaf
        case .breathingSession:
            return .breathe
        case .pomodoroSession:
            return .timer
        case .urgeCheckIn:
            return .lockShield
        case .replacementAction:
            return .refresh
        case .dailyFocus, .dailyCheckIn:
            return .plus
        case .dailySpark:
            return .pulse
        case .weekArchiveProof:
            return .journal
        case .journal:
            return .journal
        case .screenTimeLimitKept:
            return .lockShield
        case .screenTimeThresholdReached:
            return .lockShield
        }
    }

    var isQuietArchiveAction: Bool {
        switch self {
        case .quietTimer, .replacementAction, .urgeCheckIn, .breathingSession, .pomodoroSession, .settleSession:
            return true
        case .pulseRead, .resetAction, .dailyFocus, .dailyCheckIn, .dailySpark, .weekArchiveProof, .journal, .screenTimeLimitKept, .screenTimeThresholdReached:
            return false
        }
    }

    var isPracticeArchiveAction: Bool {
        switch self {
        case .resetAction, .quietTimer, .settleSession, .breathingSession, .pomodoroSession, .replacementAction, .dailyFocus, .dailyCheckIn, .journal:
            return true
        case .pulseRead, .urgeCheckIn, .dailySpark, .weekArchiveProof, .screenTimeLimitKept, .screenTimeThresholdReached:
            return false
        }
    }
}
