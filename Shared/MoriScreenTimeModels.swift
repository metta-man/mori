import Foundation

struct MoriBeforeFeedDurationOption: Identifiable, Equatable {
    let seconds: Int
    let label: String

    var id: Int { seconds }
}

enum MoriScreenTimeFeature: String, Codable, CaseIterable, Identifiable {
    case quiet
    case pomodoroFocus
    case settle
    case breathing
    case beforeFeed
    case morningGate
    case walkOfflineReset
    case journal
    case dailyCheckIn
    case manualPractice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quiet: return MoriL10n.string("screen_time.feature.quiet.title", defaultValue: "Quiet Mode")
        case .pomodoroFocus: return MoriL10n.string("screen_time.feature.pomodoro_focus.title", defaultValue: "Deep Session")
        case .settle: return MoriL10n.string("screen_time.feature.settle.title", defaultValue: "Settle")
        case .breathing: return MoriL10n.string("screen_time.feature.breathing.title", defaultValue: "Breathing")
        case .beforeFeed: return MoriL10n.string("screen_time.feature.before_feed.title", defaultValue: "Before Feed")
        case .morningGate: return MoriL10n.string("screen_time.feature.morning_gate.title", defaultValue: "Morning Gate")
        case .walkOfflineReset: return MoriL10n.string("screen_time.feature.walk_offline_reset.title", defaultValue: "Walk / Offline Reset")
        case .journal: return MoriL10n.string("screen_time.feature.journal.title", defaultValue: "Log")
        case .dailyCheckIn: return MoriL10n.string("screen_time.feature.daily_check_in.title", defaultValue: "Daily Check-In")
        case .manualPractice: return MoriL10n.string("screen_time.feature.manual_practice.title", defaultValue: "Manual Reset")
        }
    }

    var subtitle: String {
        switch self {
        case .quiet: return MoriL10n.string("screen_time.feature.quiet.subtitle", defaultValue: "Pause scrolling while the quiet timer runs.")
        case .pomodoroFocus: return MoriL10n.string("screen_time.feature.pomodoro_focus.subtitle", defaultValue: "Limit selected apps during focus phases.")
        case .settle: return MoriL10n.string("screen_time.feature.settle.subtitle", defaultValue: "Limit distractions during Settle timer sessions.")
        case .breathing: return MoriL10n.string("screen_time.feature.breathing.subtitle", defaultValue: "Keep selected apps limited during breathing reset.")
        case .beforeFeed: return MoriL10n.string("screen_time.feature.before_feed.subtitle", defaultValue: "Limit feed apps before the reset completes.")
        case .morningGate: return MoriL10n.string("screen_time.feature.morning_gate.subtitle", defaultValue: "Keep the first morning window clear.")
        case .walkOfflineReset: return MoriL10n.string("screen_time.feature.walk_offline_reset.subtitle", defaultValue: "Keep the phone quiet while you step away.")
        case .journal: return MoriL10n.string("screen_time.feature.journal.subtitle", defaultValue: "Keep selected apps limited while writing.")
        case .dailyCheckIn: return MoriL10n.string("screen_time.feature.daily_check_in.subtitle", defaultValue: "Keep selected apps limited during Daily Check-In.")
        case .manualPractice: return MoriL10n.string("screen_time.feature.manual_practice.subtitle", defaultValue: "Keep selected apps limited during manual reset timers.")
        }
    }

    var symbolName: String {
        icon.legacySystemName
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .quiet:
            return .quiet
        case .pomodoroFocus:
            return .timer
        case .settle, .breathing:
            return .breathe
        case .beforeFeed:
            return .lockShield
        case .morningGate:
            return .leaf
        case .walkOfflineReset:
            return .leaf
        case .journal, .dailyCheckIn:
            return .journal
        case .manualPractice:
            return .leaf
        }
    }
}

enum MoriScreenTimeMode: String, Codable, CaseIterable, Identifiable {
    case quiet
    case pomodoro
    case dailyThreshold

    var id: String { rawValue }

    var shieldFeature: MoriScreenTimeFeature {
        switch self {
        case .quiet:
            return .quiet
        case .pomodoro:
            return .pomodoroFocus
        case .dailyThreshold:
            return .manualPractice
        }
    }

