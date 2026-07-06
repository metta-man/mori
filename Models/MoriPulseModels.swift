import Foundation

struct MoriDailyPulse: Identifiable, Codable, Equatable {
    var id: String { dateKey }
    var dateKey: String
    var generatedAt: Date
    var topics: [String]
    var cards: [MoriPulseCard]
    var topicPulses: [MoriTopicPulse]
    var sharedCards: [MoriPulseCard]
    var reclaimedMinutes: Int
    var screenTimeAttemptsAtGeneration: Int
    var screenTimeSavedMinutesAtGeneration: Int
    var isMock: Bool
    var localeIdentifier: String?

    private static let topicCardKinds: [MoriPulseCardKind] = [
        .worthKnowing,
        .worthIgnoring,
        .attentionTrap
    ]

    private static let sharedCardKinds: [MoriPulseCardKind] = [
        .resetAction,
        .reclaimedTime
    ]

    var displayTopicPulses: [MoriTopicPulse] {
        if !topicPulses.isEmpty {
            return topicPulses
        }

        let signalCards = cards.filter { Self.topicCardKinds.contains($0.kind) }
        let normalizedTopics = Self.normalizedTopicLabels(
            topics,
            topicPulses: [],
            legacyCards: signalCards
        )
        return Self.normalizedTopicPulses(
            [],
            topics: normalizedTopics,
            legacyCards: signalCards,
            reclaimedMinutes: reclaimedMinutes
        )
    }

    var displaySharedCards: [MoriPulseCard] {
        if !sharedCards.isEmpty {
            return sharedCards
        }

        return cards.filter { card in
            card.kind == .resetAction || card.kind == .reclaimedTime
        }
    }

    var isUsableForCurrentLocale: Bool {
        let localeIdentifier = MoriLocalePreference.load().resolvedLocaleIdentifier
        guard self.localeIdentifier == localeIdentifier else { return false }
        guard localeIdentifier != MoriLocalePreference.english.rawValue else { return true }

        return !flattenedCards.contains { Self.needsLocalizedFallback($0, localeIdentifier: localeIdentifier) }
    }

    private var flattenedCards: [MoriPulseCard] {
        let topicCards = topicPulses.flatMap(\.cards)
        let v2Cards = topicCards + sharedCards
        return v2Cards.isEmpty ? cards : v2Cards
    }

    init(
        dateKey: String,
        generatedAt: Date,
        topics: [String],
        cards: [MoriPulseCard] = [],
        topicPulses: [MoriTopicPulse] = [],
        sharedCards: [MoriPulseCard] = [],
        reclaimedMinutes: Int,
        screenTimeAttemptsAtGeneration: Int = 0,
        screenTimeSavedMinutesAtGeneration: Int = 0,
        isMock: Bool,
        localeIdentifier: String? = MoriLocalePreference.load().resolvedLocaleIdentifier
    ) {
        let normalizedTopics = Self.normalizedTopicLabels(
            topics,
            topicPulses: topicPulses,
            legacyCards: cards
        )
        let normalizedTopicPulses = Self.normalizedTopicPulses(
            topicPulses,
            topics: normalizedTopics,
            legacyCards: cards,
            reclaimedMinutes: reclaimedMinutes
        )
        let normalizedSharedCards = sharedCards.isEmpty ? Self.legacySharedCards(from: cards) : sharedCards

        self.dateKey = dateKey
        self.generatedAt = generatedAt
        self.topics = normalizedTopics
        self.topicPulses = normalizedTopicPulses
        self.sharedCards = normalizedSharedCards
        self.cards = normalizedTopicPulses.isEmpty && normalizedSharedCards.isEmpty
            ? cards
            : normalizedTopicPulses.flatMap(\.cards) + normalizedSharedCards
        self.reclaimedMinutes = reclaimedMinutes
        self.screenTimeAttemptsAtGeneration = max(0, screenTimeAttemptsAtGeneration)
        self.screenTimeSavedMinutesAtGeneration = max(0, screenTimeSavedMinutesAtGeneration)
        self.isMock = isMock
        self.localeIdentifier = localeIdentifier
    }

