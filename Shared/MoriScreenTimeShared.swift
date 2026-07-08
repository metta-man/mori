import Foundation
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

enum MoriAppGroup {
    static let identifier = "group.com.mettalabs.mori"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

enum MoriPendingResetLaunchSource: String {
    case screenTimeGate = "screen_time_gate"
    case shortcut = "shortcut"
}

enum MoriScreenTimeMonitorHealthEventKind: String, Codable, CaseIterable {
    case beforeFeedGraceScheduled
    case beforeFeedGraceScheduleSkipped
    case beforeFeedGraceScheduleFailed
    case beforeFeedGraceIntervalStarted
    case beforeFeedGraceIntervalEnded
    case beforeFeedGraceExpired
    case shieldApplied
    case shieldCleared

    var title: String {
        switch self {
        case .beforeFeedGraceScheduled:
            return "Grace monitor scheduled"
        case .beforeFeedGraceScheduleSkipped:
            return "Grace monitor skipped"
        case .beforeFeedGraceScheduleFailed:
            return "Grace monitor failed"
        case .beforeFeedGraceIntervalStarted:
            return "Grace monitor fired"
        case .beforeFeedGraceIntervalEnded:
            return "Grace monitor ended"
        case .beforeFeedGraceExpired:
            return "Grace expired"
        case .shieldApplied:
            return "Shield applied"
        case .shieldCleared:
            return "Shield cleared"
        }
    }
}

struct MoriScreenTimeMonitorHealthEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: MoriScreenTimeMonitorHealthEventKind
    var recordedAt: Date
    var activityName: String?
    var featureRawValue: String?
    var action: String?
    var message: String?
    var graceUntil: Date?
    var beforeFeedNativeGateEnabled: Bool?
    var beforeFeedInGraceWindow: Bool?
    var beforeFeedHasSelection: Bool?
    var applicationTokenCount: Int?
    var webDomainTokenCount: Int?
    var displayNameCount: Int?

    init(
        id: UUID = UUID(),
        kind: MoriScreenTimeMonitorHealthEventKind,
        recordedAt: Date = Date(),
        activityName: String? = nil,
        featureRawValue: String? = nil,
        action: String? = nil,
        message: String? = nil,
        graceUntil: Date? = nil,
        beforeFeedNativeGateEnabled: Bool? = nil,
        beforeFeedInGraceWindow: Bool? = nil,
        beforeFeedHasSelection: Bool? = nil,
        applicationTokenCount: Int? = nil,
        webDomainTokenCount: Int? = nil,
        displayNameCount: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.recordedAt = recordedAt
        self.activityName = activityName
        self.featureRawValue = featureRawValue
        self.action = action
        self.message = message
        self.graceUntil = graceUntil
        self.beforeFeedNativeGateEnabled = beforeFeedNativeGateEnabled
        self.beforeFeedInGraceWindow = beforeFeedInGraceWindow
        self.beforeFeedHasSelection = beforeFeedHasSelection
        self.applicationTokenCount = applicationTokenCount
        self.webDomainTokenCount = webDomainTokenCount
        self.displayNameCount = displayNameCount
    }

    var totalTokenCount: Int? {
        guard applicationTokenCount != nil || webDomainTokenCount != nil else { return nil }
        return (applicationTokenCount ?? 0) + (webDomainTokenCount ?? 0)
    }
}

enum MoriScreenTimeMonitorHealthStore {
    private static let maxEvents = 20
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func record(_ event: MoriScreenTimeMonitorHealthEvent) {
        var events = recentEvents()
        events.insert(event, at: 0)
        if events.count > maxEvents {
            events.removeLast(events.count - maxEvents)
        }
        guard let data = try? encoder.encode(events) else { return }
        MoriAppGroup.defaults.set(data, forKey: MoriScreenTimeShared.monitorHealthEventsKey)
    }

    static func recentEvents() -> [MoriScreenTimeMonitorHealthEvent] {
        guard let data = MoriAppGroup.defaults.data(forKey: MoriScreenTimeShared.monitorHealthEventsKey),
              let events = try? decoder.decode([MoriScreenTimeMonitorHealthEvent].self, from: data)
        else {
            return []
        }
        return events
    }

    static func clear() {
        MoriAppGroup.defaults.removeObject(forKey: MoriScreenTimeShared.monitorHealthEventsKey)
    }
}

#if canImport(ActivityKit) && os(iOS)
@available(iOS 16.1, *)
struct MoriBeforeFeedWindowAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        let startedAt: Date
        let endsAt: Date
        let durationSeconds: Int

        func remainingSeconds(now: Date = Date()) -> Int {
            max(0, Int(ceil(endsAt.timeIntervalSince(now))))
        }

        var timerInterval: ClosedRange<Date> {
            startedAt...max(startedAt, endsAt)
        }

        func progress(now: Date = Date()) -> Double {
            guard durationSeconds > 0 else { return 1 }
            let elapsed = now.timeIntervalSince(startedAt)
            return min(1, max(0, elapsed / TimeInterval(durationSeconds)))
        }
    }

    let title: String
}
#endif

