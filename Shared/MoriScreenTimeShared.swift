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
    case beforeFeedGraceSaved
    case beforeFeedGraceScheduled
    case beforeFeedGraceScheduleSkipped
    case beforeFeedGraceScheduleFailed
    case beforeFeedGraceScheduleStopped
    case beforeFeedGraceIntervalStarted
    case beforeFeedGraceIntervalEnded
    case beforeFeedGraceExpired
    case beforeFeedForegroundReconcile
    case shieldApplied
    case strictLockApplied
    case hiddenAppLockApplied
    case shieldCleared

    var title: String {
        switch self {
        case .beforeFeedGraceSaved:
            return "Grace saved"
        case .beforeFeedGraceScheduled:
            return "Grace monitor scheduled"
        case .beforeFeedGraceScheduleSkipped:
            return "Grace monitor skipped"
        case .beforeFeedGraceScheduleFailed:
            return "Grace monitor failed"
        case .beforeFeedGraceScheduleStopped:
            return "Grace monitor stopped"
        case .beforeFeedGraceIntervalStarted:
            return "Grace monitor fired"
        case .beforeFeedGraceIntervalEnded:
            return "Grace monitor ended"
        case .beforeFeedGraceExpired:
            return "Grace expired"
        case .beforeFeedForegroundReconcile:
            return "Foreground reconciled"
        case .shieldApplied:
            return "Shield applied"
        case .strictLockApplied:
            return "Shield lock applied"
        case .hiddenAppLockApplied:
            return "Hidden app lock applied"
        case .shieldCleared:
            return "Shield cleared"
        }
    }
}

enum MoriScreenTimeMonitorHealthPolicy: String, Codable, Equatable {
    case none
    case shieldOnly
    case shieldLock
    case strictBlock
    case hiddenAppLock
    case clear

    var title: String {
        switch self {
        case .none:
            return "none"
        case .shieldOnly:
            return "shieldOnly"
        case .shieldLock:
            return "shieldLock"
        case .strictBlock:
            return "strictBlock"
        case .hiddenAppLock:
            return "hiddenAppLock"
        case .clear:
            return "clear"
        }
    }

    var isLockingPolicy: Bool {
        self == .shieldLock || self == .strictBlock
    }
}

struct MoriScreenTimeMonitorHealthEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var traceID: String?
    var kind: MoriScreenTimeMonitorHealthEventKind
    var recordedAt: Date
    var activityName: String?
    var featureRawValue: String?
    var activeSessionFeatureRawValue: String?
    var action: String?
    var policy: MoriScreenTimeMonitorHealthPolicy?
    var message: String?
    var graceUntil: Date?
    var beforeFeedNativeGateEnabled: Bool?
    var beforeFeedInGraceWindow: Bool?
    var beforeFeedHasSelection: Bool?
    var applicationTokenCount: Int?
    var webDomainTokenCount: Int?
    var displayNameCount: Int?
    var displayNames: [String]?

    init(
        id: UUID = UUID(),
        traceID: String? = nil,
        kind: MoriScreenTimeMonitorHealthEventKind,
        recordedAt: Date = Date(),
        activityName: String? = nil,
        featureRawValue: String? = nil,
        activeSessionFeatureRawValue: String? = nil,
        action: String? = nil,
        policy: MoriScreenTimeMonitorHealthPolicy? = nil,
        message: String? = nil,
        graceUntil: Date? = nil,
        beforeFeedNativeGateEnabled: Bool? = nil,
        beforeFeedInGraceWindow: Bool? = nil,
        beforeFeedHasSelection: Bool? = nil,
        applicationTokenCount: Int? = nil,
        webDomainTokenCount: Int? = nil,
        displayNameCount: Int? = nil,
        displayNames: [String]? = nil
    ) {
        self.id = id
        self.traceID = traceID
        self.kind = kind
        self.recordedAt = recordedAt
        self.activityName = activityName
        self.featureRawValue = featureRawValue
        self.activeSessionFeatureRawValue = activeSessionFeatureRawValue
        self.action = action
        self.policy = policy
        self.message = message
        self.graceUntil = graceUntil
        self.beforeFeedNativeGateEnabled = beforeFeedNativeGateEnabled
        self.beforeFeedInGraceWindow = beforeFeedInGraceWindow
        self.beforeFeedHasSelection = beforeFeedHasSelection
        self.applicationTokenCount = applicationTokenCount
        self.webDomainTokenCount = webDomainTokenCount
        self.displayNameCount = displayNameCount
        self.displayNames = displayNames
    }

    var totalTokenCount: Int? {
        guard applicationTokenCount != nil || webDomainTokenCount != nil else { return nil }
        return (applicationTokenCount ?? 0) + (webDomainTokenCount ?? 0)
    }

    var shortTraceID: String? {
        traceID.map { String($0.prefix(8)) }
    }
}

