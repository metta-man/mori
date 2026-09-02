import FamilyControls
import SwiftUI

struct FirstAppLimitSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.moriOpenRoute) private var openRoute
    @StateObject private var appLimitManager = AppLimitManager.shared

    let routeSource: MoriAppRouteSource?

    private let feature: MoriScreenTimeFeature = .beforeFeed

    init(routeSource: MoriAppRouteSource? = nil) {
        self.routeSource = routeSource
    }

    private var snapshot: AppLimitSettingsSnapshot {
        appLimitManager.settingsSnapshot
    }

    private var summary: MoriScreenTimeProfileSummary {
        snapshot.profileSummary(for: feature)
    }

    var body: some View {
        MoriPaperBackground(variant: .appLimit) {
            FirstAppLimitSetupSurface(
                appLimitManager: appLimitManager,
                copy: .directSetup,
                routeSource: routeSource?.analyticsName,
                primaryTitle: { isReady in
                    isReady ? "Go to Today" : "Turn App Limit On"
                },
                primaryAnalyticsAction: { isReady in
                    isReady
                        ? "go_to_today"
                        : FirstAppLimitSetupCopy.directSetup.primaryAnalyticsAction
                },
                isPrimaryDisabled: { summary in
                    !summary.hasEffectiveSelection
                },
                primaryAction: finishOrTurnAppLimitOn,
                secondaryTitle: nil,
                secondaryAction: nil
            )
        }
        .navigationTitle(MoriL10n.display("First App Limit"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(MoriL10n.display("Done")) {
                    dismissSetup()
                }
            }
        }
    }

    private func finishOrTurnAppLimitOn(_ summary: MoriScreenTimeProfileSummary) {
        if snapshot.isAppLimitReady(for: feature) {
            FirstAppLimitSetupMorningGateActivation.activate(using: appLimitManager)
            if !openRoute(.todayTab, source: .userInteraction) {
                dismiss()
            }
            return
        }

        guard summary.hasEffectiveSelection else { return }
        appLimitManager.perform(.setFeatureEnabled(true, .beforeFeed))
        FirstAppLimitSetupMorningGateActivation.activate(using: appLimitManager)
        trackCompletedIfReady()
    }

    private func dismissSetup() {
        AnalyticsManager.shared.trackFirstAppLimitSetupEvent(
            action: FirstAppLimitSetupCopy.directSetup.secondaryAnalyticsAction,
            context: FirstAppLimitSetupCopy.directSetup.analyticsContext,
            routeSource: routeSource?.analyticsName,
            snapshot: snapshot,
            summary: summary
        )
        dismiss()
    }

    private func trackCompletedIfReady() {
        let updatedSnapshot = appLimitManager.settingsSnapshot
        guard updatedSnapshot.isAppLimitReady(for: feature) else { return }

        AnalyticsManager.shared.trackFirstAppLimitSetupEvent(
            action: "app_limit_completed",
            context: FirstAppLimitSetupCopy.directSetup.analyticsContext,
            routeSource: routeSource?.analyticsName,
            snapshot: updatedSnapshot,
            summary: updatedSnapshot.profileSummary(for: feature)
        )
    }
}

struct FirstAppLimitSetupSurface: View {
    @ObservedObject var appLimitManager: AppLimitManager

    let copy: FirstAppLimitSetupCopy
    let routeSource: String?
    let primaryTitle: (Bool) -> String
    let primaryAnalyticsAction: (Bool) -> String
    let isPrimaryDisabled: (MoriScreenTimeProfileSummary) -> Bool
    let primaryAction: (MoriScreenTimeProfileSummary) -> Void
    let secondaryTitle: String?
    let secondaryAction: (() -> Void)?

    @State private var pickerTarget: AppLimitSelectionTarget?
    @State private var pickerSelection = FamilyActivitySelection()
    @State private var hasTrackedView = false

    private let feature: MoriScreenTimeFeature = .beforeFeed

    private var snapshot: AppLimitSettingsSnapshot {
        appLimitManager.settingsSnapshot
    }

