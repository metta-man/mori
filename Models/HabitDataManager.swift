import Foundation

// MARK: - Habit Entry
struct HabitEntry: Identifiable, Codable {
    var habitName: String?
    let id: UUID
    let date: Date
    let tone: HabitDayTone
    let createdAt: Date
    var note: String?
    var trigger: String?
    var thought: String?
    var feeling: String?
    var responsePlan: String?
    var journalEmotionID: String?
    var journalContextID: String?
    var journalResponseID: String?

    var isPositive: Bool {
        tone == .positive
    }

    var hasPatternLog: Bool {
        [trigger, thought, feeling, responsePlan].contains { text in
            text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }

    init(
        habitName: String? = nil,
        id: UUID = UUID(),
        date: Date,
        tone: HabitDayTone,
        createdAt: Date,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil,
        journalEmotionID: String? = nil,
        journalContextID: String? = nil,
        journalResponseID: String? = nil
    ) {
        self.habitName = habitName
        self.id = id
        self.date = date
        self.tone = tone
        self.createdAt = createdAt
        self.note = note
        self.trigger = trigger
        self.thought = thought
        self.feeling = feeling
        self.responsePlan = responsePlan
        self.journalEmotionID = journalEmotionID
        self.journalContextID = journalContextID
        self.journalResponseID = journalResponseID
    }

    init(
        habitName: String? = nil,
        id: UUID = UUID(),
        date: Date,
        isPositive: Bool,
        createdAt: Date,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil,
        journalEmotionID: String? = nil,
        journalContextID: String? = nil,
        journalResponseID: String? = nil
    ) {
        self.init(
            habitName: habitName,
            id: id,
            date: date,
            tone: isPositive ? .positive : .negative,
            createdAt: createdAt,
            note: note,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan,
            journalEmotionID: journalEmotionID,
            journalContextID: journalContextID,
            journalResponseID: journalResponseID
        )
    }

    private enum CodingKeys: String, CodingKey {
        case habitName
        case id
        case date
        case tone
        case isPositive
        case createdAt
        case note
        case trigger
        case thought
        case feeling
        case responsePlan
        case journalEmotionID
        case journalContextID
        case journalResponseID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        habitName = try container.decodeIfPresent(String.self, forKey: .habitName)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        trigger = try container.decodeIfPresent(String.self, forKey: .trigger)
        thought = try container.decodeIfPresent(String.self, forKey: .thought)
        feeling = try container.decodeIfPresent(String.self, forKey: .feeling)
        responsePlan = try container.decodeIfPresent(String.self, forKey: .responsePlan)
        journalEmotionID = try container.decodeIfPresent(String.self, forKey: .journalEmotionID)
        journalContextID = try container.decodeIfPresent(String.self, forKey: .journalContextID)
        journalResponseID = try container.decodeIfPresent(String.self, forKey: .journalResponseID)

        if let decodedTone = try container.decodeIfPresent(HabitDayTone.self, forKey: .tone) {
            tone = decodedTone
        } else {
            let legacyIsPositive = try container.decodeIfPresent(Bool.self, forKey: .isPositive) ?? false
            tone = legacyIsPositive ? .positive : .negative
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(habitName, forKey: .habitName)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(tone, forKey: .tone)
        try container.encode(isPositive, forKey: .isPositive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(trigger, forKey: .trigger)
        try container.encodeIfPresent(thought, forKey: .thought)
        try container.encodeIfPresent(feeling, forKey: .feeling)
        try container.encodeIfPresent(responsePlan, forKey: .responsePlan)
        try container.encodeIfPresent(journalEmotionID, forKey: .journalEmotionID)
        try container.encodeIfPresent(journalContextID, forKey: .journalContextID)
        try container.encodeIfPresent(journalResponseID, forKey: .journalResponseID)
    }
}

enum HabitDayTone: String, CaseIterable, Codable, Identifiable {
    case positive
    case neutral
    case negative

    var id: String { rawValue }
}

enum JournalGuidedStep: Int, CaseIterable, Equatable {
    case emotion
    case context
    case response
    case details
}

enum JournalGuidedEmotion: String, CaseIterable, Codable, Identifiable {
    case calm
    case hopeful
    case anxious
    case tired
    case hurt
    case frustrated
    case unsure
    case unclear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm"
        case .hopeful: return "Hopeful"
        case .anxious: return "Anxious"
        case .tired: return "Tired"
        case .hurt: return "Hurt"
        case .frustrated: return "Frustrated"
        case .unsure: return "Unsure"
        case .unclear: return "Unclear"
        }
    }

    var tone: HabitDayTone {
        switch self {
        case .calm, .hopeful:
            return .positive
        case .tired, .unsure, .unclear:
            return .neutral
        case .anxious, .hurt, .frustrated:
            return .negative
        }
    }
}

enum JournalGuidedContext: String, CaseIterable, Codable, Identifiable {
    case workOrStudy = "work-or-study"
    case relationships
    case money
    case myBody = "my-body"
    case howISeeMyself = "how-i-see-myself"
    case notSure = "not-sure"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workOrStudy: return "Work or study"
        case .relationships: return "Relationships"
        case .money: return "Money"
        case .myBody: return "My body"
        case .howISeeMyself: return "How I see myself"
        case .notSure: return "I'm not sure"
        }
    }
}

