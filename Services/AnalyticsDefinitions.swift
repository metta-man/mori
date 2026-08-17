import Foundation

enum MoriEvent: String {
    case appOpened = "app_opened"
    case todayViewed = "today_viewed"
    case weekArchiveViewed = "week_archive_viewed"
    case countdownViewed = "countdown_viewed"
    case habitMarked = "habit_marked"
    case gratitudeSaved = "gratitude_saved"
    case settingsChanged = "settings_changed"
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"
    case archiveStartDateSet = "archive_start_date_set"

    case habitCheckIn = "loop_habit_checkin"
    case gratitudeEntry = "loop_gratitude_entry"
    case nextDayReturn = "loop_nextday_return"
    case paywallShown = "paywall_shown"
    case subscriptionStarted = "subscription_started"
    case trialStarted = "trial_started"

    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case dailyStreak = "daily_streak"
    case featureUsed = "feature_used"
    case appRouteOpened = "app_route_opened"
    case firstAppLimitSetupEvent = "first_app_limit_setup_event"
    case screenTimeAttemptsRecorded = "screen_time_attempts_recorded"

    var defaultProperties: [String: Any]? {
        switch self {
        case .habitMarked:
            return ["is_positive": true]
        case .gratitudeSaved:
            return ["has_prompt": true, "character_count": 0]
        case .gratitudeEntry:
            return ["has_prompt": true, "character_count": 0, "is_first_entry": true]
        case .dailyStreak:
            return ["streak_length": 1, "is_best_streak": false]
        case .featureUsed:
            return ["feature_name": "", "usage_count": 1]
        default:
            return nil
        }
    }
}

struct AnalyticsProperties {
    static let empty: [String: Any] = [:]

    static let userId = "user_id"
    static let archiveStartDate = "archive_start_date_timestamp"
    static let hasCompletedOnboarding = "has_completed_onboarding"
    static let subscriptionTier = "subscription_tier"
    static let daysActive = "days_active"

    static let loopStep = "loop_step"
    static let habitName = "habit_name"
    static let habitType = "habit_type"
    static let gratitudePrompt = "gratitude_prompt"
    static let gratitudeLength = "gratitude_length"
    static let timeInApp = "time_in_app"

    static let screenViewed = "screen_viewed"
    static let buttonClicked = "button_clicked"
    static let featureDuration = "feature_duration"

    static let routeName = "route_name"
    static let routeSource = "route_source"
    static let sourceTab = "source_tab"
    static let destinationTab = "destination_tab"
    static let sourceSheet = "source_sheet"
    static let destinationSheet = "destination_sheet"
    static let sheetName = "sheet_name"
    static let launchKind = "launch_kind"

    static let setupContext = "setup_context"
    static let setupAction = "setup_action"
    static let screenTimeFeature = "screen_time_feature"
    static let isAuthorized = "is_authorized"
    static let hasEffectiveSelection = "has_effective_selection"
    static let effectiveSelectedCount = "effective_selected_count"
    static let appLimitEnabled = "app_limit_enabled"
    static let appLimitReady = "app_limit_ready"
    static let hasLastError = "has_last_error"
}

struct AnalyticsConfig {
    static var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "MORI_POSTHOG_API_KEY") as? String ?? ""
    }

    static var endpoint: String {
        Bundle.main.object(forInfoDictionaryKey: "MORI_POSTHOG_HOST") as? String
            ?? "https://eu.i.posthog.com"
    }
}
