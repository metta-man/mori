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

final class BeforeFeedAllowanceRepeatTests: XCTestCase {
    private func withStore(_ body: (BeforeFeedGateStore, UserDefaults) throws -> Void) throws {
        let suite = "mori.repeat.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults), defaults)
    }

    func testRepeatsIgnoreKeptClosedAndSurviveRelaunchAndDeduplicate() throws {
        try withStore { store, defaults in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let first = store.recordIntent(reason: .habit, routeSource: nil, openWindowSeconds: 120, now: now)
            store.recordKeptClosed(routeSource: nil, now: now.addingTimeInterval(10))
            let secondID = UUID()
            store.recordIntent(reason: .relax, routeSource: nil, openWindowSeconds: 300, eventID: secondID, now: now.addingTimeInterval(60))
            store.recordIntent(reason: .relax, routeSource: nil, eventID: secondID, now: now.addingTimeInterval(61))
            let restored = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)
            let repeatRequest = try XCTUnwrap(restored.allowanceRepeats().first)
            XCTAssertEqual(restored.intentEvents().count, 3)
            XCTAssertEqual(repeatRequest.previousEventID, first.id)
            XCTAssertEqual(repeatRequest.secondsSincePreviousAllowance, 60)
            XCTAssertEqual(repeatRequest.secondsSincePreviousPlannedEnd, -60)
            XCTAssertEqual(repeatRequest.requestedWithinPreviousPlannedWindow, true)
            store.recordIntent(reason: .learn, routeSource: nil, now: now.addingTimeInterval(400))
            XCTAssertEqual(store.allowanceRepeats().last?.secondsSincePreviousPlannedEnd, 40)
            // Cancellation creates no confirmed allowance; no additional repeat.
            XCTAssertEqual(store.allowanceRepeats().count, 2)
            store.clearIntentHistory()
            XCTAssertTrue(restored.intentEvents().isEmpty)
            XCTAssertTrue(restored.allowanceRepeats().isEmpty)
        }
    }

    func testLegacyUnknownWindowIsNotInferredAndOldHistoryIsPreserved() throws {
        try withStore { store, defaults in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let legacy = MoriBeforeFeedIntentEvent(id: UUID(), reason: .habit, confirmedAt: now, routeSource: nil)
            let encoded = try JSONEncoder().encode([legacy])
            defaults.set(encoded, forKey: "mori_before_feed_intent_events_v1")
            store.recordIntent(reason: .other, routeSource: nil, now: now.addingTimeInterval(0.5))
            XCTAssertNil(store.allowanceRepeats().first?.secondsSincePreviousPlannedEnd)
            XCTAssertNil(store.allowanceRepeats().first?.requestedWithinPreviousPlannedWindow)
            for offset in 1...(BeforeFeedGateStore.recentIntentEventLimit + 1) {
                store.recordIntent(reason: .other, routeSource: nil, now: now.addingTimeInterval(Double(offset)))
            }
            XCTAssertEqual(defaults.data(forKey: "mori_before_feed_intent_events_v1"), encoded)
            XCTAssertEqual(store.intentEvents().count, BeforeFeedGateStore.recentIntentEventLimit + 1)
            XCTAssertEqual(store.allowanceRepeats().count, BeforeFeedGateStore.recentIntentEventLimit - 1)
            XCTAssertFalse(store.allowanceRepeats().contains { $0.previousEventID == legacy.id })
            store.clearIntentHistory()
            XCTAssertNil(defaults.data(forKey: "mori_before_feed_intent_events_v1"))
            XCTAssertNil(defaults.data(forKey: "mori_before_feed_intent_events_v2_recent"))
        }
    }
}

final class BeforeFeedGentleReentryTests: XCTestCase {
    private func withStore(_ body: (BeforeFeedGateStore, UserDefaults) throws -> Void) throws {
        let name = "mori.gentle.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults), defaults)
    }

    private func request(_ store: BeforeFeedGateStore, now: Date, id: UUID = UUID(), seconds: Int = 300) -> MoriBeforeFeedAllowanceRequest {
        MoriBeforeFeedAllowanceRequest(eligibility: store.beginFreshAllowanceFlow(now: now), reason: .habit, routeSource: nil, enoughChoiceID: "5_minutes", openWindowSeconds: seconds,
            returnAnchorID: "work", eventID: id, historyGeneration: store.historyGeneration, now: now)
    }

    func testFractionalDateConfirmationAndShortcutReentryPreserveDeadline() throws {
        try withStore { store, _ in
            let now = Date(timeIntervalSince1970: 2_000_000_000.1234567)
            let saved = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            XCTAssertTrue(store.requestResetLaunchIfNeeded(now: now.addingTimeInterval(120), source: .shortcut))
            XCTAssertEqual(store.graceUntil(now: now.addingTimeInterval(120))?.timeIntervalSince1970, saved.endsAt.timeIntervalSince1970)
            XCTAssertTrue(store.requestResetLaunchIfNeeded(now: now.addingTimeInterval(180), source: .shortcut))
            XCTAssertEqual(store.graceUntil(now: now.addingTimeInterval(121))?.timeIntervalSince1970, saved.endsAt.timeIntervalSince1970)
        }
    }

