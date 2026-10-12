import Foundation
import XCTest
@testable import MoriProtection

final class ProtectionCheckedRepairTests: XCTestCase {
    func testAbsentIsDistinctFromTypeDecodeAndReadFailure() throws {
        let reader = ProtectionCheckedInputReader { key in
            switch key {
            case "absent": return nil
            case "wrong-type": return "not Data"
            case "bad-json": return Data("invalid json".utf8)
            default: throw ProtectionWriterError.unavailable
            }
        }
        XCTAssertNil(try reader.decoded("absent", as: [String].self))
        XCTAssertThrowsError(try reader.decoded("wrong-type", as: [String].self))
        XCTAssertThrowsError(try reader.decoded("bad-json", as: [String].self))
        XCTAssertThrowsError(try reader.decoded("failed-read", as: [String].self))
    }
    func testValidMarkerDoesNotPermitEffectsWhenLaterCriticalDecodeFails() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshot = ProtectionPreferenceSnapshot(url: directory.appendingPathComponent("values"), lockURL: directory.appendingPathComponent("writer.lock"))
        try snapshot.migrate(["selection": try JSONEncoder().encode(["feed"]), "active-session": Data("invalid json".utf8)])
        let reader = ProtectionCheckedInputReader(read: snapshot.object(for:))
        var effects = 0; var focus = Set(["focus"])
        try snapshot.validate()
        XCTAssertThrowsError(try ProtectionCheckedRepair.perform(load: {
            let selection = try reader.decoded("selection", as: [String].self)
            _ = try reader.decoded("active-session", as: [String].self)
            return selection
        }, apply: { _ in effects += 1; focus.removeAll() }))
        XCTAssertEqual(effects, 0); XCTAssertEqual(focus, ["focus"])
        try snapshot.set(try JSONEncoder().encode(["focus"]), for: "active-session")
        try ProtectionCheckedRepair.perform(load: {
            let selection = try reader.decoded("selection", as: [String].self)
            _ = try reader.decoded("active-session", as: [String].self)
            return selection
        }, apply: { selection in effects += 1; XCTAssertEqual(selection, ["feed"]) })
        XCTAssertEqual(effects, 1); XCTAssertEqual(focus, ["focus"])
    }
    func testMalformedFlagOrNumberIsNotAnOffOrDefaultPolicy() throws {
        let reader = ProtectionCheckedInputReader { key in
            switch key {
            case "boolean": return true
            case "numeric-bool": return NSNumber(value: 0)
            case "string-bool": return "false"
            case "not-finite": return NSNumber(value: Double.nan)
            case "out-of-range": return NSNumber(value: 99)
            default: return nil
            }
        }
        XCTAssertTrue(try reader.boolean("boolean", default: false))
        XCTAssertFalse(try reader.boolean("absent", default: false))
        XCTAssertThrowsError(try reader.boolean("numeric-bool", default: false))
        XCTAssertThrowsError(try reader.boolean("string-bool", default: false))
        XCTAssertThrowsError(try reader.number("not-finite"))
        XCTAssertThrowsError(try reader.integer("out-of-range", default: 7, range: 0...23))
    }
}
