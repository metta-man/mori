//
//  AnalyticsManager.swift
//  Mori
//
//  Enhanced Analytics Manager with PostHog integration and loop-level tracking
//  Task: j57e6a9p2359eesrr4darj4ah1820nn4
//

import Foundation
import PostHog

// MARK: - Analytics Manager
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private var postHog: PostHogSDK?
    private var isConfigured = false
    private var sessionStartTime: Date?
    private var currentLoopStep: Int = 0
    private var gratitudeCount = 0
    private let stateStore: AnalyticsStateStore

    private init(stateStore: AnalyticsStateStore = AnalyticsStateStore()) {
        self.stateStore = stateStore
    }

    // MARK: - Configuration
    func configure() {
        guard !isConfigured else { return }

        guard AnalyticsConfig.apiKey != "phc_your_posthog_key_here" else {
            #if DEBUG
            print("[Analytics] PostHog not configured - using debug mode")
            #endif
            return
        }

        let config = PostHogConfig(
            apiKey: AnalyticsConfig.apiKey,
            host: AnalyticsConfig.endpoint
        )
        config.captureScreenViews = false
        config.captureApplicationLifecycleEvents = true
        config.debug = true

        PostHogSDK.shared.setup(config)
        postHog = PostHogSDK.shared
        isConfigured = true

        #if DEBUG
        print("[Analytics] PostHog configured successfully")
        #endif
    }

    // MARK: - Event Tracking
    func track(_ event: MoriEvent, properties: [String: Any]? = nil) {
        guard isConfigured else {
            #if DEBUG
            print("[Analytics] Track: \(event.rawValue) - Properties: \(properties ?? [:])")
            #endif
            return
        }

        let mergedProperties = mergeDefaultProperties(event: event, custom: properties)
        postHog?.capture(event.rawValue, properties: mergedProperties)
    }

    // MARK: - User Identification
    func identify(userId: String, properties: [String: Any]? = nil) {
        guard isConfigured else {
            #if DEBUG
            print("[Analytics] Identify: \(userId) - Properties: \(properties ?? [:])")
            #endif
            return
        }

        postHog?.identify(userId, userProperties: properties)
    }

    // MARK: - Loop-Level Analytics (Core Feature)
    func trackLoopEvent(_ event: String, properties: [String: Any]? = nil) {
        currentLoopStep += 1

        let loopProperties: [String: Any] = [
            AnalyticsProperties.loopStep: currentLoopStep,
            "timestamp": Date().timeIntervalSince1970,
            "session_day": getCurrentSessionDay()
        ]

        let mergedProperties = (properties ?? [:]).merging(loopProperties) { _, new in new }

        if isConfigured {
            postHog?.capture(event, properties: mergedProperties)
        }

        #if DEBUG
        print("[Analytics] Loop Event: \(event) - Step: \(currentLoopStep)")
        #endif
    }

    // MARK: - Specialized Tracking Methods
    func trackAppOpened() {
        startSession()
        track(.appOpened)

        let user = stateStore.userSnapshot(daysActive: getUserActiveDays())
        var properties: [String: Any] = [
            AnalyticsProperties.hasCompletedOnboarding: user.hasCompletedOnboarding,
            AnalyticsProperties.daysActive: user.daysActive
        ]

        if let archiveStartDate = user.archiveStartDate {
            properties[AnalyticsProperties.archiveStartDate] = archiveStartDate.timeIntervalSince1970
        }

        identify(userId: getStableUserID(), properties: properties)
    }

    func trackOnboardingStarted() {
        track(.onboardingStarted, properties: [
            AnalyticsProperties.timeInApp: getTimeInApp()
        ])
    }

    func trackOnboardingCompleted(
        stepsCompleted: Int = 2,
        completionMethod: String = "first_app_limit_flow"
    ) {
        track(.onboardingCompleted, properties: [
            "steps_completed": stepsCompleted,
            "time_spent": getTimeInApp(),
            "completion_method": completionMethod
        ])
    }

    func trackAppRouteOpened(routeName: String, properties: [String: Any]) {
        track(.appRouteOpened, properties: properties.merging([
            AnalyticsProperties.routeName: routeName,
            AnalyticsProperties.timeInApp: getTimeInApp()
        ]) { _, new in new })
    }

    func trackFirstAppLimitSetupEvent(
        action: String,
        context: String,
        routeSource: String? = nil,
        snapshot: AppLimitSettingsSnapshot,
        summary: MoriScreenTimeProfileSummary
    ) {
        var properties: [String: Any] = [
            AnalyticsProperties.setupAction: action,
            AnalyticsProperties.setupContext: context,
            AnalyticsProperties.screenTimeFeature: summary.feature.rawValue,
            AnalyticsProperties.isAuthorized: snapshot.isAuthorized,
            AnalyticsProperties.hasEffectiveSelection: summary.hasEffectiveSelection,
            AnalyticsProperties.effectiveSelectedCount: summary.effectiveSelectedCount,
            AnalyticsProperties.appLimitEnabled: summary.isEnabled,
            AnalyticsProperties.appLimitReady: snapshot.isAuthorized && summary.isEnabled && summary.hasEffectiveSelection,
            AnalyticsProperties.hasLastError: snapshot.lastErrorMessage != nil,
            AnalyticsProperties.timeInApp: getTimeInApp()
        ]

        if let routeSource {
            properties[AnalyticsProperties.routeSource] = routeSource
        }

        track(.firstAppLimitSetupEvent, properties: properties)
    }

    // MARK: - Helper Methods
    private func mergeDefaultProperties(event: MoriEvent, custom: [String: Any]?) -> [String: Any] {
        var merged = event.defaultProperties ?? [:]
        merged.merge(custom ?? [:]) { _, new in new }
        return merged
    }

    private func getCurrentSessionDay() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([ .day, .month, .year], from: Date())
        return calendar.dateComponents([ .day], from: calendar.date(from: components)!).day ?? 1
    }

    private func getTimeInApp() -> TimeInterval {
        guard let sessionStartTime else { return 0 }
        return Date().timeIntervalSince(sessionStartTime)
    }

    // MARK: - Session Management
    func startSession() {
        sessionStartTime = Date()
        track(.sessionStarted)
    }

    func endSession() {
        guard let startTime = sessionStartTime else { return }

        let sessionDuration = Date().timeIntervalSince(startTime)
        track(.sessionEnded, properties: ["duration_seconds": sessionDuration])
        sessionStartTime = nil
    }

    // MARK: - Paywall Integration
    func trackGratitudeSaved(text: String, hasPrompt: Bool = false) {
        gratitudeCount += 1

        // Track as loop event
        let properties: [String: Any] = [
            "has_prompt": hasPrompt,
            AnalyticsProperties.gratitudeLength: text.count,
            "gratitude_count": gratitudeCount,
            AnalyticsProperties.timeInApp: getTimeInApp()
        ]

        track(.gratitudeSaved, properties: properties)
        trackLoopEvent("gratitude_entry", properties: properties)

        // Check if paywall should be shown (after 5th gratitude)
        if gratitudeCount >= 5 {
            showPaywallIfNeeded()
        }
    }

    private func showPaywallIfNeeded() {
        let properties: [String: Any] = [
            "trigger_reason": "gratitude_limit",
            "gratitude_count": gratitudeCount,
            "days_in_trial": getDaysInTrial(),
            AnalyticsProperties.timeInApp: getTimeInApp()
        ]

        track(.paywallShown, properties: properties)
    }

    private func getDaysInTrial() -> Int {
        // TODO: Calculate days in trial
        return 1
    }

    private func getStableUserID() -> String {
        stateStore.stableUserID()
    }
}

