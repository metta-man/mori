import Foundation

protocol GratitudeUbiquitousKeyValueStoring: AnyObject {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
    @discardableResult func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: GratitudeUbiquitousKeyValueStoring {}

struct GratitudeEntryStore {
    static let live = GratitudeEntryStore()

    private enum Key {
        static let entries = "mori_gratitude_entries"
        static let iCloudEntries = "icloud_mori_gratitude_entries"
        static let localDeletionTombstone = "mori_gratitude_local_entries_deleted"
    }

    private let defaults: UserDefaults
    private let ubiquitousStore: any GratitudeUbiquitousKeyValueStoring
    private let notificationCenter: NotificationCenter
    private let cloudBackup: GratitudeCloudBackup
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        ubiquitousStore: any GratitudeUbiquitousKeyValueStoring = NSUbiquitousKeyValueStore.default,
        notificationCenter: NotificationCenter = .default,
        cloudBackup: GratitudeCloudBackup = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.ubiquitousStore = ubiquitousStore
        self.notificationCenter = notificationCenter
        self.cloudBackup = cloudBackup
        self.encoder = encoder
        self.decoder = decoder
    }

    func loadEntries() -> [GratitudeEntry] {
        ubiquitousStore.synchronize()

        guard let data = defaults.data(forKey: Key.entries),
              let decoded = try? decoder.decode([GratitudeEntry].self, from: data) else {
            // A local deletion is intentionally different from deleting the user's
            // separate iCloud backup. Keep the mirror intact, but do not silently
            // rehydrate data that the user just removed from this device.
            guard !defaults.bool(forKey: Key.localDeletionTombstone) else {
                return []
            }

            guard let iCloudData = ubiquitousStore.data(forKey: Key.iCloudEntries),
                  let iCloudDecoded = try? decoder.decode([GratitudeEntry].self, from: iCloudData) else {
                return []
            }

            defaults.set(iCloudData, forKey: Key.entries)
            return iCloudDecoded.sorted { $0.date > $1.date }
        }

        return decoded.sorted { $0.date > $1.date }
    }

    func saveEntries(_ entries: [GratitudeEntry]) {
        guard let data = try? encoder.encode(entries) else { return }

        defaults.removeObject(forKey: Key.localDeletionTombstone)
        defaults.set(data, forKey: Key.entries)
        ubiquitousStore.set(data, forKey: Key.iCloudEntries)
        ubiquitousStore.synchronize()

        let cloudBackup = cloudBackup
        Task {
            try? await cloudBackup.save(entries: entries)
        }
        MoriDataChangeEvent.gratitude.post(notificationCenter: notificationCenter)
    }

    func deleteLocalEntries() {
        defaults.removeObject(forKey: Key.entries)
        defaults.set(true, forKey: Key.localDeletionTombstone)
        MoriDataChangeEvent.gratitude.post(notificationCenter: notificationCenter)
    }

    func deleteICloudMirror() {
        ubiquitousStore.removeObject(forKey: Key.iCloudEntries)
        ubiquitousStore.synchronize()
    }

    func saveJournalEntry(
        on date: Date,
        content: String,
        promptType: GratitudePrompt? = nil,
        photoAttachments: [GratitudePhotoAttachment] = []
    ) -> Result<GratitudeEntry, GratitudeError> {
        let validation = GratitudeEntry.validate(content)
        guard validation.isValid else {
            return .failure(GratitudeError.validationFailed(validation.errorMessage ?? "Invalid content"))
        }

        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: date)
        var entries = loadEntries()
        let entry: GratitudeEntry

        if let existingIndex = entries.firstIndex(where: {
            calendar.isDate($0.date, inSameDayAs: entryDate) && $0.sourceID == nil
        }) {
            entries[existingIndex].content = content
            entries[existingIndex].promptType = promptType
            entries[existingIndex].photoAttachments = photoAttachments
            entries[existingIndex].updatedAt = Date()
            entry = entries[existingIndex]
        } else {
            entry = GratitudeEntry(
                date: entryDate,
                content: content,
                promptType: promptType,
                photoAttachments: photoAttachments
            )
            entries.insert(entry, at: 0)
        }

