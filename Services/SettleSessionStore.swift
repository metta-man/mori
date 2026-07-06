import Combine
import Foundation

@MainActor
final class SettleSessionStore: ObservableObject {
    static let shared = SettleSessionStore()

    @Published private(set) var sessions: [SettleSession] = []

    private let persistence: SettleSessionPersistence
    private let statsCalculator: SettleSessionStatsCalculator

    private init(
        persistence: SettleSessionPersistence = SettleSessionPersistence(),
        statsCalculator: SettleSessionStatsCalculator = SettleSessionStatsCalculator()
    ) {
        self.persistence = persistence
        self.statsCalculator = statsCalculator
        sessions = persistence.loadSessions()
        pruneOldSessions()
    }

    @discardableResult
    func recordSession(
        startedAt: Date,
        endedAt: Date = Date(),
        plannedMinutes: Int,
        actualSeconds: Int,
        completed: Bool,
        intervalBellMinutes: Int?
    ) -> SettleSession {
        let session = SettleSession(
            startedAt: startedAt,
            endedAt: endedAt,
            plannedMinutes: plannedMinutes,
            actualSeconds: actualSeconds,
            outcome: completed ? .completed : .endedEarly,
            intervalBellMinutes: intervalBellMinutes,
            seedsEarned: completed ? statsCalculator.seeds(for: plannedMinutes) : 0
        )

        sessions.insert(session, at: 0)
        pruneOldSessions()
        persist()
        return session
    }

    func recentSessions(limit: Int = 6) -> [SettleSession] {
        Array(sessions.prefix(limit))
    }

    func sessions(for date: Date) -> [SettleSession] {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: date) }
    }

    func completedSessions(for date: Date) -> [SettleSession] {
        sessions(for: date).filter(\.completed)
    }

    func weeklySummary(for date: Date = Date()) -> SettleWeeklySummary {
        statsCalculator.weeklySummary(for: sessions, containing: date)
    }

    func recommendedDurationMinutes(for date: Date = Date()) -> Int {
        statsCalculator.recommendedDurationMinutes(for: sessions, containing: date)
    }

    func seeds(for plannedMinutes: Int) -> Int {
        statsCalculator.seeds(for: plannedMinutes)
    }

    private func pruneOldSessions() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -180, to: Date()) else { return }
        sessions.removeAll { $0.startedAt < cutoff }
    }

    private func persist() {
        persistence.saveSessions(sessions)
    }
}
