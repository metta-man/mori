import SwiftUI

struct PomodoroAdvancedSettingsCard: View {
    let canChangeDuration: Bool
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var animationEnabled: Bool
    @Binding var darkRoomEnabled: Bool
    let focusBreathing: MoriPomodoroBreakBreathing
    let breakBreathing: MoriPomodoroBreakBreathing
    let isGuidedBreathing: Bool
    let activeBreathing: MoriPomodoroBreakBreathing
    let currentPhaseElapsedSeconds: Int
    let onSelectFocusBreathing: (MoriPomodoroBreakBreathing) -> Void
    let onSelectBreakBreathing: (MoriPomodoroBreakBreathing) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PomodoroBreathingCue(
                isGuidedBreathing: isGuidedBreathing,
                activeBreathing: activeBreathing,
                currentPhaseElapsedSeconds: currentPhaseElapsedSeconds,
                darkRoomEnabled: darkRoomEnabled
            )

            if canChangeDuration {
                PomodoroSettingsSection(
                    focusBreathing: focusBreathing,
                    breakBreathing: breakBreathing,
                    onSelectFocusBreathing: onSelectFocusBreathing,
                    onSelectBreakBreathing: onSelectBreakBreathing
                )

                PomodoroSessionCueSettings(
                    soundEnabled: $soundEnabled,
                    hapticsEnabled: $hapticsEnabled,
                    animationEnabled: $animationEnabled,
                    darkRoomEnabled: $darkRoomEnabled
                )

                ScreenTimeLimitControls(contextTitle: "Deep Session", feature: .pomodoroFocus)
            } else if !isGuidedBreathing {
                Text(MoriL10n.display("Timing is locked while the session is active."))
                    .font(MoriV2Type.supporting)
                    .foregroundColor(MoriV2Palette.stone)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
        }
    }
}

private struct PomodoroSettingsSection: View {
    let focusBreathing: MoriPomodoroBreakBreathing
    let breakBreathing: MoriPomodoroBreakBreathing
    let onSelectFocusBreathing: (MoriPomodoroBreakBreathing) -> Void
    let onSelectBreakBreathing: (MoriPomodoroBreakBreathing) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PomodoroSettingsSectionHeader(
                title: "Breathing cues",
                subtitle: "Optional guidance for focus and pauses."
            )

            VStack(spacing: 0) {
                PomodoroBreathingPicker(
                    title: "Focus breathing",
                    selection: focusBreathing,
                    tint: MoriColors.botanicalInk,
                    onSelect: onSelectFocusBreathing
                )

                Divider()
                    .overlay(MoriV2Palette.hairline)
                    .padding(.leading, 58)

                PomodoroBreathingPicker(
                    title: "Break breathing",
                    selection: breakBreathing,
                    tint: MoriColors.botanicalMoss,
                    onSelect: onSelectBreakBreathing
                )
            }
            .background(MoriV2Palette.raisedPaper.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MoriV2Palette.hairline, lineWidth: 1)
            }
        }
    }
}

private struct PomodoroSessionCueSettings: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var animationEnabled: Bool
    @Binding var darkRoomEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PomodoroSettingsSectionHeader(
                title: "Session cues",
                subtitle: "Keep only the signals that help."
            )

            VStack(spacing: 0) {
                quietToggle("Sound cues", isOn: $soundEnabled)
                rowDivider
                quietToggle("Haptic cues", isOn: $hapticsEnabled)
                rowDivider
                quietToggle("Forest movement", isOn: $animationEnabled)
                rowDivider
                quietToggle("Dark room", isOn: $darkRoomEnabled)
            }
            .padding(.horizontal, 14)
            .background(MoriV2Palette.raisedPaper.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MoriV2Palette.hairline, lineWidth: 1)
            }
        }
    }

    private func quietToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(MoriL10n.display(title))
                .font(MoriV2Type.supporting)
                .foregroundColor(MoriV2Palette.forestInk)
        }
        .tint(MoriV2Palette.primaryForest)
        .frame(minHeight: 52)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(MoriV2Palette.hairline)
    }
}

private struct PomodoroBreathingPicker: View {
    let title: String
    let selection: MoriPomodoroBreakBreathing
    let tint: Color
    let onSelect: (MoriPomodoroBreakBreathing) -> Void

    var body: some View {
        Menu {
            ForEach(MoriPomodoroBreakBreathing.allCases) { option in
                Button {
                    onSelect(option)
                } label: {
                    if selection == option {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                MoriBitmapIconImage(icon: selection.icon, size: 17, opacity: 0.80)
                    .frame(width: 32, height: 32)
                    .background((selection.hasTechnique ? selection.tint : tint).opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(MoriL10n.display(title))
                        .font(MoriV2Type.supporting.weight(.semibold))
                        .foregroundColor(MoriV2Palette.forestInk)

                    Text(selection.title)
                        .font(MoriV2Type.caption)
                        .foregroundColor(MoriV2Palette.stone)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                MoriBitmapIconImage(icon: .chevron, size: 11, opacity: 0.58)
                    .frame(width: 32, height: 44)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display(title))
        .accessibilityValue(selection.title)
    }
}

struct PomodoroSettingsSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(MoriL10n.display(title))
                .font(MoriV2Type.caption.weight(.semibold))
                .foregroundColor(MoriV2Palette.forestInk)

            Text(MoriL10n.display(subtitle))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriV2Palette.stone)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PomodoroBreathingCue: View {
    let isGuidedBreathing: Bool
    let activeBreathing: MoriPomodoroBreakBreathing
    let currentPhaseElapsedSeconds: Int
    let darkRoomEnabled: Bool

    var body: some View {
        if isGuidedBreathing {
            let state = activeBreathing.visualState(at: TimeInterval(currentPhaseElapsedSeconds))
            HStack(alignment: .center, spacing: 12) {
                MoriBitmapIconImage(icon: activeBreathing.icon, size: 18, opacity: darkRoomEnabled ? 0.72 : 0.86)
                    .frame(width: 36, height: 36)
                    .background(darkRoomEnabled ? Color.white.opacity(0.10) : activeBreathing.tint.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(state.label)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(activePrimaryColor)

                    Text(MoriL10n.string(
                        "pomodoro.break_breathing.summary",
                        defaultValue: "%@ · %@",
                        arguments: [MoriL10n.display(activeBreathing.title), activeBreathing.timingDescription]
                    ))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(activeSecondaryColor)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .background(darkRoomEnabled ? Color.white.opacity(0.08) : activeBreathing.tint.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(darkRoomEnabled ? Color.white.opacity(0.10) : MoriV2Palette.hairline, lineWidth: 1)
            }
        }
    }

    private var activePrimaryColor: Color {
        darkRoomEnabled ? .white.opacity(0.92) : MoriColors.botanicalInk
    }

    private var activeSecondaryColor: Color {
        darkRoomEnabled ? .white.opacity(0.62) : MoriColors.botanicalMuted
    }
}
