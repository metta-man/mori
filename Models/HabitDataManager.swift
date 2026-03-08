import Foundation
import SwiftUI

// MARK: - Habit Entry
struct HabitEntry: Identifiable, Codable {
    var habitName: String?
    let id: UUID
    let date: Date
    let isPositive: Bool
    let createdAt: Date
    var note: String?
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
    func saveEntry(habitName: String? = nil, isPositive: Bool) -> HabitEntry {
        let entry = HabitEntry(
            habitName: habitName,
            id: UUID(),
            date: Date(),
            isPositive: isPositive,
            createdAt: Date(),
            note: nil
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
                weekEntries.append(entry ?? HabitEntry(habitName: nil, id: UUID(), date: date, isPositive: false, createdAt: Date(), note: nil))
            }
        }
        
        return weekEntries
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
            let hasEntry = entries.contains { calendar.isDate($0.date, inSameDayAs: checkDate) && $0.isPositive }
            if hasEntry {
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
        
        for entry in entries where entry.isPositive {
            if let prev = previousDate {
                let daysDiff = calendar.dateComponents([.day], from: entry.date, to: prev).day ?? 0
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
        let negativeDays = monthEntries.filter { !$0.isPositive }.count
        
        // Calculate best streak (simplified)
        var bestStreak = 0
        var tempStreak = 0
        for entry in monthEntries.sorted(by: { $0.date < $1.date }) where entry.isPositive {
            tempStreak += 1
            bestStreak = max(bestStreak, tempStreak)
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
            negativeDays: negativeDays,
            bestStreak: bestStreak,
            trend: trend
        )
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
        } catch {
            print("Failed to save habit entries: \(error)")
        }
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
