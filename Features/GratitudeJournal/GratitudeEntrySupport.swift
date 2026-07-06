import Foundation

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
