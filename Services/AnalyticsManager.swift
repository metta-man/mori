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
        guard stateStore.consentState() == .optedIn else { return }

        guard !AnalyticsConfig.apiKey.isEmpty else {
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
        config.captureApplicationLifecycleEvents = false
        #if DEBUG
        config.debug = true
        #else
        config.debug = false
        #endif

        PostHogSDK.shared.setup(config)
        postHog = PostHogSDK.shared
        isConfigured = true

        #if DEBUG
        print("[Analytics] PostHog configured successfully")
        #endif
    }

    // MARK: - Event Tracking
    func track(_ event: MoriEvent, properties: [String: Any]? = nil) {
        guard stateStore.consentState() == .optedIn else { return }
        configure()
        guard isConfigured else { return }

        let mergedProperties = sanitize(mergeDefaultProperties(event: event, custom: properties))
        postHog?.capture(event.rawValue, properties: mergedProperties)
    }

    // MARK: - User Identification
    func identify(userId: String, properties: [String: Any]? = nil) {
        guard stateStore.consentState() == .optedIn else { return }
        configure()
        guard isConfigured else { return }

        postHog?.identify(userId, userProperties: sanitize(properties ?? [:]))
    }

    // MARK: - Loop-Level Analytics (Core Feature)
    func trackLoopEvent(_ event: String, properties: [String: Any]? = nil) {
        currentLoopStep += 1

        let loopProperties: [String: Any] = [AnalyticsProperties.loopStep: bucket(count: currentLoopStep)]

        let mergedProperties = (properties ?? [:]).merging(loopProperties) { _, new in new }

        guard stateStore.consentState() == .optedIn else { return }
        configure()
        postHog?.capture(event, properties: sanitize(mergedProperties))

        #if DEBUG
        print("[Analytics] Loop Event: \(event) - Step: \(currentLoopStep)")
        #endif
    }

    // MARK: - Specialized Tracking Methods
    func trackAppOpened() {
        startSession()
        track(.appOpened)

        let user = stateStore.userSnapshot(daysActive: getUserActiveDays())
        let properties: [String: Any] = [
            AnalyticsProperties.hasCompletedOnboarding: user.hasCompletedOnboarding,
            AnalyticsProperties.daysActive: user.daysActive
        ]

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

    private func sanitize(_ properties: [String: Any]) -> [String: Any] {
        let blocked = Set([
            "timestamp", AnalyticsProperties.archiveStartDate, AnalyticsProperties.habitName,
            AnalyticsProperties.gratitudePrompt, "screen_name", "latest_date_key",
            "feature_breakdown", "category_breakdown"
        ])
        return properties.reduce(into: [:]) { result, item in
            guard !blocked.contains(item.key) else { return }
            switch item.key {
            case "character_count", AnalyticsProperties.gratitudeLength:
                result["entry_length_bucket"] = bucket(count: item.value as? Int ?? 0)
            case AnalyticsProperties.effectiveSelectedCount, "attempt_count", "gratitude_count":
                result["\(item.key)_bucket"] = bucket(count: item.value as? Int ?? 0)
            case AnalyticsProperties.timeInApp, AnalyticsProperties.featureDuration,
                 "time_spent", "duration_seconds", "estimated_saved_minutes":
                result["\(item.key)_bucket"] = durationBucket(item.value)
            default:
                if item.value is String || item.value is Bool || item.value is Int || item.value is Double {
                    result[item.key] = item.value
                }
            }
        }
    }

    private func bucket(count: Int) -> String {
        switch count {
        case ...0: return "0"
        case 1: return "1"
        case 2...5: return "2-5"
        case 6...20: return "6-20"
        default: return "21+"
        }
    }

    private func durationBucket(_ value: Any) -> String {
        let seconds = (value as? Double) ?? Double(value as? Int ?? 0)
        switch seconds {
        case ..<60: return "under_1m"
        case ..<300: return "1-5m"
        case ..<900: return "5-15m"
        default: return "15m+"
        }
    }

    func setConsent(_ state: AnalyticsConsentState) {
        stateStore.saveConsentState(state)
        if state == .optedIn {
            configure()
            postHog?.optIn()
        } else {
            postHog?.optOut()
            postHog?.reset()
            postHog = nil
            isConfigured = false
        }
    }

    func consentState() -> AnalyticsConsentState { stateStore.consentState() }

    func deleteAnalyticsData() async throws {
        if let userID = stateStore.existingUserID(),
           let url = URL(string: "https://mori-gray.vercel.app/api/privacy/analytics-delete") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["distinctId": userID])
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
        }
        postHog?.optOut()
        postHog?.reset()
        postHog = nil
        isConfigured = false
        stateStore.clearAnalyticsIdentity()
        stateStore.saveConsentState(.optedOut)
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
