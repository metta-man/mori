import Foundation
import XCTest
@testable import MoriProtection

final class ProtectionRecoveryTests: XCTestCase {
    private func date(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }
    private func config() -> ProtectionConfiguration {
        var c = ProtectionConfiguration.newSetup
        c.timeZoneIdentifier = "UTC"; c.morningEnabled = true
        c.morningStartMinute = 240; c.morningDetectionEndMinute = 720
        return c
    }
    private func sample(_ wall: Date, _ uptime: Double, _ boot: String = "A") -> ProtectionClockSample {
        .init(wall: wall, processID: boot, continuousSeconds: uptime)
    }
    private func la() -> Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "America/Los_Angeles")!; return c
    }

    func testSevenToSevenThirtySurvivesMultipleCoherentHandoffs() throws {
        let start = date("2026-10-07T07:00:00Z")
        let clock = TestClock(sample(start, 100))
        let store = ProtectionMemoryStore(.init(configuration: config()))
        let runtime = ProtectionRuntime(storage: store, effects: RecoveryEffects(), clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: start, authorizedWithSelection: true)
        for (index, seconds) in [60, 300, 900, 1799].enumerated() {
            clock.set(sample(start.addingTimeInterval(Double(seconds)), 1, "process-\(index)"))
            let result = runtime.callback(.foregroundReconcile, at: start, authorizedWithSelection: true)
            XCTAssertEqual(result.plan?.activeWindows.first?.end, start.addingTimeInterval(1800))
        }
        clock.set(sample(start.addingTimeInterval(1800), 1, "reboot"))
        XCTAssertTrue(runtime.callback(.elapsedDeadline, at: start, authorizedWithSelection: true).plan!.activeWindows.isEmpty)
    }

    func testLiveAnchorSurvivesOtherProcessHandoffAndIncludesSleep() throws {
        let start = date("2026-10-07T07:00:00Z")
        var state = ProtectionState(configuration: config())
        _ = ProtectionEngine.advanceClock(state: &state, sample: sample(start, 100))
        XCTAssertTrue(ProtectionEngine.firstUseDelivered(state: &state, at: start, scheduledRevision: 1, eligible: true))
        let live = ProtectionLiveProcessClock(processID: "live-A")
        _ = ProtectionEngine.advanceClock(state: &state, sample: live.sample(wall: start, continuous: 100, state: state))
        _ = ProtectionEngine.advanceClock(state: &state, sample: sample(start.addingTimeInterval(60), 1, "extension-B"))
        let resume = live.sample(wall: start.addingTimeInterval(-3600), continuous: 1900, state: state)
        XCTAssertEqual(resume.projectedNow, start.addingTimeInterval(1800))
        let logical = try XCTUnwrap(ProtectionEngine.advanceClock(state: &state, sample: resume))
        ProtectionEngine.reconcile(state: &state, at: logical)
        XCTAssertTrue(ProtectionEngine.plan(state, at: logical).activeWindows.isEmpty)
        XCTAssertNil(state.clockLedger?.recoveryEndsAt)
    }

    func testMalformedMorningEndsOnlyMorningAndPreservesBedtime() {
        let now = date("2026-10-07T06:00:00Z")
        var configuration = config(); configuration.bedtimeEnabled = true
        configuration.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        var state = ProtectionState(configuration: configuration)
        _ = ProtectionEngine.advanceClock(state: &state, sample: sample(now, 100))
        state.activeFirstUseMorning = .init(id: "malformed-morning", rule: .morning, start: now, end: now.addingTimeInterval(-1))
        state.allowances["malformed-morning"] = now.addingTimeInterval(600)
        ProtectionEngine.reconcile(state: &state, at: now)
        XCTAssertNil(state.activeFirstUseMorning)
        XCTAssertEqual(ProtectionEngine.plan(state, at: now).shieldedRules, [.bedtime])
        XCTAssertTrue(state.clockLedger!.retiredWindowIDs.contains("malformed-morning"))
        XCTAssertNotNil(state.clockLedger!.recoveryReason)
    }

    func testFixedMorningEndSurvivesDurationTimezoneAndTriggerEdit() {
        let now = date("2026-10-07T07:00:00Z")
        var configuration = config(); configuration.morningTrigger = .fixedTime
        configuration.morningStartMinute = 420
        var state = ProtectionState(configuration: configuration)
        _ = ProtectionEngine.advanceClock(state: &state, sample: sample(now, 100))
        ProtectionEngine.reconcile(state: &state, at: now)
        let original = state.activeFirstUseMorning
        XCTAssertEqual(original?.end, now.addingTimeInterval(1800))
        configuration.morningDurationSeconds = 7200
        configuration.timeZoneIdentifier = "America/Los_Angeles"
        configuration.morningTrigger = .firstUse
        XCTAssertTrue(ProtectionEngine.updateConfiguration(state: &state, to: configuration))
        ProtectionEngine.reconcile(state: &state, at: now.addingTimeInterval(60))
        XCTAssertEqual(state.activeFirstUseMorning, original)
        ProtectionEngine.reconcile(state: &state, at: now.addingTimeInterval(1800))
        XCTAssertNil(state.activeFirstUseMorning)
    }

    func testRetiredDatedBedtimeCannotRestartAfterRevisionEdit() {
        let now = date("2026-10-07T06:00:00Z")
        var configuration = config(); configuration.morningEnabled = false
        configuration.bedtimeEnabled = true; configuration.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        var state = ProtectionState(configuration: configuration)
        _ = ProtectionEngine.advanceClock(state: &state, sample: sample(now, 100))
        _ = ProtectionEngine.advanceClock(state: &state, sample: sample(now.addingTimeInterval(-3600), 1, "other-process"))
        _ = ProtectionEngine.advanceClock(state: &state, sample: sample(now.addingTimeInterval(60), 1, "coherent-process"))
        XCTAssertTrue(ProtectionEngine.updateConfiguration(state: &state, to: configuration))
        XCTAssertTrue(ProtectionEngine.plan(state, at: now.addingTimeInterval(60)).activeWindows.isEmpty)
        XCTAssertFalse(state.clockLedger!.retiredWindowIDs.isEmpty)
    }

    func testClockInvalidationAtEveryEffectCheckpointRemovesOwnedRules() throws {
        let now = date("2026-10-07T07:00:00Z")
        for checkpoint in 1...3 {
            var state = ProtectionState(configuration: config())
            _ = ProtectionEngine.advanceClock(state: &state, sample: sample(now, 100))
            _ = ProtectionEngine.firstUseDelivered(state: &state, at: now, scheduledRevision: 1, eligible: true)
            state.effectsRecovery = .init(lastAppliedRules: [.morning], lastAppliedWindowIDs: [state.activeFirstUseMorning!.id], pending: false)
            let clock = SequenceClock(Array(repeating: sample(now, 100), count: checkpoint) + [.init(wall: now, processID: "", continuousSeconds: .nan)])
            let fx = RecoveryEffects(); fx.applied = [.morning]
            let store = ProtectionMemoryStore(state)
            let result = ProtectionRuntime(storage: store, effects: fx, clock: clock.read).callback(.foregroundReconcile, at: now, authorizedWithSelection: true)
            XCTAssertFalse(result.effectsApplied)
            XCTAssertTrue(fx.applied.isEmpty)
            XCTAssertTrue(try store.load().effectsRecovery!.pending)
            XCTAssertEqual(try store.load().configuration, state.configuration)
        }
    }

    func testSkippedStartAndEndCollapseInsteadOfNextDayTwentyFourHours() {
        for end in [180, 160] {
            let window = LocalProtectionWindow(startMinute: 150, endMinute: end)
            // end160 is also skipped; both endpoints resolve to03:00.
            XCTAssertNil(window.containing(date("2026-03-08T10:00:00Z"), calendar: la()))
            XCTAssertNil(window.containing(date("2026-03-08T20:00:00Z"), calendar: la()))
        }
    }
    func testSkippedEndpointsRemainOnIntendedDay() {
        let startSkipped = LocalProtectionWindow(startMinute: 150, endMinute: 210)
        let band = startSkipped.containing(date("2026-03-08T10:10:00Z"), calendar: la())!
        XCTAssertEqual(band.start, date("2026-03-08T10:00:00Z"))
        XCTAssertEqual(band.end, date("2026-03-08T10:30:00Z"))
        let endSkipped = LocalProtectionWindow(startMinute: 90, endMinute: 150)
        XCTAssertEqual(endSkipped.containing(date("2026-03-08T09:45:00Z"), calendar: la())?.end,
                       date("2026-03-08T10:00:00Z"))
        let overnight = LocalProtectionWindow(startMinute: 1380, endMinute: 150)
        XCTAssertEqual(overnight.containing(date("2026-03-08T09:45:00Z"), calendar: la())?.end,
                       date("2026-03-08T10:00:00Z"))
    }
    func testRepeatedEndpointsUseFirstOccurrenceWithoutSecondWindow() {
        let repeated = LocalProtectionWindow(startMinute: 75, endMinute: 105)
        let band = repeated.containing(date("2026-11-01T08:20:00Z"), calendar: la())!
        XCTAssertEqual(band.start, date("2026-11-01T08:15:00Z"))
        XCTAssertEqual(band.end, date("2026-11-01T08:45:00Z"))
        XCTAssertNil(repeated.containing(date("2026-11-01T09:20:00Z"), calendar: la()))
        let crossingFold = LocalProtectionWindow(startMinute: 90, endMinute: 150)
        let folded = crossingFold.containing(date("2026-11-01T09:20:00Z"), calendar: la())!
        XCTAssertEqual(folded.end.timeIntervalSince(folded.start), 7200)
        let overnight = LocalProtectionWindow(startMinute: 1380, endMinute: 90)
        XCTAssertNil(overnight.containing(date("2026-11-01T09:15:00Z"), calendar: la()))
    }

    func testMonotonicExpiryIgnoresSameBootWallRollback() throws {
        let now = date("2026-10-07T08:00:00Z")
        let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: config()))
        let fx = RecoveryEffects()
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        XCTAssertTrue(runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now,
                                       authorizedWithSelection: true).effectsApplied)
        clock.set(sample(now.addingTimeInterval(-3600), 1900))
        let expired = runtime.callback(.elapsedDeadline, at: now.addingTimeInterval(-3600), authorizedWithSelection: true)
        XCTAssertEqual(expired.plan?.shieldedRules, [])
        XCTAssertNil(try store.load().activeFirstUseMorning)
        XCTAssertTrue(fx.applied.isEmpty)
    }
    func testAllowanceExpiresByMonotonicTimeAndOldCallbackCannotReverseState() throws {
        let now = date("2026-10-07T08:00:00Z")
        let clock = TestClock(sample(now, 100)); let fx = RecoveryEffects()
        let store = ProtectionMemoryStore(.init(configuration: config()))
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        let ticket = ProtectionEngine.beginBreathing(try store.load(), at: now)!
        XCTAssertNotNil(runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
            at: now, authorizedWithSelection: true).grant)
        clock.set(sample(now.addingTimeInterval(-7200), 700))
        let result = runtime.callback(.calendarBoundary, at: now.addingTimeInterval(-7200), authorizedWithSelection: true)
        XCTAssertEqual(result.plan?.shieldedRules, [.morning])
        XCTAssertTrue(try store.load().allowances.isEmpty)
        // Queued callback timestamp is intentionally old; clock is sampled under lock.
        XCTAssertEqual(runtime.callback(.elapsedDeadline, at: now, authorizedWithSelection: true).plan?.shieldedRules, [.morning])
    }
    func testIncoherentHandoffRetiresDatedScopesWithoutInventingBudget() throws {
        let now = date("2026-10-07T06:00:00Z")
        var c = config(); c.bedtimeEnabled = true; c.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        var state = ProtectionState(configuration: c)
        let clock = TestClock(sample(now, 100)); let fx = RecoveryEffects()
        let store = ProtectionMemoryStore(state)
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        let ticket = ProtectionEngine.beginBreathing(try store.load(), at: now)!
        clock.set(sample(now.addingTimeInterval(-3600), 1, "B"))
        let recovered = runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true)
        XCTAssertNil(recovered.plan?.nextReconciliationAt)
        XCTAssertTrue(recovered.plan!.shieldedRules.isEmpty)
        XCTAssertNil(runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
            at: now, authorizedWithSelection: true).grant)
        clock.set(sample(now.addingTimeInterval(-3600), 301, "B"))
        XCTAssertTrue(runtime.callback(.elapsedDeadline, at: now, authorizedWithSelection: true).plan!.shieldedRules.isEmpty)
        state = try store.load(); XCTAssertNil(state.activeFirstUseMorning)
        clock.set(sample(now.addingTimeInterval(301), 302, "B"))
        XCTAssertTrue(runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true).plan!.shieldedRules.isEmpty)
        XCTAssertFalse(try store.load().clockLedger!.retiredWindowIDs.isEmpty)
    }
    func testRepeatedIncoherentHandoffsCannotResurrectRetiredScopes() {
        let now = date("2026-10-07T06:00:00Z"); var c = config()
        c.bedtimeEnabled = true; c.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        let clock = TestClock(sample(now, 100)); let store = ProtectionMemoryStore(.init(configuration: c))
        let runtime = ProtectionRuntime(storage: store, effects: RecoveryEffects(), clock: clock.read)
        _ = runtime.callback(.calendarBoundary, at: now, authorizedWithSelection: true)
        for i in 0...5 {
            clock.set(sample(now.addingTimeInterval(-3600), 0, "new-\(i)"))
            let result = runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true)
            if i == 5 { XCTAssertTrue(result.plan!.shieldedRules.isEmpty) }
        }
    }
    func testCoherentRebootPreservesOriginalDeadlineAndAllowance() throws {
        let now = date("2026-10-07T08:00:00Z"); let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: config())); let fx = RecoveryEffects()
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        let ticket = ProtectionEngine.beginBreathing(try store.load(), at: now)!
        _ = runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600, at: now, authorizedWithSelection: true)
        clock.set(sample(now.addingTimeInterval(60), 1, "B"))
        XCTAssertEqual(runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true).plan?.shieldedRules, [])
        XCTAssertEqual(try store.load().allowances.values.first, now.addingTimeInterval(600))
        XCTAssertEqual(try store.load().activeFirstUseMorning?.end, now.addingTimeInterval(1800))
    }
    func testOldJSONDecodesWithoutNewClockOrRecoveryFields() throws {
        let value = ProtectionState(configuration: config())
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as! [String: Any]
        json.removeValue(forKey: "clockLedger"); json.removeValue(forKey: "effectsRecovery")
        let restored = try JSONDecoder().decode(ProtectionState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(restored.configuration, value.configuration)
        XCTAssertNil(restored.clockLedger); XCTAssertNil(restored.effectsRecovery)
    }
    func testScheduleFailureStillRemovesExpiredContributionsAndRecoversDurably() throws {
        let now = date("2026-10-07T08:00:00Z"); let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: config())); let fx = RecoveryEffects()
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        fx.failSchedule = true; clock.set(sample(now.addingTimeInterval(1800), 1900))
        let result = runtime.callback(.elapsedDeadline, at: now, authorizedWithSelection: true)
        XCTAssertFalse(result.effectsApplied); XCTAssertTrue(fx.applied.isEmpty)
        XCTAssertTrue(try store.load().effectsRecovery!.pending)
        fx.failSchedule = false
        XCTAssertTrue(runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true).effectsApplied)
        XCTAssertFalse(try store.load().effectsRecovery!.pending)
    }
    func testFailedAllowanceSchedulingDoesNotRemoveShieldOrPersistGrant() throws {
        let now = date("2026-10-07T08:00:00Z"); let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: config())); let fx = RecoveryEffects()
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        let ticket = ProtectionEngine.beginBreathing(try store.load(), at: now)!
        fx.failSchedule = true
        XCTAssertNil(runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600, at: now,
                                             authorizedWithSelection: true).grant)
        XCTAssertEqual(fx.applied, [.morning]); XCTAssertTrue(try store.load().allowances.isEmpty)
        XCTAssertTrue(try store.load().confirmedGrants.isEmpty)
    }
    func testEffectFailureLeavesDurablePendingUntilRelaunchRecovery() throws {
        let now = date("2026-10-07T08:00:00Z"); let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: config())); let fx = RecoveryEffects(); fx.failApply = true
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        XCTAssertFalse(runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true).effectsApplied)
        XCTAssertTrue(try store.load().effectsRecovery!.pending)
        fx.failApply = false
        let reopened = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        XCTAssertTrue(reopened.callback(.foregroundReconcile, at: now, authorizedWithSelection: true).effectsApplied)
        XCTAssertEqual(fx.applied, [.morning]); XCTAssertFalse(try store.load().effectsRecovery!.pending)
    }
    func testRegistrationDelayRevalidatesDeadlineBeforeApplying() {
        let now = date("2026-10-07T08:00:00Z"); let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: config())); let fx = RecoveryEffects()
        fx.onSchedule = { clock.set(self.sample(now.addingTimeInterval(1800), 1900)) }
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        XCTAssertTrue(runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true).effectsApplied)
        XCTAssertTrue(fx.applied.isEmpty)
    }
    func testIndependentFileStoreRuntimesSerializeSlowOldEffectsAndFreshExpiry() throws {
        let now = date("2026-10-07T08:00:00Z"); let initial = ProtectionState(configuration: config())
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("state.json")
        let oldEntered = DispatchSemaphore(value: 0); let releaseOld = DispatchSemaphore(value: 0)
        let newDone = DispatchSemaphore(value: 0); let oldDone = DispatchSemaphore(value: 0)
        let clock = TestClock(sample(now, 100)); let sink = RuleSink()
        let oldEffects = RecoveryEffects(); oldEffects.onApply = { rules in
            if rules.contains(.morning) { oldEntered.signal(); XCTAssertEqual(releaseOld.wait(timeout: .now() + 3), .success) }; sink.set(rules)
        }
        let newEffects = RecoveryEffects(); newEffects.onApply = sink.set
        let old = ProtectionRuntime(storage: ProtectionFileStore(url: url, initial: initial), effects: oldEffects, clock: clock.read)
        let newer = ProtectionRuntime(storage: ProtectionFileStore(url: url, initial: initial), effects: newEffects, clock: clock.read)
        DispatchQueue.global().async { _ = old.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true); oldDone.signal() }
        XCTAssertEqual(oldEntered.wait(timeout: .now() + 3), .success)
        clock.set(sample(now.addingTimeInterval(1800), 1900))
        DispatchQueue.global().async { _ = newer.callback(.elapsedDeadline, at: now, authorizedWithSelection: true); newDone.signal() }
        XCTAssertEqual(newDone.wait(timeout: .now() + 0.05), .timedOut)
        releaseOld.signal()
        XCTAssertEqual(oldDone.wait(timeout: .now() + 3), .success)
        XCTAssertEqual(newDone.wait(timeout: .now() + 3), .success)
        XCTAssertTrue(sink.get().isEmpty)
        XCTAssertFalse(try ProtectionFileStore(url: url, initial: initial).load().effectsRecovery!.pending)
    }
    func testAcknowledgementWriteFailureKeepsPendingMarkerForRetry() throws {
        let now = date("2026-10-07T08:00:00Z"); let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: config())); let fx = RecoveryEffects()
        fx.onApply = { _ in store.failNextWrite = true }
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        XCTAssertFalse(runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now,
                                        authorizedWithSelection: true).effectsApplied)
        XCTAssertEqual(fx.applied, [.morning])
        XCTAssertTrue(try store.load().effectsRecovery!.pending)
        fx.onApply = nil
        XCTAssertTrue(runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true).effectsApplied)
        XCTAssertFalse(try store.load().effectsRecovery!.pending)
    }
    func testExpiryDuringEffectWriteImmediatelyCleansUpUnderSameLock() {
        let now = date("2026-10-07T08:00:00Z"); let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: config())); let fx = RecoveryEffects()
        fx.onApply = { rules in
            if !rules.isEmpty { clock.set(self.sample(now.addingTimeInterval(1800), 1900)) }
        }
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        let outcome = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        XCTAssertTrue(outcome.effectsApplied); XCTAssertTrue(outcome.plan!.shieldedRules.isEmpty)
        XCTAssertTrue(fx.applied.isEmpty)
    }
    func testAnotherProcessCannotWriteStateUntilEffectsAndAcknowledgementFinish() throws {
        let now = date("2026-10-07T08:00:00Z"); let initial = ProtectionState(configuration: config())
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("state.json")
        let ready = folder.appendingPathComponent("child-ready")
        let done = folder.appendingPathComponent("child-done")
        let entered = DispatchSemaphore(value: 0); let release = DispatchSemaphore(value: 0)
        let finished = DispatchSemaphore(value: 0)
        let fx = RecoveryEffects(); fx.onApply = { _ in
            entered.signal(); XCTAssertEqual(release.wait(timeout: .now() + 4), .success)
        }
        let runtime = ProtectionRuntime(storage: ProtectionFileStore(url: url, initial: initial), effects: fx,
            clock: { self.sample(now, 100) })
        DispatchQueue.global().async {
            _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
            finished.signal()
        }
        XCTAssertEqual(entered.wait(timeout: .now() + 3), .success)
        let child = Process(); child.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        child.arguments = ["python3", "-c", """
import fcntl,json,os,sys
lock=open(sys.argv[1]+'.lock','a')
open(sys.argv[2],'w').write('ready')
fcntl.flock(lock,fcntl.LOCK_EX)
with open(sys.argv[1]) as f: state=json.load(f)
assert state['effectsRecovery']['pending'] is False
assert state['effectsRecovery']['lastAppliedRules']==['morning']
state['configuration']['morningEnabled']=False
with open(sys.argv[1]+'.child','w') as f: json.dump(state,f)
os.replace(sys.argv[1]+'.child',sys.argv[1])
open(sys.argv[3],'w').write('completed')
""", url.path, ready.path, done.path]
        let terminated = expectation(description: "child finished")
        child.terminationHandler = { _ in terminated.fulfill() }
        try child.run()
        defer { if child.isRunning { child.terminate() } }
        for _ in 0..<50 where !FileManager.default.fileExists(atPath: ready.path) {
            Thread.sleep(forTimeInterval: 0.01)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: ready.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: done.path))
        release.signal()
        XCTAssertEqual(finished.wait(timeout: .now() + 3), .success)
        wait(for: [terminated], timeout: 3)
        XCTAssertEqual(child.terminationStatus, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: done.path))
        let reopened = ProtectionFileStore(url: url, initial: initial)
        XCTAssertFalse(try reopened.load().configuration.morningEnabled)
        let latest = ProtectionRuntime(storage: reopened, effects: RecoveryEffects(), clock: { self.sample(now, 100) })
        XCTAssertTrue(latest.callback(.foregroundReconcile, at: now, authorizedWithSelection: true).plan!.shieldedRules.isEmpty)
    }
    func testCoherentWallRecoveryClearsDiagnosticButKeepsRetirement() throws {
        let now = date("2026-10-07T06:00:00Z"); var c = config()
        c.bedtimeEnabled = true; c.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        let clock = TestClock(sample(now, 100)); let store = ProtectionMemoryStore(.init(configuration: c))
        let runtime = ProtectionRuntime(storage: store, effects: RecoveryEffects(), clock: clock.read)
        _ = runtime.callback(.calendarBoundary, at: now, authorizedWithSelection: true)
        clock.set(sample(now.addingTimeInterval(-3600), 0, "B"))
        _ = runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true)
        let cutoff = try store.load().clockLedger!.recoveryEndsAt
        clock.set(sample(now.addingTimeInterval(60), 0, "C"))
        _ = runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true)
        XCTAssertEqual(cutoff, now)
        XCTAssertNil(try store.load().clockLedger!.recoveryEndsAt)
        XCTAssertFalse(try store.load().clockLedger!.retiredWindowIDs.isEmpty)
        clock.set(sample(now.addingTimeInterval(300), 240, "C"))
        XCTAssertTrue(runtime.callback(.elapsedDeadline, at: now, authorizedWithSelection: true).plan!.shieldedRules.isEmpty)
    }

    func testFailedSchedulingCannotCarrySameRuleIntoDifferentCalendarWindow() throws {
        let now = date("2026-10-07T23:30:00Z"); var c = config()
        c.morningEnabled = false; c.bedtimeEnabled = true
        c.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        let clock = TestClock(sample(now, 100)); let store = ProtectionMemoryStore(.init(configuration: c))
        let fx = RecoveryEffects(); let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.calendarBoundary, at: now, authorizedWithSelection: true)
        XCTAssertEqual(fx.applied, [.bedtime])
        fx.failSchedule = true
        clock.set(sample(now.addingTimeInterval(86400), 86500))
        XCTAssertFalse(runtime.callback(.calendarBoundary, at: now, authorizedWithSelection: true).effectsApplied)
        XCTAssertTrue(fx.applied.isEmpty)
        XCTAssertTrue(try store.load().effectsRecovery!.lastAppliedWindowIDs.isEmpty)
    }
    func testInvalidClockRemovesOnlyScheduledContributionAndRecordsPendingRecovery() throws {
        let now = date("2026-10-07T08:00:00Z")
        let store = ProtectionMemoryStore(.init(configuration: config())); let fx = RecoveryEffects()
        fx.applied = [.morning, .bedtime]
        let runtime = ProtectionRuntime(storage: store, effects: fx,
            clock: { .init(wall: now, processID: "", continuousSeconds: .nan) })
        XCTAssertFalse(runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true).effectsApplied)
        XCTAssertNil(try store.load().activeFirstUseMorning)
        XCTAssertTrue(try store.load().effectsRecovery!.pending)
        XCTAssertTrue(fx.applied.isEmpty)
    }

    func testClockRecoveryRejectsHistoricalGrantReplayAndNewBreathTicket() throws {
        let now = date("2026-10-07T08:00:00Z"); let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: config()))
        let runtime = ProtectionRuntime(storage: store, effects: RecoveryEffects(), clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        let ticket = ProtectionEngine.beginBreathing(try store.load(), at: now)!
        XCTAssertNotNil(runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
                                               at: now, authorizedWithSelection: true).grant)
        clock.set(sample(now.addingTimeInterval(-3600), 0, "B"))
        _ = runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true)
        XCTAssertNil(ProtectionEngine.beginBreathing(try store.load(), at: now))
        XCTAssertNil(runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
                                             at: now, authorizedWithSelection: true).grant)
        XCTAssertTrue(try store.load().allowances.isEmpty)
    }

    func testReplacementRegistrationFailureRollsBackGrantAndRetainsLiveMorning() throws {
        let now = date("2026-10-07T06:59:58Z")
        var c = config(); c.bedtimeEnabled = true
        c.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: c)); let fx = RecoveryEffects()
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        let before = try store.load()
        XCTAssertEqual(fx.applied, [.morning, .bedtime])
        let ticket = ProtectionEngine.beginBreathing(before, at: now)!
        fx.scheduledDeadlines.removeAll()
        var registrations = 0
        fx.onSchedule = {
            registrations += 1
            if registrations == 1 { clock.set(self.sample(now.addingTimeInterval(3), 103)) }
            if registrations == 2 { fx.failSchedule = true }
        }
        var contributions: [Set<ProtectionRule>] = []
        fx.onApply = { contributions.append($0) }
        let result = runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
            at: now, authorizedWithSelection: true)
        XCTAssertEqual(fx.scheduledDeadlines, [date("2026-10-07T07:00:00Z"), date("2026-10-07T07:09:58Z")])
        XCTAssertFalse(result.effectsApplied); XCTAssertNil(result.grant)
        XCTAssertEqual(result.plan?.shieldedRules, [.morning])
        XCTAssertEqual(contributions, [[.morning]])
        let after = try store.load()
        XCTAssertTrue(after.allowances.isEmpty)
        XCTAssertEqual(after.confirmedGrants, before.confirmedGrants)
        XCTAssertEqual(after.grantOrder, before.grantOrder)
        XCTAssertEqual(after.flowEpoch, before.flowEpoch)
        XCTAssertEqual(after.activeFirstUseMorning?.end, date("2026-10-07T07:29:58Z"))
        XCTAssertEqual(after.clockLedger?.logicalNow, date("2026-10-07T07:00:01Z"))
        XCTAssertEqual(after.clockLedger?.continuousSeconds, 103)
        XCTAssertTrue(after.effectsRecovery!.pending)
        XCTAssertEqual(after.effectsRecovery!.lastAppliedRules, [.morning])
        XCTAssertEqual(after.effectsRecovery!.lastAppliedWindowIDs.count, 1)
        fx.onSchedule = nil; fx.failSchedule = false
        XCTAssertTrue(runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true).effectsApplied)
        XCTAssertEqual(fx.applied, [.morning])
        XCTAssertTrue(try store.load().allowances.isEmpty)
    }

    func testPreApplyDeadlineInvalidationRollsBackOnlyGrantAtAdvancedClock() throws {
        let now = date("2026-10-07T06:59:58Z")
        var c = config(); c.bedtimeEnabled = true
        c.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        let store = ProtectionMemoryStore(.init(configuration: c)); let fx = RecoveryEffects()
        let initialClock = TestClock(sample(now, 100))
        let initial = ProtectionRuntime(storage: store, effects: fx, clock: initialClock.read)
        _ = initial.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        let before = try store.load(); let ticket = ProtectionEngine.beginBreathing(before, at: now)!
        let samples = SequenceClock([sample(now, 100), sample(now, 100),
            sample(now.addingTimeInterval(3), 103), sample(now.addingTimeInterval(3), 103)])
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: samples.read)
        fx.scheduledDeadlines.removeAll()
        var contributions: [Set<ProtectionRule>] = []; fx.onApply = { contributions.append($0) }
        let result = runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
            at: now, authorizedWithSelection: true)
        XCTAssertEqual(fx.scheduledDeadlines, [date("2026-10-07T07:00:00Z")])
        XCTAssertFalse(result.effectsApplied); XCTAssertNil(result.grant)
        XCTAssertEqual(result.plan?.shieldedRules, [.morning])
        XCTAssertEqual(contributions, [[.morning]])
        let after = try store.load()
        XCTAssertTrue(after.allowances.isEmpty)
        XCTAssertEqual(after.confirmedGrants, before.confirmedGrants)
        XCTAssertEqual(after.grantOrder, before.grantOrder)
        XCTAssertEqual(after.flowEpoch, before.flowEpoch)
        XCTAssertEqual(after.clockLedger?.logicalNow, now.addingTimeInterval(3))
        XCTAssertEqual(after.clockLedger?.continuousSeconds, 103)
        XCTAssertTrue(after.effectsRecovery!.pending)
        XCTAssertEqual(after.effectsRecovery!.lastAppliedRules, [.morning])
    }

    func testDeadlineInvalidationDuringEffectWriteRestoresMorningAndRollsBackGrant() throws {
        let now = date("2026-10-07T06:59:58Z")
        var c = config(); c.bedtimeEnabled = true
        c.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: c)); let fx = RecoveryEffects()
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        let before = try store.load(); let ticket = ProtectionEngine.beginBreathing(before, at: now)!
        var contributions: [Set<ProtectionRule>] = []
        fx.onApply = { rules in
            contributions.append(rules)
            if rules.isEmpty { clock.set(self.sample(now.addingTimeInterval(3), 103)) }
        }
        let result = runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
            at: now, authorizedWithSelection: true)
        XCTAssertFalse(result.effectsApplied); XCTAssertNil(result.grant)
        XCTAssertEqual(contributions, [[], [.morning]])
        XCTAssertEqual(result.plan?.shieldedRules, [.morning])
        let after = try store.load()
        XCTAssertTrue(after.allowances.isEmpty)
        XCTAssertEqual(after.confirmedGrants, before.confirmedGrants)
        XCTAssertEqual(after.grantOrder, before.grantOrder)
        XCTAssertEqual(after.clockLedger?.logicalNow, now.addingTimeInterval(3))
        XCTAssertTrue(after.effectsRecovery!.pending)
        XCTAssertEqual(after.effectsRecovery!.lastAppliedRules, [.morning])
    }

    func testRollbackPreservesInconsistentDateRetirementAndIndependentEpoch() throws {
        let now = date("2026-10-07T06:59:58Z")
        var c = config(); c.bedtimeEnabled = true
        c.bedtimeWindow = .init(startMinute: 1380, endMinute: 420)
        let clock = TestClock(sample(now, 100))
        let store = ProtectionMemoryStore(.init(configuration: c)); let fx = RecoveryEffects()
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        let before = try store.load(); let ticket = ProtectionEngine.beginBreathing(before, at: now)!
        fx.onSchedule = { clock.set(self.sample(now.addingTimeInterval(-3600), 0, "B")) }
        let result = runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
            at: now, authorizedWithSelection: true)
        XCTAssertFalse(result.effectsApplied); XCTAssertNil(result.grant)
        let after = try store.load()
        XCTAssertEqual(after.clockLedger?.processID, "B")
        XCTAssertEqual(after.clockLedger?.recoveryEndsAt, now)
        XCTAssertEqual(after.clockLedger?.recoveryWindowIDs.count, 2)
        XCTAssertNotEqual(after.flowEpoch, before.flowEpoch)
        XCTAssertTrue(after.allowances.isEmpty)
        XCTAssertEqual(after.confirmedGrants, before.confirmedGrants)
        XCTAssertEqual(after.grantOrder, before.grantOrder)
        XCTAssertEqual(after.effectsRecovery!.lastAppliedRules, [])
        XCTAssertTrue(after.effectsRecovery!.pending)
    }
    func testCompensatingWriteExpiryIsCleanedBeforeAcknowledgement() throws {
        let now = date("2026-10-07T07:04:58Z")
        var c = config(); c.morningDurationSeconds = 300
        c.bedtimeEnabled = true; c.bedtimeWindow = .init(startMinute: 1380, endMinute: 425)
        let clock = TestClock(sample(date("2026-10-07T07:00:02Z"), 100))
        let store = ProtectionMemoryStore(.init(configuration: c)); let fx = RecoveryEffects()
        let runtime = ProtectionRuntime(storage: store, effects: fx, clock: clock.read)
        _ = runtime.callback(.morningFirstUse(scheduledRevision: 1), at: now, authorizedWithSelection: true)
        clock.set(sample(now, 396))
        _ = runtime.callback(.foregroundReconcile, at: now, authorizedWithSelection: true)
        let before = try store.load()
        XCTAssertEqual(before.activeFirstUseMorning?.end, date("2026-10-07T07:05:02Z"))
        XCTAssertEqual(fx.applied, [.morning, .bedtime])
        let ticket = ProtectionEngine.beginBreathing(before, at: now)!
        var contributions: [Set<ProtectionRule>] = []
        fx.onApply = { rules in
            contributions.append(rules)
            if contributions.count == 1 {
                XCTAssertTrue(rules.isEmpty)
                clock.set(self.sample(self.date("2026-10-07T07:05:01Z"), 399))
            } else if contributions.count == 2 {
                XCTAssertEqual(rules, [.morning])
                clock.set(self.sample(self.date("2026-10-07T07:05:03Z"), 401))
            }
        }
        let result = runtime.finishBreathing(ticket, completed: true, allowanceSeconds: 600,
            at: now, authorizedWithSelection: true)
        XCTAssertEqual(contributions, [[], [.morning], []])
        XCTAssertFalse(result.effectsApplied); XCTAssertNil(result.grant)
        XCTAssertEqual(result.plan?.shieldedRules, [])
        XCTAssertEqual(result.plan?.activeWindows, [])
        XCTAssertNil(result.plan?.nextReconciliationAt)
        XCTAssertTrue(fx.applied.isEmpty)
        let after = try store.load()
        XCTAssertNil(after.activeFirstUseMorning)
        XCTAssertTrue(after.allowances.isEmpty)
        XCTAssertEqual(after.confirmedGrants, before.confirmedGrants)
        XCTAssertEqual(after.grantOrder, before.grantOrder)
        XCTAssertEqual(after.clockLedger?.logicalNow, date("2026-10-07T07:05:03Z"))
        XCTAssertEqual(after.clockLedger?.continuousSeconds, 401)
        XCTAssertTrue(after.effectsRecovery!.pending)
        XCTAssertTrue(after.effectsRecovery!.lastAppliedRules.isEmpty)
        XCTAssertTrue(after.effectsRecovery!.lastAppliedWindowIDs.isEmpty)
        XCTAssertLessThanOrEqual(contributions.count, 4)
    }

}