        entries.sort { $0.date > $1.date }
        saveEntries(entries)

        return .success(entry)
    }

    func saveDayLogEntry(
        on date: Date,
        tone: HabitDayTone,
        note: String?,
        trigger: String?,
        thought: String?,
        feeling: String?,
        responsePlan: String?,
        photoAttachments: [GratitudePhotoAttachment]? = nil
    ) {
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: date)
        let sourceID = dayLogSourceID(for: entryDate)
        var entries = loadEntries()
        let existingIndex = entries.firstIndex(where: { $0.sourceID == sourceID })
        let existingPhotos = existingIndex.map { entries[$0].photoAttachments } ?? []
        let resolvedPhotoAttachments = photoAttachments ?? existingPhotos
        let content = dayLogContent(
            tone: tone,
            note: note,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan,
            hasPhotos: !resolvedPhotoAttachments.isEmpty
        )

        if let existingIndex {
            if let photoAttachments, entries[existingIndex].photoAttachments != photoAttachments {
                let removedPhotos = entries[existingIndex].photoAttachments.filter { !photoAttachments.contains($0) }
                removedPhotos.forEach(GratitudePhotoStore.deletePhoto)
            }

            entries[existingIndex].content = content
            entries[existingIndex].sourceID = sourceID
            entries[existingIndex].photoAttachments = resolvedPhotoAttachments
            entries[existingIndex].updatedAt = Date()
        } else {
            entries.insert(
                GratitudeEntry(
                    date: entryDate,
                    content: content,
                    sourceID: sourceID,
                    photoAttachments: resolvedPhotoAttachments
                ),
                at: 0
            )
        }

        entries.sort { $0.date > $1.date }
        saveEntries(entries)
    }

    func dayLogEntry(on date: Date) -> GratitudeEntry? {
        let entryDate = Calendar.current.startOfDay(for: date)
        let sourceID = dayLogSourceID(for: entryDate)

        return loadEntries().first { $0.sourceID == sourceID }
    }

    func saveWeeklyIntention(_ intention: WeeklyIntention) {
        let entryDate = intention.completedAt ?? intention.createdAt
        let sourceID = "weekly-intention-\(intention.id.uuidString)"
        let content = intention.isCompleted
            ? "Week note: \(intention.action)"
            : "Planned week note: \(intention.action)"
        var entries = loadEntries()

        if let existingIndex = entries.firstIndex(where: { $0.sourceID == sourceID }) {
            let existingEntry = entries[existingIndex]
            entries[existingIndex] = GratitudeEntry(
                id: existingEntry.id,
                date: entryDate,
                content: content,
                promptType: nil,
                sourceID: sourceID,
                photoAttachments: existingEntry.photoAttachments,
                createdAt: existingEntry.createdAt,
                updatedAt: Date()
            )
        } else {
            entries.insert(
                GratitudeEntry(
                    date: entryDate,
                    content: content,
                    promptType: nil,
                    sourceID: sourceID
                ),
                at: 0
            )
        }

        entries.sort { $0.date > $1.date }

        saveEntries(entries)
    }

    func saveWeeklyIntentionCompletion(_ intention: WeeklyIntention) {
        saveWeeklyIntention(intention)
    }

    func saveDailySpark(_ spark: DailySparkEntry) {
        let sourceID = "daily-spark-\(spark.dateKey)"
        let content = """
        Focus: \(spark.focus)
        Action: \(spark.smallAction)
        Feel: \(spark.desiredFeeling)
        Avoid: \(spark.thingToAvoid)
        Plan: \(spark.ifThenPlan)
        """
        var entries = loadEntries()

        if let existingIndex = entries.firstIndex(where: { $0.sourceID == sourceID }) {
            let existingEntry = entries[existingIndex]
            entries[existingIndex] = GratitudeEntry(
                id: existingEntry.id,
                date: spark.updatedAt,
                content: content,
                promptType: nil,
                sourceID: sourceID,
                photoAttachments: existingEntry.photoAttachments,
                createdAt: existingEntry.createdAt,
                updatedAt: Date()
            )
        } else {
            entries.insert(
                GratitudeEntry(
                    date: spark.createdAt,
                    content: content,
                    promptType: nil,
                    sourceID: sourceID
                ),
                at: 0
            )
        }

        entries.sort { $0.date > $1.date }
        saveEntries(entries)
    }

    func restoreFromCloudBackup() async throws -> [GratitudeEntry] {
        try await cloudBackup.restore()
    }
}

