import SwiftUI
import FamilyControls

enum MoriScreenTimeBlockListSource: String, CaseIterable, Identifiable {
    case defaultList
    case customList

    var id: String { rawValue }

    var title: String {
        switch self {
        case .defaultList:
            return MoriL10n.string("screen_time.source.default", defaultValue: "Default")
        case .customList:
            return MoriL10n.string("screen_time.source.custom", defaultValue: "Custom")
        }
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .defaultList, .customList:
            return .lockShield
        }
    }
}

struct ScreenTimeSettingsOverviewState {
    let permissionStatus: String
    let permissionIcon: MoriBitmapIcon
    let permissionTint: Color
    let lockStatus: String
    let defaultSelectionText: String
    let dailySignalText: String
    let enabledFeaturesText: String
}

struct ScreenTimeSettingsSetupState {
    let isAuthorized: Bool
    let isLockConfigured: Bool
    let permissionDetail: String
    let lastErrorMessage: String?
    let lockModeTitle: String
    let defaultSelectionText: String
}

struct ScreenTimeSettingsDailySignalState {
    let thresholdMinutes: Int
}

struct ScreenTimeInlineLimitPresentation {
    let isAuthorized: Bool
    let lastErrorMessage: String?
    let summary: MoriScreenTimeProfileSummary
    let currentSource: MoriScreenTimeBlockListSource
    let statusText: String
    let sourceTitle: String
    let sourceStatusText: String
    let selectionButtonTitle: String

    @MainActor
    init(
        appLimitManager: AppLimitManager,
        contextTitle: String,
        feature: MoriScreenTimeFeature
    ) {
        let snapshot = appLimitManager.settingsSnapshot
        let summaries = snapshot.profileSummaries
        isAuthorized = snapshot.isAuthorized
        lastErrorMessage = snapshot.lastErrorMessage
        summary = Self.summary(for: feature, in: summaries)
        currentSource = summary.usesDefaultSelection ? .defaultList : .customList
        statusText = Self.statusText(
            isAuthorized: isAuthorized,
            summary: summary,
            contextTitle: contextTitle
        )
        sourceTitle = Self.sourceTitle(
            source: currentSource,
            contextTitle: contextTitle
        )
        sourceStatusText = Self.sourceStatusText(
            source: currentSource,
            summary: summary,
            defaultSelectedCount: snapshot.defaultSelectedCount
        )
        selectionButtonTitle = Self.selectionButtonTitle(source: currentSource)
    }

    private static func summary(
        for feature: MoriScreenTimeFeature,
        in summaries: [MoriScreenTimeProfileSummary]
    ) -> MoriScreenTimeProfileSummary {
        summaries.first { $0.feature == feature } ?? MoriScreenTimeProfileSummary(
            feature: feature,
            isEnabled: false,
            usesDefaultSelection: true,
            customSelectedCount: 0,
            effectiveSelectedCount: 0,
            displayNames: []
        )
    }

    private static func statusText(
        isAuthorized: Bool,
        summary: MoriScreenTimeProfileSummary,
        contextTitle: String
    ) -> String {
        guard isAuthorized else {
            return MoriL10n.string(
                "screen_time.inline.permission_needed",
                defaultValue: "%@ can limit selected apps after Screen Time permission is granted.",
                arguments: [contextTitle]
            )
        }

        guard summary.isEnabled else {
            return MoriL10n.string(
                "screen_time.inline.off",
                defaultValue: "%@ app limit is off.",
                arguments: [contextTitle]
            )
        }

        guard summary.hasEffectiveSelection else {
            return MoriL10n.string(
                "screen_time.inline.choose_apps",
                defaultValue: "Choose apps to limit during %@.",
                arguments: [contextTitle]
            )
        }

        if !summary.displayNames.isEmpty {
            return MoriL10n.string(
                "screen_time.inline.limited_during",
                defaultValue: "%@ limited during %@.",
                arguments: [summary.statusText, contextTitle]
            )
        }

        return MoriL10n.string(
            "screen_time.inline.selected_private",
            defaultValue: "%d selected. Names stay private unless data access is available.",
            arguments: [summary.effectiveSelectedCount]
        )
    }

