import SwiftUI
import FamilyControls
import ManagedSettings

enum TodayNavigationRoute: Hashable {
    case weekArchiveDetail
    case recovery
}

struct TodayRouteAction {
    private let handler: ((TodayNavigationRoute) -> Void)?

    init(_ handler: ((TodayNavigationRoute) -> Void)? = nil) {
        self.handler = handler
    }

    @discardableResult
    func callAsFunction(_ route: TodayNavigationRoute) -> Bool {
        guard let handler else { return false }
        handler(route)
        return true
    }
}

private struct TodayRouteActionKey: EnvironmentKey {
    static let defaultValue = TodayRouteAction()
}

extension EnvironmentValues {
    var moriOpenTodayRoute: TodayRouteAction {
        get { self[TodayRouteActionKey.self] }
        set { self[TodayRouteActionKey.self] = newValue }
    }
}

struct TodayScreenSnapshot {
    let bloomText: String
    let rootsCount: Int
    let seedsCount: Int
    let quietMinutes: Int
    let currentWeekIndex: Int
    let totalWeeks: Int

    static func live(
        settings: UserSettings,
        metrics: MoriClarityMetrics
    ) -> TodayScreenSnapshot {
        TodayScreenSnapshot(
            bloomText: metrics.bloomPercentText,
            rootsCount: metrics.rootsStreak,
            seedsCount: metrics.seedsToday,
            quietMinutes: metrics.quietMinutesToday,
            currentWeekIndex: settings.currentWeekIndex,
            totalWeeks: settings.totalWeeks
        )
    }

    static let preview = TodayScreenSnapshot(
        bloomText: "25%",
        rootsCount: 2,
        seedsCount: 6,
        quietMinutes: 7,
        currentWeekIndex: 1_567,
        totalWeeks: 4_316
    )
}

struct TodayRootScrollScreen<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let subtitle: String
    let onOpenSettings: () -> Void
    private let content: Content

    init(
        title: String,
        subtitle: String,
        onOpenSettings: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onOpenSettings = onOpenSettings
        self.content = content()
    }

    var body: some View {
        GeometryReader { _ in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 22)

                    VStack(alignment: .leading, spacing: 0) {
                        content
                    }
                    .padding(.top, dynamicTypeSize.isAccessibilitySize ? 20 : 22)
                    .padding(.horizontal, 22)
                }
                .padding(.bottom, MoriMainTabBarMetrics.scrollBottomInset + MoriTheme.Spacing.xLarge)
            }
            .clipped()
            .padding(.top, 12)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(MoriL10n.display(title))
                    .font(MoriV2Type.rootTitle)
                    .foregroundColor(MoriV2Palette.forestInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(MoriL10n.display(subtitle))
                    .font(MoriV2Type.supporting)
                    .foregroundColor(MoriV2Palette.stone)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TodaySettingsButton(action: onOpenSettings)
        }
    }
}

private struct TodaySettingsButton: View {
    let action: () -> Void

    var body: some View {
        MoriV2SettingsButton(style: .plain, action: action)
    }
}

struct TodayFocusCard: View {
    @Binding var focus: String
    @State private var isEditingFocus = false

