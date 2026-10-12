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
        // Failure performs no write. Native eligibility remains disabled; legacy
        // void APIs require acknowledgement propagation before final activation.
        do { return try exclusive(body) }
        catch ProtectionWriterError.unavailable where !nativeEligibilityReviewed {
            // Preserve existing injected/local-default legacy behavior when no
            // App Group exists. Native activation is impossible in this mode.
            return ProtectionWriterCoordination.processOnly(body)
        } catch { return fallback }
    }
}
