import Foundation

struct GratitudeJournalTransferStore {
    private let temporaryDirectory: URL
    private let now: () -> Date

    init(
        temporaryDirectory: URL = FileManager.default.temporaryDirectory,
        now: @escaping () -> Date = Date.init
    ) {
        self.temporaryDirectory = temporaryDirectory
        self.now = now
    }

    func export(entries: [GratitudeEntry]) throws -> URL {
        let backup = GratitudeJournalBackup(entries: entries)
        let data = try GratitudeCloudBackup.encode(backup)
        let url = temporaryDirectory.appendingPathComponent(exportFilename())
        try data.write(to: url, options: [.atomic])
        return url
    }

    func importEntries(from url: URL) throws -> [GratitudeEntry] {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let backup = try GratitudeCloudBackup.decode(data)
        return try backup.entries.map { try $0.gratitudeEntry() }
    }

    private func exportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "Mori-Log-\(formatter.string(from: now())).json"
    }
}