enum JournalGuidedResponse: String, CaseIterable, Codable, Identifiable {
    case keepThisMoment = "keep-this-moment"
    case thankSomeone = "thank-someone"
    case continueThisDirection = "continue-this-direction"
    case makeRoomToRest = "make-room-to-rest"
    case takeOneSmallStep = "take-one-small-step"
    case askForSupport = "ask-for-support"
    case separateFactsFromGuesses = "separate-facts-from-guesses"
    case speakToMyselfLikeAFriend = "speak-to-myself-like-a-friend"
    case justRecordIt = "just-record-it"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepThisMoment: return "Keep this moment"
        case .thankSomeone: return "Thank someone"
        case .continueThisDirection: return "Continue this direction"
        case .makeRoomToRest: return "Make room to rest"
        case .takeOneSmallStep: return "Take one small step"
        case .askForSupport: return "Ask for support"
        case .separateFactsFromGuesses: return "Separate facts from guesses"
        case .speakToMyselfLikeAFriend: return "Speak to myself like a friend"
        case .justRecordIt: return "Just record it"
        }
    }

    static func options(for tone: HabitDayTone) -> [JournalGuidedResponse] {
        switch tone {
        case .positive:
            return [.keepThisMoment, .thankSomeone, .continueThisDirection, .justRecordIt]
        case .neutral:
            return [.makeRoomToRest, .takeOneSmallStep, .askForSupport, .justRecordIt]
        case .negative:
            return [
                .separateFactsFromGuesses,
                .speakToMyselfLikeAFriend,
                .takeOneSmallStep,
                .justRecordIt
            ]
        }
    }
}

struct JournalGuidedLegacyFields: Equatable {
    let trigger: String?
    let thought: String?
    let feeling: String?
    let responsePlan: String?
}

struct JournalGuidedCheckInState: Equatable {
    private(set) var emotion: JournalGuidedEmotion?
    private(set) var context: JournalGuidedContext?
    private(set) var response: JournalGuidedResponse?
    private(set) var currentStep: JournalGuidedStep

    init(
        emotion: JournalGuidedEmotion? = nil,
        context: JournalGuidedContext? = nil,
        response: JournalGuidedResponse? = nil,
        currentStep: JournalGuidedStep = .emotion
    ) {
        self.emotion = emotion
        self.context = context
        self.response = response
        self.currentStep = currentStep
        normalizeSelections()
    }

    init(restoring entry: HabitEntry?) {
        emotion = entry?.journalEmotionID.flatMap(JournalGuidedEmotion.init(rawValue:))
        context = entry?.journalContextID.flatMap(JournalGuidedContext.init(rawValue:))
        response = entry?.journalResponseID.flatMap(JournalGuidedResponse.init(rawValue:))
        currentStep = .emotion
        if let entry, emotion?.tone != entry.tone {
            emotion = nil
            context = nil
            response = nil
        }
        normalizeSelections()
        currentStep = firstIncompleteStep
    }

    var selectedTone: HabitDayTone? {
        emotion?.tone
    }

