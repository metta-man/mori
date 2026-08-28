import Foundation
import UserNotifications

enum MoriDataCategory: String, CaseIterable, Identifiable {
    case logsAndPhotos
    case iCloudBackup
    case lifeGridAndCheckIns
    case recoveryHistory
    case focusAndReminders
    case analytics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .logsAndPhotos: "Logs & Photos"
        case .iCloudBackup: "iCloud Backup"
        case .lifeGridAndCheckIns: "Life Grid & Check-ins"
        case .recoveryHistory: "Recovery History"
        case .focusAndReminders: "App Limits, Focus & Reminders"
        case .analytics: "Analytics Data"
        }
    }
}

enum MoriDataDeletionError: LocalizedError {
    case cloudDeletionFailed
    var errorDescription: String? { "Local data was removed, but the iCloud backup could not be deleted. Check your connection and try again." }
}

/// The explicit UserDefaults ownership map used by destructive deletion.
///
/// Dynamic keys are cleared only by their owning store (for example, dated
/// Today drafts and per-feature Screen Time selections). Locale is deliberately
/// excluded so onboarding remains in the language the person selected.
struct MoriPersistedDataDeletion {
    let standardDefaults: UserDefaults
    let sharedDefaults: UserDefaults

    init(
        standardDefaults: UserDefaults = .standard,
        sharedDefaults: UserDefaults = MoriAppGroup.defaults
    ) {
        self.standardDefaults = standardDefaults
        self.sharedDefaults = sharedDefaults
    }

    func deleteLifeGridAndCheckIns() {
        HabitEntryStore(defaults: standardDefaults).clearEntries()
        DailySparkEntryStore(defaults: standardDefaults).clear()
        TodayFocusDraftStore(defaults: standardDefaults).clearAll()
        MoriClarityPersistence(userDefaults: standardDefaults).clearAll()
        WeekArchiveIdentityStore(defaults: standardDefaults).clear()
        UserSettingsStore(defaults: standardDefaults).clearLifeGridData()
        UserSettingsStore(defaults: sharedDefaults).clearLifeGridData()
        sharedDefaults.removeObject(forKey: MoriWidgetContextSnapshot.defaultsKey)
    }

    func deleteRecoveryHistory() {
        MoriRecoveryHistoryPersistence(defaults: standardDefaults).clear()
        MoriRecoveryTagOverrideStore(defaults: standardDefaults).clear()
        MoriRecoveryPreferencesStore(defaults: standardDefaults).clear()
        standardDefaults.removeObject(forKey: "mori_recovery_llm_insight_opt_in")
        sharedDefaults.removeObject(forKey: MoriWidgetContextSnapshot.defaultsKey)
    }

    func deleteFocusAndReminders() {
        SettleSessionPersistence(defaults: standardDefaults).clear()
        MindfulnessBellStateStore(defaults: standardDefaults).clearAll()
        BeforeFeedGateStore(
            defaults: sharedDefaults,
            legacyDefaults: standardDefaults
        ).clearIntentHistory()
        ScreenTimeSelectionPersistence(defaults: sharedDefaults).clearAll()

        remove(Self.focusAndReminderStandardKeys, from: standardDefaults)
        remove(Self.focusAndReminderSharedKeys, from: sharedDefaults)
    }

    func finalizeFullDeletion() {
        UserSettingsStore(defaults: standardDefaults).clearAllUserDataPreservingLocale()
        UserSettingsStore(defaults: sharedDefaults).clearAllUserDataPreservingLocale()
        standardDefaults.removeObject(forKey: "mori_pending_deep_link_target")
        sharedDefaults.removeObject(forKey: MoriWidgetContextSnapshot.defaultsKey)
    }

    func deleteAllDefaults() {
        deleteLifeGridAndCheckIns()
        deleteRecoveryHistory()
        deleteFocusAndReminders()
        finalizeFullDeletion()
    }

    private func remove(_ keys: [String], from defaults: UserDefaults) {
        keys.forEach { defaults.removeObject(forKey: $0) }
    }

    private static let focusAndReminderStandardKeys = [
        // Reminder preferences
        "clockReminderEnabled",
        "clockReminderHour",
        "clockReminderMinute",
        "dailySparkReminderEnabled",
        "dailySparkReminderHour",
        "dailySparkReminderMinute",

        // Legacy Before Feed preference
        MoriScreenTimeShared.beforeFeedDurationMinutesKey,

        // App Limits and Focus preferences
        "mori_app_limits_pin_prompt_completed_v1",
        "mori_essential_mode_duration",
        "mori_settle_last_duration",
        "mori_settle_sound_enabled",
        "mori_settle_haptics_enabled",
        "mori_settle_animation_enabled",
        "mori_settle_interval_enabled",
        "mori_settle_interval_minutes",
        "mori_timer_dark_room_enabled",
        "mori_timer_dark_room_dim",
        "mori_settle_breathing_sound_enabled",
        "mori_settle_breathing_haptics_enabled",
        "mori_settle_breathing_animation_enabled",
        "mori_settle_breathing_keep_screen_on",
        "mori_settle_breathing_haptic_style",
        "mori_settle_breathing_custom_inhale",
        "mori_settle_breathing_custom_hold",
        "mori_settle_breathing_custom_exhale",
        "mori_settle_breathing_custom_uses_hold",
        "mori_settle_pomodoro_haptics_enabled",
        "mori_settle_pomodoro_animation_enabled",
        "mori_settle_pomodoro_focus_minutes",
        "mori_settle_pomodoro_short_break_minutes",
        "mori_settle_pomodoro_long_break_minutes",
        "mori_settle_pomodoro_cycles",
        "mori_settle_pomodoro_focus_breathing",
        "mori_settle_pomodoro_break_breathing"
    ]

