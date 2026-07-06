import SwiftUI

struct MoriRecoveryDetailView: View {
    let snapshot: MoriRecoverySnapshot
    let onStartPractice: (MoriPractice) -> Void
    let onQuickComplete: (MoriPractice) -> Void

    var body: some View {
        MoriPaperBackground(variant: .today) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    MoriRootHeader(
                        title: "Recovery Signals",
                        subtitle: "Baseline-based wellness signal. Not medical advice."
                    )

                    MoriRecoveryPulseCard(
                        snapshot: snapshot,
                        isLoading: false,
                        errorMessage: nil,
                        title: MoriL10n.string("recovery.detail.readiness_title", defaultValue: "Readiness %@", arguments: [snapshot.scoreText]),
                        subtitle: snapshot.state.guidance,
                        showsDetailLink: false,
                        showsRefreshButton: false,
                        onRefresh: {},
                        onStartPractice: onStartPractice,
                        onQuickComplete: onQuickComplete
                    )

                    MoriRecoverySleepCard(summary: snapshot.sleepSummary)
                    MoriRecoveryTrainingCard(summary: snapshot.trainingSummary)
                    MoriRecoverySignalsCard(signals: snapshot.signals)
                    MoriRecoveryPatternsCard()
                    if !snapshot.missingSignals.isEmpty {
                        MoriRecoveryMissingSignalsCard(missingSignals: snapshot.missingSignals)
                    }
                    MoriRecoveryPrivacyNote()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 72)
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct MoriRecoverySleepCard: View {
    let summary: MoriRecoverySleepSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Sleep", subtitle: summary.impactText)

            MoriCompactStatStrip {
                MoriCompactStatItem(title: "Total", value: summary.durationText, icon: .quiet, tint: MoriColors.botanicalMist)
                MoriCompactStatItem(title: "Stages", value: summary.stageSummaryText, icon: .roots, tint: MoriColors.botanicalMoss)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct MoriRecoveryTrainingCard: View {
    let summary: MoriRecoveryTrainingSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Training Load", subtitle: summary.detail)

            MoriCompactStatStrip {
                MoriCompactStatItem(title: "Last day", value: summary.title, icon: .focus, tint: MoriColors.botanicalClay)
                MoriCompactStatItem(
                    title: "High HR",
                    value: summary.highIntensityMinutes.map {
                        MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [Int($0.rounded())])
                    } ?? "--",
                    icon: .heart,
                    tint: MoriColors.botanicalMist
                )
                MoriCompactStatItem(
                    title: "Status",
                    value: summary.isElevated ? MoriL10n.display("Elevated") : MoriL10n.display("Steady"),
                    icon: .pulse,
                    tint: MoriColors.botanicalMoss
                )
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct MoriRecoverySignalsCard: View {
    let signals: [MoriRecoverySignal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Signals", subtitle: "Compared with your own recent baseline.")

            if signals.isEmpty {
                Text(MoriL10n.display("No recovery samples are available yet."))
                    .font(.system(size: 13))
                    .foregroundColor(MoriColors.botanicalMuted)
            } else {
                ForEach(signals) { signal in
                    MoriRecoverySignalRow(signal: signal)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct MoriRecoveryMissingSignalsCard: View {
    let missingSignals: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MoriSectionTitle(title: "Not enough data", subtitle: "These signals will appear after Apple Health has samples.")

            FlowLayout(spacing: 8) {
                ForEach(missingSignals, id: \.self) { signal in
                    MoriPill(title: signal, icon: .timer, tint: MoriColors.botanicalMuted)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct MoriRecoveryPrivacyNote: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(icon: .lockShield, size: 18, opacity: 0.78)
                .padding(.top, 1)

            Text(MoriL10n.display("Recovery is calculated locally from HealthKit. It uses wellness language only and does not diagnose illness."))
                .font(.system(size: 12))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}

private struct MoriRecoverySignalRow: View {
    let signal: MoriRecoverySignal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MoriBitmapIconImage(icon: signal.icon, size: 18, opacity: 0.86)
                .frame(width: 34, height: 34)
                .background(MoriColors.sanctuarySurface.opacity(0.74))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(MoriL10n.display(signal.title))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display(signal.valueText))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMuted)
                }

                Text(MoriL10n.display(signal.comparisonText))
                    .font(.system(size: 13))
                    .foregroundColor(MoriColors.botanicalMuted)

                if let baselineText = signal.baselineText {
                    Text(MoriL10n.display(baselineText))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(MoriColors.botanicalMuted.opacity(0.82))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(MoriColors.botanicalPaperDeep.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var tint: Color {
        switch signal.status {
        case .supportive:
            return MoriColors.botanicalMoss
        case .steady:
            return MoriColors.botanicalMist
        case .caution:
            return MoriColors.botanicalClay
        case .elevated:
            return MoriColors.botanicalRoot
        case .unavailable:
            return MoriColors.botanicalMuted
        }
    }
}
