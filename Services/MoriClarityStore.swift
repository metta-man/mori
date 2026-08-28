import Foundation

@MainActor
final class MoriClarityStore: ObservableObject {
    static let shared = MoriClarityStore()

    @Published private(set) var actions: [MoriMindfulAction] = []
    @Published private(set) var selectedTopics: Set<PulseTopic> = PulseTopic.defaultSelected
    @Published private(set) var customTopics: [String] = []
    @Published private(set) var customTopicSymbols: [String: String] = [:]
    @Published private(set) var topicOrder: [String] = []
    @Published private(set) var latestPulse: MoriDailyPulse?

    let maxActiveTopicCount = 5
    private let firstSeedBonus = 2
    private let persistence = MoriClarityPersistence.standard

    private init() {
        actions = load([MoriMindfulAction].self, forKey: MoriClarityPersistence.Key.actions) ?? []
        selectedTopics = MoriClarityTopicPlanner.sanitizedTopics(
            Set(load([PulseTopic].self, forKey: MoriClarityPersistence.Key.selectedTopics) ?? Array(selectedTopics))
        )
        customTopics = load([String].self, forKey: MoriClarityPersistence.Key.customTopics) ?? []
        customTopicSymbols = load([String: String].self, forKey: MoriClarityPersistence.Key.customTopicSymbols) ?? [:]
        if !customTopics.isEmpty {
            selectedTopics.insert(.custom)
        }
        topicOrder = normalizedTopicOrder(load([String].self, forKey: MoriClarityPersistence.Key.topicOrder) ?? [])
        persist(Array(selectedTopics), forKey: MoriClarityPersistence.Key.selectedTopics)
        persist(topicOrder, forKey: MoriClarityPersistence.Key.topicOrder)
        latestPulse = load(MoriDailyPulse.self, forKey: MoriClarityPersistence.Key.latestPulse)
        pruneOldActions()
    }

    var selectedTopicLabels: [String] {
        let selected = Set(selectedTopicLabelSet)
        return topicOrder.filter { selected.contains($0) }
    }

    var activeTopicLabels: [String] {
        Array(selectedTopicLabels.prefix(maxActiveTopicCount))
    }

    var queuedTopicLabels: [String] {
        Array(selectedTopicLabels.dropFirst(maxActiveTopicCount))
    }

    func toggleTopic(_ topic: PulseTopic) {
        if selectedTopics.contains(topic), selectedTopicLabels.count > 1 {
            selectedTopics.remove(topic)
        } else {
            selectedTopics.insert(topic)
        }
        topicOrder = normalizedTopicOrder(topicOrder)
        persist(Array(selectedTopics), forKey: MoriClarityPersistence.Key.selectedTopics)
        persist(topicOrder, forKey: MoriClarityPersistence.Key.topicOrder)
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

    @discardableResult
    func recordDailyOnce(
        kind: MoriMindfulActionKind,
        title: String,
        seeds: Int,
        minutes: Int = 0,
        note: String? = nil,
        date: Date = Date()
    ) -> MoriMindfulAction? {
        let key = MoriDateKey.value(for: date)
        let alreadyRecorded = actions.contains { action in
            action.dateKey == key &&
            action.kind == kind &&
            action.title.caseInsensitiveCompare(title) == .orderedSame
        }

        guard !alreadyRecorded else { return nil }

        return record(
            kind: kind,
            title: title,
            seeds: seeds,
            minutes: minutes,
            note: note,
            createdAt: date
        )
    }

    func addCustomTopic(_ topic: String, symbolName: String = MoriCustomPulseTopicIcon.leaf.rawValue) {
        let trimmed = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !customTopics.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }

        customTopics.append(trimmed)
        customTopicSymbols[trimmed] = symbolName
        selectedTopics.insert(.custom)
        topicOrder = normalizedTopicOrder(topicOrder + [trimmed])
        persist(customTopics, forKey: MoriClarityPersistence.Key.customTopics)
        persist(customTopicSymbols, forKey: MoriClarityPersistence.Key.customTopicSymbols)
        persist(Array(selectedTopics), forKey: MoriClarityPersistence.Key.selectedTopics)
        persist(topicOrder, forKey: MoriClarityPersistence.Key.topicOrder)
    }

    func addCustomTopic(_ topic: String, icon: MoriCustomPulseTopicIcon) {
        addCustomTopic(topic, symbolName: icon.rawValue)
    }

    func removeCustomTopic(_ topic: String) {
        customTopics.removeAll { $0 == topic }
        customTopicSymbols.removeValue(forKey: topic)
        if customTopics.isEmpty {
            selectedTopics.remove(.custom)
        }
        topicOrder.removeAll { $0.caseInsensitiveCompare(topic) == .orderedSame }
        topicOrder = normalizedTopicOrder(topicOrder)
        persist(customTopics, forKey: MoriClarityPersistence.Key.customTopics)
        persist(customTopicSymbols, forKey: MoriClarityPersistence.Key.customTopicSymbols)
        persist(Array(selectedTopics), forKey: MoriClarityPersistence.Key.selectedTopics)
        persist(topicOrder, forKey: MoriClarityPersistence.Key.topicOrder)
    }

    func symbolName(forCustomTopic topic: String) -> String {
        customTopicSymbols[topic] ?? MoriCustomPulseTopicIcon.leaf.rawValue
    }