    private var summary: MoriScreenTimeProfileSummary {
        snapshot.profileSummary(for: feature)
    }

    private var isReady: Bool {
        snapshot.isAppLimitReady(for: feature)
    }

    private var selectedStatusText: String {
        guard snapshot.isAuthorized else {
            return MoriL10n.display("Screen Time permission is needed before app limits can work.")
        }
        guard summary.hasEffectiveSelection else {
            return MoriL10n.display("Choose one feed app, video app, news app, or shopping site to limit.")
        }
        if summary.isEnabled {
            if summary.displayNames.isEmpty {
                return "\(summary.selectionStatusText). \(MoriL10n.display("Limited before feeds."))"
            }
            return "\(summary.selectionStatusText) \(MoriL10n.display("limited before feeds."))"
        }
        return summary.selectionStatusText
    }

    private var primaryDisabled: Bool {
        snapshot.isAuthorized &&
        summary.hasEffectiveSelection &&
        isPrimaryDisabled(summary)
    }

    private var effectivePrimaryTitle: String {
        if !snapshot.isAuthorized {
            return "Allow Screen Time"
        }

        if !summary.hasEffectiveSelection {
            return "Choose one app"
        }

        return primaryTitle(isReady)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    MoriSectionTitle(
                        title: "Limit the next feed",
                        subtitle: copy.headerSubtitle
                    )

                    if snapshot.isAuthorized {
                        FirstAppLimitSetupCard(
                            title: isReady
                                ? "First App Limit is on"
                                : (summary.hasEffectiveSelection ? "App selected" : "Choose one app"),
                            emptySelectionDetail: copy.emptySelectionDetail,
                            selectedStatusText: selectedStatusText,
                            snapshot: snapshot,
                            summary: summary
                        )

                        if summary.hasEffectiveSelection {
                            FirstAppLimitTimingCard(isReady: isReady)
                        }

                        FirstAppLimitBottomActions(
                            primaryTitle: effectivePrimaryTitle,
                            isPrimaryDisabled: primaryDisabled,
                            secondaryTitle: secondaryTitle,
                            onPrimary: performPrimaryAction,
                            onSecondary: secondaryAction == nil ? nil : performSecondaryAction
                        )
                    } else {
                        MoriPermissionState(
                            title: "Allow Screen Time",
                            message: "Mori needs iOS Screen Time access before you can choose an app. Permission is requested only when you tap below.",
                            buttonTitle: "Allow Screen Time",
                            buttonAction: performPrimaryAction
                        )
                        .moriSanctuaryBox(
                            cornerRadius: 18,
                            padding: 16,
                            tone: .paper,
                            castsShadow: false
                        )

                        if let lastErrorMessage = snapshot.lastErrorMessage {
                            HStack(alignment: .top, spacing: 8) {
                                MoriBitmapIconImage(icon: .refresh, size: 13, opacity: 0.82)
                                    .accessibilityHidden(true)

                                Text(MoriL10n.display(lastErrorMessage))
                                    .font(MoriTypography.caption)
                                    .foregroundColor(MoriColors.botanicalClay)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .accessibilityElement(children: .combine)
                        }

                        if let secondaryTitle, secondaryAction != nil {
                            Button(action: performSecondaryAction) {
                                Text(MoriL10n.display(secondaryTitle))
                                    .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget)
                                    .contentShape(Rectangle())
                            }
                            .font(MoriTypography.caption)
                            .foregroundColor(MoriColors.botanicalMuted)
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(
                    .top,
                    min(copy.topPadding(for: proxy.size.height), 28)
                )
                .padding(.bottom, 32 + proxy.safeAreaInsets.bottom)
            }
        }
        .onAppear(perform: prepareView)
        .sheet(item: $pickerTarget) { target in
            ScreenTimeSettingsPickerSheet(
                title: MoriL10n.display("Apps to limit"),
                selection: $pickerSelection,
                onDone: { finishPicker(target) }
            )
        }
    }

