import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

public protocol ProtectionStorage {
    func exclusive<T>(_ body: (ProtectionStorageAccess) throws -> T) throws -> T
    func load() throws -> ProtectionState
    func transaction<T>(_ body: (inout ProtectionState) throws -> T) throws -> T
}

/// Valid only within exclusive's closure. Effects must not reenter storage or
/// wait for another process that needs this lock. The host effects are synchronous.
public final class ProtectionStorageAccess {
    private let reader: () throws -> ProtectionState
    private let writer: (ProtectionState) throws -> Void
    init(reader: @escaping () throws -> ProtectionState,
         writer: @escaping (ProtectionState) throws -> Void) {
        self.reader = reader; self.writer = writer
    }
    public func load() throws -> ProtectionState { try reader() }
    public func save(_ state: ProtectionState) throws { try writer(state) }
}

public enum ProtectionStorageError: Error { case lockFailed, invalidState, syntheticWriteFailure }

/// Supply a dedicated App Group URL at integration time. No global defaults,
/// entitlement, or existing BeforeFeed history is accessed by this prototype.
public final class ProtectionFileStore: ProtectionStorage {
    private let url: URL
    private let initial: ProtectionState
    private let io: ProtectionFileIO

    public init(url: URL, initial: ProtectionState, io: ProtectionFileIO = .system) {
        self.url = url
        self.initial = initial
        self.io = io
    }

    private func locked<T>(_ body: () throws -> T) throws -> T {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let fd = open(url.appendingPathExtension("lock").path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else { throw ProtectionStorageError.lockFailed }
        defer { close(fd) }
        guard flock(fd, LOCK_EX) == 0 else { throw ProtectionStorageError.lockFailed }
        defer { flock(fd, LOCK_UN) }
        return try body()
    }

    private func read() throws -> ProtectionState {
        guard let data = try io.optionalData(at: url) else { return initial }
        do { return try JSONDecoder().decode(ProtectionState.self, from: data) }
        catch { throw ProtectionStorageError.invalidState } // Preserve corrupt bytes for recovery.
    }

    public func exclusive<T>(_ body: (ProtectionStorageAccess) throws -> T) throws -> T {
        try locked {
            try body(ProtectionStorageAccess(reader: { try self.read() }, writer: { state in
                let data = try JSONEncoder().encode(state)
                try self.io.write(data, self.url)
            }))
        }
    }
    public func load() throws -> ProtectionState { try exclusive { try $0.load() } }
    public func transaction<T>(_ body: (inout ProtectionState) throws -> T) throws -> T {
        try exclusive { access in
            var state = try access.load()
            let result = try body(&state)
            try access.save(state)
            return result
        }
    }

}

public final class ProtectionMemoryStore: ProtectionStorage {
    private var state: ProtectionState
    private let lock = NSLock()
    public var failNextWrite = false

    public init(_ state: ProtectionState) { self.state = state }
    public func exclusive<T>(_ body: (ProtectionStorageAccess) throws -> T) throws -> T {
        lock.lock(); defer { lock.unlock() }
        return try body(ProtectionStorageAccess(reader: { self.state }, writer: { candidate in
            if self.failNextWrite {
                self.failNextWrite = false
                throw ProtectionStorageError.syntheticWriteFailure
            }
            self.state = candidate
        }))
    }
    public func load() throws -> ProtectionState { try exclusive { try $0.load() } }
    public func transaction<T>(_ body: (inout ProtectionState) throws -> T) throws -> T {
        try exclusive { access in
            var candidate = try access.load()
            let result = try body(&candidate)
            try access.save(candidate)
            return result
        }
    }
}
