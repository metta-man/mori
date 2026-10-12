import Foundation

public struct ProtectionGrantBaseline: Codable {
    public let state: ProtectionState
    public let requestID: UUID
}

/// Partner records intent/grace, applies ONLY its own contribution, and exposes
/// a fresh acknowledgement. Never touches another contribution or old history.
public protocol ProtectionAllowancePartner {
    func commit() throws
    func accessIsOpen() -> Bool
    func compensate() throws
}
public protocol ProtectionAllowanceJournal {
    func prepare(_ baseline: ProtectionGrantBaseline) throws
    func acknowledge() throws
    func finishCompensation() throws
}

public enum ProtectionJointAllowance {
    /// Caller holds the shared writer envelope for the entire operation. Native
    /// journal persists before either participant mutates; pending recovery is
    /// compensated before further access is offered after interruption.
    public static func confirm(host: ProtectionHost, ticket: ProtectionBreathTicket,
        completed: Bool, seconds: Int, authorized: Bool,
        partner: any ProtectionAllowancePartner, journal: any ProtectionAllowanceJournal) -> Bool {
        guard completed && authorized else { try? host.cancel(ticket); return false }
        do {
            let baseline = try host.grantBaseline(ticket)
            try journal.prepare(baseline)
            let outcome = host.confirm(ticket, completed: true, allowanceSeconds: seconds, authorized: authorized)
            guard outcome.effectsApplied, outcome.grant != nil else {
                try host.compensateGrant(baseline, authorized: authorized)
                try journal.finishCompensation()
                return false
            }
            do {
                try partner.commit()
                guard partner.accessIsOpen(), host.accessIsOpen(outcome, ticket: ticket) else {
                    throw ProtectionHostError.independentRestriction
                }
                try journal.acknowledge()
                guard partner.accessIsOpen(), host.accessIsOpen(outcome, ticket: ticket) else {
                    throw ProtectionHostError.independentRestriction
                }
                try journal.finishCompensation()
                return true
            } catch {
                // The journal remains pending if either compensation fails.
                try partner.compensate()
                try host.compensateGrant(baseline, authorized: authorized)
                try journal.finishCompensation()
                return false
            }
        } catch { return false }
    }
}

/// Every retained journal is unfinished. An acknowledgement marker alone never
/// licenses deleting it after a failed fresh-access check or failed compensation.
public enum ProtectionAllowanceRecovery {
    public static func recover(_ baseline: ProtectionGrantBaseline, partnerReceiptExisted: Bool,
        removeNewPartnerAllowance: () throws -> Void, repairPartner: () throws -> Void,
        compensateScheduled: (ProtectionGrantBaseline) throws -> Void) throws {
        if !partnerReceiptExisted { try removeNewPartnerAllowance() }
        try repairPartner()
        try compensateScheduled(baseline)
    }
}