    private static func sourceTitle(
        source: MoriScreenTimeBlockListSource,
        contextTitle: String
    ) -> String {
        source == .defaultList
            ? MoriL10n.string("screen_time.source.default_app_list", defaultValue: "Default app list")
            : MoriL10n.string("screen_time.source.context_custom_list", defaultValue: "%@ custom list", arguments: [contextTitle])
    }

    private static func sourceStatusText(
        source: MoriScreenTimeBlockListSource,
        summary: MoriScreenTimeProfileSummary,
        defaultSelectedCount: Int
    ) -> String {
        if source == .defaultList {
            guard defaultSelectedCount > 0 else {
                return MoriL10n.string("screen_time.source.default_empty", defaultValue: "Default app list is empty.")
            }
            if !summary.displayNames.isEmpty {
                return MoriL10n.string(
                    "screen_time.source.in_default",
                    defaultValue: "%@ in the default app list.",
                    arguments: [summary.statusText]
                )
            }
            return MoriL10n.string(
                "screen_time.source.selected_in_default",
                defaultValue: "%d selected in the default app list.",
                arguments: [summary.effectiveSelectedCount]
            )
        }

        guard summary.customSelectedCount > 0 else {
            return MoriL10n.string("screen_time.source.custom_empty", defaultValue: "Custom list is empty.")
        }
        if !summary.displayNames.isEmpty {
            return MoriL10n.string(
                "screen_time.source.in_custom",
                defaultValue: "%@ in the custom list.",
                arguments: [summary.statusText]
            )
        }
        return MoriL10n.string(
            "screen_time.source.selected_in_custom",
            defaultValue: "%d selected in the custom list.",
            arguments: [summary.customSelectedCount]
        )
    }

    private static func selectionButtonTitle(source: MoriScreenTimeBlockListSource) -> String {
        source == .defaultList
            ? MoriL10n.string("screen_time.edit_default", defaultValue: "Edit Default")
            : MoriL10n.string("screen_time.edit_custom", defaultValue: "Edit Custom")
    }
}

struct ScreenTimeSettingsLinkPresentation {
    let statusText: String

    @MainActor
    init(appLimitManager: AppLimitManager) {
        let snapshot = appLimitManager.settingsSnapshot
        if !snapshot.isAuthorized {
            statusText = MoriL10n.display("Permission needed to choose apps and apply limits.")
        } else if snapshot.defaultSelectedCount == 0 {
            statusText = MoriL10n.display("Allowed. Choose one app or website to limit before the next feed.")
        } else {
            statusText = MoriL10n.string(
                "settings.screen_time.apps_selected",
                defaultValue: "Allowed. %d apps selected.",
                arguments: [snapshot.defaultSelectedCount]
            )
        }
    }
}

struct ScreenTimeSettingsPresentation {
    let isAuthorized: Bool
    let overview: ScreenTimeSettingsOverviewState
    let setup: ScreenTimeSettingsSetupState
    let dailySignal: ScreenTimeSettingsDailySignalState
    let appLimitSummaries: [MoriScreenTimeProfileSummary]
    let beforeFeedSummary: MoriScreenTimeProfileSummary
    let morningGateSummary: MoriScreenTimeProfileSummary
    let morningGateAppsStatusText: String
    let beforeFeedAppsStatusText: String

