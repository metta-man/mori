//
//  AnalyticsManager.swift
//  Mori
//
//  Enhanced Analytics Manager with PostHog integration and loop-level tracking
//  Task: j57e6a9p2359eesrr4darj4ah1820nn4
//

import Foundation
import PostHog

// MARK: - Analytics Events
enum MoriEvent: String {
    // Core app events
    case appOpened = "app_opened"
    case lifeGridViewed = "life_grid_viewed"
    case countdownViewed = "countdown_viewed"
    case habitMarked = "habit_marked"
    case gratitudeSaved = "gratitude_saved"
    case settingsChanged = "settings_changed"
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"
    case firstGratitudeEntry = "first_gratitude_entry"
    case birthDateSet = "birth_date_set"
    
    // Loop-level events (core user interactions)
    case gridViewed = "loop_grid_view"
    case habitCheckIn = "loop_habit_checkin"
    case gratitudeEntry = "loop_gratitude_entry"
    case nextDayReturn = "loop_nextday_return"
    case paywallShown = "paywall_shown"
    case subscriptionStarted = "subscription_started"
    case trialStarted = "trial_started"
    
    // User engagement
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case dailyStreak = "daily_streak"
    case featureUsed = "feature_used"
    
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

// MARK: - Analytics Properties
struct AnalyticsProperties {
    static let empty: [String: Any] = [:]
    
    // User properties
    static let userId = "user_id"
    static let birthDate = "birth_date_timestamp"
    static let lifeExpectancy = "life_expectancy"
    static let hasCompletedOnboarding = "has_completed_onboarding"
    static let subscriptionTier = "subscription_tier"
    static let daysActive = "days_active"
    
    // Loop properties
    static let loopStep = "loop_step"
    static let habitName = "habit_name"
    static let habitType = "habit_type"
    static let gratitudePrompt = "gratitude_prompt"
    static let gratitudeLength = "gratitude_length"
    static let timeInApp = "time_in_app"
    
    // Engagement properties
    static let screenViewed = "screen_viewed"
    static let buttonClicked = "button_clicked"
    static let featureDuration = "feature_duration"
}

// MARK: - Analytics Configuration
struct AnalyticsConfig {
    static let apiKey = "phc_your_posthog_key_here"  // TODO: Replace with actual API key
    static let endpoint = "https://app.posthog.com"
}

// MARK: - Analytics Manager
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private var postHog: PHGPostHog?
    private var isConfigured = false
    private var sessionStartTime: Date?
    private var currentLoopStep: Int = 0
    private var lastGratitudeDate: Date?
    private var gratitudeCount = 0
    
    private init() {}
    
    // MARK: - Configuration
    func configure() {
        guard !isConfigured else { return }
        
        guard AnalyticsConfig.apiKey != "phc_your_posthog_key_here" else {
            #if DEBUG
            print("[Analytics] PostHog not configured - using debug mode")
            #endif
            return
        }

        let config = PHGPostHogConfiguration(
            apiKey: AnalyticsConfig.apiKey,
            host: AnalyticsConfig.endpoint
        )
        config.recordScreenViews = false
        config.captureApplicationLifecycleEvents = true

        PHGPostHog.setup(with: config)
        postHog = PHGPostHog.shared()
        PHGPostHog.debug(true)
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
        
        postHog?.identify(userId, properties: properties)
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
        
        // Track user status
        let userDefaults = UserDefaults.standard
        let hasOnboarded = userDefaults.bool(forKey: "hasCompletedOnboarding")
        let birthDate = userDefaults.object(forKey: "birthDate") as? Date
        
        var properties: [String: Any] = [
            AnalyticsProperties.hasCompletedOnboarding: hasOnboarded,
            AnalyticsProperties.daysActive: getUserActiveDays()
        ]

        if let birthDate {
            properties[AnalyticsProperties.birthDate] = birthDate.timeIntervalSince1970
        }

        identify(userId: getStableUserID(), properties: properties)
    }
    
    func trackFirstGratitudeEntry() {
        track(.firstGratitudeEntry, properties: [
            AnalyticsProperties.timeInApp: getTimeInApp(),
            "is_onboarding": true
        ])
    }
    
    func trackOnboardingStarted() {
        track(.onboardingStarted, properties: [
            AnalyticsProperties.timeInApp: getTimeInApp()
        ])
    }
    
    func trackOnboardingCompleted() {
        track(.onboardingCompleted, properties: [
            "steps_completed": 3,
            "time_spent": getTimeInApp(),
            "completion_method": "full_flow"
        ])
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
        let key = "analyticsUserID"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }

        let userID = "user_\(UUID().uuidString.prefix(8))"
        UserDefaults.standard.set(userID, forKey: key)
        return userID
    }
}

// MARK: - Convenience Extensions
extension AnalyticsManager {
    func trackLifeGridViewed() {
        track(.lifeGridViewed, properties: [
            "screen_name": "life_grid"
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
    
    func trackBirthDateSet(date: Date) {
        track(.birthDateSet, properties: [
            "timestamp": date.timeIntervalSince1970
        ])
    }
    
    private func getUserActiveDays() -> Int {
        // TODO: Implement active days tracking
        return 1
    }
}
