import SwiftUI

enum SettleNavigationRoute: Hashable {
    case appLimits
    case breathingLibrary
    case breathingSession(techniqueID: String, durationMinutes: Int, autoStart: Bool)
    case settleTimer
    case focusCycle
    case quietMode
    case essentialMode
    case mindfulnessBellSettings
}

enum PracticeActionStyle {
    case hero
    case row
}

struct MoriSettleRouteAction {
    private let handler: ((SettleNavigationRoute) -> Void)?

    init(_ handler: ((SettleNavigationRoute) -> Void)? = nil) {
        self.handler = handler
    }

    @discardableResult
    func callAsFunction(_ route: SettleNavigationRoute) -> Bool {
        guard let handler else { return false }
        handler(route)
        return true
    }
}

private struct MoriSettleRouteActionKey: EnvironmentKey {
    static let defaultValue = MoriSettleRouteAction()
}

extension EnvironmentValues {
    var moriOpenSettleRoute: MoriSettleRouteAction {
        get { self[MoriSettleRouteActionKey.self] }
        set { self[MoriSettleRouteActionKey.self] = newValue }
    }
}

struct PracticeHeroActionCard: View {
    let practice: MoriPractice
    let reason: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                MoriBitmapIconBadge(
                    icon: practice.icon,
                    size: 58,
                    fill: MoriColors.botanicalMoss.opacity(0.16),
                    stroke: Color.white.opacity(0.9),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.28)
                )

                VStack(alignment: .leading, spacing: 7) {
                    Text(MoriL10n.display("Best next step").uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(1.1)
                        .foregroundColor(MoriColors.sanctuarySage)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(MoriL10n.display(practice.title))
                            .font(.system(size: 25, weight: .regular, design: .serif))
                            .foregroundColor(MoriColors.sanctuaryInk)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(MoriL10n.display(practice.durationText))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(MoriColors.sanctuaryMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(MoriColors.sanctuaryInk.opacity(0.07))
                            .clipShape(Capsule())
                    }

                    Text(MoriL10n.display(reason))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            MoriPracticeInlineSummary(practice: practice)

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
        .moriSanctuaryBox(
            cornerRadius: 24,
            padding: 18,
            tone: .paper
        )
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct SettleCompactStatusRow: View {
    let recommendedPractice: MoriPractice
    let weeklySummary: SettleWeeklySummary

    var body: some View {
        MoriCompactStatStrip {
            MoriCompactStatItem(
                title: "Next",
                value: recommendedPractice.durationText,
                icon: recommendedPractice.icon,
                tint: MoriColors.botanicalMoss
            )

            MoriCompactStatItem(
                title: "Sessions",
                value: "\(weeklySummary.completedSessions)",
                icon: .breathe,
                tint: MoriColors.botanicalSeed
            )

            MoriCompactStatItem(
                title: "Minutes",
                value: "\(weeklySummary.totalMinutes)m",
                icon: .timer,
                tint: MoriColors.botanicalMist
            )

            MoriCompactStatItem(
                title: "Bloom",
                value: weeklySummary.bloomPercentText,
                icon: .leaf,
                tint: MoriColors.botanicalFern
            )
        }
    }
}

struct PracticeUtilityRow: View {
    let title: String
    let subtitle: String
    let icon: MoriBitmapIcon
    let productSymbol: MoriProductSymbol?

    init(
        title: String,
        subtitle: String,
        icon: MoriBitmapIcon,
        productSymbol: MoriProductSymbol? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.productSymbol = productSymbol
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            leadingGraphic

            VStack(alignment: .leading, spacing: 4) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display(subtitle))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.58)
                .padding(.top, 12)
        }
        .padding(12)
        .background(MoriColors.botanicalPaperDeep.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var leadingGraphic: some View {
        if let productSymbol {
            MoriProductSymbolBadge(
                symbol: productSymbol,
                size: 38,
                symbolScale: 0.68,
                tint: productSymbolTint,
                fill: MoriColors.sanctuarySurface.opacity(0.76),
                stroke: Color.white.opacity(0.88),
                shadow: MoriColors.sanctuaryShadow.opacity(0.20)
            )
        } else {
            MoriBitmapIconBadge(
                icon: icon,
                size: 38,
                iconScale: 0.58,
                fill: MoriColors.sanctuarySurface.opacity(0.76),
                stroke: Color.white.opacity(0.88),
                shadow: MoriColors.sanctuaryShadow.opacity(0.20)
            )
        }
    }

    private var productSymbolTint: Color {
        switch productSymbol {
        case .beforeFeedReset:
            return MoriColors.botanicalMoss
        case .attentionStreak:
            return MoriColors.botanicalMoss
        case .morningReset:
            return MoriColors.botanicalClay
        case .appLimit, .weekArchive, .dailyLog, .focusPoint, .settings:
            return MoriColors.botanicalInk
        case .neutralDay:
            return MoriColors.botanicalMuted
        case nil:
            return MoriColors.botanicalInk
        }
    }
}

struct SettlePrivacyNote: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(icon: .lockShield, size: 18, opacity: 0.78)
                .padding(.top, 1)

            Text("Settle, Breathing, and Deep Sessions are stored locally. Roots and Bloom use only aggregate minutes and consistency.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}
