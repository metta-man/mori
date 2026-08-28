import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum LifeDomain: String, CaseIterable, Identifiable, Codable {
    case body
    case mind
    case love
    case craft
    case courage
    case service
    case wonder
    case rest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .body: return MoriL10n.string("domain.body", defaultValue: "Body")
        case .mind: return MoriL10n.string("domain.mind", defaultValue: "Mind")
        case .love: return MoriL10n.string("domain.love", defaultValue: "Love")
        case .craft: return MoriL10n.string("domain.craft", defaultValue: "Craft")
        case .courage: return MoriL10n.string("domain.courage", defaultValue: "Courage")
        case .service: return MoriL10n.string("domain.service", defaultValue: "Service")
        case .wonder: return MoriL10n.string("domain.wonder", defaultValue: "Wonder")
        case .rest: return MoriL10n.string("domain.rest", defaultValue: "Rest")
        }
    }

    var symbolName: String {
        switch self {
        case .body: return "figure.walk"
        case .mind: return "brain.head.profile"
        case .love: return "heart"
        case .craft: return "hammer"
        case .courage: return "flame"
        case .service: return "hands.sparkles"
        case .wonder: return "sparkles"
        case .rest: return "moon"
        }
    }

    var suggestedActions: [String] {
        switch self {
        case .body:
            return [
                MoriL10n.string("domain.body.action.walk", defaultValue: "Take a 10 minute walk"),
                MoriL10n.string("domain.body.action.stretch", defaultValue: "Stretch before bed"),
                MoriL10n.string("domain.body.action.water", defaultValue: "Drink water before coffee")
            ]
        case .mind:
            return [
                MoriL10n.string("domain.mind.action.read", defaultValue: "Read 5 pages"),
                MoriL10n.string("domain.mind.action.write", defaultValue: "Write 3 honest lines"),
                MoriL10n.string("domain.mind.action.sit", defaultValue: "Sit quietly for 2 minutes")
            ]
        case .love:
            return [
                MoriL10n.string("domain.love.action.message", defaultValue: "Send one warm message"),
                MoriL10n.string("domain.love.action.ask", defaultValue: "Ask someone how they really are"),
                MoriL10n.string("domain.love.action.dinner", defaultValue: "Make time for dinner together")
            ]
        case .craft:
            return [
                MoriL10n.string("domain.craft.action.hard_10", defaultValue: "Do the hard 10 minutes"),
                MoriL10n.string("domain.craft.action.ship", defaultValue: "Ship one small piece"),
                MoriL10n.string("domain.craft.action.practice", defaultValue: "Practice before checking feeds")
            ]
        case .courage:
            return [
                MoriL10n.string("domain.courage.action.conversation", defaultValue: "Have the postponed conversation"),
                MoriL10n.string("domain.courage.action.ask", defaultValue: "Ask for what you need"),
                MoriL10n.string("domain.courage.action.start", defaultValue: "Start before you feel ready")
            ]
        case .service:
            return [
                MoriL10n.string("domain.service.action.help", defaultValue: "Help without announcing it"),
                MoriL10n.string("domain.service.action.check", defaultValue: "Check on someone"),
                MoriL10n.string("domain.service.action.room", defaultValue: "Leave the room easier")
            ]
        case .wonder:
            return [
                MoriL10n.string("domain.wonder.action.notice", defaultValue: "Notice one beautiful thing"),
                MoriL10n.string("domain.wonder.action.outside", defaultValue: "Go outside without headphones"),
                MoriL10n.string("domain.wonder.action.photo", defaultValue: "Take one photo for memory")
            ]
        case .rest:
            return [
                MoriL10n.string("domain.rest.action.phone", defaultValue: "Put the phone down early"),
                MoriL10n.string("domain.rest.action.evening", defaultValue: "Make the evening quieter"),
                MoriL10n.string("domain.rest.action.sleep", defaultValue: "Protect 30 minutes of sleep")
            ]
        }
    }
}

struct WeeklyIntention: Codable, Equatable, Identifiable {
    let id: UUID
    let weekKey: String
    var domain: LifeDomain
    var action: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        weekKey: String,
        domain: LifeDomain,
        action: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.weekKey = weekKey
        self.domain = domain
        self.action = action
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case weekKey
        case domain
        case action
        case isCompleted
        case createdAt
        case completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        weekKey = try container.decode(String.self, forKey: .weekKey)
        domain = try container.decode(LifeDomain.self, forKey: .domain)
        action = try container.decode(String.self, forKey: .action)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}

class UserSettings: ObservableObject {
    private let store: UserSettingsStore
    private var isApplyingDataDeletionReset = false

    @Published var archiveStartDate: Date {
        didSet {
            guard !isApplyingDataDeletionReset else { return }
            store.saveArchiveStartDate(archiveStartDate)
            syncWidgetDefaults()
            AnalyticsManager.shared.trackArchiveStartDateSet(date: archiveStartDate)
        }
    }

    @Published var archiveSpanYears: Int {
        didSet {
            guard !isApplyingDataDeletionReset else { return }
            store.saveArchiveSpanYears(archiveSpanYears)
            syncWidgetDefaults()
        }
    }

    @Published var localePreference: MoriLocalePreference {
        didSet {
            store.saveLocalePreference(localePreference)
            syncWidgetDefaults()
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            guard !isApplyingDataDeletionReset else { return }
            store.saveHasCompletedOnboarding(hasCompletedOnboarding)
        }
    }

    @Published private(set) var weeklyIntentions: [WeeklyIntention] {
        didSet {
            guard !isApplyingDataDeletionReset else { return }
            persistWeeklyIntentions()
        }
    }

