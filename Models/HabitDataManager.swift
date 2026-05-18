import Foundation
import SwiftUI

extension Notification.Name {
    static let habitDataDidChange = Notification.Name("habitDataDidChange")
}

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

// MARK: - Habit Data Manager
/// Manages habit tracking data persistence using UserDefaults
class HabitDataManager {
    static let shared = HabitDataManager()
    
    private let entriesKey = "habit_entries"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Save Entry
    func saveEntry(
        habitName: String? = nil,
        tone: HabitDayTone,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil
    ) -> HabitEntry {
        let entry = HabitEntry(
            habitName: habitName,
            id: UUID(),
            date: Date(),
            tone: tone,
            createdAt: Date(),
            note: Self.normalizedOptionalText(note),
            trigger: Self.normalizedOptionalText(trigger),
            thought: Self.normalizedOptionalText(thought),
            feeling: Self.normalizedOptionalText(feeling),
            responsePlan: Self.normalizedOptionalText(responsePlan)
        )
        
        var entries = getAllEntries()
        
        // Remove existing entry for today if exists
        let calendar = Calendar.current
        entries.removeAll { calendar.isDate($0.date, inSameDayAs: Date()) }
        
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
        let entries = getAllEntries()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var weekEntries: [HabitEntry] = []
        
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today) {
                let entry = entries.first { calendar.isDate($0.date, inSameDayAs: date) }
                weekEntries.append(entry ?? HabitEntry(habitName: nil, id: UUID(), date: date, tone: .neutral, createdAt: Date(), note: nil))
            }
        }
        
        return weekEntries
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
        let entries = getAllEntries().sorted { $0.date > $1.date }
        let calendar = Calendar.current
        
        guard !entries.isEmpty else {
            return HabitStreak(currentStreak: 0, longestStreak: 0, lastWeekTrend: .stable)
        }
        
        // Calculate current streak
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // If no entry today, check if yesterday has entry to maintain streak
        if entries.first(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) == nil {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        while true {
            if hasCheckIn(on: checkDate, in: entries, calendar: calendar) {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        // Calculate longest streak
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
        
        // Calculate trend
        let trend = calculateTrend(entries: entries)
        
        return HabitStreak(currentStreak: currentStreak, longestStreak: longestStreak, lastWeekTrend: trend)
    }
    
    // MARK: - Get Monthly Stats
    func getMonthlyStats() -> MonthlyStats {
        let entries = getAllEntries()
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of month
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? now
        
        // Filter entries for this month
        let monthEntries = entries.filter { entry in
            entry.date >= startOfMonth && entry.date <= endOfMonth
        }
        
        let positiveDays = monthEntries.filter { $0.isPositive }.count
        let neutralDays = monthEntries.filter { $0.tone == .neutral }.count
        let negativeDays = monthEntries.filter { $0.tone == .negative }.count
        
        // Calculate best check-in streak
        var bestStreak = 0
        var tempStreak = 0
        var previousDate: Date?
        for entry in monthEntries.sorted(by: { $0.date < $1.date }) {
            if let previousDate {
                let daysDiff = calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: previousDate),
                    to: calendar.startOfDay(for: entry.date)
                ).day ?? 0
                tempStreak = daysDiff == 1 ? tempStreak + 1 : 1
            } else {
                tempStreak = 1
            }
            bestStreak = max(bestStreak, tempStreak)
            previousDate = entry.date
        }
        
        // Calculate trend (compare to last month)
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? startOfMonth
        let lastMonthEntries = entries.filter { entry in
            entry.date >= lastMonthStart && entry.date < startOfMonth
        }
        let lastMonthPositive = lastMonthEntries.filter { $0.isPositive }.count
        let lastMonthTotal = lastMonthEntries.count
        
        let trend: TrendDirection
        if lastMonthTotal == 0 || monthEntries.count == 0 {
            trend = .stable
        } else {
            let thisMonthPercentage = Double(positiveDays) / Double(monthEntries.count)
            let lastMonthPercentage = Double(lastMonthPositive) / Double(lastMonthTotal)
            let diff = thisMonthPercentage - lastMonthPercentage
            
            if diff > 0.1 {
                trend = .improving
            } else if diff < -0.1 {
                trend = .declining
            } else {
                trend = .stable
            }
        }
        
        return MonthlyStats(
            month: startOfMonth,
            positiveDays: positiveDays,
            neutralDays: neutralDays,
            negativeDays: negativeDays,
            bestStreak: bestStreak,
            trend: trend
        )
    }

    // MARK: - Clear Entries
    func clearAllEntries() {
        userDefaults.removeObject(forKey: entriesKey)
        NotificationCenter.default.post(name: .habitDataDidChange, object: nil)
    }
    
    // MARK: - Private Methods
    private func getAllEntries() -> [HabitEntry] {
        guard let data = userDefaults.data(forKey: entriesKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([HabitEntry].self, from: data)
        } catch {
            return []
        }
    }
    
    private func saveEntries(_ entries: [HabitEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            userDefaults.set(data, forKey: entriesKey)
            NotificationCenter.default.post(name: .habitDataDidChange, object: nil)
        } catch {
            print("Failed to save habit entries: \(error)")
        }
    }

    private static func normalizedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func hasCheckIn(on date: Date, in entries: [HabitEntry], calendar: Calendar) -> Bool {
        entries.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func calculateTrend(entries: [HabitEntry]) -> TrendDirection {
        let calendar = Calendar.current
        let now = Date()
        
        // This week
        let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let thisWeekEntries = entries.filter { $0.date >= startOfThisWeek && $0.isPositive }.count
        
        // Last week
        let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) ?? startOfThisWeek
        let lastWeekEntries = entries.filter { $0.date >= startOfLastWeek && $0.date < startOfThisWeek && $0.isPositive }.count
        
        if thisWeekEntries > lastWeekEntries {
            return .improving
        } else if thisWeekEntries < lastWeekEntries {
            return .declining
        } else {
            return .stable
        }
    }
}
