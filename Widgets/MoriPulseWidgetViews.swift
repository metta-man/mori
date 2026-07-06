import SwiftUI
import WidgetKit

struct PulseSmallWidget: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 10) {
                MoriWidgetHeader(title: "Pulse", icon: .pulse)

                Text(context.displayPulseTopic)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetColors.moss)
                    .lineLimit(1)
                    .widgetAccentable()

                Text(context.displayPulseHeadline)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetColors.ink)
                    .minimumScaleFactor(0.72)
                    .lineLimit(4)

                Spacer(minLength: 0)

                HStack(spacing: 7) {
                    MoriWidgetMiniMetric(
                        title: context.hasRecoverySnapshot ? "Recovery" : "Bloom",
                        value: context.hasRecoverySnapshot ? context.recoveryScoreText : context.bloomPercentText,
                        icon: context.hasRecoverySnapshot ? .heart : .leaf
                    )
                    MoriWidgetMiniMetric(title: "Seeds", value: "\(context.seedsToday)", icon: .leaf)
                }
            }
        }
        .accessibilityLabel(MoriL10n.string(
            "widget.pulse.accessibility",
            defaultValue: "Pulse. %@. Bloom %@.",
            arguments: [context.displayPulseHeadline, context.bloomPercentText]
        ))
    }
}

struct PulseMediumWidget: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell(contentPadding: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    MoriWidgetHeader(title: context.isPulseFreshToday ? "Fresh Pulse" : "Pulse", icon: .pulse)

                    Text(context.displayPulseHeadline)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.ink)
                        .minimumScaleFactor(0.74)
                        .lineLimit(2)

                    MoriWidgetActionLinks(style: .compact)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 7) {
                    Text(context.hasRecoverySnapshot ? context.recoveryScoreText : context.bloomPercentText)
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.leafAccent)
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                        .widgetAccentable()

                    Text(MoriL10n.display(context.hasRecoverySnapshot ? "Recovery" : "Bloom"))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.mutedInk)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        MoriWidgetCompactStat(
                            title: "Seeds",
                            value: "\(context.seedsToday)"
                        )
                        MoriWidgetCompactStat(title: "Time", value: context.reclaimedMinutesText)
                    }
                }
                .frame(width: 126, alignment: .topLeading)
            }
        }
    }
}

struct PulseLargeWidget: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        MoriWidgetHeader(title: "Pulse", icon: .pulse)

                        Text(context.isPulseFreshToday ? context.displayPulseTopic : MoriL10n.display("Bloom fallback"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MoriWidgetColors.moss)
                            .lineLimit(1)
                            .widgetAccentable()
                    }

                    Spacer(minLength: 0)

                    Text(context.hasRecoverySnapshot ? context.recoveryScoreText : context.bloomPercentText)
                        .font(.system(size: 34, weight: .light, design: .monospaced))
                        .foregroundStyle(MoriWidgetColors.leafAccent)
                        .widgetAccentable()
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(context.displayPulseHeadline)
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetColors.ink)
                        .minimumScaleFactor(0.78)
                        .lineLimit(4)

                    HStack(spacing: 5) {
                        MoriBitmapIconImage(
                            icon: context.hasRecoverySnapshot ? context.displayRecoveryPracticeIcon : context.suggestedPracticeIcon,
                            size: 11,
                            opacity: 0.84
                        )

                        Text(MoriL10n.string(
                            "widget.pulse.suggested",
                            defaultValue: "Suggested: %@",
                            arguments: [context.hasRecoverySnapshot ? context.displayRecoveryPracticeTitle : context.suggestedPracticeTitle]
                        ))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(MoriWidgetColors.mutedInk)
                            .lineLimit(1)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MoriWidgetColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(MoriWidgetColors.leafAccent.opacity(0.16), lineWidth: 1)
                )

                HStack(spacing: 8) {
                    MoriWidgetCompactStat(
                        title: context.hasRecoverySnapshot ? "Recovery" : "Clarity",
                        value: context.hasRecoverySnapshot ? context.displayRecoveryState : "\(context.clarityScore)"
                    )
                    MoriWidgetCompactStat(title: "Seeds", value: "\(context.seedsToday)")
                    MoriWidgetCompactStat(title: "Reclaimed", value: context.reclaimedMinutesText)
                }

                MoriWidgetActionLinks(style: .full)
            }
        }
    }
}

struct PulseAccessoryCircularWidget: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        Gauge(value: context.hasRecoverySnapshot ? context.recoveryProgress : context.bloomProgress) {
            MoriBitmapIconImage(icon: context.hasRecoverySnapshot ? .heart : .pulse, size: 12)
        } currentValueLabel: {
            Text(context.hasRecoverySnapshot ? context.recoveryScoreText : context.bloomPercentText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.62)
                .lineLimit(1)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel(MoriL10n.string(
            "widget.bloom.accessibility",
            defaultValue: "Bloom %@",
            arguments: [context.bloomPercentText]
        ))
    }
}

struct PulseAccessoryRectangularWidget: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.isPulseFreshToday ? MoriL10n.string(
                "widget.inline.pulse_topic",
                defaultValue: "Pulse: %@",
                arguments: [context.displayPulseTopic]
            ) : (context.hasRecoverySnapshot ? MoriL10n.display("Recovery Pulse") : MoriL10n.display("Pulse")))
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(context.hasRecoverySnapshot ? context.displayRecoveryDetail : context.displayPulseHeadline)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            HStack(spacing: 6) {
                Text(context.hasRecoverySnapshot ? MoriL10n.string(
                    "recovery.widget.score",
                    defaultValue: "Recovery %@",
                    arguments: [context.recoveryScoreText]
                ) : MoriL10n.string(
                    "widget.inline.bloom",
                    defaultValue: "Bloom %@",
                    arguments: [context.bloomPercentText]
                ))
                Text(MoriL10n.string(
                    "practice.seed.count",
                    defaultValue: "%d Seeds",
                    arguments: [context.seedsToday]
                ))
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriL10n.string(
            "widget.pulse.accessibility",
            defaultValue: "Pulse. %@. Bloom %@.",
            arguments: [context.displayPulseHeadline, context.bloomPercentText]
        ))
    }
}
