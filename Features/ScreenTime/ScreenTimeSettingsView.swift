import SwiftUI
import FamilyControls

private enum ScreenTimeSettingsSheet: Identifiable {
    case picker(AppLimitSelectionTarget)
    case shortcutGuide
    case pinSetup
    case lockManagement(ScreenTimeSettingsLockManagementSheet)

    var id: String {
        switch self {
        case .picker(let target):
            return "picker-\(target.id)"
        case .shortcutGuide:
            return "shortcut-guide"
        case .pinSetup:
            return "pin-setup"
        case .lockManagement(let sheet):
            return "lock-\(sheet.id)"
        }
    }
}

struct ScreenTimeSettingsView: View {
    @StateObject private var appLimitManager = AppLimitManager.shared
    @StateObject private var lockStore = ScreenTimeSettingsLockStore.shared
    @AppStorage(
        MoriScreenTimeShared.beforeFeedDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedDurationSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedDurationSeconds
    @AppStorage(
        MoriScreenTimeShared.beforeFeedNativeGateEnabledKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedNativeGateEnabled: Bool = MoriScreenTimeShared.defaultBeforeFeedNativeGateEnabled
    @AppStorage(
        MoriScreenTimeShared.beforeFeedHiddenAppLockEnabledKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedHiddenAppLockEnabled: Bool = MoriScreenTimeShared.defaultBeforeFeedHiddenAppLockEnabled
    @AppStorage(
        MoriScreenTimeShared.beforeFeedGraceWindowSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedGraceWindowSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedGraceWindowSeconds
    @AppStorage(
        MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedBreathingTechniqueID: String = MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
    @AppStorage(
        MoriScreenTimeShared.morningGateEnabledKey,
        store: MoriAppGroup.defaults
    ) private var morningGateEnabled: Bool = MoriScreenTimeShared.defaultMorningGateEnabled
    @AppStorage(
        MoriScreenTimeShared.morningGateHiddenAppLockEnabledKey,
        store: MoriAppGroup.defaults
    ) private var morningGateHiddenAppLockEnabled: Bool = MoriScreenTimeShared.defaultMorningGateHiddenAppLockEnabled
    @AppStorage(
        MoriScreenTimeShared.morningGateStartHourKey,
        store: MoriAppGroup.defaults
    ) private var morningGateStartHour: Int = MoriScreenTimeShared.defaultMorningGateStartHour
    @AppStorage(
        MoriScreenTimeShared.morningGateStartMinuteKey,
        store: MoriAppGroup.defaults
    ) private var morningGateStartMinute: Int = MoriScreenTimeShared.defaultMorningGateStartMinute
    @AppStorage(
        MoriScreenTimeShared.morningGateDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var morningGateDurationSeconds: Int = MoriScreenTimeShared.defaultMorningGateDurationSeconds
    @AppStorage(
        MoriScreenTimeShared.morningGateBreathingTechniqueIDKey,
        store: MoriAppGroup.defaults
    ) private var morningGateBreathingTechniqueID: String = MoriScreenTimeShared.defaultMorningGateBreathingTechniqueID
    @AppStorage("mori_app_limits_pin_prompt_completed_v1")
    private var hasCompletedPINPrompt = false
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var activeSheet: ScreenTimeSettingsSheet?
    @State private var monitorHealthEvents = MoriScreenTimeMonitorHealthStore.recentEvents()

    var body: some View {
        let presentation = ScreenTimeSettingsPresentation(
            appLimitManager: appLimitManager,
            isLockConfigured: lockStore.isConfigured,
            lockModeTitle: lockStore.mode?.title ?? "Not configured"
        )

        MoriRootScrollScreen(
            title: "App Limits",
            subtitle: "Choose what deserves a pause, then let Mori protect the space around it.",
            spacing: 22,
            bottomPadding: 44,
            backgroundVariant: .appLimit,
            minimumTopInset: 16,
            headerStyle: .editorial
        ) {
            AppLimitsReadinessCard(
                isAuthorized: presentation.isAuthorized,
                beforeFeedSummary: presentation.beforeFeedSummary,
                nativeGateEnabled: beforeFeedNativeGateEnabled,
                primaryActionTitle: mainActionTitle,
                onPrimaryAction: performMainAction
            )

            AppLimitsProtectedAppsCard(
                summary: presentation.beforeFeedSummary,
                onEdit: editBeforeFeedApps
            )

            VStack(alignment: .leading, spacing: 10) {
                AppLimitsSectionHeading(
                    title: "Everyday protection",
                    subtitle: "Two gentle boundaries for the moments that need them most."
                )

                VStack(spacing: 0) {
                    NavigationLink {
                        beforeFeedDetail(presentation: presentation)
                    } label: {
                        AppLimitsModeRow(
                            title: "Before Feed",
                            subtitle: "Pause before selected feeds open.",
                            status: beforeFeedModeStatus(presentation.beforeFeedSummary),
                            icon: .beforeFeedReset,
                            isActive: beforeFeedIsReady
                        )
                    }

                    AppLimitsRowDivider()

                    NavigationLink {
                        morningGateDetail(presentation: presentation)
                    } label: {
                        AppLimitsModeRow(
                            title: "Morning Gate",
                            subtitle: "Keep the first part of the morning clear.",
                            status: morningGateModeStatus(presentation.morningGateSummary),
                            icon: .leaf,
                            isActive: morningGateEnabled && presentation.morningGateSummary.hasEffectiveSelection
                        )
                    }
                }
                .buttonStyle(.plain)
                .moriSanctuaryBox(cornerRadius: 20, padding: 0, tone: .paper, castsShadow: false)
            }

            if shouldOfferPINProtection {
                AppLimitsPINOfferCard(
                    onProtect: showPINSetup,
                    onNotNow: { hasCompletedPINPrompt = true }
                )
            }

            NavigationLink {
                advancedSettings(presentation: presentation)
            } label: {
                AppLimitsAdvancedLink(
                    detail: advancedSummary(presentation: presentation)
                )
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            normalizeGateSettings()
            refreshMonitorHealth()
        }
        .screenTimeGateRefreshes(
            beforeFeedNativeGateEnabled: beforeFeedNativeGateEnabled,
            beforeFeedHiddenAppLockEnabled: beforeFeedHiddenAppLockEnabled,
            beforeFeedGraceWindowSeconds: beforeFeedGraceWindowSeconds,
            morningGateEnabled: morningGateEnabled,
            morningGateHiddenAppLockEnabled: morningGateHiddenAppLockEnabled,
            morningGateStartHour: morningGateStartHour,
            morningGateStartMinute: morningGateStartMinute,
            morningGateDurationSeconds: morningGateDurationSeconds,
            onGateSettingsChange: reconcileGateAppLimit
        )
        .sheet(item: $activeSheet) { sheet in
            activeSheetContent(sheet)
        }
    }

    @ViewBuilder
    private func activeSheetContent(_ sheet: ScreenTimeSettingsSheet) -> some View {
        switch sheet {
        case .picker(let target):
            ScreenTimeSettingsPickerSheet(
                title: target.settingsTitle,
                selection: $pickerSelection,
                onDone: { finishPicker(target) }
            )
        case .shortcutGuide:
            MoriBeforeFeedShortcutGuideSheet()
        case .pinSetup:
            NavigationStack {
                ScreenTimeSettingsPINSetupView {
                    lockStore.refresh()
                    hasCompletedPINPrompt = true
                    activeSheet = nil
                }
            }
        case .lockManagement(let sheet):
            ScreenTimeSettingsLockManagementView(mode: sheet)
        }
    }

    private var beforeFeedSummary: MoriScreenTimeProfileSummary {
        appLimitManager.settingsSnapshot.profileSummary(for: .beforeFeed)
    }

    private var beforeFeedIsReady: Bool {
        appLimitManager.settingsSnapshot.isAuthorized &&
        beforeFeedSummary.isEnabled &&
        beforeFeedSummary.hasEffectiveSelection &&
        beforeFeedNativeGateEnabled
    }

    private var shouldOfferPINProtection: Bool {
        beforeFeedIsReady && !lockStore.isConfigured && !hasCompletedPINPrompt
    }

    private var mainActionTitle: String? {
        let snapshot = appLimitManager.settingsSnapshot
        if !snapshot.isAuthorized {
            return MoriL10n.display("Allow Screen Time")
        }
        if !beforeFeedSummary.hasEffectiveSelection {
            return MoriL10n.display("Choose Apps")
        }
        if !beforeFeedSummary.isEnabled || !beforeFeedNativeGateEnabled {
            return MoriL10n.display("Turn On Before Feed")
        }
        return nil
    }

    private func performMainAction() {
        let snapshot = appLimitManager.settingsSnapshot
        if !snapshot.isAuthorized {
            requestScreenTimeAuthorization()
        } else if !beforeFeedSummary.hasEffectiveSelection {
            editBeforeFeedApps()
        } else {
            beforeFeedNativeGateEnabled = true
            updateFeatureEnabled(true, for: .beforeFeed)
        }
    }

    private func editBeforeFeedApps() {
        guard appLimitManager.settingsSnapshot.isAuthorized else {
            requestScreenTimeAuthorization()
            return
        }
        beforeFeedSummary.usesDefaultSelection
            ? showDefaultListPicker()
            : showBeforeFeedPicker()
    }

    private func beforeFeedModeStatus(_ summary: MoriScreenTimeProfileSummary) -> String {
        if !appLimitManager.settingsSnapshot.isAuthorized {
            return MoriL10n.display("Permission needed")
        }
        if !summary.hasEffectiveSelection {
            return MoriL10n.display("Choose apps")
        }
        return beforeFeedIsReady ? MoriL10n.display("On") : MoriL10n.display("Off")
    }

    private func morningGateModeStatus(_ summary: MoriScreenTimeProfileSummary) -> String {
        if !appLimitManager.settingsSnapshot.isAuthorized {
            return MoriL10n.display("Permission needed")
        }
        if !summary.hasEffectiveSelection {
            return MoriL10n.display("Choose apps")
        }
        return morningGateEnabled ? MoriL10n.display("On") : MoriL10n.display("Off")
    }

    private func advancedSummary(presentation: ScreenTimeSettingsPresentation) -> String {
        let enabledCount = presentation.appLimitSummaries.filter(\.isEnabled).count
        if lockStore.isConfigured {
            return MoriL10n.string(
                "screen_time.advanced.summary_locked",
                defaultValue: "%d session limits · PIN protected",
                arguments: [enabledCount]
            )
        }
        return MoriL10n.string(
            "screen_time.advanced.summary",
            defaultValue: "%d session limits · Daily signal and diagnostics",
            arguments: [enabledCount]
        )
    }

    @ViewBuilder
    private func beforeFeedDetail(presentation: ScreenTimeSettingsPresentation) -> some View {
        Form {
            BeforeFeedSettingsSection(
                nativeGateEnabled: $beforeFeedNativeGateEnabled,
                hiddenAppLockEnabled: $beforeFeedHiddenAppLockEnabled,
                durationSeconds: $beforeFeedDurationSeconds,
                graceWindowSeconds: $beforeFeedGraceWindowSeconds,
                breathingTechniqueID: $beforeFeedBreathingTechniqueID,
                isScreenTimeAuthorized: presentation.isAuthorized,
                feedAppSummary: presentation.beforeFeedSummary,
                breathingSummary: beforeFeedBreathingSummary,
                feedAppsStatusText: presentation.beforeFeedAppsStatusText,
                onEditFeedApps: editBeforeFeedApps,
                onUseDefaultFeedAppsChange: { updateFeatureUsesDefaultSelection($0, for: .beforeFeed) },
                onShowShortcutGuide: showShortcutGuide
            )
        }
        .moriSettingsForm()
        .navigationTitle(MoriL10n.display("Before Feed"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func morningGateDetail(presentation: ScreenTimeSettingsPresentation) -> some View {
        Form {
            MorningGateSettingsSection(
                isEnabled: $morningGateEnabled,
                hiddenAppLockEnabled: $morningGateHiddenAppLockEnabled,
                startDate: morningGateStartDateBinding,
                durationSeconds: $morningGateDurationSeconds,
                breathingTechniqueID: $morningGateBreathingTechniqueID,
                morningAppSummary: presentation.morningGateSummary,
                breathingSummary: morningGateBreathingSummary,
                morningAppsStatusText: presentation.morningGateAppsStatusText,
                onEditMorningApps: {
                    presentation.morningGateSummary.usesDefaultSelection
                        ? showDefaultListPicker()
                        : showMorningGatePicker()
                },
                onUseDefaultMorningAppsChange: { updateFeatureUsesDefaultSelection($0, for: .morningGate) }
            )
        }
        .moriSettingsForm()
        .navigationTitle(MoriL10n.display("Morning Gate"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func advancedSettings(presentation: ScreenTimeSettingsPresentation) -> some View {
        Form {
            ScreenTimeSetupSection(
                state: presentation.setup,
                onRequestAuthorization: requestScreenTimeAuthorization,
                onSetupPINLock: showPINSetup,
                onChangeSelfPIN: { showLockManagement(.changeSelfPIN) },
                onGenerateAccountabilityPIN: { showLockManagement(.accountabilityPIN) },
                onRemoveLock: { showLockManagement(.removeLock) },
                onEditDefaultList: showDefaultListPicker
            )
            ScreenTimeFeatureSettingsSection(
                summaries: presentation.appLimitSummaries,
                onEnabledChange: updateFeatureEnabled,
                onUsesDefaultSelectionChange: updateFeatureUsesDefaultSelection,
                onEditDefaultList: showDefaultListPicker,
                onEditCustomList: showFeaturePicker
            )
            ScreenTimeDailySignalSection(
                state: presentation.dailySignal,
                onThresholdMinutesChange: updateDailyThresholdMinutes
            )
            ScreenTimeMonitorHealthSection(
                events: monitorHealthEvents,
                onRefresh: refreshMonitorHealth
            )
        }
        .moriSettingsForm()
        .navigationTitle(MoriL10n.display("Advanced"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var morningGateStartDateBinding: Binding<Date> {
        Binding(
            get: {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = min(23, max(0, morningGateStartHour))
                components.minute = min(59, max(0, morningGateStartMinute))
                components.second = 0
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                morningGateStartHour = components.hour ?? MoriScreenTimeShared.defaultMorningGateStartHour
                morningGateStartMinute = components.minute ?? MoriScreenTimeShared.defaultMorningGateStartMinute
            }
        )
    }

    private var morningGateBreathingSummary: String {
        ScreenTimeSettingsBreathingSummary.text(
            techniqueID: morningGateBreathingTechniqueID,
            defaultTechniqueID: MoriScreenTimeShared.defaultMorningGateBreathingTechniqueID
        )
    }

    private var beforeFeedBreathingSummary: String {
        ScreenTimeSettingsBreathingSummary.text(
            techniqueID: beforeFeedBreathingTechniqueID,
            defaultTechniqueID: MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
        )
    }

    private func showPicker(_ target: AppLimitSelectionTarget) {
        let draft = appLimitManager.selectionDraft(for: target)
        pickerSelection = draft.selection
        activeSheet = .picker(draft.target)
    }

    private func requestScreenTimeAuthorization() {
        appLimitManager.perform(.requestAuthorization)
    }

    private func showDefaultListPicker() {
        showPicker(.defaultList)
    }

    private func showFeaturePicker(_ feature: MoriScreenTimeFeature) {
        showPicker(.feature(feature))
    }

    private func showMorningGatePicker() {
        showPicker(.feature(.morningGate))
    }

    private func showBeforeFeedPicker() {
        showPicker(.feature(.beforeFeed))
    }

    private func showShortcutGuide() {
        activeSheet = .shortcutGuide
    }

    private func showPINSetup() {
        activeSheet = .pinSetup
    }

    private func showLockManagement(_ sheet: ScreenTimeSettingsLockManagementSheet) {
        activeSheet = .lockManagement(sheet)
    }

    private func reconcileGateAppLimit(for feature: MoriScreenTimeFeature) {
        appLimitManager.perform(.reconcileGateAppLimit(feature))
    }

    private func normalizeGateSettings() {
        BeforeFeedGate.normalizePersistedSettings()
        MorningGate.normalizePersistedSettings()
        beforeFeedDurationSeconds = BeforeFeedGate.durationSeconds
        beforeFeedGraceWindowSeconds = BeforeFeedGate.graceWindowSeconds
        morningGateEnabled = MorningGate.isEnabled
        morningGateHiddenAppLockEnabled = MorningGate.hiddenAppLockEnabled
        morningGateStartHour = MorningGate.startHour
        morningGateStartMinute = MorningGate.startMinute
        morningGateDurationSeconds = MorningGate.durationSeconds
    }

    private func refreshMonitorHealth() {
        appLimitManager.perform(.reconcileGateAppLimit(.beforeFeed))
        monitorHealthEvents = MoriScreenTimeMonitorHealthStore.recentEvents()
    }

    private func updateFeatureEnabled(_ isEnabled: Bool, for feature: MoriScreenTimeFeature) {
        appLimitManager.perform(.setFeatureEnabled(isEnabled, feature))
    }

    private func updateFeatureUsesDefaultSelection(_ usesDefaultSelection: Bool, for feature: MoriScreenTimeFeature) {
        appLimitManager.perform(.setFeatureUsesDefaultSelection(usesDefaultSelection, feature))
    }

    private func updateDailyThresholdMinutes(_ minutes: Int) {
        appLimitManager.perform(.setDailyThresholdMinutes(minutes))
    }

    private func finishPicker(_ target: AppLimitSelectionTarget) {
        appLimitManager.perform(
            .commitSelectionDraft(
                AppLimitSelectionDraft(
                    target: target,
                    selection: pickerSelection
                )
            )
        )
    }
}

#Preview {
    NavigationStack {
        LockedScreenTimeSettingsView()
    }
}