    private var trimmedFocus: String {
        focus.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        focusContent
            .padding(.leading, 20)
            .padding(.trailing, 12)
            .padding(.top, isEditingFocus ? 16 : 10)
            .padding(.bottom, isEditingFocus ? 16 : 6)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .background(MoriV2Palette.raisedPaper.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MoriV2Palette.hairline, lineWidth: 1)
            )
            .shadow(color: MoriV2Palette.forestInk.opacity(0.035), radius: 7, x: 0, y: 3)
    }

    @ViewBuilder
    private var focusContent: some View {
        if isEditingFocus {
            VStack(alignment: .leading, spacing: 8) {
                Text(MoriL10n.display("Today's intention"))
                    .font(.system(.footnote, design: .default, weight: .medium))
                    .foregroundColor(MoriV2Palette.stone)

                TextField(MoriL10n.display("One thing that deserves my best attention"), text: $focus, axis: .vertical)
                    .font(.system(.subheadline, design: .default, weight: .regular))
                    .foregroundColor(MoriV2Palette.forestInk)
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget, alignment: .leading)
                    .background(MoriV2Palette.paper.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(MoriV2Palette.hairline, lineWidth: 1)
                    }

                HStack {
                    Spacer(minLength: 0)

                    Button(MoriL10n.display("Done")) {
                        finishEditingFocus()
                    }
                    .font(.system(.subheadline, design: .default, weight: .semibold))
                    .foregroundColor(MoriV2Palette.forestInk)
                    .frame(minWidth: 56, minHeight: MoriV2Layout.minimumHitTarget)
                    .contentShape(Rectangle())
                    .accessibilityHint(MoriL10n.display("Saves today's intention"))
                }
            }
        } else {
            Button(action: beginEditingFocus) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(MoriL10n.display("Today's intention"))
                            .font(.system(.footnote, design: .default, weight: .medium))
                            .foregroundColor(MoriV2Palette.stone)

                        Text(trimmedFocus.isEmpty ? MoriL10n.display("Set a gentle intention for today.") : trimmedFocus)
                            .font(.system(.subheadline, design: .default, weight: .regular))
                            .foregroundColor(trimmedFocus.isEmpty ? MoriV2Palette.mutedStone : MoriV2Palette.forestInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Image(systemName: "pencil")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(MoriV2Palette.sage)
                        .frame(width: MoriV2Layout.minimumHitTarget, height: MoriV2Layout.minimumHitTarget)
                }
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(MoriV2PressButtonStyle())
            .accessibilityLabel(trimmedFocus.isEmpty ? MoriL10n.display("Set today's intention") : MoriL10n.string("today.intention.edit_accessibility", defaultValue: "Edit today's intention, %@", arguments: [trimmedFocus]))
            .accessibilityHint(MoriL10n.display("Opens today's intention editor"))
        }
    }

    private func beginEditingFocus() {
        isEditingFocus = true
    }

    private func finishEditingFocus() {
        focus = trimmedFocus
        isEditingFocus = false
    }
}

struct TodayPrimaryResetCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let appLimitPresentation: TodayAppLimitPresentation
    let keptClosedCount: Int
    let onStartReset: () -> Void
    let onOpenAppLimits: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MoriLivingLandscape(artworkAlignment: .top)
                .aspectRatio(dynamicTypeSize.isAccessibilitySize ? 3.2 : 1.8, contentMode: .fit)
                .mask(LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: 0.10),
                    .init(color: .white, location: 0.84),
                    .init(color: .clear, location: 1)
                ], startPoint: .top, endPoint: .bottom))
                .padding(.horizontal, -22)

            VStack(alignment: .leading, spacing: 12) {
                Text(MoriL10n.display("Before Feed Reset"))
                    .font(.system(.title2, design: .serif, weight: .regular))
                    .foregroundColor(MoriV2Palette.forestInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(MoriL10n.display(appLimitPresentation.resetSubtitle))
                    .font(MoriV2Type.body)
                    .foregroundColor(MoriV2Palette.stone)
                    .fixedSize(horizontal: false, vertical: true)
                startButton
                protectionStatus
                if keptClosedCount > 0 {
                    Text(masteryFeedbackAccessibilityText)
                        .font(MoriV2Type.caption)
                        .foregroundColor(MoriV2Palette.stone)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue(masteryFeedbackAccessibilityText)
    }

    private var protectionStatus: some View {
        Button(action: onOpenAppLimits) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .accessibilityHidden(true)
                Text(MoriL10n.display("App Limits") + " · " + MoriL10n.display(appLimitPresentation.stateLabel))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .accessibilityHidden(true)
            }
            .font(MoriV2Type.caption)
            .foregroundColor(MoriV2Palette.stone)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(MoriV2PressButtonStyle())
        .accessibilityIdentifier("today-app-limits-status")
        .accessibilityHint(MoriL10n.display("Opens App Limits settings"))
    }

    private var startButton: some View {
        Button(action: onStartReset) {
            HStack(spacing: 7) {
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MoriV2Palette.primaryForest)
                    .frame(width: 22, height: 22)
                    .background(MoriTheme.Colors.onPrimary)
                    .clipShape(Circle())

                Text(MoriL10n.display("Begin quiet pause"))
                    .font(.system(.body, design: .default, weight: .semibold))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.84)
            }
            .foregroundColor(MoriTheme.Colors.onPrimary)
            .padding(.horizontal, 18)
            .frame(
                maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil,
                minHeight: 51,
                alignment: .center
            )
            .background(MoriV2Palette.primaryForest)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(MoriV2PressButtonStyle())
        .accessibilityLabel(MoriL10n.display("Begin quiet pause"))
        .accessibilityHint(MoriL10n.display("Opens Before Feed Reset"))
    }

    private var masteryFeedbackAccessibilityText: String {
        if keptClosedCount == 1 {
            return MoriL10n.string(
                "today.before_feed.kept_closed_once",
                defaultValue: "Kept closed once today"
            )
        }
        if keptClosedCount > 1 {
            return MoriL10n.string(
                "today.before_feed.kept_closed_count",
                defaultValue: "Kept closed %d times today",
                arguments: [keptClosedCount]
            )
        }
        return MoriL10n.display("You can continue whenever you choose.")
    }
}

