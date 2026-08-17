import Foundation

enum AnalyticsConsentState: String {
    case undecided
    case optedIn
    case optedOut
}

struct AnalyticsUserSnapshot {
    let hasCompletedOnboarding: Bool
    let archiveStartDate: Date?
    let daysActive: Int
}

struct AnalyticsStateStore {
    private enum Key {
        static let analyticsUserID = "analyticsUserID"
        static let archiveStartDate = "archiveStartDate"
        static let archiveStartDateLegacyKey = "birthDate"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let screenTimeAttemptsLastSyncedAt = "analyticsScreenTimeAttemptsLastSyncedAt"
        static let consent = "analyticsConsentState"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func stableUserID() -> String {
        if let existing = defaults.string(forKey: Key.analyticsUserID) {
            return existing
        }

        let userID = "user_\(UUID().uuidString)"
        defaults.set(userID, forKey: Key.analyticsUserID)
        return userID
    }

    func existingUserID() -> String? { defaults.string(forKey: Key.analyticsUserID) }

    func consentState() -> AnalyticsConsentState {
        defaults.string(forKey: Key.consent)
            .flatMap(AnalyticsConsentState.init(rawValue:)) ?? .undecided
    }

    func saveConsentState(_ state: AnalyticsConsentState) {
        defaults.set(state.rawValue, forKey: Key.consent)
    }

    func clearAnalyticsIdentity() {
        defaults.removeObject(forKey: Key.analyticsUserID)
        defaults.removeObject(forKey: Key.screenTimeAttemptsLastSyncedAt)
    }

    func userSnapshot(daysActive: Int = 1) -> AnalyticsUserSnapshot {
        AnalyticsUserSnapshot(
            hasCompletedOnboarding: defaults.bool(forKey: Key.hasCompletedOnboarding),
            archiveStartDate: defaults.object(forKey: Key.archiveStartDate) as? Date ??
                defaults.object(forKey: Key.archiveStartDateLegacyKey) as? Date,
            daysActive: daysActive
        )
    }

    func screenTimeAttemptsLastSyncedAt() -> Date {
        defaults.object(forKey: Key.screenTimeAttemptsLastSyncedAt) as? Date ?? .distantPast
    }

    func saveScreenTimeAttemptsLastSyncedAt(_ date: Date) {
        defaults.set(date, forKey: Key.screenTimeAttemptsLastSyncedAt)
    }
}
