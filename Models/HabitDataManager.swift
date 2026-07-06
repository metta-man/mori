import Foundation

// MARK: - Habit Entry
struct HabitEntry: Identifiable, Codable {
    var habitName: String?
    let id: UUID
    let date: Date
    let tone: HabitDayTone
    let createdAt: Date
    var note: String?
    var trigger: String?
    var thought: String?
    var feeling: String?
    var responsePlan: String?

    var isPositive: Bool {
        tone == .positive
    }

    var hasPatternLog: Bool {
        [trigger, thought, feeling, responsePlan].contains { text in
            text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }

    init(
        habitName: String? = nil,
        id: UUID = UUID(),
        date: Date,
        tone: HabitDayTone,
        createdAt: Date,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil
    ) {
        self.habitName = habitName
        self.id = id
        self.date = date
        self.tone = tone
        self.createdAt = createdAt
        self.note = note
        self.trigger = trigger
        self.thought = thought
        self.feeling = feeling
        self.responsePlan = responsePlan
    }

    init(
        habitName: String? = nil,
        id: UUID = UUID(),
        date: Date,
        isPositive: Bool,
        createdAt: Date,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil
    ) {
        self.init(
            habitName: habitName,
            id: id,
            date: date,
            tone: isPositive ? .positive : .negative,
            createdAt: createdAt,
            note: note,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan
        )
    }

    private enum CodingKeys: String, CodingKey {
        case habitName
        case id
        case date
        case tone
        case isPositive
        case createdAt
        case note
        case trigger
        case thought
        case feeling
        case responsePlan
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        habitName = try container.decodeIfPresent(String.self, forKey: .habitName)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        trigger = try container.decodeIfPresent(String.self, forKey: .trigger)
        thought = try container.decodeIfPresent(String.self, forKey: .thought)
        feeling = try container.decodeIfPresent(String.self, forKey: .feeling)
        responsePlan = try container.decodeIfPresent(String.self, forKey: .responsePlan)

        if let decodedTone = try container.decodeIfPresent(HabitDayTone.self, forKey: .tone) {
            tone = decodedTone
        } else {
            let legacyIsPositive = try container.decodeIfPresent(Bool.self, forKey: .isPositive) ?? false
            tone = legacyIsPositive ? .positive : .negative
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(habitName, forKey: .habitName)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(tone, forKey: .tone)
        try container.encode(isPositive, forKey: .isPositive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(trigger, forKey: .trigger)
        try container.encodeIfPresent(thought, forKey: .thought)
        try container.encodeIfPresent(feeling, forKey: .feeling)
        try container.encodeIfPresent(responsePlan, forKey: .responsePlan)
    }
}

enum HabitDayTone: String, CaseIterable, Codable, Identifiable {
    case positive
    case neutral
    case negative

    var id: String { rawValue }
}

// MARK: - Habit Streak
struct HabitStreak {
    let currentStreak: Int
    let longestStreak: Int
    let lastWeekTrend: TrendDirection
}

// MARK: - Monthly Stats
struct MonthlyStats {
    let month: Date
    let positiveDays: Int
    let neutralDays: Int
    let negativeDays: Int
    let bestStreak: Int
    let trend: TrendDirection
}

// MARK: - Trend Direction
enum TrendDirection {
    case improving
    case declining
    case stable
}

struct HabitTrackerDashboardSnapshot {
    let todayEntry: HabitEntry?
    let weeklyEntries: [HabitEntry]
    let streak: HabitStreak
    let monthlyStats: MonthlyStats

    static let empty = HabitTrackerDashboardSnapshot(
        todayEntry: nil,
        weeklyEntries: [],
        streak: HabitStreak(currentStreak: 0, longestStreak: 0, lastWeekTrend: .stable),
        monthlyStats: MonthlyStats(
            month: Date(),
            positiveDays: 0,
            neutralDays: 0,
            negativeDays: 0,
            bestStreak: 0,
            trend: .stable
        )
    )
}

// MARK: - Habit Data Manager
/// Coordinates habit tracking entry writes, queries, and derived summaries.
class HabitDataManager {
    static let shared = HabitDataManager()

    private let store: HabitEntryStore
    private let statisticsCalculator: HabitStatisticsCalculator

    private init(
        store: HabitEntryStore = HabitEntryStore(),
        statisticsCalculator: HabitStatisticsCalculator = HabitStatisticsCalculator()
    ) {
        self.store = store
        self.statisticsCalculator = statisticsCalculator
    }

    // MARK: - Save Entry
    func saveEntry(
        habitName: String? = nil,
        on date: Date = Date(),
        tone: HabitDayTone,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil
    ) -> HabitEntry {
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: date)
        let entry = HabitEntry(
            habitName: habitName,
            id: UUID(),
            date: entryDate,
            tone: tone,
            createdAt: Date(),
            note: Self.normalizedOptionalText(note),
            trigger: Self.normalizedOptionalText(trigger),
            thought: Self.normalizedOptionalText(thought),
            feeling: Self.normalizedOptionalText(feeling),
            responsePlan: Self.normalizedOptionalText(responsePlan)
        )

        var entries = getAllEntries()

        // Remove existing entry for the selected day if it exists.
        entries.removeAll { calendar.isDate($0.date, inSameDayAs: entryDate) }

        // Add new entry
        entries.append(entry)

        // Save
        saveEntries(entries)

        return entry
    }

    func saveEntry(habitName: String? = nil, isPositive: Bool) -> HabitEntry {
        saveEntry(habitName: habitName, tone: isPositive ? .positive : .negative)
    }

    // MARK: - Get Today's Entry
    func getTodayEntry() -> HabitEntry? {
        let entries = getAllEntries()
        let calendar = Calendar.current
        return entries.first { calendar.isDate($0.date, inSameDayAs: Date()) }
    }

    // MARK: - Get Weekly Entries
    func getWeeklyEntries() -> [HabitEntry] {
        weeklyEntries(from: getAllEntries(), now: Date(), calendar: .current)
    }

    func getEntries(from startDate: Date, to endDate: Date) -> [HabitEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        return getAllEntries().filter { entry in
            let entryDate = calendar.startOfDay(for: entry.date)
            return entryDate >= start && entryDate <= end
        }
    }

    // MARK: - Get Streak
    func getStreak() -> HabitStreak {
        statisticsCalculator.streak(for: getAllEntries())
    }

    // MARK: - Get Monthly Stats
    func getMonthlyStats() -> MonthlyStats {
        statisticsCalculator.monthlyStats(for: getAllEntries())
    }

    func dashboardSnapshot(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> HabitTrackerDashboardSnapshot {
        let entries = getAllEntries()
        let today = calendar.startOfDay(for: now)

        return HabitTrackerDashboardSnapshot(
            todayEntry: entries.first { calendar.isDate($0.date, inSameDayAs: today) },
            weeklyEntries: weeklyEntries(from: entries, now: now, calendar: calendar),
            streak: statisticsCalculator.streak(for: entries, now: now, calendar: calendar),
            monthlyStats: statisticsCalculator.monthlyStats(for: entries, now: now, calendar: calendar)
        )
    }

    // MARK: - Clear Entries
    func clearAllEntries() {
        store.clearEntries()
    }

    // MARK: - Private Methods
    private func getAllEntries() -> [HabitEntry] {
        store.loadEntries()
    }

    private func saveEntries(_ entries: [HabitEntry]) {
        store.saveEntries(entries)
    }

    private func weeklyEntries(
        from entries: [HabitEntry],
        now: Date,
        calendar: Calendar
    ) -> [HabitEntry] {
        let today = calendar.startOfDay(for: now)

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today) else {
                return nil
            }

            return entries.first { calendar.isDate($0.date, inSameDayAs: date) }
                ?? HabitEntry(
                    habitName: nil,
                    id: UUID(),
                    date: date,
                    tone: .neutral,
                    createdAt: Date(),
                    note: nil
                )
        }
    }

    private static func normalizedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
