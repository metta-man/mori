import SwiftUI

struct MoriRecoveryPulseCardHeader: View {
    let title: String
    let subtitle: String
    let status: MoriRecoveryAuthorizationStatus
    let isLoading: Bool
    let showsRefreshButton: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MoriSectionTitle(title: title, subtitle: subtitle)

            if showsRefreshButton {
                Button(action: onRefresh) {
                    MoriBitmapIconImage(icon: refreshIcon, size: 18, opacity: isLoading ? 0.54 : 0.88)
                        .frame(width: 38, height: 38)
                        .background(MoriColors.sanctuarySurface.opacity(0.94))
                        .overlay(
                            Circle()
                                .stroke(MoriColors.botanicalInk.opacity(0.14), lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel(MoriL10n.display(refreshAccessibilityLabel))
            }
        }
    }

    private var refreshIcon: MoriBitmapIcon {
        status == .needsPermission ? .heart : .refresh
    }

    private var refreshAccessibilityLabel: String {
        status == .needsPermission ? "Connect Apple Health" : "Refresh recovery"
    }
}

struct MoriRecoveryScoreSummary: View {
    let snapshot: MoriRecoverySnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            MoriRecoveryScoreRing(
                scoreText: snapshot.scoreText,
                progress: scoreProgress,
                tint: scoreTint
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    MoriBitmapIconImage(icon: snapshot.state.icon, size: 17, opacity: 0.82)

                    Text(MoriL10n.display(snapshot.state.title))
                }
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.botanicalInk)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

                HStack(spacing: 8) {
                    MoriPill(title: snapshot.nervousSystemLabel, icon: .pulse, tint: recoveryPillTint(for: snapshot.nervousSystemLabel, defaultTint: MoriColors.botanicalMoss))
                    MoriPill(title: snapshot.bodyLoadLabel, icon: .heart, tint: recoveryPillTint(for: snapshot.bodyLoadLabel, defaultTint: MoriColors.botanicalClay))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var scoreProgress: Double {
        Double(snapshot.score ?? 0) / 100.0
    }

    private var scoreTint: Color {
        switch snapshot.state {
        case .openReady:
            return MoriColors.botanicalMoss
        case .balanced:
            return MoriColors.botanicalMist
        case .strained:
            return MoriColors.botanicalClay
        case .depleted:
            return MoriColors.botanicalRoot
        case .unknown:
            return MoriColors.botanicalMuted
        }
    }

    private func recoveryPillTint(for label: String, defaultTint: Color) -> Color {
        label == MoriL10n.display("Unavailable") ? MoriColors.botanicalInkSoft : defaultTint
    }
}

private struct MoriRecoveryScoreRing: View {
    let scoreText: String
    let progress: Double
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(MoriColors.botanicalLine.opacity(0.65), lineWidth: 9)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text(scoreText)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)
                    .monospacedDigit()

                Text("/100")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)
            }
        }
        .frame(width: 84, height: 84)
    }
}

struct MoriRecoveryPulseMessage: View {
    let primaryMessage: String
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let errorMessage {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    MoriBitmapIconImage(icon: .lockShield, size: 14, opacity: 0.82)

                    Text(MoriL10n.display(errorMessage))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MoriColors.botanicalClay)
            }

            Text(MoriL10n.display(primaryMessage))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.botanicalInkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MoriColors.sanctuarySurface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.botanicalInk.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct MoriRecoveryPulseSignalStrip: View {
    let snapshot: MoriRecoverySnapshot

    var body: some View {
        MoriCompactStatStrip {
            MoriCompactStatItem(
                title: "Sleep",
                value: snapshot.sleepSummary.durationText,
                icon: .quiet,
                tint: MoriColors.botanicalMist
            )

            MoriCompactStatItem(
                title: "Load",
                value: snapshot.trainingSummary.isElevated ? MoriL10n.display("High") : MoriL10n.display("Steady"),
                icon: .heart,
                tint: snapshot.trainingSummary.isElevated ? MoriColors.botanicalClay : MoriColors.botanicalMoss
            )

            MoriCompactStatItem(
                title: "Reset",
                value: snapshot.suggestedPractice.title,
                icon: snapshot.suggestedPractice.icon,
                tint: MoriColors.botanicalSeed
            )
        }
    }
}

struct MoriRecoveryPulseFooterActions: View {
    let snapshot: MoriRecoverySnapshot
    let showsDetailLink: Bool
    let onOpenDetails: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        Group {
            if showsConnectHealth {
                connectHealthButton
            } else if showsSignalsLink {
                viewSignalsButton
            }
        }
    }

    private var showsConnectHealth: Bool {
        snapshot.status == .needsPermission
    }

    private var showsSignalsLink: Bool {
        guard showsDetailLink else { return false }
        switch snapshot.status {
        case .ready, .missingData:
            return true
        case .needsPermission, .healthUnavailable:
            return false
        }
    }

    private var viewSignalsButton: some View {
        Button(action: onOpenDetails) {
            HStack(spacing: 7) {
                MoriBitmapIconImage(icon: .pulse, size: 15, opacity: 0.88)

                Text(MoriL10n.display("View signals"))
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(MoriColors.botanicalInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(MoriColors.sanctuarySurface.opacity(0.96))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(MoriColors.botanicalInk.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var connectHealthButton: some View {
        Button(action: onRefresh) {
            HStack(spacing: 8) {
                MoriBitmapIconImage(icon: .heart, size: 15, opacity: 0.90)
                    .frame(width: 24, height: 24)
                    .background(MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(Circle())

                Text(MoriL10n.display("Connect Health"))
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(MoriColors.botanicalInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(MoriColors.sanctuarySurface.opacity(0.96))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(MoriColors.botanicalInk.opacity(0.22), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display("Connect Apple Health"))
    }
}

struct MoriRecoveryPracticeLink: View {
    let practice: MoriPractice
    let label: String
    let onStartPractice: (MoriPractice) -> Void
    let onQuickComplete: (MoriPractice) -> Void

    var body: some View {
        Button(action: startPractice) {
            HStack(spacing: 8) {
                MoriBitmapIconImage(icon: practice.icon, size: 16, opacity: 0.94)
                    .frame(width: 24, height: 24)
                    .background(MoriColors.sanctuarySurface.opacity(0.86))
                    .clipShape(Circle())

                Text(MoriL10n.display(label))
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(MoriColors.botanicalSurface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(MoriColors.botanicalInk)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func startPractice() {
        if practice.route == .quickComplete {
            onQuickComplete(practice)
        } else {
            onStartPractice(practice)
        }
    }
}
