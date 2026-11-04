import Foundation
import XCTest
@testable import MoriProtection

final class ProtectionTests: XCTestCase {
    private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }
    private func state() -> ProtectionState {
        var c = ProtectionConfiguration.newSetup
        c.timeZoneIdentifier = "UTC"
        c.morningEnabled = true
        c.morningStartMinute = 4 * 60
        c.morningDetectionEndMinute = 12 * 60
        return .init(configuration: c)
    }
    private func triggered(at now: Date) -> ProtectionState {
        var value = state()
        let revision = value.configuration.revision
        XCTAssertTrue(ProtectionEngine.firstUseDelivered(state: &value, at: now,
            scheduledRevision: revision, eligible: true))
        return value
    }

    func testMigrationPreservesFixedSettingsCompletionAndLeavesBedtimeDisabled() {
        let c = ProtectionConfiguration(legacyMorningEnabled: true, legacyStartMinute: 545,
                                       legacyDurationSeconds: 2700, timeZoneIdentifier: "UTC")
        let value = ProtectionState(configuration: c, legacyCompletedMorningDay: "2026-10-07")
        XCTAssertEqual(c.morningTrigger, .fixedTime)
        XCTAssertEqual(c.morningStartMinute, 545)
        XCTAssertEqual(c.morningDurationSeconds, 2700)
        XCTAssertFalse(c.bedtimeEnabled)
        XCTAssertNil(c.bedtimeWindow)
        XCTAssertTrue(ProtectionEngine.plan(value, at: date("2026-10-07T09:20:00Z")).shieldedRules.isEmpty)
        XCTAssertEqual(ProtectionConfiguration.newSetup.morningDurationSeconds, 1800)
        XCTAssertFalse(ProtectionConfiguration.newSetup.morningEnabled)
    }

    func testFirstUseAnchorsElapsedThirtyMinutesToDeliveryAndNeverExtends() {
        let now = date("2026-10-07T08:12:00Z")
        var value = triggered(at: now)
        let original = value.activeFirstUseMorning!
        XCTAssertEqual(original.end, now.addingTimeInterval(1800))
        XCTAssertFalse(ProtectionEngine.firstUseDelivered(state: &value, at: now.addingTimeInterval(60),
            scheduledRevision: 1, eligible: true))
        XCTAssertEqual(value.activeFirstUseMorning, original)
        ProtectionEngine.reconcile(state: &value, at: original.end)
        XCTAssertTrue(ProtectionEngine.plan(value, at: original.end).shieldedRules.isEmpty)
        XCTAssertFalse(ProtectionEngine.firstUseDelivered(state: &value,
            at: now.addingTimeInterval(3600), scheduledRevision: 1, eligible: true))
        XCTAssertTrue(ProtectionEngine.firstUseDelivered(state: &value,
            at: date("2026-10-08T08:00:00Z"), scheduledRevision: 1, eligible: true))
    }

    func testInvalidOrUnauthorizedOrStaleOrOutsideBandCannotStart() {
        var value = state()
        let now = date("2026-10-07T08:00:00Z")
        XCTAssertFalse(ProtectionEngine.firstUseDelivered(state: &value, at: now,
            scheduledRevision: 1, eligible: false))
        XCTAssertFalse(ProtectionEngine.firstUseDelivered(state: &value, at: now,
            scheduledRevision: 0, eligible: true))
        XCTAssertFalse(ProtectionEngine.firstUseDelivered(state: &value,
            at: date("2026-10-07T13:00:00Z"), scheduledRevision: 1, eligible: true))
        var invalid = value.configuration
        invalid.bedtimeEnabled = true
        XCTAssertFalse(ProtectionEngine.updateConfiguration(state: &value, to: invalid))
        XCTAssertNil(value.activeFirstUseMorning)
    }

    func testLateBandDeliveryKeepsFullThirtyMinutesAndMidnightCycleIsAnchored() {
        var value = state()
        value.configuration.morningStartMinute = 23 * 60
        value.configuration.morningDetectionEndMinute = 3 * 60
        let now = date("2026-10-08T00:15:00Z")
        XCTAssertTrue(ProtectionEngine.firstUseDelivered(state: &value, at: now,
            scheduledRevision: 1, eligible: true))
        XCTAssertEqual(value.lastMorningCycle, "2026-10-07")
        XCTAssertEqual(value.activeFirstUseMorning?.end, date("2026-10-08T00:45:00Z"))
        var late = state()
        let lateNow = date("2026-10-07T11:59:45Z")
        XCTAssertTrue(ProtectionEngine.firstUseDelivered(state: &late, at: lateNow,
            scheduledRevision: 1, eligible: true))
        XCTAssertEqual(late.activeFirstUseMorning?.end, date("2026-10-07T12:29:45Z"))
    }

    func testBedtimeOvernightUsesPreviousStartAndIsIndependent() {
        var value = state()
        value.configuration.morningEnabled = false
        value.configuration.bedtimeEnabled = true
        value.configuration.bedtimeWindow = .init(startMinute: 23 * 60, endMinute: 7 * 60)
        let plan = ProtectionEngine.plan(value, at: date("2026-10-08T06:30:00Z"))
        XCTAssertEqual(plan.shieldedRules, [.bedtime])
        XCTAssertTrue(plan.activeWindows[0].id.contains("2026-10-07"))
        XCTAssertEqual(plan.activeWindows[0].end, date("2026-10-08T07:00:00Z"))
        XCTAssertTrue(ProtectionEngine.plan(value, at: date("2026-10-08T07:00:00Z")).shieldedRules.isEmpty)
    }

    func testDSTBedtimeHasCalendarEndpointsAndMorningHasElapsedDeadline() {
        var value = state()
        value.configuration.timeZoneIdentifier = "America/Los_Angeles"
        value.configuration.bedtimeEnabled = true
        value.configuration.bedtimeWindow = .init(startMinute: 23 * 60, endMinute: 7 * 60)
        let spring = ProtectionEngine.activeWindows(value, at: date("2026-03-08T09:30:00Z")).first!
        XCTAssertEqual(spring.end.timeIntervalSince(spring.start), 7 * 3600)
        let fall = ProtectionEngine.activeWindows(value, at: date("2026-11-01T09:30:00Z")).first!
        XCTAssertEqual(fall.end.timeIntervalSince(fall.start), 9 * 3600)
        value.configuration.morningStartMinute = 0
        value.configuration.morningDetectionEndMinute = 4 * 60
        let first = date("2026-11-01T08:15:00Z")
        XCTAssertTrue(ProtectionEngine.firstUseDelivered(state: &value, at: first,
            scheduledRevision: 1, eligible: true))
        XCTAssertEqual(value.activeFirstUseMorning?.end, first.addingTimeInterval(1800))
        XCTAssertFalse(ProtectionEngine.firstUseDelivered(state: &value,
            at: date("2026-11-01T09:15:00Z"), scheduledRevision: 1, eligible: true))
    }

    func testTimeZoneAndDurationEditPreservesRunningDeadlineAndRejectsOldCallback() {
        let now = date("2026-10-07T08:00:00Z")
        var value = triggered(at: now)
        let end = value.activeFirstUseMorning!.end
        var next = value.configuration
        next.timeZoneIdentifier = "Asia/Tokyo"
        next.morningStartMinute = 14 * 60
        next.morningDetectionEndMinute = 19 * 60
        next.morningDurationSeconds = 3600
        XCTAssertTrue(ProtectionEngine.updateConfiguration(state: &value, to: next))
        XCTAssertEqual(ProtectionEngine.plan(value, at: now.addingTimeInterval(60)).morningEndsAt, end)
        XCTAssertFalse(ProtectionEngine.firstUseDelivered(state: &value,
            at: now.addingTimeInterval(60), scheduledRevision: 1, eligible: true))
        XCTAssertFalse(ProtectionEngine.firstUseDelivered(state: &value,
            at: now.addingTimeInterval(60), scheduledRevision: 2, eligible: true))
    }

    func testBreathingOpensOnlyCapturedWindowsAndDoesNotCompleteThem() {
        let now = date("2026-10-07T06:10:00Z")
        var value = triggered(at: now)
        value.configuration.bedtimeEnabled = true
        value.configuration.bedtimeWindow = .init(startMinute: 23 * 60, endMinute: 7 * 60)
        let ticket = ProtectionEngine.beginBreathing(value, at: now)!
        let confirmed = now.addingTimeInterval(60)
        let grant = ProtectionEngine.confirmBreathing(state: &value, ticket: ticket,
            completed: true, allowanceSeconds: 600, at: confirmed)!
        XCTAssertEqual(grant.windowEnds.count, 2)
        XCTAssertTrue(ProtectionEngine.plan(value, at: confirmed).shieldedRules.isEmpty)
        XCTAssertEqual(value.activeFirstUseMorning?.end, now.addingTimeInterval(1800))
        XCTAssertEqual(ProtectionEngine.plan(value, at: confirmed.addingTimeInterval(600)).shieldedRules,
                       [.morning, .bedtime])
        XCTAssertEqual(ProtectionEngine.plan(value, at: now.addingTimeInterval(1800)).shieldedRules,
                       [.bedtime])
    }

    func testAllowanceClampsToIndependentEndsAndDuplicateDoesNotExtend() {
        let now = date("2026-10-07T06:50:00Z")
        var value = triggered(at: now)
        value.configuration.bedtimeEnabled = true
        value.configuration.bedtimeWindow = .init(startMinute: 23 * 60, endMinute: 7 * 60)
        let ticket = ProtectionEngine.beginBreathing(value, at: now)!
        let grant = ProtectionEngine.confirmBreathing(state: &value, ticket: ticket,
            completed: true, allowanceSeconds: 900, at: now)!
        XCTAssertEqual(grant.windowEnds.values.min(), date("2026-10-07T07:00:00Z"))
        XCTAssertEqual(grant.windowEnds.values.max(), date("2026-10-07T07:05:00Z"))
        let duplicate = ProtectionEngine.confirmBreathing(state: &value, ticket: ticket,
            completed: true, allowanceSeconds: 900, at: now.addingTimeInterval(30))
        XCTAssertEqual(grant, duplicate)
        XCTAssertEqual(ProtectionEngine.plan(value, at: date("2026-10-07T07:06:00Z")).shieldedRules, [.morning])
    }

    func testCancelledExpiredAndEditedTicketsNeverGrant() {
        let now = date("2026-10-07T08:00:00Z")
        var value = triggered(at: now)
        let ticket = ProtectionEngine.beginBreathing(value, at: now)!
        XCTAssertNil(ProtectionEngine.confirmBreathing(state: &value, ticket: ticket,
            completed: false, allowanceSeconds: 600, at: now))
        ProtectionEngine.cancelBreathing(state: &value)
        XCTAssertNil(ProtectionEngine.confirmBreathing(state: &value, ticket: ticket,
            completed: true, allowanceSeconds: 600, at: now))
        let editedTicket = ProtectionEngine.beginBreathing(value, at: now)!
        var next = value.configuration
        next.morningDetectionEndMinute = 13 * 60
        ProtectionEngine.updateConfiguration(state: &value, to: next)
        XCTAssertNil(ProtectionEngine.confirmBreathing(state: &value, ticket: editedTicket,
            completed: true, allowanceSeconds: 600, at: now))
        let expiredTicket = ProtectionEngine.beginBreathing(value, at: now)!
        XCTAssertNil(ProtectionEngine.confirmBreathing(state: &value, ticket: expiredTicket,
            completed: true, allowanceSeconds: 600, at: now.addingTimeInterval(1800)))
        XCTAssertTrue(value.allowances.isEmpty)
    }

    func testDisablingMorningCannotRestartItAndLeavesBedtimeEnabled() {
        let now = date("2026-10-07T06:10:00Z")
        var value = triggered(at: now)
        var next = value.configuration
        next.morningEnabled = false
        next.bedtimeEnabled = true
        next.bedtimeWindow = .init(startMinute: 23 * 60, endMinute: 7 * 60)
        ProtectionEngine.updateConfiguration(state: &value, to: next)
        XCTAssertEqual(ProtectionEngine.plan(value, at: now).shieldedRules, [.bedtime])
        next.morningEnabled = true
        ProtectionEngine.updateConfiguration(state: &value, to: next)
        let revision = value.configuration.revision
        XCTAssertFalse(ProtectionEngine.firstUseDelivered(state: &value, at: now,
            scheduledRevision: revision, eligible: true))
    }

    func testFileStoreRelaunchAndConcurrentDuplicateDeliveries() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("protection.json")
        let initial = state()
        let now = date("2026-10-07T08:00:00Z")
        let resultLock = NSLock()
        var accepted = 0
        DispatchQueue.concurrentPerform(iterations: 12) { _ in
            let store = ProtectionFileStore(url: url, initial: initial)
            let started = try! store.transaction { value in
                ProtectionEngine.firstUseDelivered(state: &value, at: now,
                    scheduledRevision: 1, eligible: true)
            }
            resultLock.lock()
            accepted += started ? 1 : 0
            resultLock.unlock()
        }
        XCTAssertEqual(accepted, 1)
        let reopened = ProtectionFileStore(url: url, initial: initial)
        XCTAssertEqual(try reopened.load().activeFirstUseMorning?.end, now.addingTimeInterval(1800))
        try reopened.transaction { ProtectionEngine.reconcile(state: &$0, at: now.addingTimeInterval(1900)) }
        XCTAssertNil(try reopened.load().activeFirstUseMorning)
        XCTAssertEqual(try reopened.load().lastMorningCycle, "2026-10-07")
    }

    func testCorruptStorePreservesBytesAndRemovesOnlyScheduledContribution() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("protection.json")
        let corrupt = Data("unreadable state".utf8)
        try corrupt.write(to: url)
        let effects = RecordingEffects()
        let now = date("2026-10-07T08:00:00Z")
        let runtime = ProtectionRuntime(storage: ProtectionFileStore(url: url, initial: state()), effects: effects, clock: { .init(wall: now, processID: "test", continuousSeconds: now.timeIntervalSince1970) })
        let outcome = runtime.callback(.foregroundReconcile, at: date("2026-10-07T08:00:00Z"),
                                       authorizedWithSelection: true)
        XCTAssertFalse(outcome.effectsApplied)
        XCTAssertEqual(effects.applyCalls, 1)
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
    }

    func testSyntheticExtensionPersistenceAndSchedulingFailuresDoNotClaimEnforcement() {
        let now = date("2026-10-07T08:00:00Z")
        let store = ProtectionMemoryStore(state())
        let effects = RecordingEffects()
        let runtime = ProtectionRuntime(storage: store, effects: effects, clock: { .init(wall: now, processID: "test", continuousSeconds: now.timeIntervalSince1970) })
        store.failNextWrite = true
        let failed = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now,
                                      authorizedWithSelection: true)
        XCTAssertFalse(failed.effectsApplied)
        XCTAssertEqual(effects.scheduleCalls, 0)
        XCTAssertNil(try! store.load().activeFirstUseMorning)
        effects.failSchedule = true
        let scheduleFailed = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now,
                                              authorizedWithSelection: true)
        XCTAssertFalse(scheduleFailed.effectsApplied)
        XCTAssertEqual(effects.applyCalls, 1) // Empty cleanup still executes.
        XCTAssertNotNil(scheduleFailed.errorDescription)
    }

    func testRevokedAuthorizationDuringBreathingDoesNotGrantOrApplyShields() throws {
        let now = date("2026-10-07T06:10:00Z")
        let store = ProtectionMemoryStore(triggered(at: now))
        let effects = RecordingEffects()
        let runtime = ProtectionRuntime(storage: store, effects: effects, clock: { .init(wall: now, processID: "test", continuousSeconds: now.timeIntervalSince1970) })
        let ticket = ProtectionEngine.beginBreathing(try store.load(), at: now)!
        let result = runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
                                            at: now, authorizedWithSelection: false)
        XCTAssertNil(result.grant)
        XCTAssertEqual(result.plan?.shieldedRules, [])
        XCTAssertNil(result.plan?.nextReconciliationAt)
        XCTAssertEqual(effects.composedRestrictions, ["beforeFeed", "focus"])
        XCTAssertTrue(try store.load().allowances.isEmpty)
    }

    func testSyntheticExtensionCancelLateExpiryAndUnrelatedRestrictions() throws {
        let now = date("2026-10-07T06:10:00Z")
        var value = state()
        value.configuration.bedtimeEnabled = true
        value.configuration.bedtimeWindow = .init(startMinute: 23 * 60, endMinute: 7 * 60)
        let store = ProtectionMemoryStore(value)
        let effects = RecordingEffects()
        let runtime = ProtectionRuntime(storage: store, effects: effects, clock: { .init(wall: now, processID: "test", continuousSeconds: now.timeIntervalSince1970) })
        let started = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now,
                                       authorizedWithSelection: true)
        XCTAssertTrue(started.effectsApplied)
        let ticket = ProtectionEngine.beginBreathing(try store.load(), at: now)!
        let cancelled = runtime.finishBreathing(ticket, completed: false, allowanceSeconds: 600,
                                                at: now, authorizedWithSelection: true)
        XCTAssertNil(cancelled.grant)
        XCTAssertEqual(cancelled.plan?.shieldedRules, [.morning, .bedtime])
        let replay = runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
                                             at: now, authorizedWithSelection: true)
        XCTAssertNil(replay.grant)
        let lateTime = now.addingTimeInterval(2000)
        let lateRuntime = ProtectionRuntime(storage: store, effects: effects, clock: { .init(wall: lateTime, processID: "test", continuousSeconds: lateTime.timeIntervalSince1970) })
        let late = lateRuntime.callback(.elapsedDeadline, at: lateTime,
                                    authorizedWithSelection: true)
        XCTAssertEqual(late.plan?.shieldedRules, [.bedtime])
        XCTAssertEqual(effects.composedRestrictions, ["beforeFeed", "focus", "bedtime"])
    }
}

private final class RecordingEffects: ProtectionRuntimeEffects {
    var scheduleCalls = 0
    var applyCalls = 0
    var failSchedule = false
    private let independentRestrictions: Set<String> = ["beforeFeed", "focus"]
    var composedRestrictions: Set<String> = ["beforeFeed", "focus"]
    func scheduleReconciliation(at: Date?) throws {
        scheduleCalls += 1
        if failSchedule { throw ProtectionStorageError.syntheticWriteFailure }
    }
    func applyScheduledContribution(_ rules: Set<ProtectionRule>) throws {
        applyCalls += 1
        composedRestrictions = independentRestrictions.union(rules.map(\.rawValue))
    }
}
