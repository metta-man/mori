import XCTest
import Foundation
@testable import Mori

final class MoriLegacyTrialRecoveryTests: XCTestCase {
    private typealias Recovery = MoriLegacyTrialRecovery
    private var root: URL!
    private let id = UUID(uuidString: "58cdcf07-608d-4aee-9ff2-b6c3154b7d94")!
    private let otherID = UUID(uuidString: "78cdcf07-608d-4aee-9ff2-b6c3154b7d94")!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("MoriLegacyTrialRecovery-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }

    private final class Fake {
        var names: Set<String> = ["mori.beforeFeedGrace", "mori.protection.morning.r1", "ordinary.unknown"]
        var stores: Set<String> = ["default", "Focus", "PIN", "mori.scheduled-protection", "unknown"]
        var stopped: [String] = []
        var stopInvocations = 0
        var cleared: [String] = []
        var readbackSucceeds = true
        var effects: Recovery.Effects {
            .init(activities: { self.names.sorted() }, stop: {
                self.stopInvocations += 1
                self.stopped += $0; self.names.subtract($0)
            }, clearStore: {
                self.cleared.append($0)
                if self.readbackSucceeds { self.stores.remove($0) }
                return self.readbackSucceeds
            })
        }
    }
    private func name(_ id: UUID, _ suffix: String = "morning.r1") -> String {
        Recovery.namespace + id.uuidString.lowercased() + "." + suffix
    }
    private func store(_ id: UUID) -> String { Recovery.namespace + id.uuidString.lowercased() }
    private func run(_ id: UUID) -> URL { root.appendingPathComponent("runs/" + id.uuidString.lowercased()) }
    private func lease(_ id: UUID) throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: ["id": id.uuidString, "armed": true,
            "selection": ["opaque": "retained"], "extra": "preserved", "expiresAt": 0])
        try data.write(to: root.appendingPathComponent("lease-v1.json")); return data
    }

    func testExplicitRecoveryKeepsIndependentRulesAndLeaseBytes() throws {
        let fake = Fake(); let beforeNames = fake.names; let beforeStores = fake.stores
        fake.names.insert(name(id)); fake.names.insert(name(id, "expiry.r1.172800")); fake.stores.insert(store(id))
        let data = try lease(id)
        let journal = root.appendingPathComponent("ordinary-journal.json")
        try Data("private record".utf8).write(to: journal)
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .acknowledged)
        XCTAssertEqual(fake.names, beforeNames); XCTAssertEqual(fake.stores, beforeStores)
        XCTAssertEqual(fake.cleared, [store(id)])
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("lease-v1.json")), data)
        XCTAssertEqual(try Data(contentsOf: journal), Data("private record".utf8))
        XCTAssertEqual(try Data(contentsOf: run(id).appendingPathComponent("OFF-v1")), Data("OFF".utf8))
    }

    func testExpiredArmedLeaseRemainsRecoverableWithoutSchedule() throws {
        let fake = Fake(); _ = try lease(id); fake.stores.insert(store(id))
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .acknowledged)
        XCTAssertEqual(fake.cleared, [store(id)]); XCTAssertTrue(fake.stopped.isEmpty)
        XCTAssertEqual(fake.stopInvocations, 0) // Empty SDK stop would stop independent schedules.
    }

    func testRunDirectoryRecoversStoreAfterLeaseAndScheduleAreMissing() throws {
        let fake = Fake(); fake.stores.insert(store(id))
        try FileManager.default.createDirectory(at: run(id), withIntermediateDirectories: true)
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .acknowledged)
        XCTAssertEqual(fake.cleared, [store(id)])
        XCTAssertEqual(fake.stopInvocations, 0)
    }

    func testUnknownStoreWithoutOwnershipIsPreservedAndNotAcknowledged() {
        let fake = Fake(); fake.stores.insert(store(id)); let before = fake.stores
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .noKnownOwnership)
        XCTAssertEqual(fake.stores, before); XCTAssertTrue(fake.cleared.isEmpty)
    }

    func testMalformedNamespaceNamesNeverBecomeStoreAuthority() {
        let fake = Fake(); let malformed = name(id, "morning.r1.extra")
        fake.names.insert(malformed); fake.stores.insert(store(id))
        XCTAssertNil(Recovery.runID(malformed))
        XCTAssertNil(Recovery.runID(name(id, "morning.r01")))
        XCTAssertNil(Recovery.runID(name(id, "other.r1")))
        XCTAssertEqual(Recovery.runID(name(id, "bedtime.r2")), id)
        XCTAssertEqual(Recovery.runID(name(id, "expiry.r2.172800")), id)
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .pending)
        XCTAssertTrue(fake.names.contains(malformed)); XCTAssertTrue(fake.cleared.isEmpty)
    }

    func testCorruptLeaseIsPreservedWhileKnownActivityCleanupStaysPending() throws {
        let fake = Fake(); fake.names.insert(name(id)); fake.stores.insert(store(id))
        let data = Data("corrupt lease".utf8); try data.write(to: root.appendingPathComponent("lease-v1.json"))
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .pending)
        XCTAssertFalse(fake.stores.contains(store(id))); XCTAssertEqual(fake.cleared, [store(id)])
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("lease-v1.json")), data)
    }

    func testFailedOFFWritePerformsNoScheduleOrStoreMutation() throws {
        let fake = Fake(); fake.names.insert(name(id)); fake.stores.insert(store(id))
        try FileManager.default.createDirectory(at: run(id).appendingPathComponent("OFF-v1"), withIntermediateDirectories: true)
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .pending)
        XCTAssertTrue(fake.stopped.isEmpty); XCTAssertTrue(fake.cleared.isEmpty)
    }

    func testSymlinkRunIsPreservedWithoutWritingThroughIt() throws {
        let fake = Fake(); fake.names.insert(name(id)); fake.stores.insert(store(id))
        let target = root.appendingPathComponent("ordinary-data")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("runs"), withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(at: run(id), withDestinationURL: target)
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .pending)
        XCTAssertTrue(fake.cleared.isEmpty); XCTAssertTrue(fake.stopped.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: target.appendingPathComponent("OFF-v1").path))
    }

    func testCorruptUUIDFileDoesNotBlockHealthyKnownRun() throws {
        try assertCorruptChildPreservesHealthyRecovery(symlink: false)
    }

    func testCorruptUUIDSymlinkDoesNotBlockHealthyKnownRun() throws {
        try assertCorruptChildPreservesHealthyRecovery(symlink: true)
    }

    private func assertCorruptChildPreservesHealthyRecovery(symlink: Bool) throws {
        let fake = Fake()
        let independentNames = fake.names; let independentStores = fake.stores
        fake.names.formUnion([name(id), name(otherID, "bedtime.r2")])
        fake.stores.formUnion([store(id), store(otherID)])
        let leaseBytes = try lease(otherID)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("runs"), withIntermediateDirectories: false)
        let preserved = Data("preserve unsafe run".utf8)
        let target = root.appendingPathComponent("ordinary-data")
        if symlink {
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
            try preserved.write(to: target.appendingPathComponent("record"))
            try FileManager.default.createSymbolicLink(at: run(otherID), withDestinationURL: target)
        } else {
            try preserved.write(to: run(otherID))
        }

        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .pending)
        XCTAssertEqual(fake.cleared, [store(id)])
        XCTAssertEqual(fake.stopped, [name(id)])
        XCTAssertEqual(fake.names, independentNames.union([name(otherID, "bedtime.r2")]))
        XCTAssertEqual(fake.stores, independentStores.union([store(otherID)]))
        XCTAssertEqual(try Data(contentsOf: run(id).appendingPathComponent("OFF-v1")), Data("OFF".utf8))
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("lease-v1.json")), leaseBytes)
        if symlink {
            XCTAssertEqual(try Data(contentsOf: target.appendingPathComponent("record")), preserved)
            XCTAssertFalse(FileManager.default.fileExists(atPath: target.appendingPathComponent("OFF-v1").path))
            XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: run(otherID).path), target.path)
        } else {
            XCTAssertEqual(try Data(contentsOf: run(otherID)), preserved)
        }
    }

    func testOverEightKnownRunsPerformNoOSMutation() {
        let fake = Fake()
        for _ in 0..<9 { let id = UUID(); fake.names.insert(name(id)); fake.stores.insert(store(id)) }
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .pending)
        XCTAssertTrue(fake.stopped.isEmpty); XCTAssertTrue(fake.cleared.isEmpty)
    }

    func testFailedSDKReadbackRemainsPendingAndCanBeRetried() {
        let fake = Fake(); fake.names.insert(name(id)); fake.stores.insert(store(id)); fake.readbackSucceeds = false
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .pending)
        fake.readbackSucceeds = true
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .acknowledged)
        XCTAssertFalse(fake.stores.contains(store(id)))
    }

    func testRepeatedRecoveryPreservesExistingOFFBytes() throws {
        let fake = Fake(); fake.names.insert(name(id)); fake.stores.insert(store(id))
        try FileManager.default.createDirectory(at: run(id), withIntermediateDirectories: true)
        let data = Data("existing OFF marker".utf8); try data.write(to: run(id).appendingPathComponent("OFF-v1"))
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .acknowledged)
        let originalNames = fake.names; let originalStores = fake.stores
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .acknowledged)
        XCTAssertEqual(fake.names, originalNames); XCTAssertEqual(fake.stores, originalStores)
        XCTAssertEqual(try Data(contentsOf: run(id).appendingPathComponent("OFF-v1")), data)
    }

    func testCallbackClearsOnlyItsOwnRunAndLeavesCurrentSchedulePending() {
        let fake = Fake(); let current = name(id); let sibling = name(id, "expiry.r1.172800")
        fake.names.formUnion([current, sibling, name(otherID)])
        fake.stores.formUnion([store(id), store(otherID)])
        XCTAssertEqual(Recovery.recoverCallback(current, root: root, effects: fake.effects), .pending)
        XCTAssertEqual(fake.cleared, [store(id)]); XCTAssertEqual(fake.stopped, [sibling])
        XCTAssertTrue(fake.names.contains(current)); XCTAssertTrue(fake.names.contains(name(otherID)))
        XCTAssertTrue(fake.stores.contains(store(otherID)))
        XCTAssertEqual(Recovery.recover(root: root, effects: fake.effects), .acknowledged)
    }

    func testCallbackWithoutRemainingScheduleCanAcknowledgeKnownRun() {
        let fake = Fake(); fake.stores.insert(store(id))
        XCTAssertEqual(Recovery.recoverCallback(name(id), root: root, effects: fake.effects), .acknowledged)
        XCTAssertEqual(fake.cleared, [store(id)])
    }

    func testMalformedCallbackNeverMutatesKnownOrUnknownRules() {
        let fake = Fake(); fake.names.insert(name(id)); fake.stores.insert(store(id))
        XCTAssertEqual(Recovery.recoverCallback(name(id, "morning.r1.extra"), root: root, effects: fake.effects), .pending)
        XCTAssertTrue(fake.stopped.isEmpty); XCTAssertTrue(fake.cleared.isEmpty)
    }
}
