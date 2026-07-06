import SwiftUI

struct QuietTimerCard: View {
    @Binding var customHours: Int
    @Binding var customMinutes: Int

    let selectedMinutes: Int
    let isCustomDurationSelected: Bool
    let isRunning: Bool
    let timerSelectionIsLocked: Bool
    let minuteOptions: [Int]
    let deepDetoxMinuteOptions: [Int]
    let availableCustomMinuteOptions: [Int]
    let timerProgress: CGFloat
    let timeText: String
    let timerStatusText: String
    let primaryTimerActionTitle: String
    let onSelectDuration: (Int) -> Void
    let onSelectCustomDuration: () -> Void
    let onToggleTimer: () -> Void
    let onResetTimer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MoriSectionTitle(
                title: "Detox Timer",
                subtitle: "Give your attention a small clearing before opening another feed."
            )

            durationControls

            if isCustomDurationSelected {
                customDurationPicker
            }

            ZStack {
                MoriTimerProgressRing(
                    progress: timerProgress,
                    tint: MoriColors.botanicalMoss,
                    lineWidth: 12
                )

                VStack(spacing: 4) {
                    Text(timeText)
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)
                        .monospacedDigit()

                    Text(timerStatusText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 210)

            HStack(spacing: 12) {
                Button(action: onToggleTimer) {
                    QuietBitmapLabel(
                        title: primaryTimerActionTitle,
                        icon: isRunning ? .pause : .play,
                        iconSize: 16,
                        iconOpacity: 0.94
                    )
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(MoriColors.botanicalInk)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onResetTimer) {
                    MoriBitmapIconImage(icon: .refresh, size: 17, opacity: 0.86)
                        .frame(width: 48, height: 48)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(MoriL10n.display("Reset timer"))
            }
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var durationControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(minuteOptions, id: \.self) { minutes in
                    durationButton(
                        title: "\(minutes)",
                        isSelected: !isCustomDurationSelected && selectedMinutes == minutes,
                        accessibilityLabel: MoriL10n.string("quiet.duration.accessibility_minutes", defaultValue: "%d minute quiet timer", arguments: [minutes])
                    ) {
                        onSelectDuration(minutes)
                    }
                }

                durationButton(
                    title: "Custom",
                    isSelected: isCustomDurationSelected,
                    accessibilityLabel: MoriL10n.display("Custom quiet timer duration"),
                    action: onSelectCustomDuration
                )
            }
            .opacity(timerSelectionIsLocked ? 0.58 : 1)

            Text(MoriL10n.display("10m is the recommended quick reset. Deep detox is for a longer break from feeds."))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(MoriL10n.display("Deep detox"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                HStack(spacing: 8) {
                    ForEach(deepDetoxMinuteOptions, id: \.self) { minutes in
                        durationButton(
                            title: deepDetoxLabel(for: minutes),
                            isSelected: !isCustomDurationSelected && selectedMinutes == minutes,
                            accessibilityLabel: MoriL10n.string(
                                "quiet.duration.accessibility_title",
                                defaultValue: "%@ quiet timer",
                                arguments: [MoriQuietTimerDuration.formattedTitle(minutes * 60)]
                            )
                        ) {
                            onSelectDuration(minutes)
                        }
                    }
                }
                .opacity(timerSelectionIsLocked ? 0.58 : 1)
            }
        }
    }

    private func durationButton(
        title: String,
        isSelected: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(MoriL10n.display(title))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? MoriColors.botanicalSurface : MoriColors.botanicalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? MoriColors.botanicalInk : MoriColors.botanicalInk.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(timerSelectionIsLocked)
        .accessibilityLabel(accessibilityLabel)
    }

    private var customDurationPicker: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Picker(MoriL10n.display("Hours"), selection: $customHours) {
                    ForEach(0...72, id: \.self) { hour in
                        Text(MoriL10n.string("duration.hours_short", defaultValue: "%dh", arguments: [hour])).tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 118)
                .clipped()

                Text(MoriL10n.display("hours"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)
            }

            VStack(spacing: 4) {
                Picker(MoriL10n.display("Minutes"), selection: $customMinutes) {
                    ForEach(availableCustomMinuteOptions, id: \.self) { minute in
                        Text(MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [minute])).tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 118)
                .clipped()

                Text(MoriL10n.display("minutes"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(MoriColors.botanicalInk.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .disabled(timerSelectionIsLocked)
        .opacity(timerSelectionIsLocked ? 0.55 : 1)
    }

    private func deepDetoxLabel(for minutes: Int) -> String {
        if minutes >= 24 * 60 {
            return "\(minutes / (24 * 60))d"
        }
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }
}