    var title: String {
        switch self {
        case .quiet: return MoriL10n.string("screen_time.mode.quiet", defaultValue: "Quiet Mode")
        case .pomodoro: return MoriL10n.string("screen_time.mode.pomodoro", defaultValue: "Deep Session")
        case .dailyThreshold: return MoriL10n.string("screen_time.mode.daily_limit", defaultValue: "Daily limit")
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

enum MoriScreenTimeAttemptTargetKind: String, Codable, Equatable {
    case application
    case category
    case webDomain
}

enum MoriScreenTimeAttemptAction: String, Codable, Equatable {
    case primaryButtonPressed
    case secondaryButtonPressed
}

enum MoriScreenTimeSavedTimeCategory: String, Codable, Equatable {
    case socialMessaging
    case newsReading
    case streamingMedia
    case games
    case shopping
    case unknown

    var title: String {
        switch self {
        case .socialMessaging: return MoriL10n.string("screen_time.saved_time.social_messaging", defaultValue: "Social / messaging")
        case .newsReading: return MoriL10n.string("screen_time.saved_time.news_reading", defaultValue: "News / reading")
        case .streamingMedia: return MoriL10n.string("screen_time.saved_time.streaming_media", defaultValue: "Streaming / media")
        case .games: return MoriL10n.string("screen_time.saved_time.games", defaultValue: "Games")
        case .shopping: return MoriL10n.string("screen_time.saved_time.shopping", defaultValue: "Shopping")
        case .unknown: return MoriL10n.string("screen_time.saved_time.general_app", defaultValue: "General app")
        }
    }

    var estimatedSavedSeconds: Int {
        switch self {
        case .socialMessaging: return 5 * 60
        case .newsReading: return 3 * 60
        case .streamingMedia: return 10 * 60
        case .games: return 5 * 60
        case .shopping: return 5 * 60
        case .unknown: return 3 * 60
        }
    }
}

struct MoriScreenTimeSavedTimeEstimate: Codable, Equatable {
    let category: MoriScreenTimeSavedTimeCategory
    let seconds: Int

    init(category: MoriScreenTimeSavedTimeCategory) {
        self.category = category
        self.seconds = category.estimatedSavedSeconds
    }

    init(category: MoriScreenTimeSavedTimeCategory, seconds: Int) {
        self.category = category
        self.seconds = max(0, seconds)
    }
}

struct MoriScreenTimeAttempt: Identifiable, Codable, Equatable {
    let id: UUID
    let dateKey: String
    let attemptedAt: Date
    let feature: MoriScreenTimeFeature?
    let targetKind: MoriScreenTimeAttemptTargetKind
    let action: MoriScreenTimeAttemptAction
    let savedTimeCategory: MoriScreenTimeSavedTimeCategory
    let estimatedSavedSeconds: Int

    init(
        id: UUID = UUID(),
        dateKey: String = MoriScreenTimeShared.dateKey(),
        attemptedAt: Date = Date(),
        feature: MoriScreenTimeFeature?,
        targetKind: MoriScreenTimeAttemptTargetKind,
        action: MoriScreenTimeAttemptAction,
        estimate: MoriScreenTimeSavedTimeEstimate
    ) {
        self.id = id
        self.dateKey = dateKey
        self.attemptedAt = attemptedAt
        self.feature = feature
        self.targetKind = targetKind
        self.action = action
        self.savedTimeCategory = estimate.category
        self.estimatedSavedSeconds = max(0, estimate.seconds)
    }
}

struct MoriScreenTimeActiveSession: Codable, Equatable {
    let feature: MoriScreenTimeFeature
    let startedAt: Date
    let endDate: Date

    init(feature: MoriScreenTimeFeature, startedAt: Date, endDate: Date) {
        self.feature = feature
        self.startedAt = startedAt
        self.endDate = endDate
    }

    var mode: MoriScreenTimeMode? {
        switch feature {
        case .quiet: return .quiet
        case .pomodoroFocus: return .pomodoro
        default: return nil
        }
    }

    var isExpired: Bool {
        isExpired(at: Date())
    }

    func isExpired(at date: Date) -> Bool {
        endDate <= date
    }

    private enum CodingKeys: String, CodingKey {
        case feature
        case mode
        case startedAt
        case endDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let feature = try container.decodeIfPresent(MoriScreenTimeFeature.self, forKey: .feature) {
            self.feature = feature
        } else if let oldMode = try container.decodeIfPresent(MoriScreenTimeMode.self, forKey: .mode) {
            switch oldMode {
            case .quiet:
                self.feature = .quiet
            case .pomodoro:
                self.feature = .pomodoroFocus
            case .dailyThreshold:
                self.feature = .manualPractice
            }
        } else {
            self.feature = .manualPractice
        }
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endDate = try container.decode(Date.self, forKey: .endDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(feature, forKey: .feature)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(endDate, forKey: .endDate)
    }
}

struct MoriQuietTimerSession: Codable, Equatable {
    var durationSeconds: Int
    var startedAt: Date
    var endDate: Date
    var remainingSeconds: Int
    var isRunning: Bool
    var quietShieldWasActive: Bool
    var didRecordCompletion: Bool

    init(
        durationSeconds: Int,
        startedAt: Date,
        endDate: Date,
        remainingSeconds: Int? = nil,
        isRunning: Bool = true,
        quietShieldWasActive: Bool = false,
        didRecordCompletion: Bool = false
    ) {
        let normalizedDuration = MoriQuietTimerDuration.normalizedSeconds(durationSeconds)
        self.durationSeconds = normalizedDuration
        self.startedAt = startedAt
        self.endDate = endDate
        self.remainingSeconds = remainingSeconds ?? normalizedDuration
        self.isRunning = isRunning
        self.quietShieldWasActive = quietShieldWasActive
        self.didRecordCompletion = didRecordCompletion
    }

    func remainingSeconds(at date: Date = Date()) -> Int {
        guard isRunning else {
            return max(0, remainingSeconds)
        }

        return max(0, Int(ceil(endDate.timeIntervalSince(date))))
    }

    func paused(at date: Date = Date()) -> MoriQuietTimerSession {
        var session = self
        session.remainingSeconds = remainingSeconds(at: date)
        session.isRunning = false
        return session
    }

    func resumed(at date: Date = Date()) -> MoriQuietTimerSession {
        let remaining = max(1, remainingSeconds(at: date))
        var session = self
        session.remainingSeconds = remaining
        session.endDate = date.addingTimeInterval(TimeInterval(remaining))
        session.isRunning = true
        return session
    }
}

enum MoriQuietTimerDuration {
    static let minimumSeconds = 5 * 60
    static let maximumSeconds = 72 * 60 * 60
    static let minuteStep = 5

    static func normalizedSeconds(_ seconds: Int) -> Int {
        let clamped = min(maximumSeconds, max(minimumSeconds, seconds))
        let stepSeconds = minuteStep * 60
        return max(minimumSeconds, (clamped / stepSeconds) * stepSeconds)
    }

    static func formattedClock(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let seconds = clamped % 60

        if hours == 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        }

        if hours < 24 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        let days = hours / 24
        let remainderHours = hours % 24
        if minutes == 0 && seconds == 0 {
            return "\(days)d \(remainderHours)h"
        }
        return "\(days)d \(remainderHours)h \(minutes)m"
    }

    static func formattedTitle(_ seconds: Int) -> String {
        let totalMinutes = max(1, normalizedSeconds(seconds) / 60)
        if totalMinutes < 60 {
            return "\(totalMinutes) minute\(totalMinutes == 1 ? "" : "s")"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours < 24 {
            if minutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            }
            return "\(hours) hour\(hours == 1 ? "" : "s") \(minutes) minutes"
        }

        let days = hours / 24
        let remainderHours = hours % 24
        if remainderHours == 0 && minutes == 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        }
        if minutes == 0 {
            return "\(days) day\(days == 1 ? "" : "s") \(remainderHours) hours"
        }
        return "\(days) day\(days == 1 ? "" : "s") \(remainderHours) hours \(minutes) minutes"
    }
}
