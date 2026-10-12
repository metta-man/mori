import XCTest
@testable import MoriProtection

final class ProtectionCoordinationTests: XCTestCase {
    private func lockURL() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("mori-writer-test-\(UUID().uuidString)/writers.lock") }
    func testNestedLegacyWriteInsideScheduledEffectsUsesSameLock() throws {
        let url = lockURL(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let memory = ProtectionMemoryStore(.init(configuration: .newSetup))
        let coordinated = ProtectionCoordinatedStorage(memory, coordinationURL: url)
        var effectsCompleted = false
        try coordinated.exclusive { access in
            var state = try access.load()
            try ProtectionWriterCoordination.exclusive(url: url) {
                // Represents synchronous native contribution + old-store write.
                state.configuration.bedtimeEnabled = false
                effectsCompleted = true
            }
            try access.save(state)
        }
        XCTAssertTrue(effectsCompleted)
        XCTAssertFalse(try coordinated.load().configuration.bedtimeEnabled)
    }
    func testConcurrentContributionsKeepIndependentRestrictionsAndFreshSelection() throws {
        let url = lockURL(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var contributions: [String: Set<String>] = ["focus": ["video"], "pin": ["social"], "beforeFeed": ["social"]]
        var selected: Set<String> = []
        var revision = 0
        let failures = NSLock(); var errorCount = 0
        DispatchQueue.concurrentPerform(iterations: 100) { index in
            do {
                try ProtectionWriterCoordination.exclusive(url: url) {
                    // Selection mutation and its corresponding write are one envelope.
                    selected = ["selected-\(index)"]; revision += 1
                    contributions["scheduled"] = selected
                    XCTAssertEqual(contributions["scheduled"], selected)
                }
            } catch { failures.lock(); errorCount += 1; failures.unlock() }
        }
        try ProtectionWriterCoordination.exclusive(url: url) {
            contributions["scheduled"] = [] // Allowance removes only owned scope.
            XCTAssertEqual(contributions["focus"], ["video"])
            XCTAssertEqual(contributions["pin"], ["social"])
            XCTAssertEqual(contributions["beforeFeed"], ["social"])
        }
        XCTAssertEqual(revision, 100); XCTAssertEqual(errorCount, 0)
    }
    func testThrowReleasesCoordinationAndDoesNotRunFallbackMutation() throws {
        let url = lockURL(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        XCTAssertThrowsError(try ProtectionWriterCoordination.exclusive(url: url) { throw ProtectionHostError.registrationFailed })
        XCTAssertEqual(try ProtectionWriterCoordination.exclusive(url: url) { 42 }, 42)
    }
    func testCanceledTicketCannotOpenAfterMigratedConfigurationEdit() throws {
        let url = lockURL(); defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let now = Date(timeIntervalSince1970: 1_791_360_000)
        let cal = Calendar(identifier: .gregorian)
        let components = cal.dateComponents([.hour, .minute], from: now)
        let migrated = ProtectionConfiguration(legacyMorningEnabled: true,
            legacyStartMinute: (components.hour ?? 0) * 60 + (components.minute ?? 0), legacyDurationSeconds: 1800)
        let memory = ProtectionMemoryStore(.init(configuration: migrated, legacyCompletedMorningDay: "2025-01-01"))
        let driver = ProtectionHostTests.Driver()
        let storage = ProtectionCoordinatedStorage(memory, coordinationURL: url)
        let host = ProtectionHost(storage: storage, driver: driver, clock: { .init(wall: now, processID: "synthetic", continuousSeconds: 100) })
        _ = host.reconcile(authorized: true)
        let old = try XCTUnwrap(host.beginBreathing()); try host.cancel(old)
        XCTAssertNil(host.confirm(old, completed: true, allowanceSeconds: 300, authorized: true).grant)
        XCTAssertEqual(try storage.load().legacyCompletedMorningDay, "2025-01-01")
        XCTAssertEqual(try storage.load().configuration.morningTrigger, .fixedTime)
        XCTAssertFalse(try storage.load().configuration.bedtimeEnabled)
        let fresh = try XCTUnwrap(host.beginBreathing())
        try host.cancel(old) // Old sheet cannot invalidate the new flow epoch.
        XCTAssertNotNil(host.confirm(fresh, completed: true, allowanceSeconds: 120, authorized: true).grant)
    }
}
