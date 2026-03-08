//
//  AnalyticsManager.swift
//  Mori
//
//  Analytics Manager - Stub implementation
//  TODO: Integrate PostHog for production
//

import Foundation

// MARK: - Analytics Events
enum MoriEvent: String {
    case appOpened = "app_opened"
    case lifeGridViewed = "life_grid_viewed"
    case countdownViewed = "countdown_viewed"
    case habitMarked = "habit_marked"
    case gratitudeSaved = "gratitude_saved"
    case settingsChanged = "settings_changed"
    case onboardingCompleted = "onboarding_completed"
    case birthDateSet = "birth_date_set"
    
    var defaultProperties: [String: Any]? {
        switch self {
        case .habitMarked:
            return ["is_positive": true]
        case .gratitudeSaved:
            return ["has_prompt": true]
        default:
            return nil
        }
    }
}

// MARK: - Analytics Manager
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // Configure - no-op in stub
    func configure() {
        // PostHog integration pending
        #if DEBUG
        print("[Analytics] Configured (stub)")
        #endif
    }
    
    // Track event - no-op in stub
    func track(_ event: MoriEvent, properties: [String: Any]? = nil) {
        #if DEBUG
        print("[Analytics] Track: \(event.rawValue)")
        #endif
    }
    
    // Identify user - no-op in stub
    func identify(userId: String, properties: [String: Any]? = nil) {
        #if DEBUG
        print("[Analytics] Identify: \(userId)")
        #endif
    }
    
    // Reset (logout) - no-op in stub
    func reset() {
        #if DEBUG
        print("[Analytics] Reset")
        #endif
    }
}

// MARK: - Convenience extensions
extension AnalyticsManager {
    func trackAppOpened() {
        track(.appOpened)
    }
    
    func trackLifeGridViewed() {
        track(.lifeGridViewed)
    }
    
    func trackCountdownViewed() {
        track(.countdownViewed)
    }
    
    func trackHabitMarked(isPositive: Bool) {
        track(.habitMarked, properties: ["is_positive": isPositive])
    }
    
    func trackGratitudeSaved(hasPrompt: Bool) {
        track(.gratitudeSaved, properties: ["has_prompt": hasPrompt])
    }
    
    func trackOnboardingCompleted() {
        track(.onboardingCompleted)
    }
    
    func trackBirthDateSet() {
        track(.birthDateSet)
    }
}