    private func requestAuthorization() {
        track("authorization_requested")
        appLimitManager.perform(.requestAuthorization)
    }

    private func showPicker() {
        track("picker_opened")
        let target = AppLimitSelectionTarget.feature(feature)
        let draft = appLimitManager.selectionDraft(for: target)
        pickerSelection = draft.selection
        pickerTarget = target
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
        track("selection_committed")
    }

    private func performPrimaryAction() {
        if !snapshot.isAuthorized {
            requestAuthorization()
            return
        }

        if !summary.hasEffectiveSelection {
            showPicker()
            return
        }

        track(primaryAnalyticsAction(isReady))
        primaryAction(summary)
    }

    private func performSecondaryAction() {
        track(copy.secondaryAnalyticsAction)
        secondaryAction?()
    }

    private func prepareView() {
        BeforeFeedGate.normalizePersistedSettings()
        trackViewedIfNeeded()
    }

    private func trackViewedIfNeeded() {
        guard !hasTrackedView else { return }
        hasTrackedView = true
        track("viewed")
    }

    private func track(_ action: String) {
        AnalyticsManager.shared.trackFirstAppLimitSetupEvent(
            action: action,
            context: copy.analyticsContext,
            routeSource: routeSource,
            snapshot: snapshot,
            summary: summary
        )
    }
}

struct FirstAppLimitSetupCopy {
    let headerSubtitle: String
    let emptySelectionDetail: String
    let analyticsContext: String
    let primaryAnalyticsAction: String
    let secondaryAnalyticsAction: String
    let topPadding: CGFloat

    func topPadding(for availableHeight: CGFloat) -> CGFloat {
        availableHeight < 820 ? min(topPadding, 64) : topPadding
    }

    static let onboarding = FirstAppLimitSetupCopy(
        headerSubtitle: "Allow Screen Time, choose one app, then turn App Limit on.",
        emptySelectionDetail: "Pick one feed, video, news, or shopping app to slow down before it opens.",
        analyticsContext: "onboarding",
        primaryAnalyticsAction: "finish_onboarding",
        secondaryAnalyticsAction: "skip_app_limit",
        topPadding: 84
    )

    static let directSetup = FirstAppLimitSetupCopy(
        headerSubtitle: "Allow Screen Time, choose one app, then turn App Limit on.",
        emptySelectionDetail: "Pick the app or website that steals attention most often.",
        analyticsContext: "direct_setup",
        primaryAnalyticsAction: "turn_app_limit_on",
        secondaryAnalyticsAction: "dismiss",
        topPadding: 58
    )
}

enum FirstAppLimitSetupMorningGateActivation {
    @MainActor
    static func activate(using appLimitManager: AppLimitManager) {
        MorningGate.isEnabled = true
        MorningGate.durationSeconds = MoriScreenTimeShared.defaultMorningGateDurationSeconds

        let draft = appLimitManager.selectionDraft(for: .feature(.beforeFeed))
        guard !draft.selection.applicationTokens.isEmpty || !draft.selection.webDomainTokens.isEmpty else {
            appLimitManager.perform(.setFeatureEnabled(true, .morningGate))
            appLimitManager.perform(.reconcileGateAppLimit(.morningGate))
            return
        }

        appLimitManager.perform(
            .commitSelectionDraft(
                AppLimitSelectionDraft(
                    target: .feature(.morningGate),
                    selection: draft.selection
                )
            )
        )
        appLimitManager.perform(.setFeatureEnabled(true, .morningGate))
        appLimitManager.perform(.reconcileGateAppLimit(.morningGate))
    }
}

private struct FirstAppLimitSetupCard: View {
    let title: String
    let emptySelectionDetail: String
    let selectedStatusText: String
    let snapshot: AppLimitSettingsSnapshot
    let summary: MoriScreenTimeProfileSummary

    private var isReady: Bool {
        snapshot.isAppLimitReady(for: .beforeFeed)
    }

