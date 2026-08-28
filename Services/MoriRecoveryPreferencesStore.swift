import Foundation

struct MoriRecoveryPreferencesStore {
    static let authorizationRequestedKey = "mori_recovery_health_authorization_requested"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasRequestedAuthorization() -> Bool {
        defaults.bool(forKey: Self.authorizationRequestedKey)
    }

    func markAuthorizationRequested() {
        defaults.set(true, forKey: Self.authorizationRequestedKey)
    }

    func clear() {
        defaults.removeObject(forKey: Self.authorizationRequestedKey)
    }
}
