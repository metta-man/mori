import Foundation

public enum ProtectionOwnershipTransition {
    /// Persisted configuration/native contribution must be acknowledged before
    /// retiring the legacy morning schedule. The retained owner marker prevents
    /// legacy whole-window completion/reapplication after voluntary native expiry.
    public static func takeOwnership(acknowledged: Bool,
        recordOwner: () throws -> Void, retireLegacyMorning: () throws -> Void,
        recomposeIndependent: () throws -> Void) throws -> Bool {
        guard acknowledged else { return false }
        try recordOwner()
        try retireLegacyMorning()
        try recomposeIndependent()
        return true
    }
}
