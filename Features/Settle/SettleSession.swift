import Foundation

enum SettleSessionOutcome: String, Codable {
    case completed
    case endedEarly
}

struct SettleSession: Identifiable, Codable, Equatable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let plannedMinutes: Int
    let actualSeconds: Int
    let outcome: SettleSessionOutcome
    let intervalBellMinutes: Int?
    let seedsEarned: Int

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        plannedMinutes: Int,
        actualSeconds: Int,
        outcome: SettleSessionOutcome,
        intervalBellMinutes: Int?,
        seedsEarned: Int
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedMinutes = max(1, plannedMinutes)
        self.actualSeconds = max(0, actualSeconds)
        self.outcome = outcome
        self.intervalBellMinutes = intervalBellMinutes
        self.seedsEarned = max(0, seedsEarned)
    }

    var completed: Bool {
        outcome == .completed
    }

    var actualMinutes: Int {
        max(1, Int((Double(actualSeconds) / 60.0).rounded(.up)))
    }

    var durationText: String {
        let minutes = actualSeconds / 60
        let seconds = actualSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var title: String {
        completed ? "\(plannedMinutes)-minute Settle" : "Settle ended early"
    }
}

struct SettleWeeklySummary: Equatable {
    let completedSessions: Int
    let totalMinutes: Int
    let consistencyDays: Int
    let bloomProgress: Double

    var bloomPercentText: String {
        "\(Int((max(0, min(1, bloomProgress)) * 100).rounded()))%"
    }
}