    var availableResponses: [JournalGuidedResponse] {
        guard let selectedTone else { return [] }
        return JournalGuidedResponse.options(for: selectedTone)
    }

    var canSave: Bool {
        emotion != nil && context != nil && response != nil
    }

    mutating func selectEmotion(_ emotion: JournalGuidedEmotion) {
        self.emotion = emotion
        if let response, !availableResponses.contains(response) {
            self.response = nil
        }
        currentStep = .context
    }

    mutating func selectContext(_ context: JournalGuidedContext) {
        self.context = context
        currentStep = .response
    }

    @discardableResult
    mutating func selectResponse(_ response: JournalGuidedResponse) -> Bool {
        guard availableResponses.contains(response) else { return false }
        self.response = response
        currentStep = .details
        return true
    }

    mutating func edit(_ step: JournalGuidedStep) {
        guard step != .details else { return }
        currentStep = step
    }

    func legacyFields(preserving existingEntry: HabitEntry?) -> JournalGuidedLegacyFields? {
        guard let emotion, let context, let response else { return nil }

        let trigger = existingEntry?.journalContextID == context.id
            ? existingEntry?.trigger ?? context.title
            : context.title
        let feeling = existingEntry?.journalEmotionID == emotion.id
            ? existingEntry?.feeling ?? emotion.title
            : emotion.title
        let responsePlan = existingEntry?.journalResponseID == response.id
            ? existingEntry?.responsePlan ?? response.title
            : response.title

        return JournalGuidedLegacyFields(
            trigger: trigger,
            thought: existingEntry?.thought,
            feeling: feeling,
            responsePlan: responsePlan
        )
    }

    private var firstIncompleteStep: JournalGuidedStep {
        if emotion == nil { return .emotion }
        if context == nil { return .context }
        if response == nil { return .response }
        return .details
    }

    private mutating func normalizeSelections() {
        guard emotion != nil else {
            context = nil
            response = nil
            return
        }

        guard context != nil else {
            response = nil
            return
        }

        if let response, !availableResponses.contains(response) {
            self.response = nil
        }
    }
}

// MARK: - Habit Streak
struct HabitStreak {
    let currentStreak: Int
    let longestStreak: Int
    let lastWeekTrend: TrendDirection
}

// MARK: - Monthly Stats
struct MonthlyStats {
    let month: Date
    let positiveDays: Int
    let neutralDays: Int
    let negativeDays: Int
    let bestStreak: Int
    let trend: TrendDirection
}

// MARK: - Trend Direction
enum TrendDirection {
    case improving
    case declining
    case stable
}

struct HabitTrackerDashboardSnapshot {
    let todayEntry: HabitEntry?
    let weeklyEntries: [HabitEntry]
    let streak: HabitStreak
    let monthlyStats: MonthlyStats

    static let empty = HabitTrackerDashboardSnapshot(
        todayEntry: nil,
        weeklyEntries: [],
        streak: HabitStreak(currentStreak: 0, longestStreak: 0, lastWeekTrend: .stable),
        monthlyStats: MonthlyStats(
            month: Date(),
            positiveDays: 0,
            neutralDays: 0,
            negativeDays: 0,
            bestStreak: 0,
            trend: .stable
        )
    )
}

// MARK: - Habit Data Manager
/// Coordinates habit tracking entry writes, queries, and derived summaries.
class HabitDataManager {
    static let shared = HabitDataManager()

    private let store: HabitEntryStore
    private let statisticsCalculator: HabitStatisticsCalculator

    init(
        store: HabitEntryStore = HabitEntryStore(),
        statisticsCalculator: HabitStatisticsCalculator = HabitStatisticsCalculator()
    ) {
        self.store = store
        self.statisticsCalculator = statisticsCalculator
    }

