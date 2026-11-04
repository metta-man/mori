import Foundation

public enum ProtectionRule: String, Codable, Hashable { case morning, bedtime }
public enum MorningTrigger: String, Codable { case fixedTime, firstUse }

public struct LocalProtectionWindow: Codable, Equatable {
    public var startMinute: Int
    public var endMinute: Int

    public init(startMinute: Int, endMinute: Int) {
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    public var isValid: Bool {
        (0..<1440).contains(startMinute) && (0..<1440).contains(endMinute)
            && startMinute != endMinute
    }

    public func containing(_ now: Date, calendar: Calendar) -> (start: Date, end: Date)? {
        guard isValid else { return nil }
        let today = calendar.startOfDay(for: now)
        for day in [today, calendar.date(byAdding: .day, value: -1, to: today)].compactMap({ $0 }) {
            guard let endDay = calendar.date(byAdding: .day,
                value: endMinute < startMinute ? 1 : 0, to: day),
            let start = calendar.nextDate(
                after: day.addingTimeInterval(-1),
                matching: DateComponents(hour: startMinute / 60, minute: startMinute % 60),
                matchingPolicy: .nextTime, repeatedTimePolicy: .first
            ), let end = calendar.nextDate(
                after: endDay.addingTimeInterval(-1),
                matching: DateComponents(hour: endMinute / 60, minute: endMinute % 60),
                matchingPolicy: .nextTime, repeatedTimePolicy: .first
            ), calendar.isDate(start, inSameDayAs: day),
               calendar.isDate(end, inSameDayAs: endDay), end > start
            else { continue } // Skipped endpoints collapsing to one instant create no window.
            if start <= now && now < end { return (start, end) }
        }
        return nil
    }
}

public struct ProtectionConfiguration: Codable, Equatable {
    public var revision: Int
    public var morningEnabled: Bool
    public var morningTrigger: MorningTrigger
    public var morningStartMinute: Int
    public var morningDetectionEndMinute: Int
    public var morningDurationSeconds: Int
    public var bedtimeEnabled: Bool
    public var bedtimeWindow: LocalProtectionWindow?
    /// nil follows the current time zone for future calendar windows.
    public var timeZoneIdentifier: String?

    public init(legacyMorningEnabled: Bool, legacyStartMinute: Int,
                legacyDurationSeconds: Int, timeZoneIdentifier: String? = nil) {
        revision = 1
        morningEnabled = legacyMorningEnabled
        morningTrigger = .fixedTime
        morningStartMinute = min(1439, max(0, legacyStartMinute))
        morningDetectionEndMinute = (morningStartMinute + 300) % 1440
        morningDurationSeconds = min(7200, max(300, legacyDurationSeconds))
        bedtimeEnabled = false
        bedtimeWindow = nil
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    public static var newSetup: Self {
        // No rule is activated by constructing a prototype configuration.
        var value = Self(legacyMorningEnabled: false, legacyStartMinute: 420,
                         legacyDurationSeconds: 1800)
        value.morningTrigger = .firstUse
        return value
    }

    public var calendar: Calendar {
        var value = Calendar.current
        value.timeZone = timeZoneIdentifier.flatMap(TimeZone.init(identifier:))
            ?? TimeZone.current
        return value
    }

    public var detectionWindow: LocalProtectionWindow {
        .init(startMinute: morningStartMinute, endMinute: morningDetectionEndMinute)
    }

    public var isValid: Bool {
        guard (0..<1440).contains(morningStartMinute),
              (300...7200).contains(morningDurationSeconds),
              timeZoneIdentifier.map({ TimeZone(identifier: $0) != nil }) ?? true
        else { return false }
        if morningEnabled && morningTrigger == .firstUse && !detectionWindow.isValid { return false }
        if bedtimeEnabled && bedtimeWindow?.isValid != true { return false }
        return true
    }
}

public struct ProtectionWindow: Codable, Equatable {
    public let id: String
    public let rule: ProtectionRule
    public let start: Date
    public let end: Date
}

public struct ProtectionBreathTicket: Codable, Equatable {
    public let requestID: UUID
    public let revision: Int
    public let flowEpoch: UUID
    public let startedAt: Date
    public let windowIDs: Set<String>
}

public struct ProtectionGrant: Codable, Equatable {
    public let requestID: UUID
    public let confirmedAt: Date
    public let windowEnds: [String: Date]
}

public struct ProtectionState: Codable, Equatable {
    public var configuration: ProtectionConfiguration
    public var activeFirstUseMorning: ProtectionWindow?
    public var lastMorningCycle: String?
    public var nextMorningEligibleAt: Date?
    public var legacyCompletedMorningDay: String?
    public var allowances: [String: Date] = [:]
    public var confirmedGrants: [String: ProtectionGrant] = [:]
    public var grantOrder: [String] = []
    public var flowEpoch = UUID()
    public var clockLedger: ProtectionClockLedger?
    public var effectsRecovery: ProtectionEffectsRecovery?

