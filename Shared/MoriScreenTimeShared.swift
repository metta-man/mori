import Foundation

enum MoriAppGroup {
    static let identifier = "group.com.mettalabs.mori"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

enum MoriScreenTimeShared {
    static let selectionKey = "mori_screen_time_selection"
    static let signalsKey = "mori_screen_time_signals"
    static let activeSessionKey = "mori_screen_time_active_session"
    static let dailyThresholdMinutesKey = "mori_screen_time_daily_threshold_minutes"
    static let defaultDailyThresholdMinutes = 45

    static func dateKey(for date: Date = Date()) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

enum MoriScreenTimeMode: String, Codable, CaseIterable, Identifiable {
    case quiet
    case pomodoro
    case dailyThreshold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quiet: return "Quiet Mode"
        case .pomodoro: return "Pomodoro"
        case .dailyThreshold: return "Daily limit"
        }
    }
}

struct MoriScreenTimeSignal: Identifiable, Codable, Equatable {
    let id: UUID
    let dateKey: String
    let thresholdID: String
    let mode: MoriScreenTimeMode
    let reachedAt: Date

    init(
        id: UUID = UUID(),
        dateKey: String = MoriScreenTimeShared.dateKey(),
        thresholdID: String,
        mode: MoriScreenTimeMode,
        reachedAt: Date = Date()
    ) {
        self.id = id
        self.dateKey = dateKey
        self.thresholdID = thresholdID
        self.mode = mode
        self.reachedAt = reachedAt
    }
}

struct MoriScreenTimeActiveSession: Codable, Equatable {
    let mode: MoriScreenTimeMode
    let startedAt: Date
    let endDate: Date

    var isExpired: Bool {
        endDate <= Date()
    }
}

enum MoriScreenTimeSignalStore {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func allSignals() -> [MoriScreenTimeSignal] {
        guard let data = MoriAppGroup.defaults.data(forKey: MoriScreenTimeShared.signalsKey),
              let signals = try? decoder.decode([MoriScreenTimeSignal].self, from: data)
        else {
            return []
        }
        return signals
    }

    static func signals(for date: Date = Date()) -> [MoriScreenTimeSignal] {
        let key = MoriScreenTimeShared.dateKey(for: date)
        return allSignals().filter { $0.dateKey == key }
    }

    static func append(_ signal: MoriScreenTimeSignal) {
        var signals = allSignals()
        guard !signals.contains(where: { $0.thresholdID == signal.thresholdID && $0.dateKey == signal.dateKey }) else {
            return
        }

        signals.insert(signal, at: 0)
        if let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) {
            signals.removeAll { $0.reachedAt < cutoff }
        }
        persist(signals)
    }

    private static func persist(_ signals: [MoriScreenTimeSignal]) {
        guard let data = try? encoder.encode(signals) else { return }
        MoriAppGroup.defaults.set(data, forKey: MoriScreenTimeShared.signalsKey)
    }
}