struct TodayQuietMetricsCard: View {
    let quietMinutes: Int
    let longestQuietMinutes: Int
    @State private var showsDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { showsDetails.toggle() } label: {
                HStack(spacing: 8) {
                    Text(MoriL10n.display("Quiet minutes today"))
                    Spacer(minLength: 8)
                    Text("\(quietMinutes) " + MoriL10n.display("min"))
                        .monospacedDigit()
                    Image(systemName: showsDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .accessibilityHidden(true)
                }
                .font(MoriV2Type.supporting)
                .foregroundColor(MoriV2Palette.stone)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(MoriV2PressButtonStyle())
            .accessibilityIdentifier("today-quiet-minutes")
            .accessibilityValue(MoriL10n.display(showsDetails ? "Expanded" : "Collapsed"))

            if showsDetails {
                HStack {
                    Text(MoriL10n.display("Longest quiet"))
                    Spacer()
                    Text("\(longestQuietMinutes) " + MoriL10n.display("min"))
                }
                .font(MoriV2Type.caption)
                .foregroundColor(MoriV2Palette.stone)
                .padding(.bottom, 8)
            }
        }
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsDetails)
    }
}

struct TodaySecondaryContextCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isShowingOtherResets = false

    @Binding var focus: String

    let morningDurationText: String
    let onOpenMorningReset: () -> Void
    let onOpenWeekArchive: () -> Void
    let onOpenRecovery: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TodayFocusCard(focus: $focus)

            otherResetsDisclosure

            if isShowingOtherResets {
                secondaryActions
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(reduceMotion ? nil : MoriV2Motion.disclosure, value: isShowingOtherResets)
    }

    private var otherResetsDisclosure: some View {
        Button {
            isShowingOtherResets.toggle()
        } label: {
            HStack(spacing: 6) {
                Text(MoriL10n.display("Other resets"))
                    .font(.system(.subheadline, design: .default, weight: .regular))

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .rotationEffect(.degrees(isShowingOtherResets ? 180 : 0))
            }
            .foregroundColor(MoriV2Palette.stone)
            .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(MoriV2PressButtonStyle())
        .accessibilityLabel(MoriL10n.display("Other resets"))
        .accessibilityValue(MoriL10n.display(isShowingOtherResets ? "Expanded" : "Collapsed"))
        .accessibilityHint(MoriL10n.display(isShowingOtherResets ? "Hides other resets" : "Shows Morning Reset, Recovery, and Life Grid"))
    }

    @ViewBuilder
    private var secondaryActions: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 0) {
                morningResetAction
                TodayHairlineDivider()
                recoveryAction
                TodayHairlineDivider()
                weekArchiveAction
            }
            .modifier(TodaySecondaryActionSurface())
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                morningResetAction

                Rectangle()
                    .fill(MoriV2Palette.hairline)
                    .frame(width: 1, height: 28)
                    .accessibilityHidden(true)

                    recoveryAction
                }
                TodayHairlineDivider()
                weekArchiveAction
            }
            .modifier(TodaySecondaryActionSurface())
        }
    }

    private var morningResetAction: some View {
        TodaySecondaryActionRow(
            title: "Morning Reset",
            subtitle: MoriL10n.string(
                "today.morning_reset.subtitle",
                defaultValue: "%@ quiet window after the first unlock.",
                arguments: [morningDurationText]
            ),
            icon: .leaf,
            action: onOpenMorningReset
        )
    }

    private var weekArchiveAction: some View {
        TodaySecondaryActionRow(
            title: "Life Grid",
            subtitle: "Return to earlier notes only when you choose.",
            icon: .journal,
            action: onOpenWeekArchive
        )
    }

    private var recoveryAction: some View {
        TodaySecondaryActionRow(
            title: "Recovery",
            subtitle: "A private signal calculated on this iPhone.",
            icon: .heart,
            action: onOpenRecovery
        )
    }
}

