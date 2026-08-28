//
//  AnalyticsManager.swift
//  Mori
//
//  Enhanced Analytics Manager with PostHog integration and loop-level tracking
//  Task: j57e6a9p2359eesrr4darj4ah1820nn4
//

import Foundation
import PostHog

protocol AnalyticsRemoteDeleting {
    func deleteAnalyticsData(for userID: String) async throws
}

protocol AnalyticsUploadDraining {
    func waitForInFlightUploads() async throws
}

/// PINNED-SDK PRIVACY INVARIANT:
/// posthog-ios 3.9.1 gives batch and replay uploads a 10-second request timeout,
/// while `PostHogSDK.close()` only stops future queue work and cannot cancel an
/// upload that already started. Remote deletion must therefore remain behind
/// this barrier, and the interval must be re-audited before upgrading PostHog.
struct PostHogUploadDrainBarrier: AnalyticsUploadDraining {
    private static let drainNanoseconds: UInt64 = 12_000_000_000

    func waitForInFlightUploads() async throws {
        try await Task.sleep(nanoseconds: Self.drainNanoseconds)
    }
}

struct AnalyticsRemoteDeletionClient: AnalyticsRemoteDeleting {
    private let session: URLSession
    private let endpoint: URL

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://mori-gray.vercel.app/api/privacy/analytics-delete")!
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func deleteAnalyticsData(for userID: String) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["distinctId": userID])

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 202 else {
            throw URLError(.badServerResponse)
        }
    }
}

protocol AnalyticsLocalDataClearing {
    func clear(postHog: PostHogSDK?) throws
}

struct PostHogLocalDataCleaner: AnalyticsLocalDataClearing {
    private let fileManager: FileManager
    private let storageDirectory: () throws -> URL

    init(
        fileManager: FileManager = .default,
        storageDirectory: (() throws -> URL)? = nil
    ) {
        self.fileManager = fileManager
        self.storageDirectory = storageDirectory ?? {
            guard let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first,
            let bundleIdentifier = Bundle.main.bundleIdentifier else {
                throw CocoaError(.fileNoSuchFile)
            }
            return applicationSupport.appendingPathComponent(bundleIdentifier, isDirectory: true)
        }
    }

    func clear(postHog: PostHogSDK?) throws {
        // Stop capture and queue timers before deleting the SDK's file-backed queues.
        postHog?.optOut()
        postHog?.close()

        let directory = try storageDirectory()
        for name in Self.postHogStorageNames {
            let url = directory.appendingPathComponent(name)
            guard fileManager.fileExists(atPath: url.path) else { continue }
            try fileManager.removeItem(at: url)
        }
    }

    // These names are the complete PostHogStorage keys in the pinned posthog-ios 3.9.1 SDK.
    private static let postHogStorageNames = [
        "posthog.distinctId",
        "posthog.anonymousId",
        "posthog.queueFolder",
        "posthog.queue.plist",
        "posthog.replayFolder",
        "posthog.enabledFeatureFlags",
        "posthog.enabledFeatureFlagPayloads",
        "posthog.groups",
        "posthog.registerProperties",
        "posthog.optOut",
        "posthog.sessionReplay"
    ]
}

enum AnalyticsDeletionError: LocalizedError {
    case remoteDeletionFailed(Error)
    case localCleanupFailed(Error)
    case remoteAndLocalCleanupFailed(remote: Error, local: Error)

    var errorDescription: String? {
        switch self {
        case .remoteDeletionFailed:
            "Analytics collection is disabled and local analytics data was removed, but Mori could not queue deletion from PostHog. Check your connection and try again."
        case .localCleanupFailed:
            "Analytics collection is disabled, but Mori could not finish removing queued analytics from this device. Try again before enabling analytics."
        case .remoteAndLocalCleanupFailed:
            "Analytics collection is disabled, but local cleanup and the PostHog deletion request did not finish. Check your connection and try again."
        }
    }
}

