import SwiftUI

struct PulseDismissButton: View {
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            MoriBitmapIconImage(icon: .chevron, size: 15, opacity: 0.88)
                .rotationEffect(.degrees(180))
                .frame(width: 40, height: 40)
                .background(MoriColors.sanctuarySurface.opacity(0.96))
                .overlay(
                    Circle()
                        .stroke(MoriColors.botanicalInk.opacity(0.16), lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display("Back"))
    }
}

struct ClarityPulseStatsHeader: View {
    let generatedAt: Date
    let metrics: MoriClarityMetrics
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            PulseHeaderStatItem(
                title: "Updated",
                value: generatedAt.formatted(date: .omitted, time: .shortened),
                icon: .timer,
                tint: MoriColors.botanicalMist
            )

            PulseHeaderStatItem(
                title: "Saved",
                value: "\(metrics.reclaimedMinutesToday)m",
                icon: .timer,
                tint: MoriColors.botanicalSeed
            )

            PulseHeaderStatItem(
                title: "Clarity",
                value: "\(metrics.clarityScore)",
                icon: .leaf,
                tint: MoriColors.botanicalMoss
            )

            Button(action: onRefresh) {
                MoriBitmapIconImage(icon: .refresh, size: 18, opacity: isLoading ? 0.54 : 0.88)
                    .frame(width: 40, height: 40)
                    .background(MoriColors.sanctuarySurface.opacity(0.92))
                    .overlay(
                        Circle()
                            .stroke(MoriColors.botanicalInk.opacity(0.14), lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .accessibilityLabel(MoriL10n.display(isLoading ? "Updating Pulse" : "Refresh Pulse"))
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MoriColors.sanctuarySurface.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.76), lineWidth: 1)
        )
    }
}

struct PulseCoreLoopGateCard: View {
    let onOpenAppLimitSetup: () -> Void
    let onStartReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconBadge(
                    icon: .lockShield,
                    size: 46,
                    iconScale: 0.58,
                    fill: MoriColors.sanctuarySurface.opacity(0.74),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.18)
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(MoriL10n.display("Finish the core loop first"))
                        .font(MoriTypography.sanctuarySection)
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display("Pulse unlocks after one App Limit is ready, so insight stays a filter instead of another feed."))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 10) {
                Button(action: onOpenAppLimitSetup) {
                    HStack(spacing: 8) {
                        MoriBitmapIconImage(icon: .lockShield, size: 17, opacity: 0.94)
                        Text(MoriL10n.display("Set first App Limit"))
                            .font(.system(size: 15, weight: .semibold))
                        Spacer(minLength: 0)
                        MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.64)
                    }
                    .foregroundColor(MoriColors.botanicalSurface)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(MoriColors.botanicalInk)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onStartReset) {
                    HStack(spacing: 8) {
                        MoriBitmapIconImage(icon: .timer, size: 16, opacity: 0.88)
                        Text(MoriL10n.display("Do one reset instead"))
                            .font(.system(size: 14, weight: .semibold))
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(MoriColors.botanicalInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 16)
        .accessibilityElement(children: .contain)
    }
}

private struct PulseHeaderStatItem: View {
    let title: String
    let value: String
    let icon: MoriBitmapIcon
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                MoriBitmapIconImage(icon: icon, size: 11, opacity: 0.78)

                Text(MoriL10n.display(title))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Text(MoriL10n.display(value))
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(MoriColors.sanctuaryInk)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PulseTopicControlsSummary: View {
    let activeTopicLabels: [String]
    let activeCount: Int
    let maxActiveCount: Int
    let selectedCount: Int
    let queuedCount: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: 12) {
                MoriBitmapIconBadge(
                    icon: .settings,
                    size: 36,
                    iconScale: 0.56,
                    fill: MoriColors.sanctuarySurface.opacity(0.72),
                    stroke: Color.white.opacity(0.86),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.14)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(MoriL10n.display("Pulse topics"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(topicSummary)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(isExpanded ? MoriL10n.display("Hide") : MoriL10n.display("Manage"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                    HStack(spacing: 5) {
                        MoriBitmapIconImage(icon: .pulse, size: 11, opacity: 0.70)

                        Text("\(activeCount)/\(maxActiveCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                    }
                    .foregroundColor(MoriColors.botanicalMuted)
                }

                MoriBitmapIconImage(icon: .chevron, size: 13, opacity: 0.64)
                    .rotationEffect(.degrees(isExpanded ? -90 : 90))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .moriSanctuaryCard(cornerRadius: 20, padding: 14)
        .accessibilityLabel(MoriL10n.string(
            "pulse.topic_controls.accessibility",
            defaultValue: "%d active Pulse topics, %d selected, %d queued. %@ topic controls.",
            arguments: [
                activeCount,
                selectedCount,
                queuedCount,
                isExpanded ? MoriL10n.display("Hide") : MoriL10n.display("Manage")
            ]
        ))
    }

    private var topicSummary: String {
        let visibleTopics = activeTopicLabels.prefix(2).joined(separator: ", ")
        let overflowCount = max(0, activeTopicLabels.count - 2)

        if visibleTopics.isEmpty {
            return MoriL10n.display("No active Pulse topics yet.")
        }

        if overflowCount > 0 {
            return MoriL10n.string(
                "pulse.topic_controls.summary_more",
                defaultValue: "%@ and %d more · %d queued",
                arguments: [visibleTopics, overflowCount, queuedCount]
            )
        }

        return MoriL10n.string(
            "pulse.topic_controls.summary",
            defaultValue: "%@ · %d queued",
            arguments: [visibleTopics, queuedCount]
        )
    }
}

struct SharedPulseSection: View {
    let cards: [MoriPulseCard]
    let onAction: (MoriPulseCard) -> Void
    let onOpenDetails: (MoriPulseCard) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Shared Reset",
                subtitle: "Close all topic pulses with one grounded action."
            )

            ForEach(cards) { card in
                PulseCardView(
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
    }
}

struct PulseErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(icon: .lockShield, size: 18, opacity: 0.82)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(MoriL10n.display("Live Pulse unavailable"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(message)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MoriColors.botanicalClay.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct PulsePrivacyNote: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(icon: .lockShield, size: 18, opacity: 0.78)
                .padding(.top, 1)

            Text(MoriL10n.display("Topic labels, aggregate clarity stats, selected Pulse cards, and your follow-up questions are sent to the configured proxy. Recovery labels are included only when you opt in. Raw HealthKit, log, habit, and screen-time details stay local whenever possible."))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}