private struct TodaySecondaryActionRow: View {
    let title: String
    let subtitle: String
    let icon: MoriBitmapIcon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MoriTheme.Spacing.xSmall) {
                Image(systemName: systemIconName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriV2Palette.sage.opacity(0.88))
                    .frame(width: 16, height: 16)

                Text(MoriL10n.display(title))
                    .font(MoriTheme.Typography.supporting)
                    .foregroundColor(MoriV2Palette.forestInk)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)

                Spacer(minLength: MoriTheme.Spacing.xxSmall)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MoriV2Palette.sage.opacity(0.64))
            }
            .padding(.horizontal, 11)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(MoriV2PressButtonStyle())
        .accessibilityLabel(MoriL10n.display(title))
        .accessibilityHint(MoriL10n.display(subtitle))
    }

    private var systemIconName: String {
        switch icon {
        case .leaf:
            return "leaf"
        case .journal:
            return "book.closed"
        default:
            return icon.legacySystemName
        }
    }
}

private struct TodaySecondaryActionSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(MoriV2Palette.raisedPaper.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(MoriV2Palette.hairline, lineWidth: 1)
            )
    }
}

private struct TodayHairlineDivider: View {
    var body: some View {
        Rectangle()
            .fill(MoriV2Palette.hairline)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

struct TodayQuickActionsCard: View {
    let morningDurationText: String
    let onOpenMorningReset: () -> Void
    let onOpenAppLimits: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(
                title: "Adjust only when needed",
                subtitle: "Keep the main loop simple: limit, reset, leave."
            )

            VStack(spacing: 10) {
                TodayQuickActionRow(
                    title: "App Limit Setup",
                    subtitle: "Choose or adjust the app Mori slows down.",
                    icon: .appLimit,
                    productSymbol: .appLimit,
                    action: onOpenAppLimits
                )

                TodayQuickActionRow(
                    title: "Morning Reset",
                    subtitle: MoriL10n.string(
                        "today.morning_reset.subtitle",
                        defaultValue: "%@ morning window for the first unlock.",
                        arguments: [morningDurationText]
                    ),
                    icon: .leaf,
                    productSymbol: .morningReset,
                    action: onOpenMorningReset
                )
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 16)
    }
}

private struct TodayQuickActionRow: View {
    let title: String
    let subtitle: String
    let icon: MoriBitmapIcon
    var productSymbol: MoriProductSymbol? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PracticeUtilityRow(
                title: title,
                subtitle: subtitle,
                icon: icon,
                productSymbol: productSymbol
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display(title))
        .accessibilityHint(MoriL10n.display(subtitle))
    }
}

