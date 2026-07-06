import SwiftUI

struct QuietBitmapLabel: View {
    let title: String
    let icon: MoriBitmapIcon
    var iconSize: CGFloat = 16
    var iconOpacity: Double = 0.88
    var spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            MoriBitmapIconImage(icon: icon, size: iconSize, opacity: iconOpacity)

            Text(MoriL10n.display(title))
        }
    }
}

struct QuietSettleSuggestionCard: View {
    @Environment(\.moriOpenRoute) private var openRoute
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconImage(icon: .leaf, size: 19, opacity: 0.88)
                    .frame(width: 38, height: 38)
                    .background(MoriColors.botanicalMoss.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(MoriL10n.display("Settle first"))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display("Before opening a feed, try a short Settle practice and let the urge soften."))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            settleAction
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    @ViewBuilder
    private var settleAction: some View {
        Button(action: openSettle) {
            label
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
        QuietBitmapLabel(title: "Open Settle", icon: .breathe, iconSize: 16, iconOpacity: 0.94)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(MoriColors.botanicalSurface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(MoriColors.botanicalInk)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func openSettle() {
        if !openRoute(.practiceSheet(.settleTimer)) {
            dismiss()
        }
    }
}

struct QuietUrgeCheckInCard: View {
    @Binding var urgeReason: String

    let onPlantPause: (String) -> Void

    private var trimmedUrgeReason: String {
        urgeReason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Urge Check-In",
                subtitle: "Why do you want to open this now?"
            )

            TextField(MoriL10n.display("Bored, anxious, avoiding something, seeking news..."), text: $urgeReason, axis: .vertical)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .lineLimit(2...4)
                .padding(14)
                .background(MoriColors.botanicalPaperDeep.opacity(0.62))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: plantPause) {
                QuietBitmapLabel(title: "Plant this pause", icon: .leaf, iconSize: 16, iconOpacity: trimmedUrgeReason.isEmpty ? 0.42 : 0.94)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(trimmedUrgeReason.isEmpty ? MoriColors.botanicalMuted.opacity(0.35) : MoriColors.botanicalMoss)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(trimmedUrgeReason.isEmpty)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private func plantPause() {
        let trimmed = trimmedUrgeReason
        guard !trimmed.isEmpty else { return }
        onPlantPause(trimmed)
        urgeReason = ""
    }
}

struct QuietDailySummarySection: View {
    let metrics: MoriClarityMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Daily Attention Summary",
                subtitle: "A local view of the attention you reclaimed today."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MoriMetricTile(
                    title: "Quiet",
                    value: "\(metrics.quietMinutesToday)m",
                    detail: "detox minutes",
                    icon: .quiet,
                    tint: MoriColors.botanicalMist
                )

                MoriMetricTile(
                    title: "Seeds",
                    value: "\(metrics.seedsToday)",
                    detail: "earned today",
                    icon: .roots,
                    tint: MoriColors.botanicalSeed
                )

                MoriMetricTile(
                    title: "Clarity",
                    value: "\(metrics.clarityScore)",
                    detail: "calm score",
                    icon: .leaf,
                    tint: MoriColors.botanicalMoss
                )

                MoriMetricTile(
                    title: "Reclaimed",
                    value: "\(metrics.reclaimedMinutesToday)m",
                    detail: "feed time saved",
                    icon: .timer,
                    tint: MoriColors.botanicalClay
                )

                MoriMetricTile(
                    title: "Limited",
                    value: "\(metrics.protectedFocusMinutesToday)m",
                    detail: "app-limited focus",
                    icon: .lockShield,
                    tint: MoriColors.botanicalFern
                )

                MoriMetricTile(
                    title: "Limits",
                    value: "\(metrics.screenTimeThresholdsReachedToday)",
                    detail: "threshold alerts",
                    icon: .lockShield,
                    tint: MoriColors.botanicalRoot
                )
            }
        }
    }
}