    @MainActor
    init(
        appLimitManager: AppLimitManager,
        isLockConfigured: Bool,
        lockModeTitle: String
    ) {
        let snapshot = appLimitManager.settingsSnapshot
        let summaries = snapshot.profileSummaries
        let defaultSelectionText = Self.defaultSelectionText(
            selectedCount: snapshot.defaultSelectedCount
        )
        isAuthorized = snapshot.isAuthorized
        let dailyThresholdMinutes = snapshot.dailyThresholdMinutes
        let enabledFeaturesText = Self.enabledFeaturesText(
            enabledCount: summaries.filter { $0.isEnabled }.count
        )

        let permissionDetail = Self.permissionDetail(
            authorizationStatus: snapshot.authorizationStatus,
            isAuthorized: isAuthorized
        )
        setup = ScreenTimeSettingsSetupState(
            isAuthorized: isAuthorized,
            isLockConfigured: isLockConfigured,
            permissionDetail: permissionDetail,
            lastErrorMessage: snapshot.lastErrorMessage,
            lockModeTitle: lockModeTitle,
            defaultSelectionText: defaultSelectionText
        )
        dailySignal = ScreenTimeSettingsDailySignalState(
            thresholdMinutes: dailyThresholdMinutes
        )
        appLimitSummaries = summaries.filter { summary in
            summary.feature != .beforeFeed && summary.feature != .morningGate
        }
        let morningSummary = Self.summary(for: .morningGate, in: summaries)
        let beforeSummary = Self.summary(for: .beforeFeed, in: summaries)
        morningGateSummary = morningSummary
        beforeFeedSummary = beforeSummary
        morningGateAppsStatusText = morningSummary.statusText
        beforeFeedAppsStatusText = beforeSummary.statusText
        overview = ScreenTimeSettingsOverviewState(
            permissionStatus: Self.permissionStatus(isAuthorized: isAuthorized),
            permissionIcon: Self.permissionIcon(isAuthorized: isAuthorized),
            permissionTint: Self.permissionTint(isAuthorized: isAuthorized),
            lockStatus: lockModeTitle,
            defaultSelectionText: defaultSelectionText,
            dailySignalText: Self.dailySignalText(minutes: dailyThresholdMinutes),
            enabledFeaturesText: enabledFeaturesText
        )
    }

    private static func statusText(
        for feature: MoriScreenTimeFeature,
        in summaries: [MoriScreenTimeProfileSummary]
    ) -> String {
        summary(for: feature, in: summaries).statusText
    }

    private static func summary(
        for feature: MoriScreenTimeFeature,
        in summaries: [MoriScreenTimeProfileSummary]
    ) -> MoriScreenTimeProfileSummary {
        summaries.first { $0.feature == feature } ?? MoriScreenTimeProfileSummary(
            feature: feature,
            isEnabled: false,
            usesDefaultSelection: true,
            customSelectedCount: 0,
            effectiveSelectedCount: 0,
            displayNames: []
        )
    }

    private static func permissionDetail(
        authorizationStatus: AuthorizationStatus,
        isAuthorized: Bool
    ) -> String {
        if #available(iOS 26.4, *), authorizationStatus == .approvedWithDataAccess {
            return MoriL10n.string("screen_time.permission.data_access", defaultValue: "App names can be shown for supported selections.")
        }
        if isAuthorized {
            return MoriL10n.string("screen_time.permission.authorized", defaultValue: "App Limits are available. iOS may show counts instead of names.")
        }
        return MoriL10n.string("screen_time.permission.needed", defaultValue: "Allow access to choose apps and apply Reset App Limits.")
    }

    private static func defaultSelectionText(selectedCount: Int) -> String {
        guard selectedCount > 0 else {
            return MoriL10n.string("None", defaultValue: "None")
        }
        return MoriL10n.string(
            "screen_time.status.selected_count",
            defaultValue: "%d selected",
            arguments: [selectedCount]
        )
    }

    private static func permissionStatus(isAuthorized: Bool) -> String {
        isAuthorized
            ? MoriL10n.string("status.allowed", defaultValue: "Allowed")
            : MoriL10n.string("status.needed", defaultValue: "Needed")
    }

    private static func permissionIcon(isAuthorized: Bool) -> MoriBitmapIcon {
        isAuthorized ? .leaf : .lockShield
    }

    private static func permissionTint(isAuthorized: Bool) -> Color {
        isAuthorized ? MoriColors.botanicalMoss : MoriColors.botanicalClay
    }

    private static func dailySignalText(minutes: Int) -> String {
        MoriL10n.string(
            "screen_time.daily_signal_minutes_short",
            defaultValue: "%dm",
            arguments: [minutes]
        )
    }

    private static func enabledFeaturesText(enabledCount: Int) -> String {
        guard enabledCount > 0 else {
            return MoriL10n.string("screen_time.overview.features_off", defaultValue: "All App Limits are off.")
        }

        return MoriL10n.string(
            "screen_time.overview.features_on",
            defaultValue: "%d App Limits are on.",
            arguments: [enabledCount]
        )
    }
}
