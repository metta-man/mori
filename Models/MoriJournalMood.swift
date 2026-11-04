import Foundation

/// Explicit self-report; never derived from journal prose or day tone.
enum MoriJournalValence: String, Codable, CaseIterable, Identifiable {
    case veryUnpleasant, unpleasant, neutral, pleasant, veryPleasant
    var id: String { rawValue }
    var value: Double {
        switch self {
        case .veryUnpleasant: return -1
        case .unpleasant: return -0.5
        case .neutral: return 0
        case .pleasant: return 0.5
        case .veryPleasant: return 1
        }
    }
    var title: String {
        switch self {
        case .veryUnpleasant: return "Very unpleasant"
        case .unpleasant: return "Unpleasant"
        case .neutral: return "Neutral"
        case .pleasant: return "Pleasant"
        case .veryPleasant: return "Very pleasant"
        }
    }
}

struct MoriJournalMood: Codable, Equatable, Identifiable {
    let id: UUID
    let recordedAt: Date
    let valence: MoriJournalValence
    let emotionID: String?
    let contextID: String?
    let version: Int
    var sharedVersion: Int?

    static func editing(_ previous: Self?, valence: MoriJournalValence,
                        emotionID: String?, contextID: String?, now: Date) -> Self {
        if let previous, previous.valence == valence,
           previous.emotionID == emotionID, previous.contextID == contextID { return previous }
        return Self(id: previous?.id ?? UUID(), recordedAt: previous?.recordedAt ?? now,
                    valence: valence, emotionID: emotionID, contextID: contextID,
                    version: (previous?.version ?? 0) + 1, sharedVersion: previous?.sharedVersion)
    }
    var needsSharing: Bool { sharedVersion != version }
    var syncIdentifier: String { "mori.journal.momentary.\(id.uuidString)" }
    // Only exact user-selected label matches; ambiguous feelings stay local.
    var healthLabelID: String? {
        ["calm", "hopeful", "anxious", "frustrated", "happy", "content", "grateful", "relieved", "sad"].contains(emotionID ?? "") ? emotionID : nil
    }
    var healthAssociationID: String? { contextID == "money" ? "money" : nil }
}

enum MoriJournalMoodEdit {
    case preserve
    case select(MoriJournalValence?)
    func applying(to previous: MoriJournalMood?, emotionID: String?, contextID: String?, now: Date) -> MoriJournalMood? {
        switch self {
        case .preserve: return previous
        case .select(nil): return nil
        case .select(let valence?):
            return .editing(previous, valence: valence, emotionID: emotionID, contextID: contextID, now: now)
        }
    }
}

/// A single projection used both by the disclosure and the Health writer.
struct MoriJournalMoodHealthPayload: Equatable {
    let recordedAt: Date
    let valence: MoriJournalValence
    let labelID: String?
    let associationID: String?
    let syncIdentifier: String
    let version: Int
}

extension MoriJournalMood {
    var healthPayload: MoriJournalMoodHealthPayload {
        .init(recordedAt: recordedAt, valence: valence, labelID: healthLabelID,
              associationID: healthAssociationID, syncIdentifier: syncIdentifier, version: version)
    }
}

struct MoriJournalMoodDraft: Equatable {
    let valence: MoriJournalValence?
    let emotionID: String?
    let contextID: String?
    func matches(_ mood: MoriJournalMood) -> Bool {
        valence == mood.valence && emotionID == mood.emotionID && contextID == mood.contextID
    }
}

/// Status belongs to one submitted observation revision, never to a later draft.
struct MoriJournalMoodSharePresentation {
    enum Outcome { case written, previouslyShared, failed }
    private(set) var mood: MoriJournalMood?
    private(set) var outcome: Outcome?
    mutating func begin(_ mood: MoriJournalMood) { self.mood = mood; outcome = nil }
    mutating func clear() { mood = nil; outcome = nil }
    mutating func clearIfChanged(draft: MoriJournalMoodDraft, persisted: MoriJournalMood?) {
        guard let mood else { return }
        if !draft.matches(mood) || persisted?.id != mood.id || persisted?.version != mood.version { clear() }
    }
    mutating func complete(_ submitted: MoriJournalMood, outcome: Outcome,
                           draft: MoriJournalMoodDraft, persisted: MoriJournalMood?) {
        guard mood?.id == submitted.id, mood?.version == submitted.version,
              draft.matches(submitted), persisted?.id == submitted.id,
              persisted?.version == submitted.version else { return }
        self.outcome = outcome
    }
}

/// Compact initial choices; old IDs remain selectable and restorable.
enum MoriJournalFeelingGroup: String, CaseIterable, Identifiable {
    case pleasant, neutral, difficult
    var id: String { rawValue }
    var choices: [JournalGuidedEmotion] {
        switch self {
        case .pleasant: return [.content, .grateful, .hopeful, .relieved]
        case .neutral: return [.tired, .unsure, .unclear]
        case .difficult: return [.anxious, .hurt, .frustrated]
        }
    }
    static let primary: [JournalGuidedEmotion] = [.happy, .calm, .okay, .sad]
    static func additionalChoices(in group: Self, selected: JournalGuidedEmotion?) -> [JournalGuidedEmotion] {
        let visible = visiblePrimary(selected: selected)
        return group.choices.filter { !visible.contains($0) }
    }
    static func visiblePrimary(selected: JournalGuidedEmotion?) -> [JournalGuidedEmotion] {
        guard let selected, !primary.contains(selected) else { return primary }
        return primary + [selected]
    }
}
