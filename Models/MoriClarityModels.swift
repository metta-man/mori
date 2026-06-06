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
        case .mind: return "Mind"
        case .wellness: return "Wellness"
        case .work: return "Work"
        case .learning: return "Learning"
        case .relationships: return "Relationships"
        case .creativity: return "Creativity"
        case .finance: return "Finance"
        case .localTrends: return "Local trends"
        case .ai: return "AI"
        case .crypto: return "Crypto"
        case .custom: return "Custom"
        }
    }

    var symbolName: String {
        switch self {
        case .mind: return "brain.head.profile"
        case .wellness: return "leaf"
        case .work: return "briefcase"
        case .learning: return "book"
        case .relationships: return "heart"
        case .creativity: return "paintpalette"
        case .finance: return "chart.line.uptrend.xyaxis"
        case .localTrends: return "location"
        case .ai: return "sparkles"
        case .crypto: return "bitcoinsign.circle"
        case .custom: return "slider.horizontal.3"
        }
    }
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
}

enum MoriPracticeRoute: String, Equatable {
    case quickComplete
    case breathing
    case settle
    case quietMode
    case journal
    case dailyCheckIn
    case focusCycle
}

struct MoriPractice: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let durationText: String
    let minutes: Int
    let seeds: Int
    let symbolName: String
    let kind: MoriMindfulActionKind
    let note: String
    let domains: [LifeDomain]
    let route: MoriPracticeRoute

    var domainText: String {
        domains.map(\.title).joined(separator: " / ")
    }

    var seedText: String {
        "+\(seeds) Seed\(seeds == 1 ? "" : "s")"
    }

    static let breatheMinute = MoriPractice(
        id: "breathe-minute",
        title: "Breathe",
        description: "1 min nervous system reset",
        durationText: "1 min",
        minutes: 1,
        seeds: 1,
        symbolName: "wind",
        kind: .breathingSession,
        note: "Completed a short breath reset",
        domains: [.body, .rest],
        route: .breathing
    )

    static let settleThree = MoriPractice(
        id: "settle-three",
        title: "Settle",
        description: "3 min return to presence",
        durationText: "3 min",
        minutes: 3,
        seeds: 1,
        symbolName: "figure.mind.and.body",
        kind: .settleSession,
        note: "Completed a short Settle practice",
        domains: [.rest, .wonder],
        route: .settle
    )

    static let quietNote = MoriPractice(
        id: "quiet-note",
        title: "Journal",
        description: "private reflection",
        durationText: "3 min",
        minutes: 3,
        seeds: 1,
        symbolName: "book.closed",
        kind: .journal,
        note: "Wrote a quiet note",
        domains: [.craft, .mind],
        route: .journal
    )

    static let dailyCheckIn = MoriPractice(
        id: "daily-check-in",
        title: "Daily Check-In",
        description: "tone, pattern, and memory",
        durationText: "2 min",
        minutes: 2,
        seeds: 1,
        symbolName: "plus.forwardslash.minus",
        kind: .dailyFocus,
        note: "Completed a daily check-in",
        domains: [.body, .rest, .love],
        route: .dailyCheckIn
    )

    static let focusFifteen = MoriPractice(
        id: "focus-fifteen",
        title: "Focus Cycle",
        description: "15 min deep work",
        durationText: "15 min",
        minutes: 15,
        seeds: 2,
        symbolName: "timer",
        kind: .pomodoroSession,
        note: "Completed a short focus cycle",
        domains: [.craft, .mind],
        route: .focusCycle
    )

    static let quietPause = MoriPractice(
        id: "quiet-pause",
        title: "Quiet Mode",
        description: "pause before scrolling",
        durationText: "2 min",
        minutes: 2,
        seeds: 1,
        symbolName: "moon.stars",
        kind: .quietTimer,
        note: "Paused before scrolling",
        domains: [.rest, .body, .mind],
        route: .quietMode
    )

    static let walkReset = MoriPractice(
        id: "walk-reset",
        title: "Walk / Offline Reset",
        description: "leave the screen",
        durationText: "8 min",
        minutes: 8,
        seeds: 2,
        symbolName: "figure.walk",
        kind: .replacementAction,
        note: "Took an offline reset",
        domains: [.body, .rest],
        route: .quickComplete
    )

    static let plantSeedChoices: [MoriPractice] = [
        .breatheMinute,
        .settleThree,
        .quietNote,
        .dailyCheckIn,
        .focusFifteen,
        .quietPause,
        .walkReset
    ]

    static let practiceGarden: [MoriPractice] = [
        .breatheMinute,
        .settleThree,
        .quietNote,
        .dailyCheckIn,
        .quietPause,
        .focusFifteen,
        .walkReset
    ]

    static func suggested(for domain: LifeDomain) -> MoriPractice {
        switch domain {
        case .body:
            return .walkReset
        case .mind:
            return .quietNote
        case .love:
            return .dailyCheckIn
        case .craft:
            return .focusFifteen
        case .courage:
            return .quietNote
        case .service:
            return .dailyCheckIn
        case .wonder:
            return .settleThree
        case .rest:
            return .quietPause
        }
    }

    static func domains(for action: MoriMindfulAction) -> [LifeDomain] {
        let loweredTitle = action.title.lowercased()

        if let practice = plantSeedChoices.first(where: { practice in
            loweredTitle.contains(practice.title.lowercased()) || action.note == practice.note
        }) {
            return practice.domains
        }

        switch action.kind {
        case .pulseRead:
            return [.mind]
        case .resetAction:
            return [.rest, .body]
        case .quietTimer:
            return quietPause.domains
        case .settleSession:
            return settleThree.domains
        case .breathingSession:
            return breatheMinute.domains
        case .pomodoroSession:
            return focusFifteen.domains
        case .urgeCheckIn:
            return [.rest, .mind]
        case .replacementAction:
            if loweredTitle.contains("walk") || loweredTitle.contains("offline") {
                return walkReset.domains
            }
            return [.body, .rest]
        case .dailyFocus:
            return dailyCheckIn.domains
        case .dailySpark:
            return [.craft, .mind]
        case .lifeGridProof:
            return [.mind]
        case .journal:
            return quietNote.domains
        case .screenTimeLimitKept:
            return [.craft, .mind]
        case .screenTimeThresholdReached:
            return [.rest, .mind]
        }
    }
}

