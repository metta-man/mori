#if os(iOS)
import Foundation
import Darwin
import DeviceActivity
import FamilyControls
import ManagedSettings

/// Public continuous-time conversion and process-local session anchors only.
struct MoriProtectionNativeClock {
    private static let live = ProtectionLiveProcessClock()
    static var isAvailable: Bool {
        let seconds = continuousSeconds()
        return seconds.isFinite && seconds >= 0 && Date().timeIntervalSince1970.isFinite
    }
    func sample() throws -> ProtectionClockSample { try sample(state: nil) }
    func sample(state: ProtectionState?) throws -> ProtectionClockSample {
        let value = Self.live.sample(wall: Date(), continuous: Self.continuousSeconds(), state: state)
        guard value.isValid else { throw ProtectionHostError.unsupportedClock }
        return value
    }
    static func continuousSeconds() -> Double {
        var info = mach_timebase_info_data_t()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return .nan }
        return Double(mach_continuous_time()) * Double(info.numer) / Double(info.denom) / 1_000_000_000
    }
}

/// Implemented native boundary for review only. Not constructed by shipping flows.
/// Named-store union preserves BeforeFeed/focus/PIN in the existing default store.
/// Integration still needs shared coordination of all existing selection writers.
final class MoriProtectionNativeDriver: ProtectionHostDriver {
    private let center = DeviceActivityCenter()
    private let contribution = ManagedSettingsStore(named: .init("mori.scheduled-protection"))
    private let selectedApps: () -> FamilyActivitySelection
    private let independent: () -> Bool
    private var revision: Int
    private var expiryName: DeviceActivityName?
    private let callbackName: DeviceActivityName?
    init(revision: Int, callbackName: DeviceActivityName? = nil,
         selectedApps: @escaping () -> FamilyActivitySelection,
         independent: @escaping () -> Bool) {
        self.revision = revision; self.callbackName = callbackName; self.selectedApps = selectedApps; self.independent = independent
    }
    func registerCalendar(_ configuration: ProtectionConfiguration) throws {
        guard MoriProtectionIntegration.isEligible else { throw ProtectionHostError.unsupportedClock }
        return try MoriShieldCoordination.exclusive {

        let registrations = try ProtectionRegistration.calendars(configuration)
        let desired = Set(registrations.map { DeviceActivityName($0.name) })
        for registration in registrations {
            try center.startMonitoring(DeviceActivityName(registration.name), during: .init(
                intervalStart: DateComponents(hour: registration.startMinute / 60, minute: registration.startMinute % 60),
                intervalEnd: DateComponents(hour: registration.endMinute / 60, minute: registration.endMinute % 60),
                repeats: true))
        }
        // Retire old revisions only after successful replacement. Never stop the
        // schedule whose callback is currently executing.
        let obsolete = center.activities.filter {
            $0.rawValue.hasPrefix("mori.protection.") && !$0.rawValue.contains(".expiry.")
                && !desired.contains($0) && $0 != callbackName
        }
        center.stopMonitoring(obsolete)
        revision = configuration.revision

        }
    }
    func scheduleReconciliation(at deadline: Date?) throws {
        guard MoriProtectionIntegration.isEligible else { throw ProtectionHostError.unsupportedClock }
        return try MoriShieldCoordination.exclusive {

        guard let deadline else {
            center.stopMonitoring(center.activities.filter {
                $0.rawValue.hasPrefix("mori.protection.expiry.") && $0 != callbackName
            })
            return
        }
        // A separate rendezvous starts AT the projected expiry, with a supported
        // 15-minute repeating interval. Callback timing remains system-controlled.
        let name = DeviceActivityName("mori.protection.expiry.r\(revision).\(Int(deadline.timeIntervalSince1970))")
        if name == callbackName { return }
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.hour, .minute, .second]
        try center.startMonitoring(name, during: .init(
            intervalStart: calendar.dateComponents(components, from: max(Date().addingTimeInterval(1), deadline)),
            intervalEnd: calendar.dateComponents(components, from: max(Date().addingTimeInterval(1), deadline).addingTimeInterval(900)),
            repeats: true))
        center.stopMonitoring(center.activities.filter {
            $0.rawValue.hasPrefix("mori.protection.expiry.") && $0 != name && $0 != callbackName
        })
        expiryName = name

        }
    }
    func applyScheduledContribution(_ rules: Set<ProtectionRule>) throws {
        if rules.isEmpty { try Self.removeOwnedContribution(); return }
        guard MoriProtectionIntegration.isEligible else { throw ProtectionHostError.unsupportedClock }
        return try MoriShieldCoordination.exclusive {

        let authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        let selection = selectedApps() // Freshly refresh selection at actual write.
        let enabled = authorized && !rules.isEmpty
        contribution.shield.applications = enabled && !selection.applicationTokens.isEmpty ? selection.applicationTokens : nil
        contribution.shield.webDomains = enabled && !selection.webDomainTokens.isEmpty ? selection.webDomainTokens : nil
        // Never broaden distractor scope to categories/all apps; never clear another store.
        contribution.shield.applicationCategories = nil
        contribution.shield.webDomainCategories = nil
        if #available(iOS 26.5, *) { contribution.isActive = true }
        guard rules.isEmpty || (authorized && (!selection.applicationTokens.isEmpty || !selection.webDomainTokens.isEmpty)) else {
            throw ProtectionHostError.independentRestriction
        }

        }
    }
    static func removeOwnedContribution() throws {
        try MoriShieldCoordination.exclusive {
            let owned = ManagedSettingsStore(named: .init("mori.scheduled-protection"))
            owned.shield.applications = nil; owned.shield.webDomains = nil
            owned.shield.applicationCategories = nil; owned.shield.webDomainCategories = nil
            if #available(iOS 26.5, *) { owned.isActive = false }
        }
    }
    func recordRecovery(reason: String) throws {
        try MoriShieldCoordination.exclusive {
            guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier) else { throw ProtectionWriterError.unavailable }
            let directory = group.appendingPathComponent("ScheduledProtection")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("recovery-v1.json")
            struct Entry: Codable { let at: Date; let reason: String }
            let previous = try ProtectionFileIO.system.optionalData(at: url)
            var entries = try previous.map { try JSONDecoder().decode([Entry].self, from: $0) } ?? []
            if entries.last?.reason != reason { entries.append(.init(at: Date(), reason: reason)) }
            try JSONEncoder().encode(Array(entries.suffix(32))).write(to: url, options: .atomic)
        }
    }
    func independentlyRestricted() -> Bool {
        MoriShieldCoordination.legacy(fallback: true) { independent() }
    }
}
#endif

