import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum UserGender: String, CaseIterable, Identifiable {
    case female
    case male
    case unspecified

    var id: String { rawValue }

    var title: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        case .unspecified: return "Prefer not to say"
        }
    }
}

enum ClockTimeUnit: String, CaseIterable, Identifiable {
    case days
    case weeks
    case months
    case years

    var id: String { rawValue }

    var title: String {
        switch self {
        case .days: return "Days"
        case .weeks: return "Weeks"
        case .months: return "Months"
        case .years: return "Years"
        }
    }

    var singularLabel: String {
        switch self {
        case .days: return "day"
        case .weeks: return "week"
        case .months: return "month"
        case .years: return "year"
        }
    }

    var pluralLabel: String {
        switch self {
        case .days: return "days"
        case .weeks: return "weeks"
        case .months: return "months"
        case .years: return "years"
        }
    }
}

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
        case .body: return "Body"
        case .mind: return "Mind"
        case .love: return "Love"
        case .craft: return "Craft"
        case .courage: return "Courage"
        case .service: return "Service"
        case .wonder: return "Wonder"
        case .rest: return "Rest"
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
            return ["Take a 10 minute walk", "Stretch before bed", "Drink water before coffee"]
        case .mind:
            return ["Read 5 pages", "Write 3 honest lines", "Sit quietly for 2 minutes"]
        case .love:
            return ["Send one warm message", "Ask someone how they really are", "Make time for dinner together"]
        case .craft:
            return ["Do the hard 10 minutes", "Ship one small piece", "Practice before checking feeds"]
        case .courage:
            return ["Have the postponed conversation", "Ask for what you need", "Start before you feel ready"]
        case .service:
            return ["Help without announcing it", "Check on someone", "Leave the room easier"]
        case .wonder:
            return ["Notice one beautiful thing", "Go outside without headphones", "Take one photo for memory"]
        case .rest:
            return ["Put the phone down early", "Make the evening quieter", "Protect 30 minutes of sleep"]
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
    @Published var birthDate: Date {
        didSet {
            UserDefaults.standard.set(birthDate, forKey: "birthDate")
            syncWidgetDefaults()
            AnalyticsManager.shared.trackBirthDateSet(date: birthDate)
        }
    }
    
    @Published var lifeExpectancy: Int {
        didSet {
            UserDefaults.standard.set(lifeExpectancy, forKey: "lifeExpectancy")
            syncWidgetDefaults()
        }
    }

    @Published var gender: UserGender {
        didSet {
            UserDefaults.standard.set(gender.rawValue, forKey: "gender")
        }
    }

    @Published var locationCountryCode: String {
        didSet {
            UserDefaults.standard.set(locationCountryCode, forKey: "locationCountryCode")
        }
    }

    @Published var locationCountryName: String {
        didSet {
            UserDefaults.standard.set(locationCountryName, forKey: "locationCountryName")
        }
    }

    @Published var clockTimeUnit: ClockTimeUnit {
        didSet {
            UserDefaults.standard.set(clockTimeUnit.rawValue, forKey: "clockTimeUnit")
            syncWidgetDefaults()
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    @Published private(set) var weeklyIntentions: [WeeklyIntention] {
        didSet {
            persistWeeklyIntentions()
        }
    }
    
    var age: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: Date())
        return components.year ?? 0
    }
    
    var totalWeeks: Int {
        lifeExpectancy * 52
    }
    
    var weeksLived: Int {
        let calendar = Calendar.current
        let now = Date()
        let currentAgeStart = calendar.date(byAdding: .year, value: age, to: birthDate) ?? birthDate
        let daysIntoCurrentAge = calendar.dateComponents([.day], from: currentAgeStart, to: now).day ?? 0
        let weeksIntoCurrentAge = max(0, min(51, daysIntoCurrentAge / 7))
        return min(age * 52 + weeksIntoCurrentAge, totalWeeks)
    }
    
    var weeksRemaining: Int {
        max(totalWeeks - weeksLived, 0)
    }
    
    var percentageLived: Double {
        guard totalWeeks > 0 else { return 0 }
        return Double(weeksLived) / Double(totalWeeks)
    }
    
    var currentWeekIndex: Int {
        min(weeksLived, max(totalWeeks - 1, 0))
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
    
    init() {
        let savedDate = UserDefaults.standard.object(forKey: "birthDate") as? Date
        self.birthDate = savedDate ?? Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        
        let savedLifeExpectancy = UserDefaults.standard.integer(forKey: "lifeExpectancy")
        self.lifeExpectancy = savedLifeExpectancy > 0 ? savedLifeExpectancy : 80

        let savedGender = UserDefaults.standard.string(forKey: "gender")
            .flatMap(UserGender.init(rawValue:))
        self.gender = savedGender ?? .unspecified

        let defaultCountryCode = Locale.current.region?.identifier ?? "US"
        let savedCountryCode = UserDefaults.standard.string(forKey: "locationCountryCode")
        let initialCountryCode = savedCountryCode ?? defaultCountryCode
        self.locationCountryCode = initialCountryCode

        let savedCountryName = UserDefaults.standard.string(forKey: "locationCountryName")
        self.locationCountryName = savedCountryName ?? LifeExpectancyService.countryName(for: initialCountryCode)

        let savedClockTimeUnit = UserDefaults.standard.string(forKey: "clockTimeUnit")
            .flatMap(ClockTimeUnit.init(rawValue:))
        self.clockTimeUnit = savedClockTimeUnit ?? .days
        
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.weeklyIntentions = Self.loadWeeklyIntentions()

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
        GratitudeEntry.saveWeeklyIntention(intention)
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
        GratitudeEntry.saveWeeklyIntentionCompletion(intention)
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

    private func syncWidgetDefaults() {
        let defaults = MoriSharedDefaults.shared
        defaults.set(birthDate, forKey: "birthDate")
        defaults.set(lifeExpectancy, forKey: "lifeExpectancy")
        defaults.set(clockTimeUnit.rawValue, forKey: "clockTimeUnit")
        MoriWatchSettingsSync.shared.send(
            birthDate: birthDate,
            lifeExpectancy: lifeExpectancy,
            timeUnit: clockTimeUnit.rawValue
        )

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func persistWeeklyIntentions() {
        if let data = try? JSONEncoder().encode(weeklyIntentions) {
            UserDefaults.standard.set(data, forKey: "weeklyIntentions")
        } else {
            UserDefaults.standard.removeObject(forKey: "weeklyIntentions")
        }
    }

    private static func loadWeeklyIntentions() -> [WeeklyIntention] {
        if let data = UserDefaults.standard.data(forKey: "weeklyIntentions"),
           let decoded = try? JSONDecoder().decode([WeeklyIntention].self, from: data) {
            return decoded
        }

        guard let data = UserDefaults.standard.data(forKey: "weeklyIntention"),
              let legacy = try? JSONDecoder().decode(WeeklyIntention.self, from: data) else {
            return []
        }

        return [legacy]
    }

    private static func weekKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? components.year ?? 0
        let week = components.weekOfYear ?? 0
        return "\(year)-\(week)"
    }
}