enum MoriPulseCardKind: String, Codable, CaseIterable, Identifiable {
    case worthKnowing
    case worthIgnoring
    case attentionTrap
    case resetAction
    case reclaimedTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .worthKnowing: return "Worth Knowing"
        case .worthIgnoring: return "Worth Ignoring"
        case .attentionTrap: return "Attention Trap"
        case .resetAction: return "Reset Action"
        case .reclaimedTime: return "Reclaimed Time"
        }
    }

    var symbolName: String {
        switch self {
        case .worthKnowing: return "checkmark.seal"
        case .worthIgnoring: return "eye.slash"
        case .attentionTrap: return "hand.raised"
        case .resetAction: return "leaf.arrow.circlepath"
        case .reclaimedTime: return "clock.arrow.circlepath"
        }
    }
}

struct MoriPulseCard: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: MoriPulseCardKind
    var headline: String
    var body: String
    var actionLabel: String?
    var minutes: Int?

    init(
        id: UUID = UUID(),
        kind: MoriPulseCardKind,
        headline: String,
        body: String,
        actionLabel: String? = nil,
        minutes: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.headline = headline
        self.body = body
        self.actionLabel = actionLabel
        self.minutes = minutes
    }
}

struct MoriDailyPulse: Identifiable, Codable, Equatable {
    var id: String { dateKey }
    var dateKey: String
    var generatedAt: Date
    var topics: [String]
    var cards: [MoriPulseCard]
    var reclaimedMinutes: Int
    var isMock: Bool