// MARK: - Analytics Manager
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private var postHog: PostHogSDK?
    private var isConfigured = false
    private var sessionStartTime: Date?
    private var currentLoopStep: Int = 0
    private var gratitudeCount = 0
    private let stateStore: AnalyticsStateStore
    private let remoteDeletionClient: AnalyticsRemoteDeleting
    private let localDataCleaner: AnalyticsLocalDataClearing
    private let uploadDrainBarrier: AnalyticsUploadDraining

    init(
        stateStore: AnalyticsStateStore = AnalyticsStateStore(),
        remoteDeletionClient: AnalyticsRemoteDeleting = AnalyticsRemoteDeletionClient(),
        localDataCleaner: AnalyticsLocalDataClearing = PostHogLocalDataCleaner(),
        uploadDrainBarrier: AnalyticsUploadDraining = PostHogUploadDrainBarrier()
    ) {
        self.stateStore = stateStore
        self.remoteDeletionClient = remoteDeletionClient
        self.localDataCleaner = localDataCleaner
        self.uploadDrainBarrier = uploadDrainBarrier
    }

    // MARK: - Configuration
    func configure() {
        guard !isConfigured else { return }
        guard stateStore.consentState() == .optedIn else { return }
        guard !stateStore.isLocalPurgePending() else { return }

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
        if state == .optedIn {
            if stateStore.isLocalPurgePending() {
                do {
                    try localDataCleaner.clear(postHog: postHog)
                    stateStore.clearLocalPurgePending()
                } catch {
                    stateStore.saveConsentState(.optedOut)
                    postHog = nil
                    isConfigured = false
                    return
                }
                postHog = nil
                isConfigured = false
            }
            stateStore.saveConsentState(.optedIn)
            configure()
            postHog?.optIn()
        } else {
            stateStore.saveConsentState(state)
            stateStore.markLocalPurgePending()
            do {
                try localDataCleaner.clear(postHog: postHog)
                stateStore.clearLocalPurgePending()
            } catch {
                #if DEBUG
                print("[Analytics] Failed to purge local PostHog data: \(error)")
                #endif
            }
            postHog = nil
            isConfigured = false
        }
    }

    func consentState() -> AnalyticsConsentState { stateStore.consentState() }

    func deleteAnalyticsData() async throws {
        if let activeUserID = stateStore.existingUserID() {
            stateStore.enqueuePendingDeletionUserID(activeUserID)
        }

        // Local privacy state is committed before any fallible network operation.
        stateStore.saveConsentState(.optedOut)
        stateStore.markLocalPurgePending()
        stateStore.clearAnalyticsIdentity()

        var localCleanupError: Error?
        do {
            try localDataCleaner.clear(postHog: postHog)
            stateStore.clearLocalPurgePending()
        } catch {
            localCleanupError = error
        }
        postHog = nil
        isConfigured = false

        var remoteDeletionError: Error?
        let pendingUserIDs = stateStore.pendingDeletionUserIDs()
        if !pendingUserIDs.isEmpty {
            do {
                try await uploadDrainBarrier.waitForInFlightUploads()
                try Task.checkCancellation()
            } catch {
                if isCancellation(error) { throw error }
                remoteDeletionError = error
            }
        }

        if remoteDeletionError == nil {
            for userID in pendingUserIDs {
                do {
                    try Task.checkCancellation()
                    try await remoteDeletionClient.deleteAnalyticsData(for: userID)
                    stateStore.removePendingDeletionUserID(userID)
                } catch {
                    if isCancellation(error) { throw error }
                    remoteDeletionError = remoteDeletionError ?? error
                }
            }
        }

        switch (remoteDeletionError, localCleanupError) {
        case let (remote?, local?):
            throw AnalyticsDeletionError.remoteAndLocalCleanupFailed(remote: remote, local: local)
        case let (remote?, nil):
            throw AnalyticsDeletionError.remoteDeletionFailed(remote)
        case let (nil, local?):
            throw AnalyticsDeletionError.localCleanupFailed(local)
        case (nil, nil):
            return
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        error is CancellationError || (error as? URLError)?.code == .cancelled
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
