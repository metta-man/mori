import XCTest
@testable import MoriProtection

final class ProtectionJointTests: XCTestCase {
    final class Partner: ProtectionAllowancePartner {
        var committed = false; var compensated = false; var fails = false; var open = true
        func commit() throws { if fails { throw ProtectionHostError.registrationFailed }; committed = true }
        func accessIsOpen() -> Bool { committed && open }
        func compensate() throws { compensated = true; committed = false }
    }
    final class Journal: ProtectionAllowanceJournal {
        var pending = false; var acknowledged = false; var failPrepare = false; var failAck = false
        var onAck: (() -> Void)?
        func prepare(_ baseline: ProtectionGrantBaseline) throws { if failPrepare { throw ProtectionWriterError.unavailable }; pending = true }
        func acknowledge() throws { if failAck { throw ProtectionWriterError.unavailable }; acknowledged = true; onAck?() }
        func finishCompensation() throws { pending = false }
    }
    func fixture() -> (ProtectionHost, ProtectionHostTests.Driver, ProtectionHostTests.Clock, ProtectionMemoryStore, ProtectionBreathTicket) {
        let driver = ProtectionHostTests.Driver(); let clock = ProtectionHostTests.Clock()
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(secondsFromGMT: 0)!
        clock.now = cal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 8))!
        var config = ProtectionConfiguration.newSetup; config.morningEnabled = true; config.timeZoneIdentifier = "UTC"
        let storage = ProtectionMemoryStore(.init(configuration: config))
        let host = ProtectionHost(storage: storage, driver: driver, clock: clock.sample)
        _ = host.reconcile(.morningFirstUse(scheduledRevision: 1), authorized: true)
        return (host, driver, clock, storage, try! XCTUnwrap(host.beginBreathing()))
    }
    func testBothParticipantsAndDurableAcknowledgementRequired() {
        let (host, driver, _, _, ticket) = fixture(); let partner = Partner(); let journal = Journal()
        XCTAssertTrue(ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: true, seconds: 120, authorized: true, partner: partner, journal: journal))
        XCTAssertTrue(journal.acknowledged); XCTAssertFalse(journal.pending); XCTAssertTrue(partner.committed); XCTAssertEqual(driver.rules, [])
    }
    func testPartnerFailureSelectivelyRevokesNewGrantAndRestoresMorning() throws {
        let (host, driver, _, storage, ticket) = fixture(); let partner = Partner(); partner.fails = true; let journal = Journal()
        XCTAssertFalse(ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: true, seconds: 120, authorized: true, partner: partner, journal: journal))
        XCTAssertTrue(partner.compensated); XCTAssertEqual(driver.rules, [.morning]); XCTAssertTrue(try storage.load().allowances.isEmpty)
        XCTAssertTrue(try storage.load().confirmedGrants.isEmpty); XCTAssertFalse(journal.pending)
    }
    func testJournalPrepareFailureMakesNoGrantOrPartnerMutation() throws {
        let (host, driver, _, storage, ticket) = fixture(); let partner = Partner(); let journal = Journal(); journal.failPrepare = true
        XCTAssertFalse(ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: true, seconds: 120, authorized: true, partner: partner, journal: journal))
        XCTAssertFalse(partner.committed); XCTAssertTrue(try storage.load().allowances.isEmpty); XCTAssertEqual(driver.rules, [.morning])
    }
    func testAckFailureOrIndependentFocusNeverReportsOpen() throws {
        for blockedByFocus in [false, true] {
            let (host, driver, _, storage, ticket) = fixture(); driver.independent = blockedByFocus
            let partner = Partner(); let journal = Journal(); journal.failAck = !blockedByFocus
            XCTAssertFalse(ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: true, seconds: 120, authorized: true, partner: partner, journal: journal))
            XCTAssertEqual(driver.independent, blockedByFocus); XCTAssertTrue(try storage.load().allowances.isEmpty); XCTAssertFalse(partner.committed)
        }
    }
    func testDeadlinePassesDuringAcknowledgementNoExpiredAccessReported() throws {
        let (host, driver, clock, storage, ticket) = fixture(); let partner = Partner(); let journal = Journal()
        journal.onAck = { clock.now += 1801; clock.uptime += 1801 }
        XCTAssertFalse(ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: true, seconds: 120, authorized: true, partner: partner, journal: journal))
        XCTAssertEqual(driver.rules, []); XCTAssertTrue(try storage.load().allowances.isEmpty); XCTAssertFalse(partner.committed)
    }
    func testCancellationBeforeConfirmationCreatesNeitherAllowance() throws {
        let (host, _, _, storage, ticket) = fixture(); let partner = Partner(); let journal = Journal()
        XCTAssertFalse(ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: false, seconds: 120, authorized: true, partner: partner, journal: journal))
        XCTAssertFalse(partner.committed); XCTAssertFalse(journal.pending); XCTAssertTrue(try storage.load().allowances.isEmpty)
    }
    func testOwnershipRequiresAckAndNeverClearsIndependentWriter() throws {
        var owns = false; var legacyMorning = true; let focus = true; let beforeFeed = true
        XCTAssertFalse(try ProtectionOwnershipTransition.takeOwnership(acknowledged: false, recordOwner: { owns = true }, retireLegacyMorning: { legacyMorning = false }, recomposeIndependent: {}))
        XCTAssertFalse(owns); XCTAssertTrue(legacyMorning)
        XCTAssertTrue(try ProtectionOwnershipTransition.takeOwnership(acknowledged: true, recordOwner: { owns = true }, retireLegacyMorning: { legacyMorning = false }, recomposeIndependent: { XCTAssertTrue(focus && beforeFeed) }))
        XCTAssertTrue(owns); XCTAssertFalse(legacyMorning); XCTAssertTrue(focus && beforeFeed)
    }
    func testPreferenceMigrationFreshAcrossInstancesDeletionAndNoHistoricalPurge() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mori-prefs-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: url) }
        let a = ProtectionPreferenceSnapshot(url: url.appendingPathComponent("values"), lockURL: url.appendingPathComponent("writers.lock"))
        let b = ProtectionPreferenceSnapshot(url: url.appendingPathComponent("values"), lockURL: url.appendingPathComponent("writers.lock"))
        let legacy = Data("existing archive".utf8)
        try a.migrate(["enabled": true, "legacy": legacy]); try b.migrate(["enabled": false])
        XCTAssertEqual(try b.object(for: "enabled") as? Bool, true)
        try a.set(300, for: "duration"); XCTAssertEqual(try b.object(for: "duration") as? Int, 300)
        try b.set(nil, for: "duration"); XCTAssertNil(try a.object(for: "duration")); XCTAssertEqual(try a.object(for: "legacy") as? Data, legacy)
        try b.set(nil, for: "legacy"); XCTAssertNil(try a.object(for: "legacy"))
    }
}