    func testWholeActiveWindowAndExpiryBoundary() throws {
        try withStore { store, _ in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let saved = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            for (offset, expected) in [(60.0, true), (180.0, true), (299.0, true), (300.0, false)] {
                var entry = MoriBeforeFeedReentryState()
                entry.evaluate(events: store.intentEvents(), now: now.addingTimeInterval(offset), allowanceEndsAt: store.graceUntil(now: now.addingTimeInterval(offset)))
                XCTAssertEqual(entry.previousAllowance?.id == saved.event.id, expected)
            }
        }
    }

    func testResumeCannotRetriggerButNewEntryCanAndKeptClosedDoesNotReplaceLatestAllowance() throws {
        try withStore { store, _ in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            var oldEntry = MoriBeforeFeedReentryState()
            oldEntry.evaluate(events: [], now: now, allowanceEndsAt: store.graceUntil(now: now))
            let saved = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            store.recordKeptClosed(routeSource: nil, now: now.addingTimeInterval(10))
            oldEntry.evaluate(events: store.intentEvents(), now: now.addingTimeInterval(20), allowanceEndsAt: store.graceUntil(now: now.addingTimeInterval(20)))
            XCTAssertNil(oldEntry.previousAllowance)
            for _ in 0..<2 {
                var newEntry = MoriBeforeFeedReentryState()
                newEntry.evaluate(events: store.intentEvents(), now: now.addingTimeInterval(30), allowanceEndsAt: store.graceUntil(now: now.addingTimeInterval(30)))
                XCTAssertEqual(newEntry.previousAllowance?.id, saved.event.id)
            }
        }
    }

    func testEntryCancellationAndReturnDoNotChangeExistingAllowance() throws {
        try withStore { store, _ in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let saved = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            var entry = MoriBeforeFeedReentryState()
            entry.evaluate(events: store.intentEvents(), now: now.addingTimeInterval(10), allowanceEndsAt: store.graceUntil(now: now.addingTimeInterval(10)))
            XCTAssertEqual(store.graceUntil(now: now.addingTimeInterval(20)), saved.endsAt)
            XCTAssertEqual(store.intentEvents().count, 1)
        }
    }

