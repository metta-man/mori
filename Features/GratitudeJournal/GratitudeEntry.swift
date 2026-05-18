//
//  GratitudeEntry.swift
//  Mori
//
//  Data model for gratitude journal entries
//

import CloudKit
import Foundation

extension Notification.Name {
    static let gratitudeDataDidChange = Notification.Name("gratitudeDataDidChange")
}

// MARK: - Gratitude Entry Model
struct GratitudeEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var content: String
    var promptType: GratitudePrompt?
    var sourceID: String?
    var photoAttachments: [GratitudePhotoAttachment]
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case content
        case promptType
        case sourceID
        case photoAttachments
        case createdAt
        case updatedAt
    }
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        content: String,
        promptType: GratitudePrompt? = nil,
        sourceID: String? = nil,
        photoAttachments: [GratitudePhotoAttachment] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.content = content
        self.promptType = promptType
        self.sourceID = sourceID
        self.photoAttachments = photoAttachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        content = try container.decode(String.self, forKey: .content)
        promptType = try container.decodeIfPresent(GratitudePrompt.self, forKey: .promptType)
        sourceID = try container.decodeIfPresent(String.self, forKey: .sourceID)
        photoAttachments = try container.decodeIfPresent([GratitudePhotoAttachment].self, forKey: .photoAttachments) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

enum GratitudeEntrySourceKind: Equatable {
    case journal
    case dailySpark
    case weeklyIntention
}

struct GratitudePhotoAttachment: Identifiable, Codable, Equatable {
    let id: UUID
    let filename: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        filename: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.filename = filename
        self.createdAt = createdAt
    }

    var fileURL: URL {
        GratitudePhotoStore.photosDirectory.appendingPathComponent(filename)
    }
}

enum GratitudePhotoStore {
    static var photosDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("GratitudePhotos", isDirectory: true)
    }

    static func savePhotoData(_ data: Data) throws -> GratitudePhotoAttachment {
        try FileManager.default.createDirectory(
            at: photosDirectory,
            withIntermediateDirectories: true
        )

        let attachment = GratitudePhotoAttachment(filename: "\(UUID().uuidString).jpg")
        try data.write(to: attachment.fileURL, options: [.atomic])
        return attachment
    }

    static func saveImportedPhotoData(_ data: Data, preferredFilename: String?) throws -> GratitudePhotoAttachment {
        try FileManager.default.createDirectory(
            at: photosDirectory,
            withIntermediateDirectories: true
        )

        let cleanFilename = preferredFilename?
            .components(separatedBy: CharacterSet(charactersIn: "/:\\"))
            .joined(separator: "-")
        let filename = cleanFilename?.isEmpty == false ? cleanFilename! : "\(UUID().uuidString).jpg"
        let uniqueFilename = uniqueFilename(for: filename)
        let attachment = GratitudePhotoAttachment(filename: uniqueFilename)
        try data.write(to: attachment.fileURL, options: [.atomic])
        return attachment
    }

    static func deletePhoto(_ attachment: GratitudePhotoAttachment) {
        try? FileManager.default.removeItem(at: attachment.fileURL)
    }

    static func photoData(for attachment: GratitudePhotoAttachment) -> Data? {
        try? Data(contentsOf: attachment.fileURL)
    }

    private static func uniqueFilename(for filename: String) -> String {
        let candidate = photosDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: candidate.path) else {
            return filename
        }

        let ext = candidate.pathExtension
        let stem = candidate.deletingPathExtension().lastPathComponent
        let suffix = UUID().uuidString
        return ext.isEmpty ? "\(stem)-\(suffix)" : "\(stem)-\(suffix).\(ext)"
    }
}

extension GratitudeEntry {
    static let storageKey = "mori_gratitude_entries"
    static let iCloudStorageKey = "icloud_mori_gratitude_entries"
    static let maxContentCharacterCount = 2_000

    var sourceKind: GratitudeEntrySourceKind {
        guard let sourceID else { return .journal }

        if sourceID.hasPrefix("daily-spark-") {
            return .dailySpark
        }

        if sourceID.hasPrefix("weekly-intention-") {
            return .weeklyIntention
        }

        return .journal
    }

    var sourceLabel: String {
        switch sourceKind {
        case .journal: return promptType?.shortName ?? "Journal"
        case .dailySpark: return "Daily Spark"
        case .weeklyIntention: return "Weekly Proof"
        }
    }

    var sourceSymbolName: String {
        switch sourceKind {
        case .journal: return "book.closed"
        case .dailySpark: return "sparkle.magnifyingglass"
        case .weeklyIntention: return "square.grid.3x3"
        }
    }