private final class SequenceClock {
    private let lock = NSLock(); private let samples: [ProtectionClockSample]
    private var index = 0
    init(_ samples: [ProtectionClockSample]) { self.samples = samples }
    func read() -> ProtectionClockSample {
        lock.lock(); defer { lock.unlock() }
        let sample = samples[min(index, samples.count - 1)]; index += 1; return sample
    }
}

private final class TestClock {
    private let lock = NSLock(); private var value: ProtectionClockSample
    init(_ value: ProtectionClockSample) { self.value = value }
    func set(_ value: ProtectionClockSample) { lock.lock(); defer { lock.unlock() }; self.value = value }
    func read() -> ProtectionClockSample { lock.lock(); defer { lock.unlock() }; return value }
}
private final class RuleSink {
    private let lock = NSLock(); private var value: Set<ProtectionRule> = []
    func set(_ rules: Set<ProtectionRule>) { lock.lock(); defer { lock.unlock() }; value = rules }
    func get() -> Set<ProtectionRule> { lock.lock(); defer { lock.unlock() }; return value }
}
private final class RecoveryEffects: ProtectionRuntimeEffects {
    var failSchedule = false; var failApply = false
    var onSchedule: (() -> Void)?; var onApply: ((Set<ProtectionRule>) -> Void)?
    var applied: Set<ProtectionRule> = []
    var scheduledDeadlines: [Date?] = []
    func scheduleReconciliation(at: Date?) throws {
        scheduledDeadlines.append(at)
        onSchedule?(); if failSchedule { throw ProtectionStorageError.syntheticWriteFailure }
    }
    func applyScheduledContribution(_ rules: Set<ProtectionRule>) throws {
        if failApply { throw ProtectionStorageError.syntheticWriteFailure }
        onApply?(rules); applied = rules
    }
}