    private static let focusAndReminderSharedKeys = [
        // Journal reminder preferences live in the app group for widgets.
        "journalReminderEnabled",
        "journalReminderHour",
        "journalReminderMinute",

        MoriScreenTimeShared.signalsKey,
        MoriScreenTimeShared.monitorHealthEventsKey,
        MoriScreenTimeShared.attemptsKey,
        MoriScreenTimeShared.activeSessionKey,
        MoriScreenTimeShared.dailyThresholdMinutesKey,
        MoriScreenTimeShared.beforeFeedDurationMinutesKey,
        MoriScreenTimeShared.beforeFeedDurationSecondsKey,
        MoriScreenTimeShared.beforeFeedNativeGateEnabledKey,
        MoriScreenTimeShared.beforeFeedHiddenAppLockEnabledKey,
        MoriScreenTimeShared.beforeFeedGraceWindowSecondsKey,
        MoriScreenTimeShared.beforeFeedGraceUntilKey,
        MoriScreenTimeShared.beforeFeedWindowTraceIDKey,
        MoriScreenTimeShared.beforeFeedPendingResetRequestKey,
        MoriScreenTimeShared.beforeFeedPendingResetSourceKey,
        MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey,
        MoriScreenTimeShared.beforeFeedPauseStyleKey,
        MoriScreenTimeShared.beforeFeedGuidedCycleCountKey,
        MoriScreenTimeShared.beforeFeedPausePreferencesMigrationKey,
        MoriScreenTimeShared.currentShieldFeatureKey,
        MoriScreenTimeShared.currentShieldSavedTimeSecondsKey,
        MoriScreenTimeShared.currentShieldSavedTimeCategoryKey,
        MoriScreenTimeShared.morningGateEnabledKey,
        MoriScreenTimeShared.morningGateStartHourKey,
        MoriScreenTimeShared.morningGateStartMinuteKey,
        MoriScreenTimeShared.morningGateDurationSecondsKey,
        MoriScreenTimeShared.morningGateHiddenAppLockEnabledKey,
        MoriScreenTimeShared.morningGateBreathingTechniqueIDKey,
        MoriScreenTimeShared.morningGateCompletedDateKey,
        MoriScreenTimeShared.morningGatePendingResetRequestKey,
        MoriScreenTimeShared.morningGatePendingResetSourceKey,
        MoriScreenTimeShared.quietTimerSessionKey
    ]
}

@MainActor
final class MoriDataDeletionService {
    static let shared = MoriDataDeletionService()

    private let standardDefaults: UserDefaults
    private let persistedData: MoriPersistedDataDeletion

    init(
        standardDefaults: UserDefaults = .standard,
        sharedDefaults: UserDefaults = MoriAppGroup.defaults
    ) {
        self.standardDefaults = standardDefaults
        persistedData = MoriPersistedDataDeletion(
            standardDefaults: standardDefaults,
            sharedDefaults: sharedDefaults
        )
    }

    func delete(_ category: MoriDataCategory) async throws {
        switch category {
        case .logsAndPhotos:
            GratitudeEntryStore(defaults: standardDefaults).deleteLocalEntries()
            GratitudeDraftStore(defaults: standardDefaults).clear()
            try GratitudePhotoStore.deleteAllPhotos()
        case .iCloudBackup:
            GratitudeEntryStore(defaults: standardDefaults).deleteICloudMirror()
            do { try await GratitudeCloudBackup.shared.delete() }
            catch { throw MoriDataDeletionError.cloudDeletionFailed }
        case .lifeGridAndCheckIns:
            persistedData.deleteLifeGridAndCheckIns()
            try WeekArchiveIdentityStore.shared.deleteAllIdentityData()
            MoriClarityStore.shared.clearAllForDataDeletion()
        case .recoveryHistory:
            persistedData.deleteRecoveryHistory()
        case .focusAndReminders:
            AttentionShieldManager.shared.resetAllProtectionData()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            persistedData.deleteFocusAndReminders()
            try ScreenTimeSettingsLockStore.shared.clearForDataDeletion()
        case .analytics:
            try await AnalyticsManager.shared.deleteAnalyticsData()
        }
    }

    func deleteEverything() async throws {
        var firstError: Error?
        for category in MoriDataCategory.allCases {
            do { try await delete(category) }
            catch { firstError = firstError ?? error }
        }

        // Always complete the local reset, even if an iCloud or analytics network
        // request failed. The caller can report that remote error separately.
        persistedData.finalizeFullDeletion()

        if let firstError { throw firstError }
    }
}
