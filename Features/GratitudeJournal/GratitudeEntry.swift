//
//  GratitudeEntry.swift
//  Mori
//
//  Data model for gratitude journal entries
//

import Foundation

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
    case dayLog
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


extension GratitudeEntry {
    var sourceKind: GratitudeEntrySourceKind {
        guard let sourceID else { return .journal }

        if sourceID.hasPrefix("day-log-") {
            return .dayLog
        }

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
        case .journal: return promptType?.shortName ?? "Log"
        case .dayLog: return "Daily Log"
        case .dailySpark: return "Daily Spark"
        case .weeklyIntention: return "Week Note"
        }
    }

    var sourceIcon: MoriBitmapIcon {
        switch sourceKind {
        case .journal: return .journal
        case .dayLog: return .timer
        case .dailySpark: return .pulse
        case .weeklyIntention: return .roots
        }
    }

    var displayContent: String {
        switch sourceKind {
        case .dailySpark:
            return content.removingDailySparkTitle
        case .journal, .dayLog, .weeklyIntention:
            return content
        }
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