    // MARK: - Save Entry
    func saveEntry(
        habitName: String? = nil,
        on date: Date = Date(),
        tone: HabitDayTone,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil,
        journalEmotionID: String? = nil,
        journalContextID: String? = nil,
        journalResponseID: String? = nil
    ) -> HabitEntry {
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: date)
        var entries = getAllEntries()
        let existingEntry = entries.first { calendar.isDate($0.date, inSameDayAs: entryDate) }
        let normalizedEmotionID = Self.normalizedOptionalText(journalEmotionID)
        let normalizedContextID = Self.normalizedOptionalText(journalContextID)
        let normalizedResponseID = Self.normalizedOptionalText(journalResponseID)
        let hasIncomingGuidedSelection = [
            normalizedEmotionID,
            normalizedContextID,
            normalizedResponseID
        ].contains { $0 != nil }
        let existingEmotionMatchesTone = existingEntry?.journalEmotionID
            .flatMap(JournalGuidedEmotion.init(rawValue:))?.tone == tone
        let preservedEntry = !hasIncomingGuidedSelection && existingEmotionMatchesTone
            ? existingEntry
            : nil
        let entry = HabitEntry(
            habitName: habitName,
            id: UUID(),
            date: entryDate,
            tone: tone,
            createdAt: Date(),
            note: Self.normalizedOptionalText(note),
            trigger: Self.normalizedOptionalText(trigger),
            thought: Self.normalizedOptionalText(thought),
            feeling: Self.normalizedOptionalText(feeling),
            responsePlan: Self.normalizedOptionalText(responsePlan),
            journalEmotionID: normalizedEmotionID ?? preservedEntry?.journalEmotionID,
            journalContextID: normalizedContextID ?? preservedEntry?.journalContextID,
            journalResponseID: normalizedResponseID ?? preservedEntry?.journalResponseID
        )

        // Remove existing entry for the selected day if it exists.
        entries.removeAll { calendar.isDate($0.date, inSameDayAs: entryDate) }

        // Add new entry
        entries.append(entry)

        // Save
        saveEntries(entries)

        return entry
    }

    func saveEntry(habitName: String? = nil, isPositive: Bool) -> HabitEntry {
        saveEntry(habitName: habitName, tone: isPositive ? .positive : .negative)
    }

    // MARK: - Get Today's Entry
    func getTodayEntry() -> HabitEntry? {
        let entries = getAllEntries()
        let calendar = Calendar.current
        return entries.first { calendar.isDate($0.date, inSameDayAs: Date()) }
    }

    // MARK: - Get Weekly Entries
    func getWeeklyEntries() -> [HabitEntry] {
        weeklyEntries(from: getAllEntries(), now: Date(), calendar: .current)
    }

    func getEntries(from startDate: Date, to endDate: Date) -> [HabitEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        return getAllEntries().filter { entry in
            let entryDate = calendar.startOfDay(for: entry.date)
            return entryDate >= start && entryDate <= end
        }
    }

    // MARK: - Get Streak
    func getStreak() -> HabitStreak {
        statisticsCalculator.streak(for: getAllEntries())
    }

    // MARK: - Get Monthly Stats
    func getMonthlyStats() -> MonthlyStats {
        statisticsCalculator.monthlyStats(for: getAllEntries())
    }

    func dashboardSnapshot(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> HabitTrackerDashboardSnapshot {
        let entries = getAllEntries()
        let today = calendar.startOfDay(for: now)

        return HabitTrackerDashboardSnapshot(
            todayEntry: entries.first { calendar.isDate($0.date, inSameDayAs: today) },
            weeklyEntries: weeklyEntries(from: entries, now: now, calendar: calendar),
            streak: statisticsCalculator.streak(for: entries, now: now, calendar: calendar),
            monthlyStats: statisticsCalculator.monthlyStats(for: entries, now: now, calendar: calendar)
        )
    }

    // MARK: - Clear Entries
    func clearAllEntries() {
        store.clearEntries()
    }

    // MARK: - Private Methods
    private func getAllEntries() -> [HabitEntry] {
        store.loadEntries()
    }

    private func saveEntries(_ entries: [HabitEntry]) {
        store.saveEntries(entries)
    }

    private func weeklyEntries(
        from entries: [HabitEntry],
        now: Date,
        calendar: Calendar
    ) -> [HabitEntry] {
        let today = calendar.startOfDay(for: now)

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today) else {
                return nil
            }

            return entries.first { calendar.isDate($0.date, inSameDayAs: date) }
                ?? HabitEntry(
                    habitName: nil,
                    id: UUID(),
                    date: date,
                    tone: .neutral,
                    createdAt: Date(),
                    note: nil
                )
        }
    }

    private static func normalizedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
