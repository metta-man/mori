import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

public enum ProtectionWriterError: Error { case unavailable, busy }

/// Global lock order: writer coordination, THEN ProtectionStorage.exclusive.
/// All native hosts must use ProtectionCoordinatedStorage. Legacy writers never
/// acquire ProtectionStorage themselves. Nested synchronous effects reuse the
/// already-held coordination lock; no async/detached work is allowed here.
public enum ProtectionWriterCoordination {
    private static let processLock = NSRecursiveLock()
    private static var depths: [String: Int] = [:]
    public static func processOnly<T>(_ body: () throws -> T) rethrows -> T {
        processLock.lock(); defer { processLock.unlock() }
        return try body()
    }
    public static func exclusive<T>(url: URL, _ body: () throws -> T) throws -> T {
        processLock.lock(); defer { processLock.unlock() }
        let path = url.standardizedFileURL.path
        if let depth = depths[path] {
            depths[path] = depth + 1
            defer { depths[path] = depth }
            return try body()
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fd = open(path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else { throw ProtectionWriterError.unavailable }
        defer { close(fd) }
        // No cross-process wait inside a bounded extension callback. Contention
        // returns a retryable failure before mutation, never falls back unlocked.
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw ProtectionWriterError.busy }
        depths[path] = 1
        defer { depths.removeValue(forKey: path); flock(fd, LOCK_UN) }
        return try body()
    }
}