    enum CodingKeys: String, CodingKey {
        case dateKey
        case generatedAt
        case topics
        case cards
        case topicPulses
        case sharedCards
        case reclaimedMinutes
        case screenTimeAttemptsAtGeneration
        case screenTimeSavedMinutesAtGeneration
        case isMock
        case localeIdentifier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateKey = try container.decode(String.self, forKey: .dateKey)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        let decodedTopics = try container.decodeIfPresent([String].self, forKey: .topics) ?? []
        let decodedTopicPulses = try container.decodeIfPresent([MoriTopicPulse].self, forKey: .topicPulses) ?? []
        let decodedSharedCards = try container.decodeIfPresent([MoriPulseCard].self, forKey: .sharedCards) ?? []
        let legacyCards = try container.decodeIfPresent([MoriPulseCard].self, forKey: .cards) ?? []
        reclaimedMinutes = try container.decodeIfPresent(Int.self, forKey: .reclaimedMinutes) ?? 0
        screenTimeAttemptsAtGeneration = try container.decodeIfPresent(Int.self, forKey: .screenTimeAttemptsAtGeneration) ?? 0
        screenTimeSavedMinutesAtGeneration = try container.decodeIfPresent(Int.self, forKey: .screenTimeSavedMinutesAtGeneration) ?? 0
        isMock = try container.decodeIfPresent(Bool.self, forKey: .isMock) ?? false
        localeIdentifier = try container.decodeIfPresent(String.self, forKey: .localeIdentifier)
        topics = Self.normalizedTopicLabels(
            decodedTopics,
            topicPulses: decodedTopicPulses,
            legacyCards: legacyCards
        )
        topicPulses = Self.normalizedTopicPulses(
            decodedTopicPulses,
            topics: topics,
            legacyCards: legacyCards,
            reclaimedMinutes: reclaimedMinutes
        )
        sharedCards = decodedSharedCards.isEmpty ? Self.legacySharedCards(from: legacyCards) : decodedSharedCards
        cards = topicPulses.isEmpty && sharedCards.isEmpty
            ? legacyCards
            : topicPulses.flatMap(\.cards) + sharedCards
    }

    private static func normalizedTopicLabels(
        _ topics: [String],
        topicPulses: [MoriTopicPulse],
        legacyCards: [MoriPulseCard]
    ) -> [String] {
        let decodedTopics = uniqueCleaned(topics)
        if !decodedTopics.isEmpty {
            return decodedTopics
        }

        let pulseTopics = uniqueCleaned(topicPulses.map(\.topic))
        if !pulseTopics.isEmpty {
            return pulseTopics
        }

        return legacyCards.contains { topicCardKinds.contains($0.kind) }
            ? [MoriL10n.string("Today", defaultValue: "Today")]
            : []
    }

    private static func normalizedTopicPulses(
        _ rawTopicPulses: [MoriTopicPulse],
        topics: [String],
        legacyCards: [MoriPulseCard],
        reclaimedMinutes: Int
    ) -> [MoriTopicPulse] {
        guard !topics.isEmpty else { return [] }

        let legacyTopicCards = legacyCards.filter { topicCardKinds.contains($0.kind) }
        return topics.enumerated().map { index, topic in
            let rawPulse = rawPulseForTopic(rawTopicPulses, topics: topics, topic: topic, index: index)
            let rawCards = rawPulse?.cards ?? (rawTopicPulses.isEmpty && index == 0 ? legacyTopicCards : [])

            return MoriTopicPulse(
                topic: topic,
                symbolName: rawPulse?.symbolName,
                cards: normalizedCards(
                    for: topicCardKinds,
                    from: rawCards,
                    topic: topic,
                    reclaimedMinutes: reclaimedMinutes
                )
            )
        }
    }

    private static func rawPulseForTopic(
        _ rawTopicPulses: [MoriTopicPulse],
        topics: [String],
        topic: String,
        index: Int
    ) -> MoriTopicPulse? {
        let normalizedTopic = topic.lowercased()
        if let exact = rawTopicPulses.first(where: { $0.topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedTopic }) {
            return exact
        }

        guard rawTopicPulses.indices.contains(index) else { return nil }
        let indexed = rawTopicPulses[index]
        let indexedTopic = indexed.topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let namesAnotherSelectedTopic = !indexedTopic.isEmpty &&
            indexedTopic != normalizedTopic &&
            topics.contains { $0.lowercased() == indexedTopic }

        return namesAnotherSelectedTopic ? nil : indexed
    }

    private static func normalizedCards(
        for kinds: [MoriPulseCardKind],
        from cards: [MoriPulseCard],
        topic: String,
        reclaimedMinutes: Int
    ) -> [MoriPulseCard] {
        kinds.map { kind in
            cards.first { $0.kind == kind } ?? fallbackCard(kind: kind, topic: topic, reclaimedMinutes: reclaimedMinutes)
        }
    }

