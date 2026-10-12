import Foundation
import CoreFoundation

/// Direct filesystem operations. Only a concrete not-found error denotes
/// absence; permission, lookup, I/O and type errors remain failures.
public struct ProtectionFileIO {
    public let read: (URL) throws -> Data
    public let write: (Data, URL) throws -> Void
    public let remove: (URL) throws -> Void
    public init(read: @escaping (URL) throws -> Data = { try Data(contentsOf: $0) },
                write: @escaping (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) },
                remove: @escaping (URL) throws -> Void = { try FileManager.default.removeItem(at: $0) }) {
        self.read = read; self.write = write; self.remove = remove
    }
    public static var system: Self { .init() }
    public static func isNotFound(_ error: Error) -> Bool {
        let error = error as NSError
        if error.domain == NSPOSIXErrorDomain { return error.code == Int(POSIXError.Code.ENOENT.rawValue) }
        guard error.domain == NSCocoaErrorDomain,
              error.code == CocoaError.fileReadNoSuchFile.rawValue || error.code == CocoaError.fileNoSuchFile.rawValue else { return false }
        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            // A broad Cocoa code cannot conceal an underlying permission or
            // invalid-path error such as EACCES/ENOTDIR.
            return underlying.domain == NSPOSIXErrorDomain && underlying.code == Int(POSIXError.Code.ENOENT.rawValue)
        }
        return true
    }
    public func optionalData(at url: URL) throws -> Data? {
        do { return try read(url) }
        catch { if Self.isNotFound(error) { return nil }; throw error }
    }
    public func removeIfPresent(at url: URL) throws {
        do { try remove(url) }
        catch { if !Self.isNotFound(error) { throw error } }
    }
}

/// Fresh per-key files avoid rereading an unbounded preserved legacy archive
/// whenever a small gate preference changes. Migration never deletes old defaults.
public final class ProtectionPreferenceSnapshot {
    private let url: URL
    private let lockURL: URL
    private let io: ProtectionFileIO
    public init(url: URL, lockURL: URL, io: ProtectionFileIO = .system) { self.url = url; self.lockURL = lockURL; self.io = io }
    private var marker: URL { url.appendingPathComponent("migrated-v1") }
    private func keyURL(_ key: String) -> URL {
        url.appendingPathComponent(Data(key.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "_") + ".plist")
    }
    public func migrate(_ initial: [String: Any]) throws {
        try ProtectionWriterCoordination.exclusive(url: lockURL) {
            if let markerData = try io.optionalData(at: marker) {
                guard markerData == Data("1".utf8) else { throw ProtectionWriterError.unavailable }
                return
            }
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            for (key, object) in initial {
                let destination = keyURL(key)
                if try io.optionalData(at: destination) == nil {
                    try io.write(PropertyListSerialization.data(fromPropertyList: [object], format: .binary, options: 0), destination)
                }
            }
            try io.write(Data("1".utf8), marker)
        }
    }
    public func object(for key: String) throws -> Any? {
        try ProtectionWriterCoordination.exclusive(url: lockURL) {
            try validateUnlocked()
            guard let data = try io.optionalData(at: keyURL(key)) else { return nil }
            guard let values = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [Any], values.count == 1 else { throw ProtectionWriterError.unavailable }
            return values[0]
        }
    }
    public func set(_ object: Any?, for key: String) throws {
        try ProtectionWriterCoordination.exclusive(url: lockURL) {
            try validateUnlocked()
            if let object { try io.write(PropertyListSerialization.data(fromPropertyList: [object], format: .binary, options: 0), keyURL(key)) }
            else { try io.removeIfPresent(at: keyURL(key)) }
        }
    }
    private func validateUnlocked() throws {
        guard try io.read(marker) == Data("1".utf8) else { throw ProtectionWriterError.unavailable }
    }
    public func validate() throws { try ProtectionWriterCoordination.exclusive(url: lockURL) { try validateUnlocked() } }
}

public enum ProtectionCheckedInputError: Error {
    case invalidType(String)
    case invalidValue(String)
}

/// Absence is permitted only when the fresh read succeeds and returns nil.
/// Type, serialization and decode failures are never converted to defaults.
public struct ProtectionCheckedInputReader {
    private let read: (String) throws -> Any?
    public init(read: @escaping (String) throws -> Any?) { self.read = read }
    public func optional<T>(_ key: String, as type: T.Type) throws -> T? {
        guard let value = try read(key) else { return nil }
        guard let typed = value as? T else { throw ProtectionCheckedInputError.invalidType(key) }
        return typed
    }
    public func decoded<T: Decodable>(_ key: String, as type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T? {
        guard let data = try optional(key, as: Data.self) else { return nil }
        return try decoder.decode(type, from: data)
    }
    public func boolean(_ key: String, default fallback: Bool) throws -> Bool {
        guard let value = try read(key) else { return fallback }
        guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { throw ProtectionCheckedInputError.invalidType(key) }
        return number.boolValue
    }
    public func number(_ key: String) throws -> Double? {
        guard let value = try read(key) else { return nil }
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.isFinite else { throw ProtectionCheckedInputError.invalidType(key) }
        return number.doubleValue
    }
    public func integer(_ key: String, default fallback: Int, range: ClosedRange<Int>? = nil) throws -> Int {
        guard let number = try number(key) else { return fallback }
        guard number.rounded(.towardZero) == number, number >= Double(Int.min), number < Double(Int.max),
              range.map({ Double($0.lowerBound) <= number && number <= Double($0.upperBound) }) ?? true else { throw ProtectionCheckedInputError.invalidValue(key) }
        return Int(number)
    }
}

public enum ProtectionCheckedRepair {
    /// The effect closure is unreachable until the entire checked load succeeds.
    public static func perform<Snapshot>(load: () throws -> Snapshot,
                                         apply: (Snapshot) throws -> Void) throws {
        let snapshot = try load()
        try apply(snapshot)
    }
}