enum MoriScreenTimeMonitorHealthStore {
    private static let maxEvents = 80
    private static let duplicateSuppressionWindow: TimeInterval = 30
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func record(_ event: MoriScreenTimeMonitorHealthEvent) {
        var events = recentEvents()
        if let latest = events.first,
           abs(latest.recordedAt.distance(to: event.recordedAt)) <= duplicateSuppressionWindow,
           isDuplicate(latest, event) {
            return
        }
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

    private static func isDuplicate(
        _ lhs: MoriScreenTimeMonitorHealthEvent,
        _ rhs: MoriScreenTimeMonitorHealthEvent
    ) -> Bool {
        lhs.traceID == rhs.traceID &&
        lhs.kind == rhs.kind &&
        lhs.activityName == rhs.activityName &&
        lhs.featureRawValue == rhs.featureRawValue &&
        lhs.activeSessionFeatureRawValue == rhs.activeSessionFeatureRawValue &&
        lhs.action == rhs.action &&
        lhs.policy == rhs.policy &&
        lhs.message == rhs.message &&
        lhs.beforeFeedNativeGateEnabled == rhs.beforeFeedNativeGateEnabled &&
        lhs.beforeFeedInGraceWindow == rhs.beforeFeedInGraceWindow &&
        lhs.beforeFeedHasSelection == rhs.beforeFeedHasSelection &&
        lhs.applicationTokenCount == rhs.applicationTokenCount &&
        lhs.webDomainTokenCount == rhs.webDomainTokenCount &&
        lhs.displayNameCount == rhs.displayNameCount &&
        lhs.displayNames == rhs.displayNames
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
    static let beforeFeedDedicatedSelectionMigrationKey = "mori_before_feed_dedicated_selection_migrated_v1"
    static let signalsKey = "mori_screen_time_signals"
    static let monitorHealthEventsKey = "mori_screen_time_monitor_health_events"
    static let attemptsKey = "mori_screen_time_attempts"
    static let activeSessionKey = "mori_screen_time_active_session"
    static let dailyThresholdMinutesKey = "mori_screen_time_daily_threshold_minutes"
    static let defaultDailyThresholdMinutes = 45
    static let beforeFeedDurationMinutesKey = "mori_before_feed_duration_minutes"
    static let defaultBeforeFeedDurationMinutes = 1
    static let beforeFeedDurationSecondsKey = "mori_before_feed_duration_seconds"
    static let minBeforeFeedDurationSeconds = 10
    static let maxBeforeFeedDurationSeconds = 10 * 60
    static let defaultBeforeFeedDurationSeconds = 60
    static let beforeFeedNativeGateEnabledKey = "mori_before_feed_native_gate_enabled"
    static let defaultBeforeFeedNativeGateEnabled = true
    static let beforeFeedHiddenAppLockEnabledKey = "mori_before_feed_hidden_app_lock_enabled"
    static let defaultBeforeFeedHiddenAppLockEnabled = false
    static let beforeFeedGraceWindowSecondsKey = "mori_before_feed_grace_window_seconds"
    static let minBeforeFeedGraceWindowSeconds = 60
    static let maxBeforeFeedGraceWindowSeconds = 15 * 60
    static let defaultBeforeFeedGraceWindowSeconds = 10 * 60
    static let beforeFeedGraceUntilKey = "mori_before_feed_grace_until"
    static let beforeFeedWindowTraceIDKey = "mori_before_feed_window_trace_id"
    static let beforeFeedPendingResetRequestKey = "mori_before_feed_pending_reset_request"
    static let beforeFeedPendingResetSourceKey = "mori_before_feed_pending_reset_source"
    static let beforeFeedBreathingTechniqueIDKey = "mori_before_feed_breathing_technique_id"
    static let beforeFeedPauseStyleKey = "mori_before_feed_pause_style_v1"
    static let beforeFeedGuidedCycleCountKey = "mori_before_feed_guided_cycle_count"
    static let beforeFeedPausePreferencesMigrationKey = "mori_before_feed_pause_preferences_migrated_v1"
    static let beforeFeedWindowEndReminderEnabledKey = "mori_before_feed_window_end_reminder_enabled"
    static let defaultBeforeFeedWindowEndReminderEnabled = false
    static let beforeFeedWindowEndNotificationIdentifier = "mori_before_feed_window_complete"
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
    static let morningGateHiddenAppLockEnabledKey = "mori_morning_gate_hidden_app_lock_enabled"
    static let defaultMorningGateHiddenAppLockEnabled = false
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
