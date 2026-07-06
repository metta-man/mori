import Foundation
import FamilyControls

enum AttentionShieldAuthorizationPolicy {
    static func canApplyShield(for status: AuthorizationStatus) -> Bool {
        if status == .approved {
            return true
        }
        return hasFamilyActivityDataAccess(for: status)
    }

    static func canDisplaySelectionNames(for status: AuthorizationStatus) -> Bool {
        hasFamilyActivityDataAccess(for: status)
    }

    static func hasFamilyActivityDataAccess(for status: AuthorizationStatus) -> Bool {
        if #available(iOS 26.4, *), status == .approvedWithDataAccess {
            return true
        }
        return false
    }
}
