import SwiftUI

enum TodayNavigationRoute: Hashable {
    case weekArchiveDetail
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

struct TodayFocusCard: View {
    @Binding var focus: String
    @State private var isEditingFocus = false

    private var trimmedFocus: String {
        focus.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                MoriProductSymbolBadge(
                    symbol: .focusPoint,
                    size: 38,
                    symbolScale: 0.66,
                    tint: MoriColors.botanicalInk,
                    fill: MoriColors.sanctuarySurface.opacity(0.74),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.20)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(MoriL10n.display("Today"))
                        .font(MoriTypography.sanctuarySection)
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display("One clear action before the next feed."))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(MoriL10n.display("Today's focus"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)

            focusContent
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 14)
    }

    @ViewBuilder
    private var focusContent: some View {
        if isEditingFocus {
            VStack(alignment: .leading, spacing: 10) {
                TextField(MoriL10n.display("One thing that deserves my best attention"), text: $focus, axis: .vertical)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .lineLimit(1...2)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(MoriColors.botanicalPaperDeep.opacity(0.68))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(MoriColors.botanicalLine.opacity(0.75), lineWidth: 1)
                    )

                Button(MoriL10n.display("Done")) {
                    finishEditingFocus()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.botanicalInk)
            }
        } else {
            Button(action: beginEditingFocus) {
                HStack(spacing: 10) {
                    MoriBitmapIconImage(icon: trimmedFocus.isEmpty ? .plus : .focus, size: 16, opacity: 0.94)

                    Text(trimmedFocus.isEmpty ? MoriL10n.display("Set one focus") : trimmedFocus)
                        .font(.system(size: 16, weight: trimmedFocus.isEmpty ? .semibold : .regular))
                        .foregroundColor(MoriColors.sanctuaryInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)

                    MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.58)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 11)
                .background(MoriColors.sanctuarySurface.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(MoriColors.botanicalLine.opacity(0.86), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(trimmedFocus.isEmpty ? MoriL10n.display("Set one focus") : MoriL10n.string("today.focus.edit_accessibility", defaultValue: "Edit focus, %@", arguments: [trimmedFocus]))
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

struct TodayAttentionStreakCard: View {
    let onStartPractice: () -> Void

    var body: some View {
        Button(action: onStartPractice) {
            HStack(alignment: .center, spacing: 10) {
                MoriProductSymbolBadge(
                    symbol: .attentionStreak,
                    size: 38,
                    symbolScale: 0.76,
                    tint: MoriColors.botanicalMoss,
                    fill: MoriColors.sanctuarySurface.opacity(0.74),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.20)
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(MoriL10n.display("Attention streak"))
                        .font(MoriTypography.sanctuarySection)
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display("Your pause is working."))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(MoriL10n.display("Start one reset before the next feed."))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MoriBitmapIconImage(icon: .play, size: 15, opacity: 0.92)
                    .frame(width: 30, height: 30)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(Circle())
            }
            .fixedSize(horizontal: false, vertical: true)
            .moriSanctuaryCard(cornerRadius: 22, padding: 14)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display("Start reset"))
        .accessibilityHint(MoriL10n.display("Opens reset practices"))
    }
}

struct TodayPrimaryResetCard: View {
    let durationText: String
    let onStartReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                MoriProductSymbolBadge(
                    symbol: .beforeFeedReset,
                    size: 52,
                    symbolScale: 0.66,
                    tint: MoriColors.botanicalMoss,
                    fill: MoriColors.botanicalMoss.opacity(0.14),
                    stroke: Color.white.opacity(0.9),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.24)
                )

                VStack(alignment: .leading, spacing: 7) {
                    Text(MoriL10n.display("Do this next").uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(MoriColors.sanctuarySage)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(MoriL10n.display("Before Feed Reset"))
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .foregroundColor(MoriColors.sanctuaryInk)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(MoriL10n.display(durationText))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(MoriColors.sanctuaryMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(MoriColors.sanctuaryInk.opacity(0.07))
                            .clipShape(Capsule())
                    }

                    Text(MoriL10n.display("Create one pause before the next selected feed opens."))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Text(MoriL10n.display("Open only if you still mean to."))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(MoriColors.botanicalInk.opacity(0.055))
                .clipShape(Capsule())

            Button(action: onStartReset) {
                HStack(spacing: 8) {
                    Text(MoriL10n.display("Start this reset"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalSurface)

                    MoriBitmapIconImage(icon: .play, size: 14, opacity: 0.94)
                        .frame(width: 23, height: 23)
                        .background(MoriColors.sanctuarySurface.opacity(0.86))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(MoriColors.botanicalInk)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.display("Start Before Feed Reset"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                onStartReset()
            }
        }
        .moriSanctuaryBox(
            cornerRadius: 24,
            padding: 18,
            tone: .paper
        )
        .accessibilityElement(children: .contain)
    }
}

struct TodayQuickActionsCard: View {
    let beforeFeedDurationText: String
    let morningDurationText: String
    let onOpenBeforeFeed: () -> Void
    let onOpenMorningReset: () -> Void
    let onOpenAppLimits: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(
                title: "Open",
                subtitle: "The main actions stay one tap from Today."
            )

            VStack(spacing: 10) {
                TodayQuickActionRow(
                    title: "Before Feed Reset",
                    subtitle: "Start the \(beforeFeedDurationText) reset now.",
                    icon: .timer,
                    productSymbol: .beforeFeedReset,
                    action: onOpenBeforeFeed
                )

                TodayQuickActionRow(
                    title: "Morning Reset",
                    subtitle: "Default-on \(morningDurationText) morning window.",
                    icon: .leaf,
                    productSymbol: .morningReset,
                    action: onOpenMorningReset
                )

                TodayQuickActionRow(
                    title: "App Limit Setup",
                    subtitle: "Choose or adjust the app Mori slows down.",
                    icon: .lockShield,
                    productSymbol: .appLimit,
                    action: onOpenAppLimits
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

    init(
        snapshot: AppLimitSettingsSnapshot,
        durationSeconds: Int,
        graceWindowSeconds: Int,
        breathingTechniqueID: String
    ) {
        let summary = snapshot.profileSummaries.first { $0.feature == .beforeFeed } ?? MoriScreenTimeProfileSummary(
            feature: .beforeFeed,
            isEnabled: false,
            usesDefaultSelection: false,
            customSelectedCount: 0,
            effectiveSelectedCount: 0,
            displayNames: []
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
            buttonIcon = .settings
            isReady = true
            timingRows = Self.timingRows(
                durationSeconds: durationSeconds,
                graceWindowSeconds: graceWindowSeconds,
                breathingTechniqueID: breathingTechniqueID
            )
        } else {
            stateLabel = "Selection ready"
            title = "Set timing and turn on"
            detail = Self.selectionReadyDetail(for: summary)
            buttonTitle = "Finish Setup"
            badgeIcon = .timer
            buttonIcon = .play
            isReady = false
            timingRows = Self.timingRows(
                durationSeconds: durationSeconds,
                graceWindowSeconds: graceWindowSeconds,
                breathingTechniqueID: breathingTechniqueID
            )
        }
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

    private static func timingRows(
        durationSeconds: Int,
        graceWindowSeconds: Int,
        breathingTechniqueID: String
    ) -> [TodayAppLimitTimingRow] {
        [
            TodayAppLimitTimingRow(
                id: "breathing",
                icon: .breathe,
                title: "Breathing",
                value: breathingTitle(for: breathingTechniqueID)
            ),
            TodayAppLimitTimingRow(
                id: "duration",
                icon: .timer,
                title: "Reset duration",
                value: BeforeFeedGate.formattedDuration(durationSeconds)
            ),
            TodayAppLimitTimingRow(
                id: "window",
                icon: .refresh,
                title: "App open window",
                value: BeforeFeedGate.formattedDuration(graceWindowSeconds)
            )
        ]
    }

    private static func breathingTitle(for techniqueID: String) -> String {
        guard techniqueID != MoriScreenTimeShared.beforeFeedBreathingNoneID else {
            return "None"
        }

        return MoriBreathingTechniqueRepository.getTechnique(id: techniqueID)?.name
            ?? "Guided"
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
