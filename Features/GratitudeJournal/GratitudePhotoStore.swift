import Foundation

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
