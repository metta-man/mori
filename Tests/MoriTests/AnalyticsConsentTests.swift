import XCTest
@testable import Mori

final class AnalyticsConsentTests: XCTestCase {
    func testConsentDefaultsToUndecidedAndPersists() {
        let suite = "AnalyticsConsentTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AnalyticsStateStore(defaults: defaults)

        XCTAssertEqual(store.consentState(), .undecided)
        store.saveConsentState(.optedIn)
        XCTAssertEqual(store.consentState(), .optedIn)
    }

    func testStableIDUsesFullUUID() {
        let suite = "AnalyticsIdentityTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let id = AnalyticsStateStore(defaults: defaults).stableUserID()
        XCTAssertTrue(id.hasPrefix("user_"))
        XCTAssertNotNil(UUID(uuidString: String(id.dropFirst(5))))
    }
}
