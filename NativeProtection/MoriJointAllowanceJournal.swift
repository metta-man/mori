#if os(iOS)
import Foundation

final class MoriJointAllowanceJournal: ProtectionAllowanceJournal {
    private let journal: ProtectionFileAllowanceJournal
    init(request: MoriBeforeFeedAllowanceRequest) throws {
        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier) else { throw ProtectionWriterError.unavailable }
        let store = BeforeFeedGateStore()
        journal = .init(url: group.appendingPathComponent("ScheduledProtection/joint-allowance-v1.json"),
            eventID: request.eventID, generation: request.historyGeneration,
            end: request.now.addingTimeInterval(Double(store.resolvedGraceWindowSeconds(override: request.openWindowSeconds))),
            receiptExisted: { try store.jointReceiptExistsChecked(eventID: request.eventID) })
    }
    func prepare(_ baseline: ProtectionGrantBaseline) throws { try journal.prepare(baseline) }
    func acknowledge() throws { try journal.acknowledge() }
    func finishCompensation() throws { try journal.finishCompensation() }
    func compensatePartner(repair: () throws -> Void) throws {
        let record = try journal.record()
        if !record.beforeFeedReceiptExisted {
            try BeforeFeedGateStore().revokeJointAllowance(eventID: record.eventID, historyGeneration: record.historyGeneration, expectedEnd: record.expectedEnd)
        }
        try repair()
    }
    static func recover(host: ProtectionHost, authorized: Bool, repairBeforeFeed: () throws -> Void) throws {
        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier) else { throw ProtectionWriterError.unavailable }
        let url = group.appendingPathComponent("ScheduledProtection/joint-allowance-v1.json")
        try ProtectionFileAllowanceJournal.recover(at: url) { record in
            try ProtectionAllowanceRecovery.recover(record.baseline, partnerReceiptExisted: record.beforeFeedReceiptExisted,
                removeNewPartnerAllowance: {
                    try BeforeFeedGateStore().revokeJointAllowance(eventID: record.eventID, historyGeneration: record.historyGeneration, expectedEnd: record.expectedEnd)
                }, repairPartner: repairBeforeFeed,
                compensateScheduled: { try host.compensateGrant($0, authorized: authorized) })
        }
    }
}
final class MoriJointAllowancePartner: ProtectionAllowancePartner {
    let commitBody: () throws -> Void
    let openBody: () -> Bool
    let compensateBody: () throws -> Void
    init(commit: @escaping () throws -> Void, open: @escaping () -> Bool, compensate: @escaping () throws -> Void) {
        commitBody = commit; openBody = open; compensateBody = compensate
    }
    func commit() throws { try commitBody() }
    func accessIsOpen() -> Bool { openBody() }
    func compensate() throws { try compensateBody() }
}
#endif
