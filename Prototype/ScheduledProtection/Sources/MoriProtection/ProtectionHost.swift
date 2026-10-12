import Foundation

public enum ProtectionHostError: Error { case unsupportedClock, invalidConfiguration, staleCallback, independentRestriction, registrationFailed }

/// Host boundary uses the SAME storage coordination as the cleared runtime.
/// Drivers are synchronous and must neither reenter storage nor detach work.
public protocol ProtectionHostDriver: ProtectionRuntimeEffects {
    func registerCalendar(_ configuration: ProtectionConfiguration) throws
    func independentlyRestricted() -> Bool
}

public final class ProtectionHost {
    private let storage: any ProtectionStorage
    private let driver: any ProtectionHostDriver
    private let clock: (ProtectionState) throws -> ProtectionClockSample
    public init(storage: any ProtectionStorage, driver: any ProtectionHostDriver,
                clock: @escaping () throws -> ProtectionClockSample) {
        self.storage = storage; self.driver = driver; self.clock = { _ in try clock() }
    }
    public init(storage: any ProtectionStorage, driver: any ProtectionHostDriver,
                clockWithState: @escaping (ProtectionState) throws -> ProtectionClockSample) {
        self.storage = storage; self.driver = driver; self.clock = clockWithState
    }
    private var runtime: ProtectionRuntime {
        ProtectionRuntime(storage: storage, effects: driver, clockWithState: { state in
            // Never fabricate boot identity. The core rejects an invalid sample.
            (try? self.clock(state)) ?? .init(wall: Date(), processID: "", continuousSeconds: .nan)
        })
    }
    public func configure(_ configuration: ProtectionConfiguration) throws {
        guard configuration.isValid else { throw ProtectionHostError.invalidConfiguration }
        _ = try ProtectionRegistration.calendars(configuration)
        try storage.exclusive { access in
            var state = try access.load()
            guard ProtectionEngine.advanceClock(state: &state, sample: try clock(state)) != nil else {
                throw ProtectionHostError.unsupportedClock
            }
            _ = ProtectionEngine.updateConfiguration(state: &state, to: configuration)
            state.effectsRecovery = .init(lastAppliedRules: state.effectsRecovery?.lastAppliedRules ?? [],
                lastAppliedWindowIDs: state.effectsRecovery?.lastAppliedWindowIDs ?? [], pending: true)
            // Persist revision BEFORE registration; stale callbacks cannot act on it.
            try access.save(state)
            try driver.registerCalendar(state.configuration)
        }
    }
    public func reconcile(_ callback: ProtectionCallback = .foregroundReconcile,
                          authorized: Bool) -> ProtectionRuntimeOutcome {
        runtime.callback(callback, at: Date(), authorizedWithSelection: authorized)
    }
    public func beginBreathing() throws -> ProtectionBreathTicket? {
        try storage.exclusive { access in
            var state = try access.load()
            guard let now = ProtectionEngine.advanceClock(state: &state, sample: try clock(state)) else {
                throw ProtectionHostError.unsupportedClock
            }
            ProtectionEngine.reconcile(state: &state, at: now)
            let ticket = ProtectionEngine.beginBreathing(state, at: now)
            try access.save(state)
            return ticket
        }
    }
    public func cancel(_ ticket: ProtectionBreathTicket) throws {
        try storage.transaction { state in
            // Abandoned older sheet must not invalidate a newer sheet's ticket.
            guard state.flowEpoch == ticket.flowEpoch else { return }
            ProtectionEngine.cancelBreathing(state: &state)
        }
    }
    public func confirm(_ ticket: ProtectionBreathTicket, completed: Bool,
                        allowanceSeconds: Int, authorized: Bool) -> ProtectionRuntimeOutcome {
        runtime.finishBreathing(ticket, completed: completed, allowanceSeconds: allowanceSeconds,
                                at: Date(), authorizedWithSelection: authorized)
    }
    public func grantBaseline(_ ticket: ProtectionBreathTicket) throws -> ProtectionGrantBaseline {
        .init(state: try storage.load(), requestID: ticket.requestID)
    }
    /// Remove only a newly-created receipt/deadline. Never rewind the clock,
    /// configuration, recovery, another grant, or completed historical receipt.
    public func compensateGrant(_ baseline: ProtectionGrantBaseline, authorized: Bool) throws {
        try storage.exclusive { access in
            var state = try access.load()
            guard let now = ProtectionEngine.advanceClock(state: &state, sample: try clock(state)) else {
                throw ProtectionHostError.unsupportedClock
            }
            let key = baseline.requestID.uuidString
            if baseline.state.confirmedGrants[key] == nil, let grant = state.confirmedGrants[key] {
                for (id, end) in grant.windowEnds where state.allowances[id] == end {
                    if state.clockLedger?.recoveryEndsAt == nil,
                       let old = baseline.state.allowances[id], old > now { state.allowances[id] = old }
                    else { state.allowances.removeValue(forKey: id) }
                }
                state.confirmedGrants.removeValue(forKey: key)
                state.grantOrder.removeAll { $0 == key }
                // Failed confirmed operation cannot reuse its old flow ticket.
                state.flowEpoch = UUID()
                state.effectsRecovery = baseline.state.effectsRecovery.map {
                    .init(lastAppliedRules: $0.lastAppliedRules, lastAppliedWindowIDs: $0.lastAppliedWindowIDs, pending: true)
                }
            }
            ProtectionEngine.reconcile(state: &state, at: now)
            try access.save(state)
        }
        guard reconcile(authorized: authorized).effectsApplied else { throw ProtectionHostError.registrationFailed }
    }
    public func accessIsOpen(_ outcome: ProtectionRuntimeOutcome, ticket: ProtectionBreathTicket) -> Bool {
        guard outcome.effectsApplied, outcome.grant != nil else { return false }
        // Historical grant alone is insufficient. Read fresh clock/state under lock.
        return (try? storage.exclusive { access in
            var state = try access.load()
            guard let now = ProtectionEngine.advanceClock(state: &state, sample: try clock(state)) else { return false }
            ProtectionEngine.reconcile(state: &state, at: now)
            try access.save(state)
            let plan = ProtectionEngine.plan(state, at: now)
            let captured = plan.activeWindows.filter { ticket.windowIDs.contains($0.id) }
            return !captured.isEmpty && plan.shieldedRules.isEmpty
                && !driver.independentlyRestricted()
        }) ?? false
    }
}