    var displayContent: String {
        switch sourceKind {
        case .dailySpark:
            return content.removingDailySparkTitle
        case .journal, .weeklyIntention:
            return content
        }
    }

    static func loadAllStored() -> [GratitudeEntry] {
        NSUbiquitousKeyValueStore.default.synchronize()

        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([GratitudeEntry].self, from: data) else {
            guard let iCloudData = NSUbiquitousKeyValueStore.default.data(forKey: iCloudStorageKey),
                  let iCloudDecoded = try? JSONDecoder().decode([GratitudeEntry].self, from: iCloudData) else {
                return []
            }

            UserDefaults.standard.set(iCloudData, forKey: storageKey)
            return iCloudDecoded.sorted { $0.date > $1.date }
        }

        return decoded.sorted { $0.date > $1.date }
    }

    static func persist(_ entries: [GratitudeEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }

        UserDefaults.standard.set(data, forKey: storageKey)
        NSUbiquitousKeyValueStore.default.set(data, forKey: iCloudStorageKey)
        NSUbiquitousKeyValueStore.default.synchronize()
        Task {
            try? await GratitudeCloudBackup.shared.save(entries: entries)
        }
        NotificationCenter.default.post(name: .gratitudeDataDidChange, object: nil)
    }

    static func saveWeeklyIntention(_ intention: WeeklyIntention) {
        let entryDate = intention.completedAt ?? intention.createdAt
        let sourceID = "weekly-intention-\(intention.id.uuidString)"
        let content = intention.isCompleted
            ? "I made this week real: \(intention.action)"
            : "Little action for this week: \(intention.action)"
        var entries = loadAllStored()

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

        persist(entries)
    }

    static func saveWeeklyIntentionCompletion(_ intention: WeeklyIntention) {
        saveWeeklyIntention(intention)
    }

    static func saveDailySpark(_ spark: DailySparkEntry) {
        let sourceID = "daily-spark-\(spark.dateKey)"
        let content = """
        Focus: \(spark.focus)
        Feel: \(spark.desiredFeeling)
        Avoid: \(spark.thingToAvoid)
        Plan: \(spark.ifThenPlan)
        """
        var entries = loadAllStored()

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
        persist(entries)
    }
}

private extension String {
    var removingDailySparkTitle: String {
        var lines = components(separatedBy: .newlines)

        while let first = lines.first,
              first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.removeFirst()
        }

        if lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "Daily Spark" {
            lines.removeFirst()
        }

        let stripped = lines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return stripped.isEmpty ? self : stripped
    }
}

struct GratitudeJournalBackup: Codable {
    let exportedAt: Date
    let entries: [Entry]

    init(exportedAt: Date = Date(), entries: [GratitudeEntry]) {
        self.exportedAt = exportedAt
        self.entries = entries.map(Entry.init)
    }

    struct Entry: Codable {
        let id: UUID
        let date: Date
        let content: String
        let promptRawValue: String?
        let sourceID: String?
        let createdAt: Date
        let updatedAt: Date
        let photos: [Photo]

        init(_ entry: GratitudeEntry) {
            id = entry.id
            date = entry.date
            content = entry.content
            promptRawValue = entry.promptType?.rawValue
            sourceID = entry.sourceID
            createdAt = entry.createdAt
            updatedAt = entry.updatedAt
            photos = entry.photoAttachments.map(Photo.init)
        }

        func gratitudeEntry() throws -> GratitudeEntry {
            let attachments = try photos.compactMap { photo -> GratitudePhotoAttachment? in
                guard let base64Data = photo.base64Data,
                      let data = Data(base64Encoded: base64Data) else {
                    return nil
                }

                return try GratitudePhotoStore.saveImportedPhotoData(
                    data,
                    preferredFilename: photo.filename
                )
            }

            return GratitudeEntry(
                id: id,
                date: date,
                content: content,
                promptType: promptRawValue.flatMap(GratitudePrompt.init(rawValue:)),
                sourceID: sourceID,
                photoAttachments: attachments,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }

    struct Photo: Codable {
        let id: UUID
        let filename: String
        let createdAt: Date
        let base64Data: String?

        init(_ attachment: GratitudePhotoAttachment) {
            id = attachment.id
            filename = attachment.filename
            createdAt = attachment.createdAt
            base64Data = GratitudePhotoStore.photoData(for: attachment)?.base64EncodedString()
        }
    }
}

struct GratitudeCloudBackup {
    static let shared = GratitudeCloudBackup()

    private static let recordType = "JournalBackup"
    private static let recordName = "current"
    private static let backupAssetKey = "backupFile"
    private static let updatedAtKey = "updatedAt"