enum MoriScreenTimeShared {
    static let selectionKey = "mori_screen_time_selection"
    static let defaultSelectionKey = "mori_screen_time_default_selection"
    static let defaultSelectionDisplayNamesKey = "mori_screen_time_default_selection_display_names"
    static let featureSelectionKeyPrefix = "mori_screen_time_feature_selection_"
    static let featureProfilesKey = "mori_screen_time_feature_profiles"
    static let featureMigrationKey = "mori_screen_time_feature_profiles_migrated_v1"
    static let signalsKey = "mori_screen_time_signals"
    static let monitorHealthEventsKey = "mori_screen_time_monitor_health_events"
    static let attemptsKey = "mori_screen_time_attempts"
    static let activeSessionKey = "mori_screen_time_active_session"
    static let dailyThresholdMinutesKey = "mori_screen_time_daily_threshold_minutes"
    static let defaultDailyThresholdMinutes = 45
    static let beforeFeedDurationMinutesKey = "mori_before_feed_duration_minutes"
    static let defaultBeforeFeedDurationMinutes = 1
    static let beforeFeedDurationSecondsKey = "mori_before_feed_duration_seconds"
    static let minBeforeFeedDurationSeconds = 30
    static let maxBeforeFeedDurationSeconds = 10 * 60
    static let defaultBeforeFeedDurationSeconds = 60
    static let beforeFeedNativeGateEnabledKey = "mori_before_feed_native_gate_enabled"
    static let defaultBeforeFeedNativeGateEnabled = true
    static let beforeFeedGraceWindowSecondsKey = "mori_before_feed_grace_window_seconds"
    static let minBeforeFeedGraceWindowSeconds = 60
    static let maxBeforeFeedGraceWindowSeconds = 15 * 60
    static let defaultBeforeFeedGraceWindowSeconds = 10 * 60
    static let beforeFeedGraceUntilKey = "mori_before_feed_grace_until"
    static let beforeFeedPendingResetRequestKey = "mori_before_feed_pending_reset_request"
    static let beforeFeedPendingResetSourceKey = "mori_before_feed_pending_reset_source"
    static let beforeFeedBreathingTechniqueIDKey = "mori_before_feed_breathing_technique_id"
    static let beforeFeedBreathingNoneID = "none"
    static let defaultBeforeFeedBreathingTechniqueID = "Long Exhale (4-6)"
    static let currentShieldFeatureKey = "mori_screen_time_current_shield_feature"
    static let currentShieldSavedTimeSecondsKey = "mori_screen_time_current_shield_saved_time_seconds"
    static let currentShieldSavedTimeCategoryKey = "mori_screen_time_current_shield_saved_time_category"
    static let morningGateEnabledKey = "mori_morning_gate_enabled"
    static let defaultMorningGateEnabled = true
    static let morningGateStartHourKey = "mori_morning_gate_start_hour"
    static let defaultMorningGateStartHour = 7
    static let morningGateStartMinuteKey = "mori_morning_gate_start_minute"
    static let defaultMorningGateStartMinute = 0
    static let morningGateDurationSecondsKey = "mori_morning_gate_duration_seconds"
    static let defaultMorningGateDurationSeconds = 30 * 60
    static let morningGateBreathingTechniqueIDKey = "mori_morning_gate_breathing_technique_id"
    static let defaultMorningGateBreathingTechniqueID = defaultBeforeFeedBreathingTechniqueID
    static let morningGateCompletedDateKey = "mori_morning_gate_completed_date_key"
    static let morningGatePendingResetRequestKey = "mori_morning_gate_pending_reset_request"
    static let morningGatePendingResetSourceKey = "mori_morning_gate_pending_reset_source"
    static let quietTimerSessionKey = "mori_quiet_timer_session"
    static let quietTimerCompletionNotificationIdentifier = "mori_quiet_timer_completion"

    static var beforeFeedDurationOptions: [MoriBeforeFeedDurationOption] {
        [
            MoriBeforeFeedDurationOption(seconds: 30, label: MoriL10n.string("duration.seconds", defaultValue: "%d seconds", arguments: [30])),
            MoriBeforeFeedDurationOption(seconds: 60, label: MoriL10n.string("duration.minute_one", defaultValue: "%d minute", arguments: [1])),
            MoriBeforeFeedDurationOption(seconds: 2 * 60, label: MoriL10n.string("duration.minutes", defaultValue: "%d minutes", arguments: [2])),
            MoriBeforeFeedDurationOption(seconds: 5 * 60, label: MoriL10n.string("duration.minutes", defaultValue: "%d minutes", arguments: [5])),
            MoriBeforeFeedDurationOption(seconds: 10 * 60, label: MoriL10n.string("duration.full_settle", defaultValue: "Full Settle"))
        ]
    }

    static var beforeFeedGraceWindowOptions: [MoriBeforeFeedDurationOption] {
        [
            MoriBeforeFeedDurationOption(seconds: 2 * 60, label: MoriL10n.string("duration.minutes", defaultValue: "%d minutes", arguments: [2])),
            MoriBeforeFeedDurationOption(seconds: 5 * 60, label: MoriL10n.string("duration.minutes", defaultValue: "%d minutes", arguments: [5])),
            MoriBeforeFeedDurationOption(seconds: 10 * 60, label: MoriL10n.string("duration.minutes", defaultValue: "%d minutes", arguments: [10])),
            MoriBeforeFeedDurationOption(seconds: 15 * 60, label: MoriL10n.string("duration.minutes", defaultValue: "%d minutes", arguments: [15]))
        ]
    }

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