extension GratitudeEntry {
    static let maxContentCharacterCount = 2_000

    static func loadAllStored() -> [GratitudeEntry] {
        GratitudeEntryStore.live.loadEntries()
    }

    static func persist(_ entries: [GratitudeEntry]) {
        GratitudeEntryStore.live.saveEntries(entries)
    }

    static func saveJournalEntry(
        on date: Date,
        content: String,
        promptType: GratitudePrompt? = nil,
        photoAttachments: [GratitudePhotoAttachment] = []
    ) -> Result<GratitudeEntry, GratitudeError> {
        GratitudeEntryStore.live.saveJournalEntry(
            on: date,
            content: content,
            promptType: promptType,
            photoAttachments: photoAttachments
        )
    }

    static func saveDayLogEntry(
        on date: Date,
        tone: HabitDayTone,
        note: String?,
        trigger: String?,
        thought: String?,
        feeling: String?,
        responsePlan: String?,
        photoAttachments: [GratitudePhotoAttachment]? = nil
    ) {
        GratitudeEntryStore.live.saveDayLogEntry(
            on: date,
            tone: tone,
            note: note,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan,
            photoAttachments: photoAttachments
        )
    }

    static func saveWeeklyIntention(_ intention: WeeklyIntention) {
        GratitudeEntryStore.live.saveWeeklyIntention(intention)
    }

    static func saveWeeklyIntentionCompletion(_ intention: WeeklyIntention) {
        GratitudeEntryStore.live.saveWeeklyIntentionCompletion(intention)
    }

    static func saveDailySpark(_ spark: DailySparkEntry) {
        GratitudeEntryStore.live.saveDailySpark(spark)
    }
}

private func dayLogDateKey(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

private func dayLogSourceID(for date: Date) -> String {
    "day-log-\(dayLogDateKey(for: date))"
}

private func dayLogContent(
    tone: HabitDayTone,
    note: String?,
    trigger: String?,
    thought: String?,
    feeling: String?,
    responsePlan: String?,
    hasPhotos: Bool
) -> String {
    var rows = ["\(tone.dayLogTitle) day logged."]

    if let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
        rows.append("Note: \(note)")
    }

    if let trigger = trigger?.trimmingCharacters(in: .whitespacesAndNewlines), !trigger.isEmpty {
        rows.append("Trigger: \(trigger)")
    }

    if let thought = thought?.trimmingCharacters(in: .whitespacesAndNewlines), !thought.isEmpty {
        rows.append("Thought: \(thought)")
    }

    if let feeling = feeling?.trimmingCharacters(in: .whitespacesAndNewlines), !feeling.isEmpty {
        rows.append("Feeling: \(feeling)")
    }

    if let responsePlan = responsePlan?.trimmingCharacters(in: .whitespacesAndNewlines), !responsePlan.isEmpty {
        rows.append("Next response: \(responsePlan)")
    }

    if hasPhotos {
        rows.append("Photo memory attached.")
    }

    return rows.joined(separator: "\n")
}

private extension HabitDayTone {
    var dayLogTitle: String {
        switch self {
        case .positive: return "Good"
        case .neutral: return "Neutral"
        case .negative: return "Difficult"
        }
    }
}
