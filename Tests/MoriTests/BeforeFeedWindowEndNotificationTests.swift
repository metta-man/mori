import XCTest
import UserNotifications
@testable import Mori

@MainActor
final class BeforeFeedWindowEndNotificationTests: XCTestCase {
    func testNotificationPlanUsesAuthoritativeExpiryAndStableIdentifier() throws {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let expiry = now.addingTimeInterval(15 * 60)

        let plan = try XCTUnwrap(
            BeforeFeedWindowEndNotificationPlan.make(graceUntil: expiry, now: now)
        )

        XCTAssertEqual(plan.identifier, MoriScreenTimeShared.beforeFeedWindowEndNotificationIdentifier)
        XCTAssertEqual(plan.fireDate, expiry)
        XCTAssertFalse(plan.title.isEmpty)
        XCTAssertFalse(plan.body.isEmpty)
    }

    func testNotificationPlanRejectsExpiredOrNearExpiredWindow() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)

        XCTAssertNil(BeforeFeedWindowEndNotificationPlan.make(graceUntil: now, now: now))
        XCTAssertNil(
            BeforeFeedWindowEndNotificationPlan.make(
                graceUntil: now.addingTimeInterval(1),
                now: now
            )
        )
    }

    func testWindowReminderDefaultsOffAndPersistsExplicitChoice() {
        let suite = "BeforeFeedWindowReminder.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)

        XCTAssertFalse(store.windowEndReminderEnabled())
        store.saveWindowEndReminderEnabled(true)
        XCTAssertTrue(store.windowEndReminderEnabled())
        store.saveWindowEndReminderEnabled(false)
        XCTAssertFalse(store.windowEndReminderEnabled())
    }

    func testWindowCompletionTargetHasStableDeepLinkValue() {
        XCTAssertEqual(
            MoriDeepLinkTarget.beforeFeedWindowComplete.rawValue,
            "before-feed-window-complete"
        )
    }

    func testAuthorizedReminderSchedulesWithoutRequestingPermission() async throws {
        let suite = "BeforeFeedWindowReminder.Authorized.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)
        store.saveWindowEndReminderEnabled(true)

        let added = expectation(description: "notification request added")
        let center = NotificationCenterStub(status: .authorized, added: added)
        let scheduler = BeforeFeedWindowEndNotificationScheduler(center: center, gateStore: store)
        let expiry = Date().addingTimeInterval(15 * 60)

        scheduler.scheduleIfPermitted(at: expiry)
        await fulfillment(of: [added], timeout: 1)

        let request = try XCTUnwrap(center.addedRequests.first)
        XCTAssertEqual(
            center.removedIdentifierBatches,
            [[MoriScreenTimeShared.beforeFeedWindowEndNotificationIdentifier]]
        )
        XCTAssertEqual(request.identifier, MoriScreenTimeShared.beforeFeedWindowEndNotificationIdentifier)
        XCTAssertTrue(
            request.content.userInfo.values.contains {
                ($0 as? String) == MoriDeepLinkTarget.beforeFeedWindowComplete.rawValue
            }
        )
        let trigger = try XCTUnwrap(request.trigger as? UNTimeIntervalNotificationTrigger)
        XCTAssertEqual(trigger.timeInterval, 15 * 60, accuracy: 2)
        XCTAssertEqual(center.authorizationRequestCount, 0)
    }

    func testDeniedReminderDoesNotScheduleOrRequestPermission() async {
        let suite = "BeforeFeedWindowReminder.Denied.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)
        store.saveWindowEndReminderEnabled(true)

        let checked = expectation(description: "authorization checked")
        let center = NotificationCenterStub(status: .denied, checked: checked)
        let scheduler = BeforeFeedWindowEndNotificationScheduler(center: center, gateStore: store)

        scheduler.scheduleIfPermitted(at: Date().addingTimeInterval(5 * 60))
        await fulfillment(of: [checked], timeout: 1)
        await Task.yield()

        XCTAssertTrue(center.addedRequests.isEmpty)
        XCTAssertEqual(center.authorizationRequestCount, 0)
    }

    func testDisabledReminderCancelsExistingRequestWithoutCheckingPermission() async {
        let suite = "BeforeFeedWindowReminder.Disabled.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)
        let center = NotificationCenterStub(status: .authorized)
        let scheduler = BeforeFeedWindowEndNotificationScheduler(center: center, gateStore: store)

        scheduler.scheduleIfPermitted(at: Date().addingTimeInterval(5 * 60))
        await Task.yield()

        XCTAssertEqual(
            center.removedIdentifierBatches,
            [[MoriScreenTimeShared.beforeFeedWindowEndNotificationIdentifier]]
        )
        XCTAssertEqual(center.authorizationStatusCheckCount, 0)
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func testSettingsAuthorizationRequestsOnlyWhenStatusIsUndetermined() async {
        let suite = "BeforeFeedWindowReminder.Permission.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)
        let requested = expectation(description: "permission requested")
        let center = NotificationCenterStub(
            status: .notDetermined,
            requestResult: true,
            requested: requested
        )
        let scheduler = BeforeFeedWindowEndNotificationScheduler(center: center, gateStore: store)

        let result = await withCheckedContinuation { continuation in
            scheduler.requestAuthorizationIfNeeded { granted in
                continuation.resume(returning: granted)
            }
        }
        await fulfillment(of: [requested], timeout: 1)

        XCTAssertTrue(result)
        XCTAssertEqual(center.authorizationRequestCount, 1)
        XCTAssertTrue(center.addedRequests.isEmpty)
    }
}

private final class NotificationCenterStub: BeforeFeedWindowEndNotificationCenter {
    private let status: UNAuthorizationStatus
    private let requestResult: Bool
    private let checkedExpectation: XCTestExpectation?
    private let requestedExpectation: XCTestExpectation?
    private let addedExpectation: XCTestExpectation?

    private(set) var authorizationStatusCheckCount = 0
    private(set) var authorizationRequestCount = 0
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedIdentifierBatches: [[String]] = []

    init(
        status: UNAuthorizationStatus,
        requestResult: Bool = false,
        checked: XCTestExpectation? = nil,
        requested: XCTestExpectation? = nil,
        added: XCTestExpectation? = nil
    ) {
        self.status = status
        self.requestResult = requestResult
        checkedExpectation = checked
        requestedExpectation = requested
        addedExpectation = added
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationStatusCheckCount += 1
        checkedExpectation?.fulfill()
        return status
    }

    func requestAlertAuthorization() async -> Bool {
        authorizationRequestCount += 1
        requestedExpectation?.fulfill()
        return requestResult
    }

    func add(_ request: UNNotificationRequest) async {
        addedRequests.append(request)
        addedExpectation?.fulfill()
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifierBatches.append(identifiers)
    }
}
