import CloudKit
import Foundation

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
            .appendingPathComponent("Mori-CloudKit-Log-\(UUID().uuidString).json")
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
