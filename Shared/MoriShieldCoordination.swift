import Foundation

/// Shared by app, monitor, shield action and selection persistence.
/// This coordination file is distinct from scheduled state and history files.
enum MoriShieldCoordination {
    static let nativeEligibilityReviewed = false
    static let morningOwnerKey = "mori_morning_gate_scheduled_owner_v1"
    static var scheduledOwnsMorning: Bool {
        guard nativeEligibilityReviewed else { return false }
        do {
            guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier),
                  let preferences = MoriAppGroup.defaults as? MoriCoordinatedPreferences else { return true }
            let marker = group.appendingPathComponent("ScheduledProtection/native-owner-v1")
            if try ProtectionFileIO.system.optionalData(at: marker) != nil { return true }
            return try ProtectionCheckedInputReader(read: preferences.objectChecked(forKey:))
                .boolean(morningOwnerKey, default: false)
        } catch {
            // Unknown ownership suppresses legacy resurrection; it is not an
            // assertion that the native contribution is currently enforced.
            return true
        }
    }
    static func url() throws -> URL {
        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier) else {
            throw ProtectionWriterError.unavailable
        }
        return group.appendingPathComponent("ScheduledProtection/writers.lock")
    }
    static func exclusive<T>(_ body: () throws -> T) throws -> T {
        try ProtectionWriterCoordination.exclusive(url: url(), body)
    }
    static func legacy<T>(fallback: T, _ body: () -> T) -> T {
        // Do not impose a fallible experimental file lock on shipping callbacks.
        // Keep this gate paired with MoriAppGroup's preference-store selection.
        guard nativeEligibilityReviewed else {
            return ProtectionWriterCoordination.processOnly(body)
        }
        // Native activation still requires acknowledgement/retry propagation.
        do { return try exclusive(body) }
        catch { return fallback }
    }
}