struct TodayAppLimitPresentation {
    let stateLabel: String
    let title: String
    let detail: String
    let buttonTitle: String
    let badgeIcon: MoriBitmapIcon
    let buttonIcon: MoriBitmapIcon
    let isReady: Bool
    let timingRows: [TodayAppLimitTimingRow]
    let profileSummary: MoriScreenTimeProfileSummary
    let effectiveSelection: FamilyActivitySelection
    let durationText: String

    init(
        snapshot: AppLimitSettingsSnapshot,
        effectiveSelection: FamilyActivitySelection,
        pauseStyle: MoriBeforeFeedPauseStyle,
        guidedCycleCount: Int,
        quietDurationSeconds: Int,
        breathingTechniqueID: String
    ) {
        let summary = snapshot.profileSummaries.first { $0.feature == .beforeFeed } ?? MoriScreenTimeProfileSummary(
            feature: .beforeFeed,
            isEnabled: false,
            usesDefaultSelection: false,
            customSelectedCount: 0,
            effectiveSelectedCount: 0,
            displayNames: [],
            restrictionPolicy: .blockSelected
        )
        self.profileSummary = summary
        self.effectiveSelection = effectiveSelection
        durationText = MoriBeforeFeedPauseSettingsPresentation.summary(
            style: pauseStyle,
            techniqueID: breathingTechniqueID,
            guidedCycleCount: guidedCycleCount,
            quietDurationSeconds: quietDurationSeconds
        )

        if !snapshot.isAuthorized {
            stateLabel = "Permission needed"
            title = "First App Limit"
            detail = "Allow Screen Time, then choose one app or website to slow down before feeds."
            buttonTitle = "Set App Limit"
            badgeIcon = .lockShield
            buttonIcon = .lockShield
            isReady = false
            timingRows = []
        } else if !summary.hasEffectiveSelection {
            stateLabel = "No app selected"
            title = "Choose App Limit"
            detail = "Pick the feed, video, news, or shopping app that grabs you first."
            buttonTitle = "Choose App"
            badgeIcon = .focus
            buttonIcon = .focus
            isReady = false
            timingRows = []
        } else if summary.isEnabled {
            stateLabel = "App Limit on"
            title = "App Limit active"
            detail = Self.limitedDetail(for: summary)
            buttonTitle = "Adjust Timing"
            badgeIcon = .leaf
            buttonIcon = .lockShield
            isReady = true
            timingRows = Self.timingRows(summary: durationText)
        } else {
            stateLabel = "Selection ready"
            title = "Set timing and turn on"
            detail = Self.selectionReadyDetail(for: summary)
            buttonTitle = "Finish Setup"
            badgeIcon = .timer
            buttonIcon = .play
            isReady = false
            timingRows = Self.timingRows(summary: durationText)
        }
    }

    var statusKicker: String {
        if isReady {
            return "App Limit active"
        }

        return hasEffectiveSelection ? stateLabel : "App Limit setup"
    }

    var resetSubtitle: String {
        if effectiveTokenCount == 1, let displayName = profileSummary.displayNames.first {
            return MoriL10n.string(
                "today.before_feed.named_subtitle",
                defaultValue: "Pause before %@ opens.",
                arguments: [displayName]
            )
        }

        if effectiveTokenCount == 1 {
            return "Pause before a protected app opens."
        }

        if effectiveTokenCount > 1 {
            return "Pause before your protected apps open."
        }

        return "Pause before the next feed opens."
    }

    var protectedSelectionTitle: String {
        if effectiveTokenCount == 1, let displayName = profileSummary.displayNames.first {
            return displayName
        }

        if soleApplicationToken != nil {
            return "Protected app"
        }

        if soleWebDomainToken != nil {
            return "Protected website"
        }

        if effectiveTokenCount > 1 {
            return profileSummary.selectionStatusText
        }

        return "Set up App Limit"
    }

