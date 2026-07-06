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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ObservedObject var appLimitManager: AppLimitManager
    @AppStorage(
        MoriScreenTimeShared.beforeFeedDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedDurationSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedDurationSeconds
    @AppStorage(
        MoriScreenTimeShared.beforeFeedGraceWindowSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedGraceWindowSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedGraceWindowSeconds
    @AppStorage(
        MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedBreathingTechniqueID: String = MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID

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
                VStack(alignment: .leading, spacing: 22) {
                    MoriPageHeader(
                        eyebrow: "First App Limit",
                        title: "Limit the next feed",
                        subtitle: copy.headerSubtitle,
                        showsEyebrow: proxy.size.height >= 820
                    )
                    .padding(.top, proxy.size.height < 820 ? 28 : 0)

                    if shouldShowHero(availableHeight: proxy.size.height) && (!summary.hasEffectiveSelection || isReady) {
                        FirstAppLimitHero(isReady: isReady)
                    }

                    FirstAppLimitSetupCard(
                        title: isReady ? "First App Limit ready" : copy.setupTitle,
                        emptySelectionDetail: copy.emptySelectionDetail,
                        selectedStatusText: selectedStatusText,
                        snapshot: snapshot,
                        summary: summary
                    )

                    if summary.hasEffectiveSelection {
                        FirstAppLimitTimingCard(
                            durationSeconds: $beforeFeedDurationSeconds,
                            graceWindowSeconds: $beforeFeedGraceWindowSeconds,
                            breathingTechniqueID: $beforeFeedBreathingTechniqueID,
                            isReady: isReady
                        )
                    }

                    FirstAppLimitBottomActions(
                        primaryTitle: effectivePrimaryTitle,
                        isPrimaryDisabled: primaryDisabled,
                        secondaryTitle: secondaryTitle,
                        onPrimary: performPrimaryAction,
                        onSecondary: secondaryAction == nil ? nil : performSecondaryAction
                    )

                    if copy.showsReasonCard {
                        FirstAppLimitReasonCard(copy: copy, isReady: isReady)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, copy.topPadding(for: proxy.size.height) + proxy.safeAreaInsets.top)
                .padding(.bottom, 40 + proxy.safeAreaInsets.bottom)
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

    private func shouldShowHero(availableHeight: CGFloat) -> Bool {
        copy.showsHero && !dynamicTypeSize.isAccessibilitySize && availableHeight >= 820
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
    let setupTitle: String
    let emptySelectionDetail: String
    let reasonSubtitle: String
    let secondaryReasonTitle: String
    let secondaryReasonDetail: String
    let analyticsContext: String
    let primaryAnalyticsAction: String
    let secondaryAnalyticsAction: String
    let topPadding: CGFloat
    let bottomScrollPadding: CGFloat
    let showsHero: Bool
    let showsReasonCard: Bool

    func topPadding(for availableHeight: CGFloat) -> CGFloat {
        availableHeight < 820 ? min(topPadding, 64) : topPadding
    }

    static let onboarding = FirstAppLimitSetupCopy(
        headerSubtitle: "Allow Screen Time, choose one app, then turn App Limit on.",
        setupTitle: "Set first App Limit",
        emptySelectionDetail: "Pick one feed, video, news, or shopping app to slow down before it opens.",
        reasonSubtitle: "One limited app changes behavior faster than another dashboard.",
        secondaryReasonTitle: "Private by default",
        secondaryReasonDetail: "Selected names stay hidden unless Screen Time data access supports display.",
        analyticsContext: "onboarding",
        primaryAnalyticsAction: "finish_onboarding",
        secondaryAnalyticsAction: "skip_app_limit",
        topPadding: 84,
        bottomScrollPadding: 184,
        showsHero: true,
        showsReasonCard: false
    )

    static let directSetup = FirstAppLimitSetupCopy(
        headerSubtitle: "Allow Screen Time, choose one app, then turn App Limit on.",
        setupTitle: "Set first App Limit",
        emptySelectionDetail: "Pick the app or website that steals attention most often.",
        reasonSubtitle: "A dashboard reports the problem. App Limit changes the next open.",
        secondaryReasonTitle: "Settings can wait",
        secondaryReasonDetail: "PIN locks and advanced timers stay in App Limits after the first App Limit exists.",
        analyticsContext: "direct_setup",
        primaryAnalyticsAction: "turn_app_limit_on",
        secondaryAnalyticsAction: "dismiss",
        topPadding: 58,
        bottomScrollPadding: 168,
        showsHero: true,
        showsReasonCard: true
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

    private var appLimitStepDetail: String {
        if isReady {
            return "The selected app will pause before the next feed."
        }

        if summary.hasEffectiveSelection {
            return "Review timing below, then turn the limit on."
        }

        return "After choosing one app, set the reset timing."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MoriSectionTitle(
                title: title,
                subtitle: selectedStatusText
            )

            FirstAppLimitStepRow(
                index: 1,
                title: snapshot.isAuthorized ? "Screen Time allowed" : "Allow Screen Time",
                detail: snapshot.isAuthorized
                    ? "Selected app limits can be applied."
                    : "Required by iOS before any app limit can work.",
                isComplete: snapshot.isAuthorized
            )

            FirstAppLimitStepRow(
                index: 2,
                title: summary.hasEffectiveSelection ? "App selected" : "Choose one app",
                detail: summary.hasEffectiveSelection
                    ? selectedStatusText
                    : emptySelectionDetail,
                isComplete: summary.hasEffectiveSelection
            )

            FirstAppLimitStepRow(
                index: 3,
                title: summary.hasEffectiveSelection ? "Timing available" : "Set reset timing",
                detail: summary.hasEffectiveSelection
                    ? "Choose breathing, reset duration, and app open window."
                    : "Appears after one app is selected.",
                isComplete: isReady
            )

            FirstAppLimitStepRow(
                index: 4,
                title: isReady ? "App Limit on" : "Turn App Limit on",
                detail: appLimitStepDetail,
                isComplete: isReady
            )

            if let lastErrorMessage = snapshot.lastErrorMessage {
                Text(MoriL10n.display(lastErrorMessage))
                    .font(MoriTypography.caption)
                    .foregroundColor(MoriColors.botanicalClay)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .moriSanctuaryBox(
            cornerRadius: 22,
            padding: 16,
            tone: .paper
        )
    }
}

private struct FirstAppLimitTimingCard: View {
    @Binding var durationSeconds: Int
    @Binding var graceWindowSeconds: Int
    @Binding var breathingTechniqueID: String

    let isReady: Bool

    private var breathingSummary: String {
        ScreenTimeSettingsBreathingSummary.text(
            techniqueID: breathingTechniqueID,
            defaultTechniqueID: MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
        )
    }

    private var title: String {
        isReady ? "Timing set" : "Set reset timing"
    }

    private var subtitle: String {
        isReady
            ? "You can still tune the reset before leaving."
            : "This is the next step after choosing the app."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: title,
                subtitle: subtitle
            )

            VStack(spacing: 10) {
                FirstAppLimitTimingPickerRow(
                    icon: .breathe,
                    title: "Breathing",
                    detail: "Guided cue during the pause."
                ) {
                    Picker(MoriL10n.display("Breathing"), selection: $breathingTechniqueID) {
                        Text(MoriL10n.display("None")).tag(MoriScreenTimeShared.beforeFeedBreathingNoneID)
                        ForEach(MoriBreathingTechniqueRepository.techniques) { technique in
                            Text(technique.name).tag(technique.id)
                        }
                    }
                }

                FirstAppLimitTimingPickerRow(
                    icon: .timer,
                    title: "Reset duration",
                    detail: "How long MORI holds the first open."
                ) {
                    Picker(MoriL10n.display("Reset duration"), selection: $durationSeconds) {
                        ForEach(MoriScreenTimeShared.beforeFeedDurationOptions) { option in
                            Text(option.label).tag(option.seconds)
                        }
                    }
                }

                FirstAppLimitTimingPickerRow(
                    icon: .refresh,
                    title: "App open window",
                    detail: "How long the app stays open after reset."
                ) {
                    Picker(MoriL10n.display("App open window"), selection: $graceWindowSeconds) {
                        ForEach(MoriScreenTimeShared.beforeFeedGraceWindowOptions) { option in
                            Text(option.label).tag(option.seconds)
                        }
                    }
                }
            }

            Text(MoriL10n.display(breathingSummary))
                .font(MoriTypography.caption)
                .foregroundColor(MoriColors.sanctuaryMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryBox(
            cornerRadius: 22,
            padding: 16,
            tone: .paper
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
            MoriBitmapIconImage(icon: icon, size: 17, opacity: 0.86)
                .frame(width: 34, height: 34)
                .background(MoriColors.botanicalInk.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryInk)

                Text(MoriL10n.display(detail))
                    .font(.system(size: 13, weight: .regular))
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
        .padding(12)
        .background(MoriColors.sanctuarySurface.opacity(0.60))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct FirstAppLimitReasonCard: View {
    let copy: FirstAppLimitSetupCopy
    let isReady: Bool

    private var title: String {
        isReady ? "What happens next?" : "Why this first?"
    }

    private var subtitle: String {
        isReady
            ? "Leave MORI. The next open is where the limit does its work."
            : copy.reasonSubtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MoriSectionTitle(
                title: title,
                subtitle: subtitle
            )

            FirstAppLimitReasonRow(
                icon: .leaf,
                productSymbol: .beforeFeedReset,
                title: isReady ? "Open the app normally" : "Friction beats willpower",
                detail: isReady
                    ? "MORI will pause before the feed instead of asking you to configure more."
                    : "The limit slows the app at the moment you open it."
            )

            FirstAppLimitReasonRow(
                icon: copy.secondaryReasonTitle == "Settings can wait" ? .settings : .lockShield,
                title: copy.secondaryReasonTitle,
                detail: copy.secondaryReasonDetail
            )
        }
        .moriSanctuaryBox(
            cornerRadius: 22,
            padding: 16,
            tone: .paper
        )
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
        .frame(height: 56)
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
                    .frame(height: 32)
                    .contentShape(Rectangle())
            }
            .font(MoriTypography.caption)
            .foregroundColor(MoriColors.botanicalMuted)
        }
    }
}

private struct FirstAppLimitHero: View {
    let isReady: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(MoriL10n.display("App Limit"))
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.botanicalMoss)
                        .textCase(.uppercase)

                    Text(MoriL10n.display(isReady ? "Ready before the feed." : "One app. Less gravity."))
                        .font(MoriTypography.sanctuarySection)
                        .foregroundColor(MoriColors.sanctuaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                FirstAppLimitStatusPill(isReady: isReady)
            }

            HStack(spacing: 10) {
                FirstAppLimitMetric(value: "1", label: "app")
                FirstAppLimitMetric(value: "iOS", label: "system")
                FirstAppLimitMetric(value: "now", label: "before feed")
            }
        }
        .padding(22)
        .background(
            MoriPlainWatercolorCardBackground(
                cornerRadius: 18,
                fill: MoriColors.sanctuarySurface.opacity(0.68),
                paperOpacity: 0.07,
                edgeOpacity: 0.04
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.84), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriL10n.display(isReady ? "App Limit ready before the feed." : "App Limit setup. One app. Less gravity."))
    }
}

private struct FirstAppLimitStatusPill: View {
    let isReady: Bool

    var body: some View {
        HStack(spacing: 7) {
            MoriProductSymbolView(
                symbol: isReady ? .appLimit : .settings,
                size: 18,
                tint: MoriColors.botanicalInk,
                opacity: 0.92
            )

            Text(MoriL10n.display(isReady ? "Ready" : "Screen Time"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.botanicalInk)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(MoriColors.sanctuarySurface.opacity(0.70))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.74), lineWidth: 1)
        )
    }
}

private struct FirstAppLimitMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(MoriL10n.display(value))
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundColor(MoriColors.sanctuaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(MoriL10n.display(label))
                .font(MoriTypography.caption)
                .foregroundColor(MoriColors.botanicalMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(MoriColors.sanctuarySurface.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct FirstAppLimitStepRow: View {
    let index: Int
    let title: String
    let detail: String
    let isComplete: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? MoriColors.botanicalMoss : MoriColors.botanicalInk.opacity(0.10))
                    .frame(width: 30, height: 30)

                if isComplete {
                    MoriProductSymbolView(
                        symbol: .appLimit,
                        size: 16,
                        tint: MoriColors.sanctuarySurface,
                        opacity: 0.96
                    )
                } else {
                    Text("\(index)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryInk)

                Text(MoriL10n.display(detail))
                    .font(MoriTypography.caption)
                    .foregroundColor(MoriColors.sanctuaryMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct FirstAppLimitReasonRow: View {
    let icon: MoriBitmapIcon
    var productSymbol: MoriProductSymbol? = nil
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            rowGraphic
                .frame(width: 34, height: 34)
                .background(MoriColors.botanicalInk.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryInk)

                Text(MoriL10n.display(detail))
                    .font(MoriTypography.caption)
                    .foregroundColor(MoriColors.sanctuaryMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var rowGraphic: some View {
        if let productSymbol {
            MoriProductSymbolView(
                symbol: productSymbol,
                size: 20,
                tint: MoriColors.botanicalInk,
                opacity: 0.92
            )
        } else {
            MoriBitmapIconImage(icon: icon, size: 18, opacity: 0.92)
        }
    }
}
