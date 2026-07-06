import Foundation

enum MoriDateKey {
    static func value(for date: Date = Date()) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

enum PulseTopic: String, CaseIterable, Codable, Identifiable {
    case mind
    case wellness
    case work
    case learning
    case relationships
    case creativity
    case finance
    case localTrends
    case ai
    case crypto
    case custom

    static var allCases: [PulseTopic] {
        [
            .mind,
            .wellness,
            .work,
            .learning,
            .relationships,
            .creativity,
            .finance,
            .localTrends,
            .ai,
            .custom
        ]
    }

    static var defaultSelected: Set<PulseTopic> {
        [.mind, .wellness, .work, .learning, .relationships, .creativity, .finance, .localTrends]
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mind: return MoriL10n.string("pulse_topic.mind", defaultValue: "Mind")
        case .wellness: return MoriL10n.string("pulse_topic.wellness", defaultValue: "Wellness")
        case .work: return MoriL10n.string("pulse_topic.work", defaultValue: "Work")
        case .learning: return MoriL10n.string("pulse_topic.learning", defaultValue: "Learning")
        case .relationships: return MoriL10n.string("pulse_topic.relationships", defaultValue: "Relationships")
        case .creativity: return MoriL10n.string("pulse_topic.creativity", defaultValue: "Creativity")
        case .finance: return MoriL10n.string("pulse_topic.finance", defaultValue: "Finance")
        case .localTrends: return MoriL10n.string("pulse_topic.local_trends", defaultValue: "Local trends")
        case .ai: return MoriL10n.string("pulse_topic.ai", defaultValue: "AI")
        case .crypto: return MoriL10n.string("pulse_topic.crypto", defaultValue: "Crypto")
        case .custom: return MoriL10n.string("pulse_topic.custom", defaultValue: "Custom")
        }
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .mind: return .pulse
        case .wellness: return .leaf
        case .work: return .focus
        case .learning: return .journal
        case .relationships: return .heart
        case .creativity: return .journal
        case .finance: return .pulse
        case .localTrends: return .roots
        case .ai: return .pulse
        case .crypto: return .pulse
        case .custom: return .settings
        }
    }

    var symbolName: String { icon.legacySystemName }
}

enum MoriCustomPulseTopicIcon: String, CaseIterable, Identifiable, Codable {
    case leaf = "leaf"
    case sparkles = "sparkles"
    case brain = "brain.head.profile"
    case heart = "heart"
    case book = "book"
    case briefcase = "briefcase"
    case chart = "chart.line.uptrend.xyaxis"
    case paint = "paintpalette"
    case globe = "globe.asia.australia"
    case location = "location"
    case tag = "tag"
    case star = "star"

    var id: String { rawValue }

    var icon: MoriBitmapIcon {
        switch self {
        case .leaf: return .leaf
        case .sparkles: return .pulse
        case .brain: return .pulse
        case .heart: return .heart
        case .book: return .journal
        case .briefcase: return .focus
        case .chart: return .pulse
        case .paint: return .journal
        case .globe: return .roots
        case .location: return .roots
        case .tag: return .settings
        case .star: return .leaf
        }
    }
}