#if os(iOS)
/// Read-only import; never rewrites legacy defaults or existing BeforeFeed history.
/// Call before legacy normalization if distinguishing a genuinely new setup.
enum MoriProtectionMigration {
    static func state(defaults: UserDefaults) -> ProtectionState {
        guard defaults.object(forKey: MoriScreenTimeShared.morningGateEnabledKey) != nil else {
            return .init(configuration: .newSetup)
        }
        let hour = defaults.object(forKey: MoriScreenTimeShared.morningGateStartHourKey) == nil
            ? MoriScreenTimeShared.defaultMorningGateStartHour : defaults.integer(forKey: MoriScreenTimeShared.morningGateStartHourKey)
        let minute = defaults.object(forKey: MoriScreenTimeShared.morningGateStartMinuteKey) == nil
            ? MoriScreenTimeShared.defaultMorningGateStartMinute : defaults.integer(forKey: MoriScreenTimeShared.morningGateStartMinuteKey)
        let duration = defaults.object(forKey: MoriScreenTimeShared.morningGateDurationSecondsKey) == nil
            ? MoriScreenTimeShared.defaultMorningGateDurationSeconds : defaults.integer(forKey: MoriScreenTimeShared.morningGateDurationSecondsKey)
        return .init(configuration: .init(legacyMorningEnabled: defaults.bool(forKey: MoriScreenTimeShared.morningGateEnabledKey),
            legacyStartMinute: min(23, max(0, hour)) * 60 + min(59, max(0, minute)), legacyDurationSeconds: duration),
            legacyCompletedMorningDay: defaults.string(forKey: MoriScreenTimeShared.morningGateCompletedDateKey))
    }
    static func store() throws -> ProtectionFileStore {
        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier) else {
            throw ProtectionStorageError.lockFailed // No fallback to unrelated storage.
        }
        return .init(url: group.appendingPathComponent("ScheduledProtection/state-v1.json"),
                     initial: state(defaults: MoriAppGroup.defaults))
    }
}
#endif
