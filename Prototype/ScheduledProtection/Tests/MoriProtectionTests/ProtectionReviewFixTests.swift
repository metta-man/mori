import Foundation
import XCTest
@testable import MoriProtection

final class ProtectionReviewFixTests: XCTestCase {
    private func fixture() throws -> (ProtectionHost, ProtectionMemoryStore, ProtectionHostTests.Driver, ProtectionHostTests.Clock, ProtectionBreathTicket) {
        let clock = ProtectionHostTests.Clock(); let driver = ProtectionHostTests.Driver()
        clock.now = ISO8601DateFormatter().date(from: "2026-10-07T08:00:00Z")!
        var configuration = ProtectionConfiguration.newSetup; configuration.morningEnabled = true; configuration.timeZoneIdentifier = "UTC"
        let store = ProtectionMemoryStore(.init(configuration: configuration))
        let host = ProtectionHost(storage: store, driver: driver, clock: clock.sample)
        _ = host.reconcile(.morningFirstUse(scheduledRevision: 1), authorized: true)
        return (host, store, driver, clock, try XCTUnwrap(host.beginBreathing()))
    }
    private final class Partner: ProtectionAllowancePartner {
        var hasAllowance = false; var failRemoval = false; var failRepair = false; var failAfterCommit = false
        var history: [String] = ["pre-existing"]
        var removals = 0; var repairs = 0
        func commit() throws { hasAllowance = true; history.append("new request"); if failAfterCommit { throw ProtectionWriterError.unavailable } }
        func accessIsOpen() -> Bool { hasAllowance }
        func compensate() throws {
            try remove(); try repair()
        }
        func remove() throws {
            removals += 1
            if failRemoval { throw ProtectionWriterError.unavailable }
            hasAllowance = false
        }
        func repair() throws {
            repairs += 1
            if failRepair { throw ProtectionHostError.independentRestriction }
        }
    }
    private final class AckInterposer: ProtectionAllowanceJournal {
        let file: ProtectionFileAllowanceJournal; let afterAck: () -> Void
        init(_ file: ProtectionFileAllowanceJournal, afterAck: @escaping () -> Void) { self.file = file; self.afterAck = afterAck }
        func prepare(_ baseline: ProtectionGrantBaseline) throws { try file.prepare(baseline) }
        func acknowledge() throws { try file.acknowledge(); afterAck() }
        func finishCompensation() throws { try file.finishCompensation() }
    }