    var archiveYearIndex: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: archiveStartDate, to: Date())
        return components.year ?? 0
    }

    var totalWeeks: Int {
        archiveSpanYears * 52
    }

    var archiveWeeksElapsed: Int {
        let calendar = Calendar.current
        let now = Date()
        let currentArchiveYearStart = calendar.date(byAdding: .year, value: archiveYearIndex, to: archiveStartDate) ?? archiveStartDate
        let daysIntoCurrentArchiveYear = calendar.dateComponents([.day], from: currentArchiveYearStart, to: now).day ?? 0
        let weeksIntoCurrentArchiveYear = max(0, min(51, daysIntoCurrentArchiveYear / 7))
        return min(archiveYearIndex * 52 + weeksIntoCurrentArchiveYear, totalWeeks)
    }

    var currentWeekIndex: Int {
        min(archiveWeeksElapsed, max(totalWeeks - 1, 0))
    }

    var currentWeekKey: String {
        Self.weekKey(for: Date())
    }

    var weeklyIntention: WeeklyIntention? {
        activeWeeklyIntention
    }

    var activeWeeklyIntentions: [WeeklyIntention] {
        weeklyIntentions
            .filter { $0.weekKey == currentWeekKey }
            .sorted {
                if $0.isCompleted != $1.isCompleted {
                    return !$0.isCompleted
                }

                return $0.createdAt < $1.createdAt
            }
    }

    var activeWeeklyIntention: WeeklyIntention? {
        activeWeeklyIntentions.first
    }

    var activeWeeklyIntentionDomain: LifeDomain? {
        activeWeeklyIntentions.first?.domain
    }

    var hasCompletedWeeklyIntention: Bool {
        activeWeeklyIntentions.contains { $0.isCompleted }
    }

    init(store: UserSettingsStore = UserSettingsStore()) {
        self.store = store
        let snapshot = store.load()
        self.archiveStartDate = snapshot.archiveStartDate
        self.archiveSpanYears = snapshot.archiveSpanYears
        self.localePreference = snapshot.localePreference
        self.hasCompletedOnboarding = snapshot.hasCompletedOnboarding
        self.weeklyIntentions = snapshot.weeklyIntentions

        syncWidgetDefaults()
    }

    func setWeeklyIntention(domain: LifeDomain, action: String) {
        let trimmed = action.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let duplicate = activeWeeklyIntentions.contains {
            $0.domain == domain && $0.action.caseInsensitiveCompare(trimmed) == .orderedSame
        }
        guard !duplicate else { return }

        let intention = WeeklyIntention(
            weekKey: currentWeekKey,
            domain: domain,
            action: trimmed,
            isCompleted: false,
            createdAt: Date(),
            completedAt: nil
        )
        weeklyIntentions.append(intention)
        GratitudeEntryStore.live.saveWeeklyIntention(intention)
    }

    func completeWeeklyIntention() {
        guard let intention = activeWeeklyIntentions.first(where: { !$0.isCompleted }) else { return }
        completeWeeklyIntention(intention)
    }

    func completeWeeklyIntention(_ intention: WeeklyIntention) {
        guard let index = weeklyIntentions.firstIndex(where: { $0.id == intention.id }) else { return }
        var intention = weeklyIntentions[index]
        intention.isCompleted = true
        intention.completedAt = Date()
        weeklyIntentions[index] = intention
        GratitudeEntryStore.live.saveWeeklyIntentionCompletion(intention)
    }

    func reopenWeeklyIntention() {
        guard let intention = activeWeeklyIntentions.first(where: { $0.isCompleted }) else { return }
        reopenWeeklyIntention(intention)
    }

    func reopenWeeklyIntention(_ intention: WeeklyIntention) {
        guard let index = weeklyIntentions.firstIndex(where: { $0.id == intention.id }) else { return }
        var intention = weeklyIntentions[index]
        intention.isCompleted = false
        intention.completedAt = nil
        weeklyIntentions[index] = intention
    }

    func prepareForOnboardingAfterDataDeletion(
        sharedDefaults: UserDefaults = MoriSharedDefaults.shared
    ) {
        isApplyingDataDeletionReset = true
        archiveStartDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        archiveSpanYears = 80
        weeklyIntentions = []
        hasCompletedOnboarding = false
        isApplyingDataDeletionReset = false

        // Keep the selected locale stable, but ensure the reset values above
        // remain in-memory only until onboarding explicitly saves new choices.
        store.clearAllUserDataPreservingLocale()
        UserSettingsStore(defaults: sharedDefaults).clearAllUserDataPreservingLocale()
        sharedDefaults.removeObject(forKey: MoriWidgetContextSnapshot.defaultsKey)
    }

    private func syncWidgetDefaults() {
        let defaults = MoriSharedDefaults.shared
        defaults.set(archiveStartDate, forKey: "archiveStartDate")
        defaults.set(archiveSpanYears, forKey: "archiveSpanYears")
        defaults.set(localePreference.rawValue, forKey: MoriLocalePreference.defaultsKey)
        MoriWatchSettingsSync.shared.send(
            archiveStartDate: archiveStartDate,
            archiveSpanYears: archiveSpanYears,
            localePreference: localePreference.rawValue
        )
        Task { @MainActor in
            MoriWidgetContextPublisher.publish(settings: self, reloadTimelines: false)
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func persistWeeklyIntentions() {
        store.saveWeeklyIntentions(weeklyIntentions)
        Task { @MainActor in
            MoriWidgetContextPublisher.publish(settings: self)
        }
    }

    private static func weekKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? components.year ?? 0
        let week = components.weekOfYear ?? 0
        return "\(year)-\(week)"
    }
}
