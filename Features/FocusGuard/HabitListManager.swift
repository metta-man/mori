import Foundation
import SwiftUI

// MARK: - Daily Habit Model
struct DailyHabit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String          // SF Symbol name
    var isCompleted: Bool
    var completedAt: Date?
    var order: Int
    var createdAt: Date
    
    static func == (lhs: DailyHabit, rhs: DailyHabit) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Habit List Manager
/// Manages a list of daily habits that can trigger Focus Guard unlock.
/// Replaces the simple good/bad day system with named habit tracking.
@MainActor
class HabitListManager: ObservableObject {
    
    static let shared = HabitListManager()
    
    @Published var habits: [DailyHabit] = []
    @Published var todayCompletions: [UUID: Date] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let kHabits = "focus_guard_habits"
    private let kTodayCompletions = "focus_guard_today_completions"
    private let kCompletionsDate = "focus_guard_completions_date"
    
    private init() {
        loadHabits()
        loadTodayCompletions()
    }
    
    // MARK: - Computed
    
    var totalHabits: Int { habits.count }
    
    var completedCount: Int { todayCompletions.count }
    
    var allCompleted: Bool {
        guard !habits.isEmpty else { return false }
        return habits.allSatisfy { todayCompletions[$0.id] != nil }
    }
    
    var progressFraction: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedCount) / Double(totalHabits)
    }
    
    // MARK: - CRUD
    
    func addHabit(name: String, icon: String = "circle") {
        let habit = DailyHabit(
            id: UUID(),
            name: name,
            icon: icon,
            isCompleted: false,
            order: habits.count,
            createdAt: Date()
        )
        habits.append(habit)
        saveHabits()
    }
    
    func deleteHabit(_ habit: DailyHabit) {
        habits.removeAll { $0.id == habit.id }
        todayCompletions.removeValue(forKey: habit.id)
        reorder()
        saveHabits()
        notifyFocusGuard()
    }
    
    func moveHabit(from source: IndexSet, to destination: Int) {
        habits.move(fromOffsets: source, toOffset: destination)
        reorder()
        saveHabits()
    }
    
    func renameHabit(_ habit: DailyHabit, newName: String) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].name = newName
            saveHabits()
        }
    }
    
    // MARK: - Completion
    
    func toggleHabit(_ habit: DailyHabit) {
        if todayCompletions[habit.id] != nil {
            // Uncomplete
            todayCompletions.removeValue(forKey: habit.id)
        } else {
            // Complete
            todayCompletions[habit.id] = Date()
        }
        saveTodayCompletions()
        notifyFocusGuard()
    }
    
    func isHabitCompleted(_ habit: DailyHabit) -> Bool {
        todayCompletions[habit.id] != nil
    }
    
    /// Reset all completions for a new day
    func resetDaily() {
        let calendar = Calendar.current
        let savedDate = userDefaults.string(forKey: kCompletionsDate)
        let today = calendar.startOfDay(for: Date()).description
        
        if savedDate != today {
            todayCompletions.removeAll()
            saveTodayCompletions()
            notifyFocusGuard()
        }
    }
    
    // MARK: - Focus Guard Integration
    
    private func notifyFocusGuard() {
        let focusGuard = FocusGuardManager.shared
        focusGuard.updateShieldState(
            completedHabits: completedCount,
            totalHabits: totalHabits
        )
    }
    
    // MARK: - Persistence
    
    private func reorder() {
        for i in habits.indices {
            habits[i].order = i
        }
    }
    
    private func loadHabits() {
        guard let data = userDefaults.data(forKey: kHabits) else { return }
        do {
            habits = try JSONDecoder().decode([DailyHabit].self, from: data)
            habits.sort { $0.order < $1.order }
        } catch {
            print("Failed to load habits: \(error)")
        }
    }
    
    private func saveHabits() {
        do {
            let data = try JSONEncoder().encode(habits)
            userDefaults.set(data, forKey: kHabits)
        } catch {
            print("Failed to save habits: \(error)")
        }
    }
    
    private func loadTodayCompletions() {
        // Check if completions are from today
        let calendar = Calendar.current
        let savedDate = userDefaults.string(forKey: kCompletionsDate) ?? ""
        let today = calendar.startOfDay(for: Date()).description
        
        guard savedDate == today else {
            // New day, reset
            todayCompletions = [:]
            return
        }
        
        guard let data = userDefaults.data(forKey: kTodayCompletions) else { return }
        do {
            if let dict = try JSONDecoder().decode([String: Date].self, from: data) as? [String: Date] {
                todayCompletions = Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
                    guard let uuid = UUID(uuidString: key) else { return nil }
                    return (uuid, value)
                })
            }
        } catch {
            print("Failed to load completions: \(error)")
        }
    }
    
    private func saveTodayCompletions() {
        let calendar = Calendar.current
        userDefaults.set(calendar.startOfDay(for: Date()).description, forKey: kCompletionsDate)
        
        do {
            let dict = Dictionary(uniqueKeysWithValues: todayCompletions.compactMap { (key, value) in
                (key.uuidString, value)
            })
            let data = try JSONEncoder().encode(dict)
            userDefaults.set(data, forKey: kTodayCompletions)
        } catch {
            print("Failed to save completions: \(error)")
        }
    }
}