// MARK: - Convenience Extensions
extension AnalyticsManager {
    func trackTodayViewed() {
        track(.todayViewed, properties: [
            "screen_name": "today"
        ])
    }

    func trackWeekArchiveViewed() {
        track(.weekArchiveViewed, properties: [
            "screen_name": "week_archive"
        ])
    }

    func trackHabitMarked(isPositive: Bool) {
        track(.habitMarked, properties: [
            "is_positive": isPositive
        ])
    }

    func trackOnboardingSkipped() {
        track(.onboardingSkipped)
    }

    func trackArchiveStartDateSet(date: Date) {
        track(.archiveStartDateSet, properties: [
            "timestamp": date.timeIntervalSince1970
        ])
    }

    func trackScreenTimeAttemptsIfNeeded() {
        let attempts = MoriScreenTimeAttemptStore.allAttempts()
        guard !attempts.isEmpty else { return }

        let lastSyncedAt = stateStore.screenTimeAttemptsLastSyncedAt()
        let newAttempts = attempts.filter { $0.attemptedAt > lastSyncedAt }
        guard !newAttempts.isEmpty,
              let newestAttemptAt = newAttempts.map(\.attemptedAt).max()
        else {
            return
        }

        let savedSeconds = newAttempts.reduce(0) { $0 + $1.estimatedSavedSeconds }
        let savedMinutes = savedSeconds > 0 ? Int(ceil(Double(savedSeconds) / 60.0)) : 0
        let featureBreakdown = newAttempts.reduce(into: [String: Int]()) { result, attempt in
            result[attempt.feature?.rawValue ?? "unknown", default: 0] += 1
        }
        let categoryBreakdown = newAttempts.reduce(into: [String: Int]()) { result, attempt in
            result[attempt.savedTimeCategory.rawValue, default: 0] += 1
        }

        track(.screenTimeAttemptsRecorded, properties: [
            "latest_date_key": MoriScreenTimeShared.dateKey(for: newestAttemptAt),
            "attempt_count": newAttempts.count,
            "estimated_saved_minutes": savedMinutes,
            "feature_breakdown": featureBreakdown,
            "category_breakdown": categoryBreakdown
        ])
        stateStore.saveScreenTimeAttemptsLastSyncedAt(newestAttemptAt)
    }

    private func getUserActiveDays() -> Int {
        // TODO: Implement active days tracking
        return 1
    }
}