    func icon(forCustomTopic topic: String) -> MoriBitmapIcon {
        MoriBitmapIcon.fromLegacySymbolName(symbolName(forCustomTopic: topic))
    }

    func symbolName(forTopicLabel topic: String) -> String {
        if let defaultTopic = PulseTopic.allCases.first(where: { $0.title.caseInsensitiveCompare(topic) == .orderedSame }) {
            return defaultTopic.symbolName
        }

        return symbolName(forCustomTopic: topic)
    }

    func icon(forTopicLabel topic: String) -> MoriBitmapIcon {
        if let defaultTopic = PulseTopic.allCases.first(where: { $0.title.caseInsensitiveCompare(topic) == .orderedSame }) {
            return defaultTopic.icon
        }

        return icon(forCustomTopic: topic)
    }

    func promoteTopic(_ topic: String) {
        guard selectedTopicLabelSet.contains(where: { $0.caseInsensitiveCompare(topic) == .orderedSame }) else { return }
        topicOrder.removeAll { $0.caseInsensitiveCompare(topic) == .orderedSame }
        topicOrder.insert(topic, at: 0)
        topicOrder = normalizedTopicOrder(topicOrder)
        persist(topicOrder, forKey: MoriClarityPersistence.Key.topicOrder)
    }

    func savePulse(_ pulse: MoriDailyPulse) {
        latestPulse = pulse
        persist(pulse, forKey: MoriClarityPersistence.Key.latestPulse)
        MoriWidgetContextPublisher.publish(clarityStore: self)
    }

    func clearAllForDataDeletion() {
        actions = []
        selectedTopics = PulseTopic.defaultSelected
        customTopics = []
        customTopicSymbols = [:]
        topicOrder = normalizedTopicOrder([])
        latestPulse = nil
        persistence.clearAll()
    }

    @discardableResult
    func record(
        kind: MoriMindfulActionKind,
        title: String,
        seeds: Int,
        minutes: Int = 0,
        note: String? = nil,
        createdAt: Date = Date()
    ) -> MoriMindfulAction {
        let baseSeeds = max(0, seeds)
        let bonus = firstSeedBonusIfNeeded(for: baseSeeds, on: createdAt)
        let action = MoriMindfulAction(
            kind: kind,
            title: title,
            seeds: baseSeeds + bonus,
            minutes: max(0, minutes),
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: createdAt
        )
        actions.insert(action, at: 0)
        pruneOldActions()
        persist(actions, forKey: MoriClarityPersistence.Key.actions)
        MoriWidgetContextPublisher.publish(clarityStore: self)
        return action
    }

    func actions(for date: Date = Date()) -> [MoriMindfulAction] {
        let key = MoriDateKey.value(for: date)
        return actions.filter { $0.dateKey == key }
    }

    func metrics(settings: UserSettings) -> MoriClarityMetrics {
        MoriClarityStatsCalculator.metrics(
            settings: settings,
            actions: actions,
            latestPulse: latestPulse
        )
    }

    func userContext(settings: UserSettings) -> MoriPulseUserContext {
        let metrics = metrics(settings: settings)
        return MoriPulseUserContext(
            clarityScore: metrics.clarityScore,
            seedsToday: metrics.seedsToday,
            quietMinutesToday: metrics.quietMinutesToday,
            reclaimedMinutesToday: metrics.reclaimedMinutesToday,
            screenTimeAttemptsToday: metrics.screenTimeAttemptsToday,
            screenTimeSavedMinutesToday: metrics.screenTimeSavedMinutesToday,
            weeklyProofCompleted: false
        )
    }

    func weeklyStats(settings: UserSettings) -> MoriWeeklyStats {
        MoriClarityStatsCalculator.weeklyStats(
            settings: settings,
            actions: actions,
            latestPulse: latestPulse
        )
    }

    func growthSummaries(settings: UserSettings) -> [MoriGrowthPeriodSummary] {
        MoriClarityStatsCalculator.growthSummaries(
            settings: settings,
            actions: actions,
            latestPulse: latestPulse
        )
    }

    func clarityTrend(days: Int = 7, settings: UserSettings) -> [MoriClarityTrendPoint] {
        MoriClarityStatsCalculator.clarityTrend(
            days: days,
            settings: settings,
            actions: actions,
            latestPulse: latestPulse
        )
    }

    private func pruneOldActions() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) else { return }
        actions.removeAll { $0.createdAt < cutoff }
    }

    private func firstSeedBonusIfNeeded(for baseSeeds: Int, on date: Date) -> Int {
        guard baseSeeds > 0 else { return 0 }
        let key = MoriDateKey.value(for: date)
        let hasSeedToday = actions.contains { action in
            action.dateKey == key && action.seeds > 0
        }
        return hasSeedToday ? 0 : firstSeedBonus
    }

    private var selectedTopicLabelSet: [String] {
        MoriClarityTopicPlanner.selectedTopicLabelSet(
            selectedTopics: selectedTopics,
            customTopics: customTopics
        )
    }

    private func normalizedTopicOrder(_ order: [String]) -> [String] {
        MoriClarityTopicPlanner.normalizedTopicOrder(order, customTopics: customTopics)
    }

    private func persist<T: Encodable>(_ value: T, forKey key: String) {
        persistence.save(value, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        persistence.load(type, forKey: key)
    }
}