/// Pure native registration contract, including minimum 15-minute intervals.
public struct ProtectionRegistration: Equatable {
    public let name: String
    public let startMinute: Int
    public let endMinute: Int
    public static func calendars(_ config: ProtectionConfiguration) throws -> [Self] {
        guard config.isValid else { throw ProtectionHostError.invalidConfiguration }
        var result: [Self] = []
        if config.morningEnabled {
            let end = config.morningTrigger == .firstUse ? config.morningDetectionEndMinute
                : (config.morningStartMinute + config.morningDurationSeconds / 60) % 1440
            result.append(.init(name: "mori.protection.morning.r\(config.revision)",
                                startMinute: config.morningStartMinute, endMinute: end))
        }
        if config.bedtimeEnabled, let window = config.bedtimeWindow {
            result.append(.init(name: "mori.protection.bedtime.r\(config.revision)",
                                startMinute: window.startMinute, endMinute: window.endMinute))
        }
        // Pad only the OS monitoring envelope. Core protection/allowance ends
        // stay at the original 5-minute (or other short) absolute deadline.
        return result.map { registration in
            let minutes = (registration.endMinute - registration.startMinute + 1440) % 1440
            return minutes >= 15 ? registration : .init(name: registration.name,
                startMinute: registration.startMinute, endMinute: (registration.startMinute + 15) % 1440)
        }
    }
    public static func delivered(_ name: String, configuration: ProtectionConfiguration,
                                 intervalStarted: Bool) throws -> ProtectionCallback {
        guard try calendars(configuration).contains(where: { $0.name == name }) else {
            throw ProtectionHostError.staleCallback
        }
        if intervalStarted && name.contains(".morning.") && configuration.morningTrigger == .firstUse {
            return .morningFirstUse(scheduledRevision: configuration.revision)
        }
        return .calendarBoundary
    }
}
