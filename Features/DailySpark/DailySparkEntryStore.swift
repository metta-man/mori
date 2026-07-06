import Foundation

struct DailySparkEntryStore {
    private enum Key {
        static let entries = "mori_daily_spark_entries"
    }

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.encoder = encoder
        self.decoder = decoder
    }

    func loadEntries() -> [DailySparkEntry] {
        guard let data = defaults.data(forKey: Key.entries),
              let decoded = try? decoder.decode([DailySparkEntry].self, from: data) else {
            return []
        }

        return decoded.sorted { $0.dateKey > $1.dateKey }
    }

    func saveEntries(_ entries: [DailySparkEntry]) {
        guard let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: Key.entries)
    }
}