    private var database: CKDatabase {
        CKContainer.default().privateCloudDatabase
    }

    func save(entries: [GratitudeEntry]) async throws {
        let backup = GratitudeJournalBackup(entries: entries)
        let data = try encode(backup)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Mori-CloudKit-Journal-\(UUID().uuidString).json")
        try data.write(to: url, options: [.atomic])
        defer { try? FileManager.default.removeItem(at: url) }

        let recordID = CKRecord.ID(recordName: Self.recordName)
        let record: CKRecord

        do {
            record = try await database.record(for: recordID)
        } catch {
            record = CKRecord(recordType: Self.recordType, recordID: recordID)
        }

        record[Self.updatedAtKey] = Date() as CKRecordValue
        record[Self.backupAssetKey] = CKAsset(fileURL: url)
        _ = try await database.save(record)
    }

    func restore() async throws -> [GratitudeEntry] {
        let recordID = CKRecord.ID(recordName: Self.recordName)
        let record = try await database.record(for: recordID)

        guard let asset = record[Self.backupAssetKey] as? CKAsset,
              let url = asset.fileURL else {
            return []
        }

        let data = try Data(contentsOf: url)
        let backup = try decode(data)
        return try backup.entries.map { try $0.gratitudeEntry() }
    }

    static func encode(_ backup: GratitudeJournalBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> GratitudeJournalBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GratitudeJournalBackup.self, from: data)
    }

    private func encode(_ backup: GratitudeJournalBackup) throws -> Data {
        try Self.encode(backup)
    }

    private func decode(_ data: Data) throws -> GratitudeJournalBackup {
        try Self.decode(data)
    }
}

// MARK: - Gratitude Prompt Enum
enum GratitudePrompt: String, CaseIterable, Codable {
    case today = "Today I'm grateful for..."
    case smallJoy = "A small joy I noticed..."
    case moment = "I want to remember this moment..."
    case person = "Someone I appreciate today..."
    case reachOut = "Who would be warmed by hearing from me today?"
    case postponedConversation = "What conversation have I been postponing?"
    case growth = "Something I learned..."
    
    var displayText: String {
        rawValue
    }
    
    var shortName: String {
        switch self {
        case .today: return "Today"
        case .smallJoy: return "Joy"
        case .moment: return "Moment"
        case .person: return "Person"
        case .reachOut: return "Reach Out"
        case .postponedConversation: return "Conversation"
        case .growth: return "Growth"
        }
    }
}

// MARK: - Gratitude Draft (for auto-save)
struct GratitudeDraft: Codable {
    var content: String
    var promptType: GratitudePrompt?
    var photoAttachments: [GratitudePhotoAttachment]
    var entryDate: Date
    var lastSaved: Date

    enum CodingKeys: String, CodingKey {
        case content
        case promptType
        case photoAttachments
        case entryDate
        case lastSaved
    }
    
    init(
        content: String = "",
        promptType: GratitudePrompt? = nil,
        photoAttachments: [GratitudePhotoAttachment] = [],
        entryDate: Date = Date(),
        lastSaved: Date = Date()
    ) {
        self.content = content
        self.promptType = promptType
        self.photoAttachments = photoAttachments
        self.entryDate = entryDate
        self.lastSaved = lastSaved
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        content = try container.decode(String.self, forKey: .content)
        promptType = try container.decodeIfPresent(GratitudePrompt.self, forKey: .promptType)
        photoAttachments = try container.decodeIfPresent([GratitudePhotoAttachment].self, forKey: .photoAttachments) ?? []
        lastSaved = try container.decode(Date.self, forKey: .lastSaved)
        entryDate = try container.decodeIfPresent(Date.self, forKey: .entryDate) ?? lastSaved
    }
}

// MARK: - Validation Result
enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

// MARK: - Entry Validation
extension GratitudeEntry {
    static func validate(_ content: String) -> ValidationResult {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmed.count >= 10 else {
            return .invalid("Write a bit more (at least 10 characters)")
        }
        
        guard trimmed.count <= maxContentCharacterCount else {
            return .invalid("Keep it concise (max \(maxContentCharacterCount.formatted()) characters)")
        }
        
        return .valid
    }
}

// MARK: - Character Count Status
enum CharacterCountStatus {
    case normal
    case warning
    case error
    
    var color: String {
        switch self {
        case .normal: return "#888888"
        case .warning: return "#FF6B35"
        case .error: return "#DC3545"
        }
    }
    
    static func status(for count: Int) -> CharacterCountStatus {
        let maxCount = GratitudeEntry.maxContentCharacterCount
        if count > maxCount { return .error }
        if count > Int(Double(maxCount) * 0.9) { return .warning }
        return .normal
    }
}