    private var supportingDetail: String {
        if isReady {
            return "The selected app will pause before the next feed."
        }

        if summary.hasEffectiveSelection {
            return "Review timing below, then turn the limit on."
        }

        return emptySelectionDetail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                MoriProductSymbolView(
                    symbol: summary.hasEffectiveSelection ? .appLimit : .settings,
                    size: 19,
                    tint: MoriColors.botanicalInk,
                    opacity: 0.92
                )
                .frame(width: 36, height: 36)
                .background(MoriColors.botanicalInk.opacity(0.08))
                .clipShape(Circle())
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(MoriL10n.display(title))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display(selectedStatusText))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Text(MoriL10n.display(supportingDetail))
                .font(MoriTypography.caption)
                .foregroundColor(MoriColors.sanctuaryInkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if let lastErrorMessage = snapshot.lastErrorMessage {
                HStack(alignment: .top, spacing: 8) {
                    MoriBitmapIconImage(icon: .refresh, size: 13, opacity: 0.82)
                        .accessibilityHidden(true)

                    Text(MoriL10n.display(lastErrorMessage))
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.botanicalClay)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .moriSanctuaryBox(
            cornerRadius: 18,
            padding: 14,
            tone: .paper,
            castsShadow: false
        )
    }
}

private struct FirstAppLimitTimingCard: View {
    let isReady: Bool

    private var title: String {
        isReady ? "Timing" : "Reset timing"
    }

    private var subtitle: String {
        isReady
            ? "A configurable breath, then one conscious choice."
            : "Choose the breath ritual later in App Limits."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(
                title: title,
                subtitle: subtitle
            )

            VStack(alignment: .leading, spacing: 0) {
                FirstAppLimitTimingPickerRow(
                    icon: .breathe,
                    title: "Breath key",
                    detail: "Guided breathing or your own timed breath"
                ) {
                    EmptyView()
                }

                Divider()
                    .overlay(MoriColors.sanctuaryHairline)

                FirstAppLimitTimingPickerRow(
                    icon: .refresh,
                    title: "Feed window",
                    detail: "Choose 2, 5, 10, or 15 minutes each time."
                ) {
                    EmptyView()
                }
            }
        }
        .moriSanctuaryBox(
            cornerRadius: 18,
            padding: 14,
            tone: .paper,
            castsShadow: false
        )
    }
}

private struct FirstAppLimitTimingPickerRow<Control: View>: View {
    let icon: MoriBitmapIcon
    let title: String
    let detail: String
    let control: () -> Control

    init(
        icon: MoriBitmapIcon,
        title: String,
        detail: String,
        @ViewBuilder control: @escaping () -> Control
    ) {
        self.icon = icon
        self.title = title
        self.detail = detail
        self.control = control
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.86)
                .frame(width: 30, height: 30)
                .background(MoriColors.botanicalInk.opacity(0.08))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryInk)

                Text(MoriL10n.display(detail))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.sanctuaryMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            control()
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(MoriColors.botanicalInk)
                .frame(maxWidth: 150, alignment: .trailing)
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

private struct FirstAppLimitBottomActions: View {
    let primaryTitle: String
    let isPrimaryDisabled: Bool
    let secondaryTitle: String?
    let onPrimary: () -> Void
    let onSecondary: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            primaryButton
            secondaryButton
        }
        .frame(maxWidth: .infinity)
    }

    private var primaryButton: some View {
        Button(action: onPrimary) {
            Text(MoriL10n.display(primaryTitle))
        }
        .buttonStyle(MoriPrimaryButtonStyle())
        .frame(minHeight: 52)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .disabled(isPrimaryDisabled)
        .opacity(isPrimaryDisabled ? 0.48 : 1)
    }

    @ViewBuilder
    private var secondaryButton: some View {
        if let secondaryTitle, let onSecondary {
            Button(action: onSecondary) {
                Text(MoriL10n.display(secondaryTitle))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: MoriV2Layout.minimumHitTarget)
                    .contentShape(Rectangle())
            }
            .font(MoriTypography.caption)
            .foregroundColor(MoriColors.botanicalMuted)
            .buttonStyle(.plain)
        }
    }
}
