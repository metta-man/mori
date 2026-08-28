import SwiftUI
import WidgetKit

struct PulseSmallWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 10) {
                MoriWidgetHeader(title: "Recovery", icon: .heart)

                Text(context.recoveryScoreText)
                    .font(.system(size: 34, weight: .light, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                    .monospacedDigit()
                    .widgetAccentable()

                Text(context.displayRecoveryState)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.moss(for: renderingMode))
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(context.displayRecoveryDetail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                    .lineLimit(2)
            }
        }
        .accessibilityLabel(MoriL10n.string(
            "widget.recovery.accessibility",
            defaultValue: "Recovery %@. %@.",
            arguments: [context.recoveryScoreText, context.displayRecoveryState]
        ))
    }
}

struct PulseMediumWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell(contentPadding: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    MoriWidgetHeader(title: "Recovery", icon: .heart)

                    Text(context.displayRecoveryDetail)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                        .minimumScaleFactor(0.74)
                        .lineLimit(2)

                    Text(MoriL10n.display("Calculated privately on this iPhone."))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 7) {
                    Text(context.recoveryScoreText)
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.accent(for: renderingMode))
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                        .widgetAccentable()

                    Text(MoriL10n.display(context.displayRecoveryState))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                        .lineLimit(1)

                    Text(MoriL10n.display(context.hasRecoverySnapshot ? "Updated from Apple Health" : "Open Mori to connect Health"))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                        .lineLimit(2)
                }
                .frame(width: 126, alignment: .topLeading)
            }
        }
    }
}

struct PulseLargeWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode

    let context: MoriWidgetContextSnapshot

    var body: some View {
        MoriWidgetShell {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        MoriWidgetHeader(title: "Recovery", icon: .heart)

                        Text(context.displayRecoveryState)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MoriWidgetPalette.moss(for: renderingMode))
                            .lineLimit(1)
                            .widgetAccentable()
                    }

                    Spacer(minLength: 0)

                    Text(context.recoveryScoreText)
                        .font(.system(size: 34, weight: .light, design: .monospaced))
                        .foregroundStyle(MoriWidgetPalette.accent(for: renderingMode))
                        .widgetAccentable()
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(context.displayRecoveryDetail)
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .foregroundStyle(MoriWidgetPalette.ink(for: renderingMode))
                        .minimumScaleFactor(0.78)
                        .lineLimit(4)

                    HStack(spacing: 5) {
                        MoriWidgetIconImage(
                            icon: context.displayRecoveryPracticeIcon,
                            size: 11,
                            opacity: 0.84
                        )

                        Text(MoriL10n.string(
                            "widget.pulse.suggested",
                            defaultValue: "Suggested: %@",
                            arguments: [context.displayRecoveryPracticeTitle]
                        ))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(MoriWidgetPalette.mutedInk(for: renderingMode))
                            .lineLimit(1)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MoriWidgetCardWash(cornerRadius: 13))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(MoriWidgetPalette.outline(for: renderingMode), lineWidth: 1)
                )

                MoriWidgetCompactStat(title: "Privacy", value: "On device")
            }
        }
    }
}

struct PulseAccessoryCircularWidget: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        Gauge(value: context.recoveryProgress) {
            MoriWidgetIconImage(icon: .heart, size: 12)
        } currentValueLabel: {
            Text(context.recoveryScoreText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.62)
                .lineLimit(1)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel(MoriL10n.string(
            "widget.recovery.accessibility",
            defaultValue: "Recovery %@",
            arguments: [context.recoveryScoreText]
        ))
    }
}

struct PulseAccessoryRectangularWidget: View {
    let context: MoriWidgetContextSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(MoriL10n.display("Recovery"))
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(context.displayRecoveryDetail)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            HStack(spacing: 6) {
                Text(MoriL10n.string(
                    "recovery.widget.score",
                    defaultValue: "Recovery %@",
                    arguments: [context.recoveryScoreText]
                ))
                Text(context.displayRecoveryState)
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriL10n.string(
            "widget.recovery.accessibility",
            defaultValue: "Recovery %@. %@.",
            arguments: [context.recoveryScoreText, context.displayRecoveryState]
        ))
    }
}