    private static func fallbackCard(
        kind: MoriPulseCardKind,
        topic: String,
        reclaimedMinutes: Int
    ) -> MoriPulseCard {
        switch kind {
        case .worthKnowing:
            return MoriPulseCard(
                kind: kind,
                headline: MoriL10n.string(
                    "pulse.fallback.worth_knowing.headline",
                    defaultValue: "%@: one useful signal is enough",
                    arguments: [topic]
                ),
                body: MoriL10n.string(
                    "pulse.fallback.worth_knowing.body",
                    defaultValue: "For %@, choose the update that changes a real decision and let the rest stay outside your day. Turn the broad topic into one bounded signal, then stop before the search becomes a loop.",
                    arguments: [topic]
                ),
                actionLabel: MoriL10n.string("pulse.action.mark_useful", defaultValue: "Mark useful"),
                followUpPrompts: [
                    MoriL10n.string("pulse.prompt.real_signal", defaultValue: "What is the real signal?"),
                    MoriL10n.string("pulse.prompt.next", defaultValue: "What should I do next?")
                ]
            )
        case .worthIgnoring:
            return MoriPulseCard(
                kind: kind,
                headline: MoriL10n.string(
                    "pulse.fallback.worth_ignoring.headline",
                    defaultValue: "%@: repeated commentary can wait",
                    arguments: [topic]
                ),
                body: MoriL10n.string(
                    "pulse.fallback.worth_ignoring.body",
                    defaultValue: "For %@, repeated commentary can wait when it does not change your next step. Keep the useful context and let reactions, rankings, and speculative takes pass without another check.",
                    arguments: [topic]
                ),
                actionLabel: MoriL10n.string("pulse.action.let_pass", defaultValue: "Let it pass"),
                followUpPrompts: [
                    MoriL10n.string("pulse.prompt.why_ignore", defaultValue: "Why ignore this?"),
                    MoriL10n.string("pulse.prompt.skip_today", defaultValue: "What can I skip today?")
                ]
            )
        case .attentionTrap:
            return MoriPulseCard(
                kind: kind,
                headline: MoriL10n.string(
                    "pulse.fallback.attention_trap.headline",
                    defaultValue: "%@: the sticky part is the refresh",
                    arguments: [topic]
                ),
                body: MoriL10n.string(
                    "pulse.fallback.attention_trap.body",
                    defaultValue: "For %@, the sticky part is often the refresh, not the signal itself. Name whether the pull is curiosity, tension, boredom, or avoidance before opening another source.",
                    arguments: [topic]
                ),
                actionLabel: MoriL10n.string("pulse.action.name_trap", defaultValue: "Name the trap"),
                followUpPrompts: [
                    MoriL10n.string("pulse.prompt.sticky", defaultValue: "What makes this sticky?"),
                    MoriL10n.string("pulse.prompt.step_away", defaultValue: "How do I step away?")
                ]
            )
        case .resetAction:
            return MoriPulseCard(
                kind: kind,
                headline: MoriL10n.string("pulse.fallback.reset.headline", defaultValue: "Close with one reset"),
                body: MoriL10n.string(
                    "pulse.fallback.reset.body",
                    defaultValue: "Choose one small reset before opening another source. Breathe slowly for one minute, write the next real action in a single sentence, then put the phone down for five minutes."
                ),
                actionLabel: MoriL10n.string("pulse.action.choose_practice", defaultValue: "Choose practice"),
                followUpPrompts: [
                    MoriL10n.string("pulse.prompt.practice", defaultValue: "Which reset fits now?"),
                    MoriL10n.string("pulse.prompt.smaller", defaultValue: "Make this smaller")
                ]
            )
        case .reclaimedTime:
            return MoriPulseCard(
                kind: kind,
                headline: MoriL10n.string(
                    "pulse.fallback.reclaimed.headline",
                    defaultValue: "About %d minutes reclaimed",
                    arguments: [reclaimedMinutes]
                ),
                body: MoriL10n.string(
                    "pulse.fallback.reclaimed.body",
                    defaultValue: "This Pulse turns an open-ended scan into a short signal check, protecting about %d minutes for something with a beginning and an end.",
                    arguments: [reclaimedMinutes]
                ),
                minutes: reclaimedMinutes,
                followUpPrompts: [
                    MoriL10n.string("pulse.prompt.protect_time", defaultValue: "How do I protect this time?"),
                    MoriL10n.string("pulse.prompt.time_source", defaultValue: "Where did this time come from?")
                ]
            )
        }
    }

    private static func legacySharedCards(from cards: [MoriPulseCard]) -> [MoriPulseCard] {
        sharedCardKinds.compactMap { kind in
            cards.first { $0.kind == kind }
        }
    }

    private static func uniqueCleaned(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var cleaned: [String] = []

        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            guard !trimmed.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            cleaned.append(trimmed)
        }

