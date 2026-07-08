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
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var activeSheet: ScreenTimeSettingsSheet?
    @State private var monitorHealthEvents = MoriScreenTimeMonitorHealthStore.recentEvents()

    var body: some View {
        let presentation = ScreenTimeSettingsPresentation(
            appLimitManager: appLimitManager,
            isLockConfigured: lockStore.isConfigured,
            lockModeTitle: lockStore.mode?.title ?? "Not configured"
        )

        Form {
            ScreenTimeSettingsOverviewSection(
                state: presentation.overview
            )
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
            MorningGateSettingsSection(
                isEnabled: $morningGateEnabled,
                startDate: morningGateStartDateBinding,
                durationSeconds: $morningGateDurationSeconds,
                breathingTechniqueID: $morningGateBreathingTechniqueID,
                breathingSummary: morningGateBreathingSummary,
                morningAppsStatusText: presentation.morningGateAppsStatusText,
                onEditMorningApps: showMorningGatePicker
            )
            BeforeFeedSettingsSection(
                nativeGateEnabled: $beforeFeedNativeGateEnabled,
                durationSeconds: $beforeFeedDurationSeconds,
                graceWindowSeconds: $beforeFeedGraceWindowSeconds,
                breathingTechniqueID: $beforeFeedBreathingTechniqueID,
                isScreenTimeAuthorized: presentation.isAuthorized,
                feedAppSummary: presentation.beforeFeedSummary,
                breathingSummary: beforeFeedBreathingSummary,
                feedAppsStatusText: presentation.beforeFeedAppsStatusText,
                onEditFeedApps: showBeforeFeedPicker,
                onShowShortcutGuide: showShortcutGuide
            )
            ScreenTimeMonitorHealthSection(
                events: monitorHealthEvents,
                onRefresh: refreshMonitorHealth
            )
        }
        .moriSettingsForm()
        .navigationTitle(MoriL10n.display("App Limits"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .onAppear {
            normalizeGateSettings()
            refreshMonitorHealth()
        }
        .screenTimeGateRefreshes(
            beforeFeedNativeGateEnabled: beforeFeedNativeGateEnabled,
            beforeFeedGraceWindowSeconds: beforeFeedGraceWindowSeconds,
            morningGateEnabled: morningGateEnabled,
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
                    activeSheet = nil
                }
            }
        case .lockManagement(let sheet):
            ScreenTimeSettingsLockManagementView(mode: sheet)
        }
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
        morningGateStartHour = MorningGate.startHour
        morningGateStartMinute = MorningGate.startMinute
        morningGateDurationSeconds = MorningGate.durationSeconds
    }

    private func refreshMonitorHealth() {
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
