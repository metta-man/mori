import Foundation

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
    case dailyCheckIn
    case dailySpark
    case weekArchiveProof
    case journal
    case screenTimeLimitKept
    case screenTimeThresholdReached

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        if rawValue == "lifeGridProof" {
            self = .weekArchiveProof
            return
        }

        guard let value = Self(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown mindful action kind: \(rawValue)"
            )
        }

        self = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

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
        case .dailyCheckIn: return "Daily Check-In"
        case .dailySpark: return "Daily Spark"
        case .weekArchiveProof: return "Week archive note"
        case .journal: return "Log"
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
    let screenTimeAttemptsToday: Int
    let screenTimeSavedMinutesToday: Int
    let screenTimeThresholdsReachedToday: Int
    let protectedFocusMinutesToday: Int
    let mindfulActionsToday: Int

    var bloomPercentText: String {
        "\(Int((max(0, min(1, bloomProgress)) * 100).rounded()))%"
    }
}

struct MoriSeedDomainSummary: Identifiable, Equatable {
    let domain: LifeDomain
    let score: Int
    let recentSeeds: [MoriMindfulAction]

    var id: String { domain.rawValue }

    var isNourished: Bool {
        score > 0
    }

    var scoreText: String {
        MoriL10n.string(
            score == 1 ? "practice.seed.count_one" : "practice.seed.count",
            defaultValue: score == 1 ? "%d Seed" : "%d Seeds",
            arguments: [score]
        )
    }
}

struct MoriGrowthPeriodSummary: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let seeds: Int
    let quietMinutes: Int
    let mindfulActions: Int
    let clarityScore: Int

    var seedText: String {
        MoriL10n.string(
            seeds == 1 ? "practice.seed.count_one" : "practice.seed.count",
            defaultValue: seeds == 1 ? "%d Seed" : "%d Seeds",
            arguments: [seeds]
        )
    }
}

struct MoriClarityTrendPoint: Identifiable, Equatable {
    let date: Date
    let score: Int
    let seeds: Int

    var id: String {
        MoriDateKey.value(for: date)
    }
}

struct MoriPulseUserContext: Codable {
    let clarityScore: Int
    let seedsToday: Int
    let quietMinutesToday: Int
    let reclaimedMinutesToday: Int
    let screenTimeAttemptsToday: Int
    let screenTimeSavedMinutesToday: Int
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