        return cleaned
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dateKey, forKey: .dateKey)
        try container.encode(generatedAt, forKey: .generatedAt)
        try container.encode(topics, forKey: .topics)
        try container.encode(flattenedCards, forKey: .cards)
        try container.encode(topicPulses, forKey: .topicPulses)
        try container.encode(sharedCards, forKey: .sharedCards)
        try container.encode(reclaimedMinutes, forKey: .reclaimedMinutes)
        try container.encode(screenTimeAttemptsAtGeneration, forKey: .screenTimeAttemptsAtGeneration)
        try container.encode(screenTimeSavedMinutesAtGeneration, forKey: .screenTimeSavedMinutesAtGeneration)
        try container.encode(isMock, forKey: .isMock)
        try container.encodeIfPresent(localeIdentifier, forKey: .localeIdentifier)
    }

    func taggedForCurrentLocale() -> MoriDailyPulse {
        var tagged = self
        tagged.localeIdentifier = MoriLocalePreference.load().resolvedLocaleIdentifier
        return tagged
    }

    func localizedForCurrentLocaleIfNeeded() -> MoriDailyPulse {
        var pulse = taggedForCurrentLocale()
        let localeIdentifier = MoriLocalePreference.load().resolvedLocaleIdentifier
        guard localeIdentifier != MoriLocalePreference.english.rawValue else { return pulse }

        pulse.topicPulses = pulse.topicPulses.map { topicPulse in
            MoriTopicPulse(
                topic: topicPulse.topic,
                symbolName: topicPulse.symbolName,
                cards: topicPulse.cards.map { card in
                    Self.localizedCardIfNeeded(card, topic: topicPulse.topic, reclaimedMinutes: pulse.reclaimedMinutes, localeIdentifier: localeIdentifier)
                }
            )
        }

        pulse.sharedCards = pulse.sharedCards.map { card in
            Self.localizedCardIfNeeded(card, topic: nil, reclaimedMinutes: pulse.reclaimedMinutes, localeIdentifier: localeIdentifier)
        }

        if !pulse.topicPulses.isEmpty || !pulse.sharedCards.isEmpty {
            pulse.cards = pulse.topicPulses.flatMap(\.cards) + pulse.sharedCards
        } else {
            let fallbackTopic = pulse.topics.first ?? MoriL10n.string("Today", defaultValue: "Today")
            pulse.cards = pulse.cards.map { card in
                Self.localizedCardIfNeeded(card, topic: fallbackTopic, reclaimedMinutes: pulse.reclaimedMinutes, localeIdentifier: localeIdentifier)
            }
        }

        return pulse
    }

    private static func localizedCardIfNeeded(
        _ card: MoriPulseCard,
        topic: String?,
        reclaimedMinutes: Int,
        localeIdentifier: String
    ) -> MoriPulseCard {
        guard needsLocalizedFallback(card, localeIdentifier: localeIdentifier) else {
            return card
        }

        var fallback = fallbackCard(
            kind: card.kind,
            topic: topic ?? MoriL10n.string("Today", defaultValue: "Today"),
            reclaimedMinutes: reclaimedMinutes
        )
        fallback.id = card.id
        return fallback
    }

    private static func needsLocalizedFallback(_ card: MoriPulseCard, localeIdentifier: String) -> Bool {
        guard localeIdentifier != MoriLocalePreference.english.rawValue else { return false }

        let text = [card.headline, card.body, card.actionLabel ?? ""].joined(separator: " ")
        let scalars = Array(text.unicodeScalars)
        let latinLetters = scalars.filter { scalar in
            (65...90).contains(Int(scalar.value)) || (97...122).contains(Int(scalar.value))
        }.count
        let cjkCharacters = scalars.filter { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }.count

        return latinLetters >= 24 && latinLetters > max(8, cjkCharacters * 2)
    }

    func card(with id: UUID) -> MoriPulseCard? {
        for topicPulse in topicPulses {
            if let card = topicPulse.cards.first(where: { $0.id == id }) {
                return card
            }
        }

        if let sharedCard = sharedCards.first(where: { $0.id == id }) {
            return sharedCard
        }

        return cards.first { $0.id == id }
    }

    func topic(for cardID: UUID) -> String? {
        topicPulses.first { topicPulse in
            topicPulse.cards.contains { $0.id == cardID }
        }?.topic
    }

    @discardableResult
    mutating func replaceCard(_ updatedCard: MoriPulseCard) -> Bool {
        var didReplace = false

        for topicIndex in topicPulses.indices {
            if let cardIndex = topicPulses[topicIndex].cards.firstIndex(where: { $0.id == updatedCard.id }) {
                topicPulses[topicIndex].cards[cardIndex] = updatedCard
                didReplace = true
            }
        }

        if let sharedIndex = sharedCards.firstIndex(where: { $0.id == updatedCard.id }) {
            sharedCards[sharedIndex] = updatedCard
            didReplace = true
        }

        if let legacyIndex = cards.firstIndex(where: { $0.id == updatedCard.id }) {
            cards[legacyIndex] = updatedCard
            didReplace = true
        }

        if didReplace, (!topicPulses.isEmpty || !sharedCards.isEmpty) {
            cards = topicPulses.flatMap(\.cards) + sharedCards
        }

        return didReplace
    }

}
