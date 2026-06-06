import Combine
import Foundation

@MainActor
final class SettleSessionStore: ObservableObject {
    static let shared = SettleSessionStore()

    @Published private(set) var sessions: [SettleSession] = []

    private let sessionsKey = "mori_settle_sessions"
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        sessions = loadSessions()
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
            seedsEarned: completed ? seeds(for: plannedMinutes) : 0
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
        let weekly = sessionsInWeek(containing: date).filter(\.completed)
        let totalMinutes = weekly.reduce(0) { $0 + $1.actualMinutes }
        let days = Set(weekly.map { Calendar.current.startOfDay(for: $0.startedAt) }).count
        let sessionProgress = min(1.0, Double(weekly.count) / 5.0)
        let minuteProgress = min(1.0, Double(totalMinutes) / 90.0)
        let consistencyProgress = min(1.0, Double(days) / 5.0)
        let bloom = min(1.0, sessionProgress * 0.35 + minuteProgress * 0.40 + consistencyProgress * 0.25)

        return SettleWeeklySummary(
            completedSessions: weekly.count,
            totalMinutes: totalMinutes,
            consistencyDays: days,
            bloomProgress: bloom
        )
    }

    func recommendedDurationMinutes(for date: Date = Date()) -> Int {
        let summary = weeklySummary(for: date)

        if summary.completedSessions == 0 {
            return 10
        }

        if summary.consistencyDays >= 4 {
            return 15
        }

        if summary.totalMinutes < 20 {
            return 8
        }

        return 12
    }

    func seeds(for plannedMinutes: Int) -> Int {
        max(2, min(12, plannedMinutes / 5 + 1))
    }

    private func sessionsInWeek(containing date: Date) -> [SettleSession] {
        let calendar = moriWeekCalendar
        guard
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)
        else {
            return []
        }

        return sessions.filter { $0.startedAt >= startOfWeek && $0.startedAt < endOfWeek }
    }

    private var moriWeekCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private func pruneOldSessions() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -180, to: Date()) else { return }
        sessions.removeAll { $0.startedAt < cutoff }
    }

    private func persist() {
        guard let data = try? encoder.encode(sessions) else { return }
        userDefaults.set(data, forKey: sessionsKey)
    }

    private func loadSessions() -> [SettleSession] {
        guard let data = userDefaults.data(forKey: sessionsKey),
              let decoded = try? decoder.decode([SettleSession].self, from: data)
        else {
            return []
        }
        return decoded.sorted { $0.startedAt > $1.startedAt }
    }
}
