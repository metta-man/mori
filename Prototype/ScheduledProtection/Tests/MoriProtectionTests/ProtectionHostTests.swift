import XCTest
@testable import MoriProtection

final class ProtectionHostTests: XCTestCase {
    final class Driver: ProtectionHostDriver {
        var rules: Set<ProtectionRule> = []; var independent = false; var fails = false
        var registrations: [ProtectionRegistration] = []
        func registerCalendar(_ c: ProtectionConfiguration) throws { registrations = try ProtectionRegistration.calendars(c) }
        func scheduleReconciliation(at: Date?) throws { if fails { throw ProtectionHostError.registrationFailed } }
        func applyScheduledContribution(_ value: Set<ProtectionRule>) throws { rules = value }
        func independentlyRestricted() -> Bool { independent }
    }
    final class Clock { var now = Date(timeIntervalSince1970: 1_800_000_000); var uptime = 100.0
        func sample() -> ProtectionClockSample { .init(wall: now, processID: "synthetic-stable-boot", continuousSeconds: uptime) }
    }
    func fixture() -> (ProtectionHost, Driver, Clock, ProtectionMemoryStore) {
        let clock = Clock(); let driver = Driver()
        var config = ProtectionConfiguration.newSetup; config.morningEnabled = true
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        clock.now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 8))!
        config.timeZoneIdentifier = "UTC"; config.morningStartMinute = 420; config.morningDetectionEndMinute = 720
        let storage = ProtectionMemoryStore(.init(configuration: config))
        return (.init(storage: storage, driver: driver, clock: clock.sample), driver, clock, storage)
    }
    func testFirstDeliveredCallbackAndTemporaryConfirmedAccess() throws {
        let (host, driver, _, _) = fixture()
        XCTAssertTrue(host.reconcile(.morningFirstUse(scheduledRevision: 1), authorized: true).effectsApplied)
        XCTAssertEqual(driver.rules, [.morning])
        let ticket = try XCTUnwrap(host.beginBreathing())
        let outcome = host.confirm(ticket, completed: true, allowanceSeconds: 120, authorized: true)
        XCTAssertTrue(host.accessIsOpen(outcome, ticket: ticket)); XCTAssertEqual(driver.rules, [])
    }
    func testIndependentBeforeFeedFocusPINNeverReportedOpen() throws {
        let (host, driver, _, _) = fixture(); _ = host.reconcile(.morningFirstUse(scheduledRevision: 1), authorized: true)
        let ticket = try XCTUnwrap(host.beginBreathing()); driver.independent = true
        let outcome = host.confirm(ticket, completed: true, allowanceSeconds: 120, authorized: true)
        XCTAssertFalse(host.accessIsOpen(outcome, ticket: ticket)); XCTAssertTrue(driver.independent)
    }
    func testCancellationAndDuplicateDoNotExtendAllowance() throws {
        let (host, _, clock, storage) = fixture(); _ = host.reconcile(.morningFirstUse(scheduledRevision: 1), authorized: true)
        let canceled = try XCTUnwrap(host.beginBreathing()); try host.cancel(canceled)
        XCTAssertNil(host.confirm(canceled, completed: true, allowanceSeconds: 120, authorized: true).grant)
        let ticket = try XCTUnwrap(host.beginBreathing()); let first = host.confirm(ticket, completed: true, allowanceSeconds: 120, authorized: true)
        clock.uptime += 10; clock.now += 10
        let duplicate = host.confirm(ticket, completed: true, allowanceSeconds: 900, authorized: true)
        XCTAssertEqual(first.grant, duplicate.grant); XCTAssertEqual(try storage.load().confirmedGrants.count, 1)
        clock.uptime += 111; clock.now += 111
        XCTAssertFalse(host.accessIsOpen(duplicate, ticket: ticket))
    }
    func testRegistrationFailureCannotOpenAndForegroundRecovers() throws {
        let (host, driver, _, _) = fixture(); _ = host.reconcile(.morningFirstUse(scheduledRevision: 1), authorized: true)
        let ticket = try XCTUnwrap(host.beginBreathing()); driver.fails = true
        let failed = host.confirm(ticket, completed: true, allowanceSeconds: 120, authorized: true)
        XCTAssertFalse(failed.effectsApplied); XCTAssertFalse(host.accessIsOpen(failed, ticket: ticket)); XCTAssertEqual(driver.rules, [.morning])
        driver.fails = false; XCTAssertTrue(host.reconcile(authorized: true).effectsApplied)
    }
    func testMigrationAndIndependentBedtimeAndStaleRevision() throws {
        var config = ProtectionConfiguration(legacyMorningEnabled: true, legacyStartMinute: 420, legacyDurationSeconds: 1800)
        XCTAssertEqual(config.morningTrigger, .fixedTime); XCTAssertFalse(config.bedtimeEnabled)
        XCTAssertEqual(try ProtectionRegistration.calendars(config).count, 1)
        config.bedtimeEnabled = true; config.bedtimeWindow = .init(startMinute: 1320, endMinute: 420)
        XCTAssertEqual(try ProtectionRegistration.calendars(config).count, 2)
        XCTAssertThrowsError(try ProtectionRegistration.delivered("mori.protection.morning.r0", configuration: config, intervalStarted: true))
        config.morningDurationSeconds = 300
        XCTAssertEqual(try ProtectionRegistration.calendars(config).first?.endMinute, 435) // OS envelope15m; configured protection remains5m.
        XCTAssertEqual(config.morningDurationSeconds, 300)
    }
    func testUnsupportedClockCannotActivateButCanRemoveScheduledContribution() throws {
        let (_, driver, _, storage) = fixture(); let before = try storage.load()
        let host = ProtectionHost(storage: storage, driver: driver, clock: { throw ProtectionHostError.unsupportedClock })
        XCTAssertFalse(host.reconcile(authorized: true).effectsApplied); XCTAssertThrowsError(try host.beginBreathing())
        XCTAssertEqual(try storage.load().configuration, before.configuration)
        XCTAssertTrue(try storage.load().effectsRecovery!.pending); XCTAssertEqual(driver.rules, [])
    }
}
