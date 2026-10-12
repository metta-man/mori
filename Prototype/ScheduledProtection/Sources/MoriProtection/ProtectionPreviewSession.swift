import Foundation

/// Complete preview boundary. Storage, partner, journal and effects are owned
/// memory values; callers cannot substitute a production driver or file store.
public final class ProtectionPreviewSession {
    private final class Effects: ProtectionHostDriver {
        var rules: Set<ProtectionRule> = []
        func registerCalendar(_ configuration: ProtectionConfiguration) throws { _ = try ProtectionRegistration.calendars(configuration) }
        func scheduleReconciliation(at: Date?) throws {}
        func applyScheduledContribution(_ rules: Set<ProtectionRule>) throws { self.rules = rules }
        func independentlyRestricted() -> Bool { false }
    }
    private final class Participant: ProtectionAllowancePartner {
        var hasAllowance = false
        func commit() throws { hasAllowance = true }
        func accessIsOpen() -> Bool { hasAllowance }
        func compensate() throws { hasAllowance = false }
    }
    private final class Journal: ProtectionAllowanceJournal {
        var pending = false
        func prepare(_ baseline: ProtectionGrantBaseline) throws { pending = true }
        func acknowledge() throws {}
        func finishCompensation() throws { pending = false }
    }
    private let effects = Effects()
    private let participant = Participant()
    private let journal = Journal()
    private let storage: ProtectionMemoryStore
    private let host: ProtectionHost
    private var ticket: ProtectionBreathTicket?
    public init(now: Date = Date(), clock: (() -> ProtectionClockSample)? = nil) {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.hour, .minute], from: now)
        var configuration = ProtectionConfiguration(legacyMorningEnabled: true,
            legacyStartMinute: (components.hour ?? 0) * 60 + (components.minute ?? 0), legacyDurationSeconds: 1800)
        configuration.timeZoneIdentifier = "UTC"
        storage = ProtectionMemoryStore(.init(configuration: configuration))
        host = ProtectionHost(storage: storage, driver: effects, clock: clock ?? {
            .init(wall: Date(), processID: "memory-preview", continuousSeconds: ProcessInfo.processInfo.systemUptime)
        })
        _ = host.reconcile(authorized: true)
    }
    @discardableResult public func start() -> Bool {
        if ticket != nil { return true }
        ticket = try? host.beginBreathing()
        return ticket != nil
    }
    public func cancel() {
        if let ticket { try? host.cancel(ticket) }
        ticket = nil
    }
    @discardableResult public func confirm(completed: Bool, seconds: Int = 120) -> Bool {
        guard let ticket else { return false }
        let opened = ProtectionJointAllowance.confirm(host: host, ticket: ticket, completed: completed,
            seconds: seconds, authorized: true, partner: participant, journal: journal)
        if opened || !completed { self.ticket = nil }
        return opened
    }
    public var previewAllowanceIsOpen: Bool { participant.hasAllowance }
    public var previewRules: Set<ProtectionRule> { effects.rules }
    public func snapshot() throws -> ProtectionState { try storage.load() }
}