    func testPostAckRemovalAndRepairFailuresRetainFileAndRecoverOnRelaunch() throws {
        for failsRemoval in [true, false] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("joint.json")
            let (host, store, driver, clock, ticket) = try fixture()
            let oldID = UUID().uuidString
            try store.transaction { state in
                state.confirmedGrants[oldID] = .init(requestID: UUID(uuidString: oldID)!, confirmedAt: clock.now.addingTimeInterval(-3600), windowEnds: [:])
                state.grantOrder.append(oldID)
            }
            let partner = Partner(); partner.failRemoval = failsRemoval; partner.failRepair = !failsRemoval
            let file = ProtectionFileAllowanceJournal(url: url, eventID: UUID(), generation: "history", end: clock.now.addingTimeInterval(120), receiptExisted: { false })
            let interposer = AckInterposer(file) { driver.independent = true }
            XCTAssertFalse(ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: true, seconds: 120, authorized: true, partner: partner, journal: interposer))
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            XCTAssertTrue(try ProtectionFileAllowanceJournal.read(url).acknowledged)
            // A fresh recovery path must not treat acknowledged as finished.
            XCTAssertThrowsError(try ProtectionFileAllowanceJournal.recover(at: url) { record in
                try ProtectionAllowanceRecovery.recover(record.baseline, partnerReceiptExisted: record.beforeFeedReceiptExisted,
                    removeNewPartnerAllowance: partner.remove, repairPartner: partner.repair,
                    compensateScheduled: { try host.compensateGrant($0, authorized: true) })
            })
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            XCTAssertNotNil(try store.load().confirmedGrants[ticket.requestID.uuidString])
            partner.failRemoval = false; partner.failRepair = false; driver.independent = false
            try ProtectionFileAllowanceJournal.recover(at: url) { record in
                try ProtectionAllowanceRecovery.recover(record.baseline, partnerReceiptExisted: record.beforeFeedReceiptExisted,
                    removeNewPartnerAllowance: partner.remove, repairPartner: partner.repair,
                    compensateScheduled: { try host.compensateGrant($0, authorized: true) })
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
            XCTAssertFalse(partner.hasAllowance)
            XCTAssertEqual(partner.history, ["pre-existing", "new request"])
            XCTAssertNotNil(try store.load().confirmedGrants[oldID])
            XCTAssertNil(try store.load().confirmedGrants[ticket.requestID.uuidString])
            XCTAssertEqual(driver.rules, [.morning])
        }
    }

    func testPartialCommitWithoutReturnedReceiptKeepsDurableOwnershipUntilRemovalSucceeds() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("joint.json")
        let (host, store, _, clock, ticket) = try fixture()
        let partner = Partner(); partner.failAfterCommit = true; partner.failRemoval = true
        let file = ProtectionFileAllowanceJournal(url: url, eventID: UUID(), generation: "history", end: clock.now.addingTimeInterval(120), receiptExisted: { false })
        XCTAssertFalse(ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: true, seconds: 120, authorized: true, partner: partner, journal: file))
        XCTAssertTrue(partner.hasAllowance); XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertFalse(try file.record().acknowledged)
        partner.failRemoval = false
        try ProtectionFileAllowanceJournal.recover(at: url) { record in
            try ProtectionAllowanceRecovery.recover(record.baseline, partnerReceiptExisted: record.beforeFeedReceiptExisted,
                removeNewPartnerAllowance: partner.remove, repairPartner: partner.repair,
                compensateScheduled: { try host.compensateGrant($0, authorized: true) })
        }
        XCTAssertFalse(partner.hasAllowance); XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(try store.load().allowances.isEmpty)
        XCTAssertEqual(partner.history, ["pre-existing", "new request"])
    }

    func testInvalidReceiptBaselineCannotPrepareJournalOrGrantAllowance() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let (host, store, _, clock, ticket) = try fixture()
        let partner = Partner()
        let file = ProtectionFileAllowanceJournal(url: url, eventID: UUID(), generation: "history", end: clock.now.addingTimeInterval(120), receiptExisted: { throw ProtectionWriterError.unavailable })
        XCTAssertFalse(ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: true, seconds: 120, authorized: true, partner: partner, journal: file))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path)); XCTAssertFalse(partner.hasAllowance)
        XCTAssertTrue(try store.load().allowances.isEmpty)
    }

    func testMalformedPreferenceKeyIsFailureNotMissingRemovalAcknowledgement() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshot = ProtectionPreferenceSnapshot(url: directory.appendingPathComponent("values"), lockURL: directory.appendingPathComponent("writer.lock"))
        try snapshot.migrate(["grace": 123.0])
        let path = directory.appendingPathComponent("values").appendingPathComponent(Data("grace".utf8).base64EncodedString() + ".plist")
        try PropertyListSerialization.data(fromPropertyList: [], format: .binary, options: 0).write(to: path)
        XCTAssertThrowsError(try snapshot.object(for: "grace"))
    }

    func testRecoveryPreservesExistingPartnerReceiptAndRetainsFileOnScheduledFailure() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("joint.json")
        let (host, store, driver, clock, ticket) = try fixture()
        let file = ProtectionFileAllowanceJournal(url: url, eventID: UUID(), generation: "old history", end: clock.now.addingTimeInterval(120), receiptExisted: { true })
        try file.prepare(host.grantBaseline(ticket)); try file.acknowledge()
        let partner = Partner(); partner.hasAllowance = true
        driver.fails = true
        XCTAssertThrowsError(try ProtectionFileAllowanceJournal.recover(at: url) { record in
            try ProtectionAllowanceRecovery.recover(record.baseline, partnerReceiptExisted: record.beforeFeedReceiptExisted,
                removeNewPartnerAllowance: partner.remove, repairPartner: partner.repair,
                compensateScheduled: { try host.compensateGrant($0, authorized: true) })
        })
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path)); XCTAssertEqual(partner.removals, 0)
        driver.fails = false
        try ProtectionFileAllowanceJournal.recover(at: url) { record in
            try ProtectionAllowanceRecovery.recover(record.baseline, partnerReceiptExisted: record.beforeFeedReceiptExisted,
                removeNewPartnerAllowance: partner.remove, repairPartner: partner.repair,
                compensateScheduled: { try host.compensateGrant($0, authorized: true) })
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(partner.hasAllowance); XCTAssertEqual(partner.history, ["pre-existing"])
        XCTAssertEqual(partner.removals, 0); XCTAssertTrue(try store.load().allowances.isEmpty)
    }

    func testCorruptRetainedJournalPreservesBytesAndRunsNoCompensation() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let bytes = Data("invalid retained journal".utf8); try bytes.write(to: url)
        var calls = 0
        XCTAssertThrowsError(try ProtectionFileAllowanceJournal.recover(at: url) { _ in calls += 1 })
        XCTAssertEqual(calls, 0); XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testStatelessProbeCannotClearAnchorBeforeExtensionHandoffAndSleepRollback() throws {
        let (_, store, _, clock, _) = try fixture()
        var state = try store.load(); let start = clock.now
        let live = ProtectionLiveProcessClock(processID: "A")
        _ = ProtectionEngine.advanceClock(state: &state, sample: live.sample(wall: start, continuous: 100, state: state))
        // This was the native capability probe's previous mutating call.
        XCTAssertTrue(live.sample(wall: start, continuous: 100, state: nil).isValid)
        _ = ProtectionEngine.advanceClock(state: &state, sample: .init(wall: start.addingTimeInterval(60), processID: "B", continuousSeconds: 1))
        let resumed = live.sample(wall: start.addingTimeInterval(-3600), continuous: 1900, state: state)
        XCTAssertEqual(resumed.projectedNow, start.addingTimeInterval(1800))
        let now = try XCTUnwrap(ProtectionEngine.advanceClock(state: &state, sample: resumed))
        ProtectionEngine.reconcile(state: &state, at: now)
        XCTAssertTrue(ProtectionEngine.plan(state, at: now).activeWindows.isEmpty)
        XCTAssertNil(state.clockLedger?.recoveryEndsAt)
    }

    func testPreviewStartCancelIncompleteAndCompleteUseOnlyOwnedMemory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let sentinel = directory.appendingPathComponent("existing-history.json")
        let bytes = Data("untouched history and preferences".utf8); try bytes.write(to: sentinel)
        let now = ISO8601DateFormatter().date(from: "2026-10-07T08:00:00Z")!
        let make = { ProtectionPreviewSession(now: now, clock: { .init(wall: now, processID: "test-preview", continuousSeconds: 100) }) }
        let canceled = make(); XCTAssertTrue(canceled.start()); canceled.cancel()
        XCTAssertFalse(canceled.confirm(completed: true)); XCTAssertFalse(canceled.previewAllowanceIsOpen)
        XCTAssertTrue(try canceled.snapshot().confirmedGrants.isEmpty)
        let incomplete = make(); XCTAssertTrue(incomplete.start()); XCTAssertFalse(incomplete.confirm(completed: false))
        XCTAssertFalse(incomplete.previewAllowanceIsOpen); XCTAssertTrue(try incomplete.snapshot().allowances.isEmpty)
        let completed = make(); XCTAssertTrue(completed.start()); XCTAssertTrue(completed.confirm(completed: true))
        XCTAssertTrue(completed.previewAllowanceIsOpen); XCTAssertEqual(completed.previewRules, [])
        XCTAssertEqual(try completed.snapshot().confirmedGrants.count, 1)
        completed.cancel(); XCTAssertFalse(completed.confirm(completed: true))
        XCTAssertEqual(try Data(contentsOf: sentinel), bytes)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["existing-history.json"])
    }
}
