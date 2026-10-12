import Foundation

/// Cleanup-only compatibility for the former DEBUG trial. There is no activation
/// API, permission request, production preference writer or default store here.
enum MoriLegacyTrialRecovery {
    static let namespace = "mori.debug.device-trial."
    static let maximumRuns = 8

    enum Outcome: Equatable {
        case acknowledged
        case noKnownOwnership
        case pending
    }

    struct Effects {
        var activities: () -> [String]
        var stop: ([String]) -> Void
        /// Called only with namespace + a validated UUID. Returns OS readback.
        var clearStore: (String) throws -> Bool
    }

    private struct LeaseIdentity: Decodable {
        let id: UUID
        let armed: Bool
    }
    private enum Failure: Error { case unknownPath }

    /// Matches only the exact calendar/expiry grammar written by the old trial.
    static func runID(_ name: String) -> UUID? {
        guard name.hasPrefix(namespace) else { return nil }
        let parts = String(name.dropFirst(namespace.count)).split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 || parts.count == 4,
              let id = UUID(uuidString: String(parts[0])),
              id.uuidString.lowercased() == parts[0].lowercased(),
              parts[2].first == "r" else { return nil }
        let revision = String(parts[2].dropFirst())
        guard let number = Int(revision), number >= 0, String(number) == revision else { return nil }
        if parts.count == 3, parts[1] == "morning" || parts[1] == "bedtime" { return id }
        if parts.count == 4, parts[1] == "expiry",
           let end = Int64(parts[3]), String(end) == parts[3] { return id }
        return nil
    }

    static func recover(root: URL, effects: Effects) -> Outcome {
        do {
            return try coordinated(root: root) {
                var ids = Set<UUID>()
                var unknown = false
                for name in effects.activities() where name.hasPrefix(namespace) {
                    if let id = runID(name) { ids.insert(id) } else { unknown = true }
                }
                do {
                    if let data = try optionalRegularFile(root.appendingPathComponent("lease-v1.json")) {
                        ids.insert(try JSONDecoder().decode(LeaseIdentity.self, from: data).id)
                    }
                } catch { unknown = true } // Preserve corrupt/inaccessible lease bytes.
                let runs = root.appendingPathComponent("runs", isDirectory: true)
                if try directory(runs, create: false) {
                    let children = try FileManager.default.contentsOfDirectory(at: runs, includingPropertiesForKeys: nil)
                    guard children.count <= maximumRuns else { return .pending }
                    for child in children {
                        if let id = UUID(uuidString: child.lastPathComponent),
                           id.uuidString.lowercased() == child.lastPathComponent,
                           try directory(child, create: false) { ids.insert(id) }
                        else { unknown = true }
                    }
                }
                guard ids.count <= maximumRuns else { return .pending }
                guard !ids.isEmpty else { return unknown ? .pending : .noKnownOwnership }
                var complete = !unknown
                for id in ids {
                    if !cleanup(id, root: root, effects: effects, callbackName: nil) { complete = false }
                }
                // A malformed namespace name is never stopped or called clear.
                if effects.activities().contains(where: { $0.hasPrefix(namespace) }) { complete = false }
                return complete ? .acknowledged : .pending
            }
        } catch { return .pending }
    }

    /// A delivered old callback proves only its own UUID. Never re-arm it or
    /// touch another run. Leave the currently executing schedule for the explicit
    /// recovery action; any remaining schedule means pending, not acknowledged.
    static func recoverCallback(_ name: String, root: URL, effects: Effects) -> Outcome {
        guard let id = runID(name) else { return .pending }
        do {
            return try coordinated(root: root) {
                cleanup(id, root: root, effects: effects, callbackName: name) ? .acknowledged : .pending
            }
        } catch { return .pending }
    }

    private static func cleanup(_ id: UUID, root: URL, effects: Effects, callbackName: String?) -> Bool {
        do {
            let runs = root.appendingPathComponent("runs", isDirectory: true)
            _ = try directory(runs, create: true)
            let run = runs.appendingPathComponent(id.uuidString.lowercased(), isDirectory: true)
            _ = try directory(run, create: true)
            let marker = run.appendingPathComponent("OFF-v1")
            // Old requireArmed rejects any existing regular OFF marker. Preserve
            // its bytes if already present; do not rewrite lease/state/history.
            if try optionalRegularFile(marker) == nil { try Data("OFF".utf8).write(to: marker, options: .atomic) }
            let names = effects.activities().filter { runID($0) == id && $0 != callbackName }
            if !names.isEmpty { effects.stop(names) }
            let cleared = try effects.clearStore(namespace + id.uuidString.lowercased())
            return cleared && !effects.activities().contains(where: { runID($0) == id })
        } catch { return false } // No OS mutation until the OFF marker is durable.
    }

    private static func coordinated<T>(root: URL, _ body: () throws -> T) throws -> T {
        _ = try directory(root, create: true)
        let lock = root.appendingPathComponent("writers.lock")
        _ = try optionalRegularFile(lock)
        return try ProtectionWriterCoordination.exclusive(url: lock, body)
    }

    /// Refuse symlinks and non-directory paths before creating any child/marker.
    private static func directory(_ url: URL, create: Bool) throws -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard attributes[.type] as? FileAttributeType == .typeDirectory else { throw Failure.unknownPath }
            return true
        } catch where ProtectionFileIO.isNotFound(error) {
            guard create else { return false }
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
            return true
        }
    }

    private static func optionalRegularFile(_ url: URL) throws -> Data? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard attributes[.type] as? FileAttributeType == .typeRegular,
                  ((attributes[.size] as? NSNumber)?.intValue ?? Int.max) <= 262_144 else { throw Failure.unknownPath }
            return try Data(contentsOf: url)
        } catch where ProtectionFileIO.isNotFound(error) { return nil }
    }
}