    static func mock(
        topics: [String] = ["Mind", "Wellness", "Learning"],
        date: Date = Date()
    ) -> MoriDailyPulse {
        MoriDailyPulse(
            dateKey: MoriDateKey.value(for: date),
            generatedAt: date,
            topics: topics,
            cards: [
                MoriPulseCard(
                    kind: .worthKnowing,
                    headline: "Your attention is easier to protect early",
                    body: "The useful signal today is to choose the first screen intentionally, then let the rest wait.",
                    actionLabel: "Mark useful"
                ),
                MoriPulseCard(
                    kind: .worthIgnoring,
                    headline: "Urgent commentary can wait",
                    body: "Skip loops that turn ordinary updates into a reason to keep checking.",
                    actionLabel: "Let it pass"
                ),
                MoriPulseCard(
                    kind: .attentionTrap,
                    headline: "The next refresh may not answer the real need",
                    body: "If the urge is boredom, tension, or avoidance, name that before opening another feed.",
                    actionLabel: "Use Quiet Mode"
                ),
                MoriPulseCard(
                    kind: .resetAction,
                    headline: "Plant a practice Seed",
                    body: "Take one minute of breathing, write a quiet note, or step outside before returning to the day.",
                    actionLabel: "Choose practice"
                ),
                MoriPulseCard(
                    kind: .reclaimedTime,
                    headline: "About 28 minutes reclaimed",
                    body: "Reading the Pulse instead of scanning feeds keeps the signal and leaves the afternoon softer.",
                    minutes: 28
                )
            ],
            reclaimedMinutes: 28,
            isMock: true
        )
    }
}

enum MoriMindfulActionKind: String, Codable, CaseIterable, Identifiable {
    case pulseRead
    case resetAction
    case quietTimer
    case settleSession
    case breathingSession
    case pomodoroSession
    case urgeCheckIn
    case replacementAction
    case dailyFocus
    case dailySpark
    case lifeGridProof
    case journal
    case screenTimeLimitKept
    case screenTimeThresholdReached

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pulseRead: return "Pulse read"
        case .resetAction: return "Reset action"
        case .quietTimer: return "Quiet timer"
        case .settleSession: return "Settle session"
        case .breathingSession: return "Breathing session"
        case .pomodoroSession: return "Pomodoro session"
        case .urgeCheckIn: return "Urge check-in"
        case .replacementAction: return "Replacement action"
        case .dailyFocus: return "Daily focus"
        case .dailySpark: return "Daily Spark"
        case .lifeGridProof: return "Life Grid proof"
        case .journal: return "Journal"
        case .screenTimeLimitKept: return "Screen Time limit kept"
        case .screenTimeThresholdReached: return "Screen Time threshold reached"
        }
    }
}

struct MoriMindfulAction: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: MoriMindfulActionKind
    let title: String
    let seeds: Int
    let minutes: Int
    let note: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        kind: MoriMindfulActionKind,
        title: String,
        seeds: Int,
        minutes: Int = 0,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.seeds = seeds
        self.minutes = minutes
        self.note = note
        self.createdAt = createdAt
    }

    var dateKey: String {
        MoriDateKey.value(for: createdAt)
    }
}

struct MoriClarityMetrics: Equatable {
    let clarityScore: Int
    let seedsToday: Int
    let bloomProgress: Double
    let rootsStreak: Int
    let quietMinutesToday: Int
    let settleMinutesToday: Int
    let settleSessionsToday: Int
    let reclaimedMinutesToday: Int
    let screenTimeThresholdsReachedToday: Int
    let protectedFocusMinutesToday: Int
    let mindfulActionsToday: Int

    var bloomPercentText: String {
        "\(Int((max(0, min(1, bloomProgress)) * 100).rounded()))%"
    }
}

struct MoriPulseUserContext: Codable {
    let clarityScore: Int
    let seedsToday: Int
    let quietMinutesToday: Int
    let reclaimedMinutesToday: Int
    let weeklyProofCompleted: Bool
}

struct MoriResetUserState: Codable {
    let clarityScore: Int
    let quietMinutesToday: Int
    let likelyUrge: String
}

enum MoriNoiseClassification: String, Codable {
    case useful
    case noise
    case attentionTrap
}

struct MoriWeeklyStats: Codable {
    let seeds: Int
    let quietMinutes: Int
    let reclaimedMinutes: Int
    let rootsStreak: Int
    let clarityAverage: Int
}

struct MoriWeeklyReflection: Codable, Equatable {
    let title: String
    let body: String
    let nextSeed: String
}