    var protectedSelectionDetail: String {
        durationText
    }

    var hasEffectiveSelection: Bool {
        effectiveTokenCount > 0
    }

    var soleApplicationToken: ApplicationToken? {
        guard effectiveSelection.applicationTokens.count == 1,
              effectiveSelection.webDomainTokens.isEmpty
        else { return nil }

        return effectiveSelection.applicationTokens.first
    }

    var soleWebDomainToken: WebDomainToken? {
        guard effectiveSelection.webDomainTokens.count == 1,
              effectiveSelection.applicationTokens.isEmpty
        else { return nil }

        return effectiveSelection.webDomainTokens.first
    }

    private var effectiveTokenCount: Int {
        effectiveSelection.applicationTokens.count + effectiveSelection.webDomainTokens.count
    }

    private static func limitedDetail(for summary: MoriScreenTimeProfileSummary) -> String {
        if summary.displayNames.isEmpty {
            return "\(summary.selectionStatusText). \(MoriL10n.display("Limited before feeds."))"
        }
        return "\(summary.selectionStatusText) \(MoriL10n.display("limited before feeds."))"
    }

    private static func selectionReadyDetail(for summary: MoriScreenTimeProfileSummary) -> String {
        if summary.displayNames.isEmpty {
            return "\(summary.selectionStatusText). \(MoriL10n.display("Turn on App Limit before feeds."))"
        }
        return "\(summary.selectionStatusText) \(MoriL10n.display("selected. Turn on App Limit before feeds."))"
    }

    private static func timingRows(summary: String) -> [TodayAppLimitTimingRow] {
        [
            TodayAppLimitTimingRow(
                id: "pause",
                icon: .breathe,
                title: "Breath key",
                value: summary
            ),
            TodayAppLimitTimingRow(
                id: "window",
                icon: .refresh,
                title: "Feed window",
                value: "Chosen each time"
            )
        ]
    }
}

struct TodayAppLimitTimingRow: Identifiable, Equatable {
    let id: String
    let icon: MoriBitmapIcon
    let title: String
    let value: String
}

struct TodayAppLimitCard: View {
    let presentation: TodayAppLimitPresentation
    let onOpenAppLimits: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 11) {
                MoriProductSymbolBadge(
                    symbol: .appLimit,
                    size: 40,
                    symbolScale: 0.66,
                    tint: presentation.isReady ? MoriColors.botanicalMoss : MoriColors.botanicalInk,
                    fill: MoriColors.sanctuarySurface.opacity(0.76),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.22)
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(MoriL10n.display(presentation.stateLabel))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMoss)
                        .textCase(.uppercase)

                    Text(MoriL10n.display(presentation.title))
                        .font(MoriTypography.sanctuarySection)
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display(presentation.detail))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !presentation.timingRows.isEmpty {
                TodayAppLimitTimingSummary(rows: presentation.timingRows)
            }

            Button(action: onOpenAppLimits) {
                HStack(spacing: 8) {
                    MoriBitmapIconImage(icon: presentation.buttonIcon, size: 17, opacity: 0.94)

                    Text(MoriL10n.display(presentation.buttonTitle))
                        .font(.system(size: 15, weight: .semibold))

                    Spacer(minLength: 0)

                    MoriBitmapIconImage(icon: .chevron, size: 14, opacity: 0.68)
                }
                .foregroundColor(MoriColors.botanicalInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(MoriColors.botanicalInk.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.display(presentation.buttonTitle))
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 16)
    }
}

private struct TodayAppLimitTimingSummary: View {
    let rows: [TodayAppLimitTimingRow]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows) { row in
                HStack(spacing: 9) {
                    MoriBitmapIconImage(icon: row.icon, size: 14, opacity: 0.78)
                        .frame(width: 22, height: 22)

                    Text(MoriL10n.display(row.title))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMuted)

                    Spacer(minLength: 8)

                    Text(MoriL10n.display(row.value))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .background(MoriColors.botanicalInk.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
