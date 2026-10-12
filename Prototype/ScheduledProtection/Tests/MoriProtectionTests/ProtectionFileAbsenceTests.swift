import Foundation
import XCTest
@testable import MoriProtection

final class ProtectionFileAbsenceTests: XCTestCase {
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    private func keyURL(_ directory: URL, _ key: String) -> URL {
        directory.appendingPathComponent(Data(key.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "_") + ".plist")
    }
    private func journal(_ url: URL, io: ProtectionFileIO = .system) throws -> ProtectionFileAllowanceJournal {
        let file = ProtectionFileAllowanceJournal(url: url, eventID: UUID(), generation: "history", end: Date().addingTimeInterval(120), io: io, receiptExisted: { false })
        try file.prepare(.init(state: .init(configuration: .newSetup), requestID: UUID()))
        try file.acknowledge()
        return file
    }
    private func error(_ code: POSIXError.Code) -> NSError { NSError(domain: NSPOSIXErrorDomain, code: Int(code.rawValue)) }

    func testOnlyConcreteNotFoundCountsAsAbsence() {
        XCTAssertTrue(ProtectionFileIO.isNotFound(error(.ENOENT)))
        XCTAssertTrue(ProtectionFileIO.isNotFound(CocoaError(.fileReadNoSuchFile)))
        for code in [POSIXError.Code.EACCES, .EIO, .ENOTDIR, .ELOOP] {
            XCTAssertFalse(ProtectionFileIO.isNotFound(error(code)))
            let misleading = NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileReadNoSuchFile.rawValue, userInfo: [NSUnderlyingErrorKey: error(code)])
            XCTAssertFalse(ProtectionFileIO.isNotFound(misleading))
        }
        XCTAssertFalse(ProtectionFileIO.isNotFound(CocoaError(.fileReadNoPermission)))
    }

    func testGenuineAbsenceSucceedsWithoutEffectsOrRemovingIndependentRestrictions() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let snapshot = ProtectionPreferenceSnapshot(url: root.appendingPathComponent("values"), lockURL: root.appendingPathComponent("writer.lock"))
        try snapshot.migrate([:]); try snapshot.validate()
        XCTAssertNil(try snapshot.object(for: "session"))
        XCTAssertNoThrow(try snapshot.set(nil, for: "session"))
        let url = root.appendingPathComponent("absent-journal.json")
        var effects = 0; let focus = Set(["focus"])
        try ProtectionFileAllowanceJournal.recover(at: url) { _ in effects += 1 }
        XCTAssertEqual(effects, 0); XCTAssertEqual(focus, ["focus"])
        let file = try journal(url); try file.finishCompensation()
        XCTAssertNoThrow(try file.finishCompensation())
    }

    func testValidMarkerLookupDeniedCannotBecomeNoSessionAndRestorationRecovers() throws {
        if NSUserName() == "root" { throw XCTSkip("Root bypasses Unix directory lookup permissions") }
        let root = try directory(); let protected = root.appendingPathComponent("protected")
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: protected.path)
            try? FileManager.default.removeItem(at: root)
        }
        let values = root.appendingPathComponent("values")
        let snapshot = ProtectionPreferenceSnapshot(url: values, lockURL: root.appendingPathComponent("writer.lock"))
        try snapshot.migrate(["session": try JSONEncoder().encode(["focus"])])
        let key = keyURL(values, "session")
        try FileManager.default.createDirectory(at: protected, withIntermediateDirectories: true)
        let target = protected.appendingPathComponent("session.plist")
        try FileManager.default.moveItem(at: key, to: target)
        try FileManager.default.createSymbolicLink(at: key, withDestinationURL: target)
        let journalURL = root.appendingPathComponent("journal.json")
        _ = try journal(journalURL)
        let originalJournal = try Data(contentsOf: journalURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: protected.path)
        try snapshot.validate() // Marker remains accessible and valid.
        XCTAssertFalse(FileManager.default.fileExists(atPath: key.path), "Original preflight falsely reported absence here")
        let reader = ProtectionCheckedInputReader(read: snapshot.object(for:))
        var effectCalls = 0; var focus = Set(["focus"]); var scheduled = Set(["scheduled"])
        let recover = {
            try ProtectionFileAllowanceJournal.recover(at: journalURL) { record in
                try ProtectionAllowanceRecovery.recover(record.baseline, partnerReceiptExisted: false,
                    removeNewPartnerAllowance: {}, repairPartner: {
                        try ProtectionCheckedRepair.perform(load: { try reader.decoded("session", as: [String].self) }, apply: { session in
                            effectCalls += 1
                            if session == nil { focus.removeAll() }
                        })
                    }, compensateScheduled: { _ in scheduled.remove("scheduled") })
            }
        }
        XCTAssertThrowsError(try recover())
        XCTAssertEqual(effectCalls, 0); XCTAssertEqual(focus, ["focus"]); XCTAssertEqual(scheduled, ["scheduled"])
        XCTAssertEqual(try Data(contentsOf: journalURL), originalJournal)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: protected.path)
        try recover()
        XCTAssertEqual(effectCalls, 1); XCTAssertEqual(focus, ["focus"]); XCTAssertTrue(scheduled.isEmpty)
        XCTAssertNil(try ProtectionFileIO.system.optionalData(at: journalURL))
    }

    func testValidMarkerReadAndPreferenceRemovalFailuresKeepRestrictionsAndJournalUntilRetry() throws {
        for failsRead in [true, false] {
            let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
            let values = root.appendingPathComponent("values"); let key = keyURL(values, "session")
            var fault = false
            let injected = ProtectionFileIO(read: { url in
                if fault && failsRead && url == key { throw self.error(.EIO) }
                return try Data(contentsOf: url)
            }, remove: { url in
                if fault && !failsRead && url == key { throw self.error(.EACCES) }
                try FileManager.default.removeItem(at: url)
            })
            let snapshot = ProtectionPreferenceSnapshot(url: values, lockURL: root.appendingPathComponent("writer.lock"), io: injected)
            try snapshot.migrate(["session": try JSONEncoder().encode(["focus"])])
            let journalURL = root.appendingPathComponent("journal.json"); _ = try journal(journalURL)
            let original = try Data(contentsOf: journalURL)
            fault = true; try snapshot.validate()
            var effects = 0; let focus = Set(["focus"])
            let recover = {
                try ProtectionFileAllowanceJournal.recover(at: journalURL) { _ in
                    if failsRead { _ = try snapshot.object(for: "session") }
                    else { try snapshot.set(nil, for: "session") }
                    effects += 1
                }
            }
            XCTAssertThrowsError(try recover())
            XCTAssertEqual(effects, 0); XCTAssertEqual(focus, ["focus"])
            XCTAssertEqual(try Data(contentsOf: journalURL), original)
            fault = false; try recover()
            XCTAssertEqual(effects, 1); XCTAssertEqual(focus, ["focus"])
            XCTAssertNil(try ProtectionFileIO.system.optionalData(at: journalURL))
        }
    }

    func testJournalReadPrepareAndRemoveErrorsNeverReportAbsentOrFinished() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("journal.json")
        var failRead = false; var failRemove = false
        let injected = ProtectionFileIO(read: { path in
            if failRead && path == url { throw self.error(.EACCES) }
            return try Data(contentsOf: path)
        }, remove: { path in
            if failRemove && path == url { throw self.error(.EIO) }
            try FileManager.default.removeItem(at: path)
        })
        let file = try journal(url, io: injected); let original = try Data(contentsOf: url)
        failRead = true
        var effects = 0
        XCTAssertThrowsError(try ProtectionFileAllowanceJournal.recover(at: url, io: injected) { _ in effects += 1 })
        XCTAssertThrowsError(try file.prepare(.init(state: .init(configuration: .newSetup), requestID: UUID())))
        XCTAssertEqual(effects, 0); XCTAssertEqual(try Data(contentsOf: url), original)
        failRead = false; failRemove = true
        XCTAssertThrowsError(try file.finishCompensation())
        XCTAssertThrowsError(try ProtectionFileAllowanceJournal.recover(at: url, io: injected) { _ in effects += 1 })
        XCTAssertEqual(try Data(contentsOf: url), original)
        failRemove = false
        try ProtectionFileAllowanceJournal.recover(at: url, io: injected) { _ in effects += 1 }
        XCTAssertNil(try ProtectionFileIO.system.optionalData(at: url))
    }

    func testStateReadFailureIsNotNewInitialStateAndMigrationFailureDoesNotOverwriteExistingFiles() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let stateURL = root.appendingPathComponent("state.json")
        let injected = ProtectionFileIO(read: { url in
            if url == stateURL { throw self.error(.EACCES) }
            return try Data(contentsOf: url)
        })
        XCTAssertThrowsError(try ProtectionFileStore(url: stateURL, initial: .init(configuration: .newSetup), io: injected).load())
        let values = root.appendingPathComponent("values")
        let snapshot = ProtectionPreferenceSnapshot(url: values, lockURL: root.appendingPathComponent("writer.lock"))
        try snapshot.migrate(["session": "existing"])
        let marker = values.appendingPathComponent("migrated-v1"); let bytes = try Data(contentsOf: keyURL(values, "session"))
        let failsMarker = ProtectionPreferenceSnapshot(url: values, lockURL: root.appendingPathComponent("writer.lock"), io: .init(read: { url in
            if url == marker { throw self.error(.EACCES) }
            return try Data(contentsOf: url)
        }))
        XCTAssertThrowsError(try failsMarker.migrate(["session": "replacement"]))
        XCTAssertEqual(try Data(contentsOf: keyURL(values, "session")), bytes)
    }
}
