import Foundation

extension Notification.Name {
    static let dailySparkDataDidChange = Notification.Name("dailySparkDataDidChange")
}

struct DailySparkEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let dateKey: String
    var focus: String
    var desiredFeeling: String
    var thingToAvoid: String
    var ifThenPlan: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dateKey: String = DailySparkEntry.dateKey(for: Date()),
        focus: String,
        desiredFeeling: String,
        thingToAvoid: String,
        ifThenPlan: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dateKey = dateKey
        self.focus = focus
        self.desiredFeeling = desiredFeeling
        self.thingToAvoid = thingToAvoid
        self.ifThenPlan = ifThenPlan
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func dateKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

@MainActor
final class DailySparkStore: ObservableObject {
    static let shared = DailySparkStore()

    @Published private(set) var entries: [DailySparkEntry] = []

    private let storageKey = "mori_daily_spark_entries"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {
        entries = Self.loadStoredEntries(storageKey: storageKey, decoder: decoder)
    }

    var todayEntry: DailySparkEntry? {
        entry(for: Date())
    }

    func entry(for date: Date) -> DailySparkEntry? {
        let key = DailySparkEntry.dateKey(for: date)
        return entries.first { $0.dateKey == key }
    }

    @discardableResult
    func saveToday(
        focus: String,
        desiredFeeling: String,
        thingToAvoid: String,
        ifThenPlan: String
    ) -> DailySparkEntry? {
        let focus = focus.trimmedForDailySpark
        let desiredFeeling = desiredFeeling.trimmedForDailySpark
        let thingToAvoid = thingToAvoid.trimmedForDailySpark
        let ifThenPlan = ifThenPlan.trimmedForDailySpark

        guard !focus.isEmpty, !desiredFeeling.isEmpty, !thingToAvoid.isEmpty else {
            return nil
        }

        let key = DailySparkEntry.dateKey(for: Date())
        let plan = ifThenPlan.isEmpty ? Self.defaultIfThenPlan(for: thingToAvoid) : ifThenPlan
        let entry: DailySparkEntry

        if let index = entries.firstIndex(where: { $0.dateKey == key }) {
            var existing = entries[index]
            existing.focus = focus
            existing.desiredFeeling = desiredFeeling
            existing.thingToAvoid = thingToAvoid
            existing.ifThenPlan = plan
            existing.updatedAt = Date()
            entries[index] = existing
            entry = existing
        } else {
            entry = DailySparkEntry(
                dateKey: key,
                focus: focus,
                desiredFeeling: desiredFeeling,
                thingToAvoid: thingToAvoid,
                ifThenPlan: plan
            )
            entries.insert(entry, at: 0)
        }

        entries.sort { $0.dateKey > $1.dateKey }
        persist()
        GratitudeEntry.saveDailySpark(entry)
        NotificationCenter.default.post(name: .dailySparkDataDidChange, object: nil)
        return entry
    }

    private func persist() {
        guard let data = try? encoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static func loadStoredEntries(storageKey: String, decoder: JSONDecoder) -> [DailySparkEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? decoder.decode([DailySparkEntry].self, from: data) else {
            return []
        }

        return decoded.sorted { $0.dateKey > $1.dateKey }
    }

    private static func defaultIfThenPlan(for thingToAvoid: String) -> String {
        "If I notice \(thingToAvoid), I will pause and come back to today's focus."
    }
}

private extension String {
    var trimmedForDailySpark: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
