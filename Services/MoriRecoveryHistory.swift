import Foundation
import Combine

struct MoriRecoveryDailyIndicator: Codable, Equatable, Identifiable {
    let dateKey: String
    let date: Date
    let readinessScore: Double?
    let sleepMinutes: Double?
    let bodyLoadScore: Double
    let hrvImpact: Double?
    let restingHeartImpact: Double?
    let sleepImpact: Double?
    let trainingLoadPoints: Double
    let highIntensityMinutes: Double?

    var id: String { dateKey }

    init(snapshot: MoriRecoverySnapshot) {
        date = Calendar.current.startOfDay(for: snapshot.date)
        dateKey = MoriDateKey.value(for: snapshot.date)
        readinessScore = snapshot.score.map(Double.init)
        sleepMinutes = snapshot.sleepSummary.duration.map { $0 / 60.0 }
        bodyLoadScore = Self.bodyLoadScore(snapshot.bodyLoadLabel)
        hrvImpact = snapshot.signals.first { $0.id == "hrv" }.map { Double($0.impact) }
        restingHeartImpact = snapshot.signals.first { $0.id == "resting-heart-rate" }.map { Double($0.impact) }
        sleepImpact = snapshot.signals.first { $0.id == "sleep" }.map { Double($0.impact) }
        trainingLoadPoints = snapshot.trainingSummary.loadPoints
        highIntensityMinutes = snapshot.trainingSummary.highIntensityMinutes
    }

    private static func bodyLoadScore(_ label: String) -> Double {
        let lowered = label.lowercased()
        if lowered.contains("elevated") && !lowered.contains("slightly") { return 2 }
        if lowered.contains("slightly") { return 1 }
        return 0
    }
}

@MainActor
final class MoriRecoveryHistoryStore: ObservableObject {
    static let shared = MoriRecoveryHistoryStore()

    @Published private(set) var indicators: [MoriRecoveryDailyIndicator] = []

    private let persistence: MoriRecoveryHistoryPersistence

    private init(persistence: MoriRecoveryHistoryPersistence = MoriRecoveryHistoryPersistence()) {
        self.persistence = persistence
        indicators = persistence.loadIndicators()
    }

    func record(_ snapshot: MoriRecoverySnapshot) {
        guard snapshot.hasUsableData else { return }
        let indicator = MoriRecoveryDailyIndicator(snapshot: snapshot)
        indicators.removeAll { $0.dateKey == indicator.dateKey }
        indicators.append(indicator)
        prune()
        persist()
    }

    func indicator(for date: Date) -> MoriRecoveryDailyIndicator? {
        let key = MoriDateKey.value(for: date)
        return indicators.first { $0.dateKey == key }
    }

    private func prune() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -120, to: Date()) else { return }
        indicators.removeAll { $0.date < cutoff }
        indicators.sort { $0.date < $1.date }
    }

    private func persist() {
        persistence.saveIndicators(indicators)
    }
}

struct MoriDailyPracticeSummary: Equatable {
    let settleMinutes: Int
    let breathingMinutes: Int
    let walkMinutes: Int
    let focusMinutes: Int
}

struct MoriDailyFactorLog: Identifiable, Equatable {
    let date: Date
    let factorTags: [MoriFactorTag]
    let subjectiveTone: HabitDayTone?
    let journalEntryIDs: [UUID]
    let practiceSummary: MoriDailyPracticeSummary
    let recoveryIndicator: MoriRecoveryDailyIndicator?

    var id: String { MoriDateKey.value(for: date) }
}

@MainActor
enum MoriDailyFactorLogBuilder {
    static func logs(windowDays: Int = 60, now: Date = Date()) -> [MoriDailyFactorLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -max(1, windowDays), to: today) ?? today
        let habitEntries = HabitDataManager.shared.getEntries(from: start, to: today)
        let journalEntries = GratitudeEntryStore.live.loadEntries()

        return (0...max(1, windowDays)).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let habit = habitEntries.first { calendar.isDate($0.date, inSameDayAs: dayStart) }
            let journals = journalEntries.filter { $0.date >= dayStart && $0.date < dayEnd }
            let actions = MoriClarityStore.shared.actions(for: dayStart)

            return MoriDailyFactorLog(
                date: dayStart,
                factorTags: MoriFactorTagStore.shared.tags(for: dayStart),
                subjectiveTone: habit?.tone,
                journalEntryIDs: journals.map(\.id),
                practiceSummary: practiceSummary(actions: actions),
                recoveryIndicator: MoriRecoveryHistoryStore.shared.indicator(for: dayStart)
            )
        }
        .sorted { $0.date < $1.date }
    }

    private static func practiceSummary(actions: [MoriMindfulAction]) -> MoriDailyPracticeSummary {
        MoriDailyPracticeSummary(
            settleMinutes: actions.filter { $0.kind == .settleSession }.reduce(0) { $0 + $1.minutes },
            breathingMinutes: actions.filter { $0.kind == .breathingSession }.reduce(0) { $0 + $1.minutes },
            walkMinutes: actions.filter { $0.kind == .replacementAction }.reduce(0) { $0 + $1.minutes },
            focusMinutes: actions.filter { $0.kind == .pomodoroSession }.reduce(0) { $0 + $1.minutes }
        )
    }
}
