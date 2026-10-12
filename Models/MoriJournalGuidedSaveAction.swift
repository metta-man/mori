import Foundation

/// The screen and tests execute this same command; mood selection cannot fall back
/// to the legacy pattern-log path's default preserve behavior.
struct MoriJournalGuidedSaveAction {
    let tone: HabitDayTone
    let note: String
    let legacyFields: JournalGuidedLegacyFields
    let emotionID: String?
    let emotionWasSkipped: Bool
    let contextID: String
    let responseID: String
    let recordedAt: Date
    let moodEdit: MoriJournalMoodEdit

    init?(checkIn: JournalGuidedCheckInState, existingEntry: HabitEntry?,
          note: String, valence: MoriJournalValence?, recordedAt: Date = Date()) {
        guard checkIn.canSave, let context = checkIn.context,
              let response = checkIn.response,
              let fields = checkIn.legacyFields(preserving: existingEntry) else { return nil }
        tone = checkIn.selectedTone ?? .neutral; self.note = note; legacyFields = fields
        emotionID = checkIn.emotion?.id; emotionWasSkipped = checkIn.emotionWasSkipped
        contextID = context.id; responseID = response.id
        self.recordedAt = recordedAt
        moodEdit = .select(valence)
    }
    func save(using manager: HabitDataManager) -> HabitEntry {
        manager.saveEntry(tone: tone, note: note, trigger: legacyFields.trigger,
            thought: legacyFields.thought, feeling: legacyFields.feeling,
            responsePlan: legacyFields.responsePlan, journalEmotionID: emotionID,
            journalContextID: contextID, journalResponseID: responseID, journalEmotionWasSkipped: emotionWasSkipped, moodEdit: moodEdit, moodRecordedAt: recordedAt)
    }
}
