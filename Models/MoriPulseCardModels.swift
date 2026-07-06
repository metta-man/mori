import Foundation

enum MoriPulseCardKind: String, Codable, CaseIterable, Identifiable {
    case worthKnowing
    case worthIgnoring
    case attentionTrap
    case resetAction
    case reclaimedTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .worthKnowing: return MoriL10n.string("pulse.card_kind.worth_knowing", defaultValue: "Worth Knowing")
        case .worthIgnoring: return MoriL10n.string("pulse.card_kind.worth_ignoring", defaultValue: "Worth Ignoring")
        case .attentionTrap: return MoriL10n.string("pulse.card_kind.attention_trap", defaultValue: "Attention Trap")
        case .resetAction: return MoriL10n.string("pulse.card_kind.reset_action", defaultValue: "Reset Action")
        case .reclaimedTime: return MoriL10n.string("pulse.card_kind.reclaimed_time", defaultValue: "Reclaimed Time")
        }
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .worthKnowing: return .leaf
        case .worthIgnoring: return .quiet
        case .attentionTrap: return .lockShield
        case .resetAction: return .refresh
        case .reclaimedTime: return .timer
        }
    }

    var symbolName: String { icon.legacySystemName }
}

struct MoriPulseSource: Identifiable, Codable, Equatable {
    var title: String
    var url: String
    var site: String?
    var publishedAt: String?
    var snippet: String?

    var id: String {
        url.isEmpty ? title : url
    }
}

enum MoriPulseFollowUpRole: String, Codable, Equatable {
    case user
    case assistant
}

struct MoriPulseFollowUpMessage: Identifiable, Codable, Equatable {
    var id: UUID
    var role: MoriPulseFollowUpRole
    var content: String
    var createdAt: Date
    var sources: [MoriPulseSource]

    init(
        id: UUID = UUID(),
        role: MoriPulseFollowUpRole,
        content: String,
        createdAt: Date = Date(),
        sources: [MoriPulseSource] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.sources = sources
    }
}

struct MoriPulseCard: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: MoriPulseCardKind
    var headline: String
    var body: String
    var actionLabel: String?
    var minutes: Int?
    var sources: [MoriPulseSource]
    var followUpPrompts: [String]
    var followUpMessages: [MoriPulseFollowUpMessage]

    init(
        id: UUID = UUID(),
        kind: MoriPulseCardKind,
        headline: String,
        body: String,
        actionLabel: String? = nil,
        minutes: Int? = nil,
        sources: [MoriPulseSource] = [],
        followUpPrompts: [String] = [],
        followUpMessages: [MoriPulseFollowUpMessage] = []
    ) {
        self.id = id
        self.kind = kind
        self.headline = headline
        self.body = body
        self.actionLabel = actionLabel
        self.minutes = minutes
        self.sources = sources
        self.followUpPrompts = followUpPrompts
        self.followUpMessages = followUpMessages
    }

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case headline
        case body
        case actionLabel
        case minutes
        case sources
        case followUpPrompts
        case followUpMessages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try container.decode(MoriPulseCardKind.self, forKey: .kind)
        headline = try container.decode(String.self, forKey: .headline)
        body = try container.decode(String.self, forKey: .body)
        actionLabel = try container.decodeIfPresent(String.self, forKey: .actionLabel)
        minutes = try container.decodeIfPresent(Int.self, forKey: .minutes)
        sources = try container.decodeIfPresent([MoriPulseSource].self, forKey: .sources) ?? []
        followUpPrompts = try container.decodeIfPresent([String].self, forKey: .followUpPrompts) ?? []
        followUpMessages = try container.decodeIfPresent([MoriPulseFollowUpMessage].self, forKey: .followUpMessages) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(kind, forKey: .kind)
        try container.encode(headline, forKey: .headline)
        try container.encode(body, forKey: .body)
        try container.encodeIfPresent(actionLabel, forKey: .actionLabel)
        try container.encodeIfPresent(minutes, forKey: .minutes)
        try container.encode(sources, forKey: .sources)
        try container.encode(followUpPrompts, forKey: .followUpPrompts)
        try container.encode(followUpMessages, forKey: .followUpMessages)
    }
}

struct MoriTopicPulse: Identifiable, Codable, Equatable {
    var id: String { topic }
    var topic: String
    var symbolName: String?
    var cards: [MoriPulseCard]

    var icon: MoriBitmapIcon? {
        symbolName.map { MoriBitmapIcon.fromLegacySymbolName($0) }
    }

    func icon(fallback: MoriBitmapIcon) -> MoriBitmapIcon {
        icon ?? fallback
    }

    init(
        topic: String,
        symbolName: String? = nil,
        cards: [MoriPulseCard]
    ) {
        self.topic = topic
        self.symbolName = symbolName
        self.cards = cards
    }
}
