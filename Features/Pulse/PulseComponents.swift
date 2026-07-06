import SwiftUI

struct PulsePracticeCTA: View {
    let onOpenPractices: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Close the loop",
                subtitle: "End with a reset so Pulse stays an attention filter, not a feed."
            )

            Button(action: onOpenPractices) {
                HStack(spacing: 12) {
                    MoriBitmapIconBadge(
                        icon: .refresh,
                        size: 38,
                        iconScale: 0.58,
                        fill: MoriColors.sanctuarySurface.opacity(0.76),
                        stroke: Color.white.opacity(0.88),
                        shadow: MoriColors.sanctuaryShadow.opacity(0.18)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(MoriL10n.display("Choose a reset action"))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.botanicalInk)

                        Text(MoriL10n.display("Breathe, Settle, Log, Focus, Quiet Mode, or walk offline."))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(MoriColors.botanicalMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.58)
                }
                .padding(12)
                .background(MoriColors.botanicalPaperDeep.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

struct TopicPulseSection: View {
    let topicPulse: MoriTopicPulse
    let topicIcon: MoriBitmapIcon
    let onAction: (MoriPulseCard) -> Void
    let onOpenDetails: (MoriPulseCard) -> Void

    private var orderedCards: [MoriPulseCard] {
        [.worthKnowing, .worthIgnoring, .attentionTrap].compactMap { kind in
            topicPulse.cards.first { $0.kind == kind }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                MoriBitmapIconBadge(
                    icon: topicPulse.icon(fallback: topicIcon),
                    size: 38,
                    iconScale: 0.58,
                    fill: MoriColors.sanctuarySurface.opacity(0.76),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.18)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(topicPulse.topic)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.string(
                        orderedCards.count == 1 ? "pulse.signals.count_one" : "pulse.signals.count",
                        defaultValue: orderedCards.count == 1 ? "%d signal" : "%d signals",
                        arguments: [orderedCards.count]
                    ))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                }

                Spacer(minLength: 0)
            }

            ForEach(orderedCards) { card in
                TopicPulseSignalRow(
                    card: card,
                    onAction: {
                        onAction(card)
                    },
                    onOpenDetails: {
                        onOpenDetails(card)
                    }
                )
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct TopicPulseSignalRow: View {
    let card: MoriPulseCard
    let onAction: () -> Void
    let onOpenDetails: () -> Void

    private var tint: Color {
        switch card.kind {
        case .worthKnowing: return MoriColors.botanicalMoss
        case .worthIgnoring: return MoriColors.botanicalMist
        case .attentionTrap: return MoriColors.botanicalClay
        case .resetAction: return MoriColors.botanicalFern
        case .reclaimedTime: return MoriColors.botanicalSeed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                MoriBitmapIconImage(icon: card.kind.icon, size: 17, opacity: 0.88)
                    .frame(width: 30, height: 30)
                    .background(MoriColors.sanctuarySurface.opacity(0.74))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(card.kind.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(tint)

                    Text(card.headline)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Text(card.body)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .lineSpacing(2)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button(action: onAction) {
                    HStack(spacing: 5) {
                        MoriBitmapIconImage(icon: .leaf, size: 13, opacity: 0.82)

                        Text(MoriL10n.display(card.actionLabel ?? MoriL10n.string("pulse.action.mark_useful", defaultValue: "Mark useful")))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(tint.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onOpenDetails) {
                    HStack(spacing: 5) {
                        MoriBitmapIconImage(icon: .pulse, size: 13, opacity: 0.82)

                        Text(MoriL10n.display("Ask"))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if !card.sources.isEmpty {
                    MoriPill(
                        title: MoriL10n.string(
                            card.sources.count == 1 ? "pulse.sources.count_one" : "pulse.sources.count",
                            defaultValue: card.sources.count == 1 ? "%d source" : "%d sources",
                            arguments: [card.sources.count]
                        ),
                        icon: .journal,
                        tint: tint
                    )
                }
            }
        }
        .padding(12)
        .background(MoriColors.botanicalPaperDeep.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct PulseCardView: View {
    let card: MoriPulseCard
    let onAction: () -> Void
    let onOpenDetails: () -> Void

    private var tint: Color {
        switch card.kind {
        case .worthKnowing: return MoriColors.botanicalMoss
        case .worthIgnoring: return MoriColors.botanicalMist
        case .attentionTrap: return MoriColors.botanicalClay
        case .resetAction: return MoriColors.botanicalFern
        case .reclaimedTime: return MoriColors.botanicalSeed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconBadge(
                    icon: card.kind.icon,
                    size: 38,
                    iconScale: 0.58,
                    fill: MoriColors.sanctuarySurface.opacity(0.76),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.18)
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(card.kind.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(tint)

                    Text(card.headline)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(card.body)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if let minutes = card.minutes {
                MoriBotanicalProgressBar(value: Double(min(minutes, 45)) / 45.0, tint: tint)
            }

            HStack(spacing: 10) {
                Button(action: onAction) {
                    HStack(spacing: 6) {
                        MoriBitmapIconImage(icon: .leaf, size: 14, opacity: 0.84)

                        Text(MoriL10n.display(card.actionLabel ?? MoriL10n.string("pulse.action.mark_useful", defaultValue: "Mark useful")))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onOpenDetails) {
                    MoriBitmapIconImage(icon: .pulse, size: 16, opacity: 0.86)
                        .frame(width: 48, height: 45)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(MoriL10n.string(
                    "pulse.card.ask_about_accessibility",
                    defaultValue: "Ask about %@",
                    arguments: [card.headline]
                ))
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}
