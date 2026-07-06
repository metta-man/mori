import Foundation

struct HabitEntryStore {
    private enum Key {
        static let entries = "habit_entries"
    }

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        notificationCenter: NotificationCenter = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        self.encoder = encoder
        self.decoder = decoder
    }

    func loadEntries() -> [HabitEntry] {
        guard let data = defaults.data(forKey: Key.entries) else {
            return []
        }

        do {
            return try decoder.decode([HabitEntry].self, from: data)
        } catch {
            return []
        }
    }

    func saveEntries(_ entries: [HabitEntry]) {
        do {
            let data = try encoder.encode(entries)
            defaults.set(data, forKey: Key.entries)
            notifyDataDidChange()
        } catch {
            print("Failed to save habit entries: \(error)")
        }
    }

    func clearEntries() {
        defaults.removeObject(forKey: Key.entries)
        notifyDataDidChange()
    }

    private func notifyDataDidChange() {
        MoriDataChangeEvent.habit.post(notificationCenter: notificationCenter)
    }
}
