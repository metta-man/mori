import SwiftUI

struct MoriPracticeCard: View {
    let practice: MoriPractice
    var eyebrow: String?
    var reason: String?
    var showsChevron = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MoriBitmapIconBadge(
                icon: practice.icon,
                size: 42,
                fill: MoriColors.sanctuarySurface.opacity(0.72),
                stroke: Color.white.opacity(0.9)
            )

            VStack(alignment: .leading, spacing: 8) {
                if let eyebrow {
                    Text(MoriL10n.display(eyebrow))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuarySage)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(MoriL10n.display(practice.title))
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display(practice.durationText))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(MoriColors.sanctuaryInk.opacity(0.07))
                        .clipShape(Capsule())
                }

                Text(MoriL10n.display(reason ?? practice.description))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(MoriColors.sanctuaryMuted)
                    .fixedSize(horizontal: false, vertical: true)

                MoriPracticeInlineSummary(practice: practice)
            }

            Spacer(minLength: 0)

            if showsChevron {
                MoriBitmapIconImage(icon: .chevron, size: 15, opacity: 0.58)
                    .padding(.top, 12)
            }
        }
        .moriSanctuaryBox(cornerRadius: 16, padding: 12, tone: .paper, castsShadow: false)
    }
}

struct MoriPracticeInlineSummary: View {
    let practice: MoriPractice

    var body: some View {
        Text(summaryText)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(MoriColors.botanicalMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(MoriColors.botanicalInk.opacity(0.055))
            .clipShape(Capsule())
            .accessibilityLabel(accessibilityText)
    }

    private var summaryText: String {
        "\(practice.seedText) / \(practice.domainText)"
    }

    private var accessibilityText: String {
        MoriL10n.string(
            "practice.inline_summary.accessibility",
            defaultValue: "%@. %@.",
            arguments: [practice.seedText, practice.domainText]
        )
    }
}

struct MoriFeatureBox: View {
    let title: String
    let subtitle: String
    let icon: MoriBitmapIcon
    var detail: String?
    var tone: MoriSanctuaryBoxTone = .paper
    var iconSize: CGFloat = 58
    var minHeight: CGFloat = 132
    var showsChevron = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(alignment: .top, spacing: isCompact ? 10 : 14) {
                iconBadge
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: isCompact ? 5 : 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(MoriL10n.display(title))
                            .font(.system(size: isCompact ? 17 : 22, weight: .regular, design: .serif))
                            .foregroundColor(MoriColors.sanctuaryInk)
                            .lineLimit(isCompact ? 1 : 2)
                            .minimumScaleFactor(isCompact ? 0.72 : 0.82)
                            .layoutPriority(2)

                        if let detail {
                            Text(MoriL10n.display(detail))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(tone.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(tone.accent.opacity(0.11))
                                .clipShape(Capsule())
                        }
                    }

                    Text(MoriL10n.display(subtitle))
                        .font(.system(size: isCompact ? 11 : 15, weight: .regular))
                        .foregroundColor(MoriColors.sanctuaryMuted)
                        .lineLimit(isCompact ? 3 : nil)
                        .minimumScaleFactor(isCompact ? 0.78 : 0.88)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, showsChevron ? (isCompact ? 22 : 16) : 0)

                Spacer(minLength: 0)
            }

            if showsChevron {
                MoriBitmapIconImage(icon: .chevron, size: 16, opacity: 0.68)
                    .frame(width: 26, height: 26)
                    .background(MoriColors.sanctuarySurface.opacity(0.52))
                    .clipShape(Circle())
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .moriSanctuaryBox(
            cornerRadius: 22,
            padding: isCompact ? 10 : 14,
            tone: tone,
            castsShadow: !isCompact
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var isCompact: Bool {
        iconSize <= 52
    }

    @ViewBuilder
    private var iconBadge: some View {
        MoriBitmapIconBadge(
            icon: icon,
            size: iconSize,
            iconScale: isCompact ? 0.50 : 0.54,
            fill: tone.iconFill,
            stroke: Color.white.opacity(0.88),
            shadow: MoriColors.sanctuaryShadow.opacity(0.34)
        )
        .accessibilityHidden(true)
    }
}

extension LifeDomain {
    var moriTint: Color {
        switch self {
        case .body:
            return MoriColors.botanicalFern
        case .mind:
            return MoriColors.botanicalMist
        case .love:
            return MoriColors.botanicalClay
        case .craft:
            return MoriColors.botanicalSeed
        case .courage:
            return MoriColors.botanicalRoot
        case .service:
            return MoriColors.botanicalSage
        case .wonder:
            return MoriColors.botanicalSeed
        case .rest:
            return MoriColors.botanicalMuted
        }
    }

    var moriIcon: MoriBitmapIcon {
        switch self {
        case .body:
            return .focus
        case .mind:
            return .pulse
        case .love:
            return .heart
        case .craft:
            return .journal
        case .courage:
            return .leaf
        case .service:
            return .breathe
        case .wonder:
            return .pulse
        case .rest:
            return .quiet
        }
    }
}
