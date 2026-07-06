import Foundation

struct DailySparkEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let dateKey: String
    var focus: String
    var smallAction: String
    var desiredFeeling: String
    var thingToAvoid: String
    var ifThenPlan: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dateKey: String = DailySparkEntry.dateKey(for: Date()),
        focus: String,
        smallAction: String,
        desiredFeeling: String,
        thingToAvoid: String,
        ifThenPlan: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dateKey = dateKey
        self.focus = focus
        self.smallAction = smallAction
        self.desiredFeeling = desiredFeeling
        self.thingToAvoid = thingToAvoid
        self.ifThenPlan = ifThenPlan
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case dateKey
        case focus
        case smallAction
        case desiredFeeling
        case thingToAvoid
        case ifThenPlan
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dateKey = try container.decode(String.self, forKey: .dateKey)
        focus = try container.decode(String.self, forKey: .focus)
        smallAction = try container.decodeIfPresent(String.self, forKey: .smallAction) ?? ""
        desiredFeeling = try container.decode(String.self, forKey: .desiredFeeling)
        thingToAvoid = try container.decode(String.self, forKey: .thingToAvoid)
        ifThenPlan = try container.decode(String.self, forKey: .ifThenPlan)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
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

    private let entryStore: DailySparkEntryStore

    private init(entryStore: DailySparkEntryStore = DailySparkEntryStore()) {
        self.entryStore = entryStore
        entries = entryStore.loadEntries()
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
        smallAction: String,
        desiredFeeling: String,
        thingToAvoid: String,
        ifThenPlan: String
    ) -> DailySparkEntry? {
        let focus = focus.trimmedForDailySpark
        let smallAction = smallAction.trimmedForDailySpark
        let desiredFeeling = desiredFeeling.trimmedForDailySpark
        let thingToAvoid = thingToAvoid.trimmedForDailySpark
        let ifThenPlan = ifThenPlan.trimmedForDailySpark

        guard !focus.isEmpty, !smallAction.isEmpty, !desiredFeeling.isEmpty, !thingToAvoid.isEmpty else {
            return nil
        }

        let key = DailySparkEntry.dateKey(for: Date())
        let plan = ifThenPlan.isEmpty ? Self.defaultIfThenPlan(for: thingToAvoid) : ifThenPlan
        let entry: DailySparkEntry

        if let index = entries.firstIndex(where: { $0.dateKey == key }) {
            var existing = entries[index]
            existing.focus = focus
            existing.smallAction = smallAction
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
                smallAction: smallAction,
                desiredFeeling: desiredFeeling,
                thingToAvoid: thingToAvoid,
                ifThenPlan: plan
            )
            entries.insert(entry, at: 0)
        }

        entries.sort { $0.dateKey > $1.dateKey }
        persist()
        GratitudeEntryStore.live.saveDailySpark(entry)
        MoriClarityStore.shared.recordDailyOnce(
            kind: .dailySpark,
            title: "Daily Spark",
            seeds: 2,
            minutes: 3,
            note: "Set the lens for today"
        )
        MoriDataChangeEvent.dailySpark.post()
        return entry
    }

    private func persist() {
        entryStore.saveEntries(entries)
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
