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

    @State private var showsDurationOptions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Image("MoriDeepSessionForest")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 315)
                    .clipped()
                    .scaleEffect(1.16)
                    .offset(y: -34)
                    .saturation(0.66)
                    .brightness(0.09)
                    .opacity(0.82)

                LinearGradient(
                    colors: [
                        MoriV2Palette.raisedPaper.opacity(0.20),
                        MoriV2Palette.raisedPaper.opacity(0.56),
                        MoriV2Palette.raisedPaper.opacity(0.86)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Circle()
                    .stroke(MoriV2Palette.forestInk.opacity(0.12), lineWidth: 3)
                    .frame(width: 190, height: 190)

                Circle()
                    .trim(from: 0, to: max(0.018, timerProgress))
                    .stroke(
                        MoriV2Palette.primaryForest,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 10) {
                    Text(MoriL10n.display("Quiet Session"))
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(MoriV2Palette.forestInk)

                    Text(timeText)
                        .font(.system(size: 58, weight: .regular, design: .serif))
                        .foregroundColor(MoriV2Palette.forestInk)
                        .monospacedDigit()
                        .minimumScaleFactor(0.72)

                    Text(timerStatusText)
                        .font(MoriV2Type.caption)
                        .foregroundColor(MoriV2Palette.mutedStone)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 315)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(MoriV2Palette.hairline, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)

            MoriV2PrimaryButton(
                title: primaryTimerActionTitle,
                icon: isRunning ? .pause : .play,
                action: onToggleTimer
            )

            if timerSelectionIsLocked || timerProgress > 0 {
                Button(action: onResetTimer) {
                    QuietBitmapLabel(title: "Reset", icon: .refresh, iconSize: 15)
                        .font(MoriV2Type.control)
                        .foregroundColor(MoriV2Palette.stone)
                        .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget)
                }
                .buttonStyle(MoriV2PressButtonStyle())
                .accessibilityLabel(MoriL10n.display("Reset timer"))
            }

            if !isRunning && !timerSelectionIsLocked {
                MoriV2QuietDisclosureRow(
                    title: showsDurationOptions ? "Hide session options" : "Session options",
                    subtitle: "Choose a different length only when you need it.",
                    isExpanded: showsDurationOptions,
                    action: { showsDurationOptions.toggle() }
                )

                if showsDurationOptions {
                    VStack(alignment: .leading, spacing: 14) {
                        durationControls

                        if isCustomDurationSelected {
                            customDurationPicker
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsDurationOptions)
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

            Text(MoriL10n.display("Ten minutes is a gentle place to begin."))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(MoriL10n.display("Longer pauses"))
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
                .frame(minHeight: MoriV2Layout.minimumHitTarget)
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