    public init(configuration: ProtectionConfiguration, legacyCompletedMorningDay: String? = nil) {
        self.configuration = configuration
        self.legacyCompletedMorningDay = legacyCompletedMorningDay
    }
}

/// Process identity only avoids comparing elapsed anchors from different live
/// processes. It is NOT a boot identifier and a handoff is not a recovery fault.
public struct ProtectionClockSample: Equatable {
    public let wall: Date
    public let processID: String
    public let continuousSeconds: TimeInterval
    public let projectedNow: Date?
    public init(wall: Date, processID: String, continuousSeconds: TimeInterval, projectedNow: Date? = nil) {
        self.wall = wall; self.processID = processID; self.continuousSeconds = continuousSeconds; self.projectedNow = projectedNow
    }
    public var isValid: Bool {
        !processID.isEmpty && wall.timeIntervalSince1970.isFinite && continuousSeconds.isFinite && continuousSeconds >= 0
            && (projectedNow?.timeIntervalSince1970.isFinite ?? true)
    }
}
public struct ProtectionClockLedger: Codable, Equatable {
    public var processID: String
    public var continuousSeconds: TimeInterval
    public var logicalNow: Date
    /// An inconsistency marker, not a handoff/reboot countdown or budget.
    public var recoveryEndsAt: Date?
    public var recoveryWindowIDs: Set<String>
    public var retiredWindowIDs: Set<String>
    public var recoveryReason: String? = nil
    private enum CodingKeys: String, CodingKey {
        case processID, continuousSeconds, logicalNow, recoveryEndsAt, recoveryWindowIDs, retiredWindowIDs, recoveryReason
        case legacyBootID = "bootID"
    }
    public init(processID: String, continuousSeconds: TimeInterval, logicalNow: Date,
                recoveryEndsAt: Date?, recoveryWindowIDs: Set<String>, retiredWindowIDs: Set<String>) {
        self.processID = processID; self.continuousSeconds = continuousSeconds; self.logicalNow = logicalNow
        self.recoveryEndsAt = recoveryEndsAt; self.recoveryWindowIDs = recoveryWindowIDs; self.retiredWindowIDs = retiredWindowIDs
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        processID = try c.decodeIfPresent(String.self, forKey: .processID) ?? "legacy-process-unknown"
        continuousSeconds = try c.decode(TimeInterval.self, forKey: .continuousSeconds)
        logicalNow = try c.decode(Date.self, forKey: .logicalNow)
        recoveryEndsAt = try c.decodeIfPresent(Date.self, forKey: .recoveryEndsAt)
        recoveryWindowIDs = try c.decodeIfPresent(Set<String>.self, forKey: .recoveryWindowIDs) ?? []
        retiredWindowIDs = try c.decodeIfPresent(Set<String>.self, forKey: .retiredWindowIDs) ?? []
        recoveryReason = try c.decodeIfPresent(String.self, forKey: .recoveryReason)
        if c.contains(.legacyBootID), recoveryEndsAt != nil {
            retiredWindowIDs.formUnion(recoveryWindowIDs); recoveryReason = "Retired legacy uncertain-clock scopes"
        }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(processID, forKey: .processID); try c.encode(continuousSeconds, forKey: .continuousSeconds)
        try c.encode(logicalNow, forKey: .logicalNow); try c.encodeIfPresent(recoveryEndsAt, forKey: .recoveryEndsAt)
        try c.encode(recoveryWindowIDs, forKey: .recoveryWindowIDs); try c.encode(retiredWindowIDs, forKey: .retiredWindowIDs)
        try c.encodeIfPresent(recoveryReason, forKey: .recoveryReason)
    }
}

/// Persisted before external effects; an interrupted operation is reconciled, never
/// reported as enforced. ManagedSettings and DeviceActivity are not atomic together.
public struct ProtectionEffectsRecovery: Codable, Equatable {
    public var lastAppliedRules: Set<ProtectionRule>
    public var lastAppliedWindowIDs: Set<String>
    public var pending: Bool
}

public struct ProtectionPlan: Equatable {
    public let activeWindows: [ProtectionWindow]
    public let shieldedRules: Set<ProtectionRule>
    public let nextReconciliationAt: Date?
    /// A persisted elapsed deadline; it does not assert an OS callback arrived.
    public var morningEndsAt: Date? { activeWindows.first { $0.rule == .morning }?.end }
}
