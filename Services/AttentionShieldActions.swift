import Foundation
import FamilyControls

struct AttentionShieldSettingsSnapshot {
    let authorizationStatus: AuthorizationStatus
    let isAuthorized: Bool
    let defaultSelectedCount: Int
    let profileSummaries: [MoriScreenTimeProfileSummary]
    let lastErrorMessage: String?
    let dailyThresholdMinutes: Int
}

extension AttentionShieldSettingsSnapshot {
    func profileSummary(for feature: MoriScreenTimeFeature) -> MoriScreenTimeProfileSummary {
        profileSummaries.first { $0.feature == feature } ?? MoriScreenTimeProfileSummary(
            feature: feature,
            isEnabled: false,
            usesDefaultSelection: false,
            customSelectedCount: 0,
            effectiveSelectedCount: 0,
            displayNames: [],
            restrictionPolicy: .blockSelected
        )
    }

    func isShieldReady(for feature: MoriScreenTimeFeature) -> Bool {
        let summary = profileSummary(for: feature)
        return isAuthorized && summary.isEnabled && summary.hasEffectiveSelection
    }

    func isAppLimitReady(for feature: MoriScreenTimeFeature) -> Bool {
        isShieldReady(for: feature)
    }
}

enum AttentionShieldSelectionTarget: Identifiable, Hashable {
    case defaultList
    case feature(MoriScreenTimeFeature)

    var id: String {
        switch self {
        case .defaultList:
            return "default"
        case .feature(let feature):
            return feature.rawValue
        }
    }
}

struct AttentionShieldSelectionDraft {
    let target: AttentionShieldSelectionTarget
    var selection: FamilyActivitySelection
}

enum AttentionShieldAction {
    case requestAuthorization
    case setDailyThresholdMinutes(Int)
    case setFeatureEnabled(Bool, MoriScreenTimeFeature)
    case setFeatureUsesDefaultSelection(Bool, MoriScreenTimeFeature)
    case reconcileGateProtection(MoriScreenTimeFeature)
    case reconcileProtectionState
    case commitSelectionDraft(AttentionShieldSelectionDraft)
    case startTimedShieldDuration(feature: MoriScreenTimeFeature, duration: TimeInterval, now: Date)
    case startTimedShieldSeconds(feature: MoriScreenTimeFeature, remainingSeconds: Int, now: Date)
    case startManualShield(feature: MoriScreenTimeFeature, now: Date)
    case beginResetProtectionRequest(
        feature: MoriScreenTimeFeature,
        remainingSeconds: Int,
        usesNativeBeforeFeedGate: Bool,
        now: Date
    )
    case endResetProtectionIfNeeded(feature: MoriScreenTimeFeature)
    case endShield(feature: MoriScreenTimeFeature?)
    case completeBeforeFeedResetAt(Date)
    case completeMorningGateResetAt(Date)
}

typealias AppLimitSettingsSnapshot = AttentionShieldSettingsSnapshot
typealias AppLimitSelectionTarget = AttentionShieldSelectionTarget
typealias AppLimitSelectionDraft = AttentionShieldSelectionDraft
typealias AppLimitAction = AttentionShieldAction

extension AttentionShieldAction {
    static var reconcileAppLimitState: Self {
        .reconcileProtectionState
    }

    static func reconcileGateAppLimit(_ feature: MoriScreenTimeFeature) -> Self {
        .reconcileGateProtection(feature)
    }

    static func endAppLimit(feature: MoriScreenTimeFeature?) -> Self {
        .endShield(feature: feature)
    }

    static func startTimedShield(
        feature: MoriScreenTimeFeature,
        duration: TimeInterval,
        now: Date = Date()
    ) -> Self {
        .startTimedShieldDuration(feature: feature, duration: duration, now: now)
    }

    static func startTimedAppLimit(
        feature: MoriScreenTimeFeature,
        duration: TimeInterval,
        now: Date = Date()
    ) -> Self {
        .startTimedShield(feature: feature, duration: duration, now: now)
    }

    static func startManualAppLimit(
        feature: MoriScreenTimeFeature,
        now: Date = Date()
    ) -> Self {
        .startManualShield(feature: feature, now: now)
    }

    static func startTimedShield(
        feature: MoriScreenTimeFeature,
        remainingSeconds: Int,
        now: Date = Date()
    ) -> Self {
        .startTimedShieldSeconds(feature: feature, remainingSeconds: remainingSeconds, now: now)
    }

    static func startTimedAppLimit(
        feature: MoriScreenTimeFeature,
        remainingSeconds: Int,
        now: Date = Date()
    ) -> Self {
        .startTimedShield(feature: feature, remainingSeconds: remainingSeconds, now: now)
    }

    static func beginResetProtection(
        feature: MoriScreenTimeFeature,
        remainingSeconds: Int,
        usesNativeBeforeFeedGate: Bool = true,
        now: Date = Date()
    ) -> Self {
        .beginResetProtectionRequest(
            feature: feature,
            remainingSeconds: remainingSeconds,
            usesNativeBeforeFeedGate: usesNativeBeforeFeedGate,
            now: now
        )
    }

    static func beginResetAppLimit(
        feature: MoriScreenTimeFeature,
        remainingSeconds: Int,
        usesNativeBeforeFeedGate: Bool = true,
        now: Date = Date()
    ) -> Self {
        .beginResetProtection(
            feature: feature,
            remainingSeconds: remainingSeconds,
            usesNativeBeforeFeedGate: usesNativeBeforeFeedGate,
            now: now
        )
    }

    static func endResetAppLimitIfNeeded(feature: MoriScreenTimeFeature) -> Self {
        .endResetProtectionIfNeeded(feature: feature)
    }

    static func completeBeforeFeedReset(now: Date = Date()) -> Self {
        .completeBeforeFeedResetAt(now)
    }

    static func completeMorningGateReset(now: Date = Date()) -> Self {
        .completeMorningGateResetAt(now)
    }
}
