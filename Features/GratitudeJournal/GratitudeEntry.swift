//
//  GratitudeEntry.swift
//  Mori
//
//  Data model for gratitude journal entries
//

import Foundation

// MARK: - Gratitude Entry Model
struct GratitudeEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var content: String
    var promptType: GratitudePrompt?
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        content: String,
        promptType: GratitudePrompt? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.content = content
        self.promptType = promptType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Gratitude Prompt Enum
enum GratitudePrompt: String, CaseIterable, Codable {
    case today = "Today I'm grateful for..."
    case smallJoy = "A small joy I noticed..."
    case moment = "I want to remember this moment..."
    case person = "Someone I appreciate today..."
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
        case .growth: return "Growth"
        }
    }
}

// MARK: - Gratitude Draft (for auto-save)
struct GratitudeDraft: Codable {
    var content: String
    var promptType: GratitudePrompt?
    var lastSaved: Date
    
    init(content: String = "", promptType: GratitudePrompt? = nil, lastSaved: Date = Date()) {
        self.content = content
        self.promptType = promptType
        self.lastSaved = lastSaved
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
        
        guard trimmed.count <= 500 else {
            return .invalid("Keep it concise (max 500 characters)")
        }
        
        return .valid
    }
}

// MARK: - Character Count Status
enum CharacterCountStatus {
    case normal
    case warning  // > 450
    case error    // > 500
    
    var color: String {
        switch self {
        case .normal: return "#888888"
        case .warning: return "#FF6B35"
        case .error: return "#DC3545"
        }
    }
    
    static func status(for count: Int) -> CharacterCountStatus {
        if count > 500 { return .error }
        if count > 450 { return .warning }
        return .normal
    }
}