    func testReuseKeepsDeadlineAcrossRepeatedTapsRelaunchAndRejectsExpiredOrReplaced() throws {
        try withStore { store, defaults in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let saved = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            for offset in [60.0, 180.0, 299.0] {
                let restored = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)
                for _ in 0..<3 {
                    XCTAssertTrue(restored.canReuseAllowance(endsAt: saved.endsAt, historyGeneration: store.historyGeneration, now: now.addingTimeInterval(offset)))
                }
                XCTAssertEqual(restored.intentEvents().count, 1)
                XCTAssertEqual(restored.graceUntil(now: now.addingTimeInterval(offset)), saved.endsAt)
            }
            XCTAssertFalse(store.canReuseAllowance(endsAt: saved.endsAt, historyGeneration: store.historyGeneration, now: saved.endsAt))
            XCTAssertNil(store.confirmAllowance(request(store, now: now.addingTimeInterval(180), seconds: 120)))
            XCTAssertFalse(store.canReuseAllowance(endsAt: saved.endsAt, historyGeneration: "stale", now: now.addingTimeInterval(181)))
            let replaced = try XCTUnwrap(store.confirmAllowance(request(store, now: saved.endsAt, seconds: 120)))
            XCTAssertNotEqual(replaced.endsAt, saved.endsAt)
            XCTAssertFalse(store.canReuseAllowance(endsAt: saved.endsAt, historyGeneration: store.historyGeneration, now: saved.endsAt.addingTimeInterval(1)))
        }
    }

    func testQueuedExpiryCannotEndReplacementOrClearedAllowance() throws {
        try withStore { store, _ in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let first = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            XCTAssertFalse(store.shouldReapplyExpiredAllowance(endsAt: first.endsAt, now: first.endsAt.addingTimeInterval(-1)))
            XCTAssertTrue(store.shouldReapplyExpiredAllowance(endsAt: first.endsAt, now: first.endsAt))
            let replacement = try XCTUnwrap(store.confirmAllowance(request(store, now: first.endsAt)))
            XCTAssertFalse(store.shouldReapplyExpiredAllowance(endsAt: first.endsAt, now: first.endsAt))
            XCTAssertTrue(store.shouldReapplyExpiredAllowance(endsAt: replacement.endsAt, now: replacement.endsAt))
            store.clearGraceUntil()
            XCTAssertFalse(store.shouldReapplyExpiredAllowance(endsAt: replacement.endsAt, now: replacement.endsAt))
        }
    }

    func testFreshConfirmationAfterExpiryStartsFromNowExactlyOnce() throws {
        try withStore { store, _ in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            _ = store.confirmAllowance(request(store, now: now))
            let newRequest = request(store, now: now.addingTimeInterval(300), seconds: 120)
            let first = try XCTUnwrap(store.confirmAllowance(newRequest))
            let duplicate = try XCTUnwrap(store.confirmAllowance(newRequest))
            XCTAssertTrue(first.isNew)
            XCTAssertFalse(duplicate.isNew)
            XCTAssertEqual(first.endsAt, now.addingTimeInterval(420))
            XCTAssertEqual(store.graceUntil(now: now.addingTimeInterval(300)), first.endsAt)
            XCTAssertEqual(store.intentEvents().count, 2)
        }
    }

    func testFailedSavePreservesPreviousWindowAndDoesNotConfirm() throws {
        try withStore { store, defaults in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let saved = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            let failing = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults, persistData: { _, _ in false })
            XCTAssertNil(failing.confirmAllowance(request(failing, now: saved.endsAt, seconds: 120)))
            XCTAssertNil(store.graceUntil(now: saved.endsAt))
            XCTAssertEqual(store.intentEvents().count, 1)
        }
    }

    func testHistoryDeletedDuringSaveCannotBeRecreatedByStaleCallback() throws {
        try withStore { store, defaults in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let original = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            let staleRequest = request(store, now: original.endsAt)
            let interrupted = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults, persistData: { data, key in
                store.clearIntentHistory()
                defaults.set(data, forKey: key)
                return true
            })
            XCTAssertNil(interrupted.confirmAllowance(staleRequest))
            XCTAssertTrue(store.intentEvents().isEmpty)
            XCTAssertNil(store.graceUntil(now: original.endsAt))
        }
    }

    func testActiveEntryCannotBecomeEligibleByWaitingForExpiryOrRelaunch() throws {
        try withStore { store, defaults in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let first = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            let activeTicket = store.beginFreshAllowanceFlow(now: now.addingTimeInterval(1))
            XCTAssertNil(activeTicket)
            let stale = MoriBeforeFeedAllowanceRequest(eligibility: activeTicket, reason: .habit, routeSource: "shortcut", enoughChoiceID: "5_minutes", openWindowSeconds: 300, returnAnchorID: nil, eventID: UUID(), historyGeneration: store.historyGeneration, now: first.endsAt)
            let restored = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)
            XCTAssertNil(restored.confirmAllowance(stale))
            XCTAssertEqual(restored.intentEvents().count, 1)
            XCTAssertNotNil(restored.confirmAllowance(request(restored, now: first.endsAt)))
        }
    }

    func testInterveningAllowanceInvalidatesOldFreshSheetEvenAfterExpiry() throws {
        try withStore { store, defaults in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let oldTicket = try XCTUnwrap(store.beginFreshAllowanceFlow(now: now))
            let granted = try XCTUnwrap(store.confirmAllowance(request(store, now: now.addingTimeInterval(1))))
            let stale = MoriBeforeFeedAllowanceRequest(eligibility: oldTicket, reason: .habit, routeSource: nil, enoughChoiceID: "5_minutes", openWindowSeconds: 300, returnAnchorID: nil, eventID: UUID(), historyGeneration: store.historyGeneration, now: granted.endsAt)
            let restored = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)
            XCTAssertNil(restored.confirmAllowance(stale))
            XCTAssertEqual(restored.intentEvents().count, 1)
            let fresh = request(restored, now: granted.endsAt)
            let saved = try XCTUnwrap(restored.confirmAllowance(fresh))
            XCTAssertFalse(try XCTUnwrap(restored.confirmAllowance(fresh)).isNew)
            XCTAssertEqual(restored.graceUntil(now: granted.endsAt), saved.endsAt)
            XCTAssertEqual(restored.intentEvents().count, 2)
        }
    }

    func testDeletedHistoryRejectsStaleConfirmationAndRelaunchRestoresSuccessfulOne() throws {
        try withStore { store, defaults in
            let now = Date(timeIntervalSince1970: 2_000_000_000)
            let stale = request(store, now: now)
            store.clearIntentHistory()
            XCTAssertNil(store.confirmAllowance(stale))
            XCTAssertTrue(store.intentEvents().isEmpty)
            let saved = try XCTUnwrap(store.confirmAllowance(request(store, now: now)))
            let restored = BeforeFeedGateStore(defaults: defaults, legacyDefaults: defaults)
            XCTAssertEqual(restored.intentEvents().last?.id, saved.event.id)
            XCTAssertEqual(restored.graceUntil(now: now), saved.endsAt)
        }
    }
}
