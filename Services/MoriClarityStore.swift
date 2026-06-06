import Foundation

@MainActor
final class MoriClarityStore: ObservableObject {
    static let shared = MoriClarityStore()

    @Published private(set) var actions: [MoriMindfulAction] = []
    @Published private(set) var selectedTopics: Set<PulseTopic> = PulseTopic.defaultSelected
    @Published private(set) var customTopics: [String] = []
    @Published private(set) var latestPulse: MoriDailyPulse?

    private let actionsKey = "mori_clarity_actions"
    private let topicsKey = "mori_pulse_selected_topics"
    private let customTopicsKey = "mori_pulse_custom_topics"
    private let latestPulseKey = "mori_latest_pulse"
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        actions = load([MoriMindfulAction].self, forKey: actionsKey) ?? []
        selectedTopics = sanitizedTopics(Set(load([PulseTopic].self, forKey: topicsKey) ?? Array(selectedTopics)))
        customTopics = load([String].self, forKey: customTopicsKey) ?? []
        if !customTopics.isEmpty {
            selectedTopics.insert(.custom)
        }
        persist(Array(selectedTopics), forKey: topicsKey)
        latestPulse = load(MoriDailyPulse.self, forKey: latestPulseKey)
        pruneOldActions()
    }

    var selectedTopicLabels: [String] {
        let defaults = PulseTopic.allCases
            .filter { selectedTopics.contains($0) }
            .filter { $0 != .custom && $0 != .crypto }
            .map(\.title)

        return defaults + customTopics
    }

    func toggleTopic(_ topic: PulseTopic) {
        if selectedTopics.contains(topic), selectedTopics.count > 1 {
            selectedTopics.remove(topic)
        } else {
            selectedTopics.insert(topic)
        }
        persist(Array(selectedTopics), forKey: topicsKey)
    }

    @discardableResult
    func recordPractice(_ practice: MoriPractice, note: String? = nil) -> MoriMindfulAction {
        record(
            kind: practice.kind,
            title: practice.title,
            seeds: practice.seeds,
            minutes: practice.minutes,
            note: note ?? practice.note
        )
    }

    func addCustomTopic(_ topic: String) {
        let trimmed = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !customTopics.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }

        customTopics.append(trimmed)
        selectedTopics.insert(.custom)
        persist(customTopics, forKey: customTopicsKey)
        persist(Array(selectedTopics), forKey: topicsKey)
    }

    func removeCustomTopic(_ topic: String) {
        customTopics.removeAll { $0 == topic }
        if customTopics.isEmpty {
            selectedTopics.remove(.custom)
        }
        persist(customTopics, forKey: customTopicsKey)
        persist(Array(selectedTopics), forKey: topicsKey)
    }

    func savePulse(_ pulse: MoriDailyPulse) {
        latestPulse = pulse
        persist(pulse, forKey: latestPulseKey)
    }

    @discardableResult
    func record(
        kind: MoriMindfulActionKind,
        title: String,
        seeds: Int,
        minutes: Int = 0,
        note: String? = nil
    ) -> MoriMindfulAction {
        let action = MoriMindfulAction(
            kind: kind,
            title: title,
            seeds: max(0, seeds),
            minutes: max(0, minutes),
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        actions.insert(action, at: 0)
        pruneOldActions()
        persist(actions, forKey: actionsKey)
        return action
    }

    func actions(for date: Date = Date()) -> [MoriMindfulAction] {
        let key = MoriDateKey.value(for: date)
        return actions.filter { $0.dateKey == key }
    }

    func nourishedDomains(for date: Date = Date()) -> [LifeDomain: Int] {
        var scores = Dictionary(uniqueKeysWithValues: LifeDomain.allCases.map { ($0, 0) })

        for action in actions(for: date) {
            let weight = max(1, action.seeds)
            for domain in MoriPractice.domains(for: action) {
                scores[domain, default: 0] += weight
            }
        }

        if Calendar.current.isDateInToday(date), DailySparkStore.shared.todayEntry != nil {
            scores[.mind, default: 0] += 1
            scores[.craft, default: 0] += 1
        }

        if Calendar.current.isDateInToday(date), HabitDataManager.shared.getTodayEntry() != nil {
            scores[.body, default: 0] += 1
            scores[.rest, default: 0] += 1
        }

        return scores
    }

    func suggestedPracticeForToday() -> MoriPractice {
        let scores = nourishedDomains()
        let total = scores.values.reduce(0, +)
        guard total > 0 else { return .quietPause }

        let lowestDomain = LifeDomain.allCases.min { lhs, rhs in
            scores[lhs, default: 0] < scores[rhs, default: 0]
        } ?? .rest

        return MoriPractice.suggested(for: lowestDomain)
    }

    func metrics(settings: UserSettings) -> MoriClarityMetrics {
        let todayActions = actions()
        let actionSeeds = todayActions.reduce(0) { $0 + $1.seeds }
        let quietMinutes = todayActions
            .filter {
                $0.kind == .quietTimer ||
                    $0.kind == .replacementAction ||
                    $0.kind == .urgeCheckIn ||
                    $0.kind == .breathingSession ||
                    $0.kind == .pomodoroSession
            }
            .reduce(0) { $0 + $1.minutes }
        let settleActions = todayActions.filter {
            $0.kind == .settleSession ||
                $0.kind == .breathingSession ||
                $0.kind == .pomodoroSession
        }
        let settleMinutes = settleActions.reduce(0) { $0 + $1.minutes }
        let pulseMinutes = latestPulse?.dateKey == MoriDateKey.value() ? latestPulse?.reclaimedMinutes ?? 0 : 0
        let reclaimedMinutes = todayActions
            .filter { $0.kind == .pulseRead || $0.kind == .resetAction }
            .reduce(pulseMinutes) { $0 + $1.minutes }

        let sparkBonus = DailySparkStore.shared.todayEntry == nil ? 0 : 2
        let habitBonus = habitScoreBonus()
        let weeklyBonus = settings.hasCompletedWeeklyIntention ? 4 : 0
        let seeds = actionSeeds + sparkBonus + habitBonus + weeklyBonus
        let clarityScore = min(100, 46 + seeds * 4 + min(16, quietMinutes / 2) + min(12, reclaimedMinutes / 5) + min(10, settleMinutes / 3))
        let bloom = min(1, Double(seeds) / 24.0 + (settings.hasCompletedWeeklyIntention ? 0.18 : 0))

        return MoriClarityMetrics(
            clarityScore: clarityScore,
            seedsToday: seeds,
            bloomProgress: bloom,
            rootsStreak: rootsStreak(settings: settings),
            quietMinutesToday: quietMinutes,
            settleMinutesToday: settleMinutes,
            settleSessionsToday: settleActions.count,
            reclaimedMinutesToday: reclaimedMinutes,
            mindfulActionsToday: todayActions.count + (DailySparkStore.shared.todayEntry == nil ? 0 : 1)
        )
    }

    func userContext(settings: UserSettings) -> MoriPulseUserContext {
        let metrics = metrics(settings: settings)
        return MoriPulseUserContext(
            clarityScore: metrics.clarityScore,
            seedsToday: metrics.seedsToday,
            quietMinutesToday: metrics.quietMinutesToday,
            reclaimedMinutesToday: metrics.reclaimedMinutesToday,
            weeklyProofCompleted: settings.hasCompletedWeeklyIntention
        )
    }

    func weeklyStats(settings: UserSettings) -> MoriWeeklyStats {
        let recent = actions.filter { action in
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return true }
            return action.createdAt >= cutoff
        }
        let metrics = metrics(settings: settings)
        return MoriWeeklyStats(
            seeds: recent.reduce(0) { $0 + $1.seeds },
            quietMinutes: recent.reduce(0) { $0 + ($1.kind == .quietTimer ? $1.minutes : 0) },
            reclaimedMinutes: recent.reduce(0) { $0 + ($1.kind == .pulseRead ? $1.minutes : 0) },
            rootsStreak: metrics.rootsStreak,
            clarityAverage: metrics.clarityScore
        )
    }

    private func rootsStreak(settings: UserSettings) -> Int {
        var streak = 0
        var date = Date()

        while hasPractice(on: date, settings: settings) {
            streak += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }

        return streak
    }

    private func hasPractice(on date: Date, settings: UserSettings) -> Bool {
        if !actions(for: date).isEmpty {
            return true
        }

        if Calendar.current.isDateInToday(date) {
            return DailySparkStore.shared.todayEntry != nil ||
                HabitDataManager.shared.getTodayEntry() != nil ||
                settings.hasCompletedWeeklyIntention
        }

        return false
    }

    private func habitScoreBonus() -> Int {
        guard let entry = HabitDataManager.shared.getTodayEntry() else { return 0 }
        switch entry.tone {
        case .positive: return 3
        case .neutral: return 1
        case .negative: return 1
        }
    }

    private func pruneOldActions() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) else { return }
        actions.removeAll { $0.createdAt < cutoff }
    }

    private func sanitizedTopics(_ topics: Set<PulseTopic>) -> Set<PulseTopic> {
        let sanitized = topics.subtracting([.crypto])
        return sanitized.isEmpty ? PulseTopic.defaultSelected : sanitized
    }

    private func persist<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        userDefaults.set(data, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
