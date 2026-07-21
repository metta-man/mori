import SwiftUI

struct PomodoroAdvancedSettingsCard: View {
    let canChangeDuration: Bool
    @Binding var focusMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var cycles: Int
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
            MoriSectionTitle(
                title: "Session settings",
                subtitle: "Choose only what helps the room feel quieter."
            )

            PomodoroBreathingCue(
                isGuidedBreathing: isGuidedBreathing,
                activeBreathing: activeBreathing,
                currentPhaseElapsedSeconds: currentPhaseElapsedSeconds,
                darkRoomEnabled: darkRoomEnabled
            )

            if canChangeDuration {
                PomodoroSettingsSection(
                    focusMinutes: $focusMinutes,
                    shortBreakMinutes: $shortBreakMinutes,
                    longBreakMinutes: $longBreakMinutes,
                    cycles: $cycles,
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
            }

            if canChangeDuration {
                ScreenTimeLimitControls(contextTitle: "Deep Session", feature: .pomodoroFocus)
            }
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }
}

private struct PomodoroSettingsSection: View {
    @Binding var focusMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var cycles: Int
    let focusBreathing: MoriPomodoroBreakBreathing
    let breakBreathing: MoriPomodoroBreakBreathing
    let onSelectFocusBreathing: (MoriPomodoroBreakBreathing) -> Void
    let onSelectBreakBreathing: (MoriPomodoroBreakBreathing) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Stepper(
                MoriL10n.string("deep_session.settings.focus_minutes", defaultValue: "Deep Session %dm", arguments: [focusMinutes]),
                value: $focusMinutes,
                in: 5...90,
                step: 5
            )
            Stepper(
                MoriL10n.string("deep_session.settings.short_break_minutes", defaultValue: "Quiet pause %dm", arguments: [shortBreakMinutes]),
                value: $shortBreakMinutes,
                in: 1...30,
                step: 1
            )
            Stepper(
                MoriL10n.string("deep_session.settings.long_break_minutes", defaultValue: "Long pause %dm", arguments: [longBreakMinutes]),
                value: $longBreakMinutes,
                in: 5...45,
                step: 5
            )
            Stepper(
                MoriL10n.string("deep_session.settings.repeats", defaultValue: "Repeats %d", arguments: [cycles]),
                value: $cycles,
                in: 1...8,
                step: 1
            )

            PomodoroBreathingPicker(
                title: "Focus breathing",
                selection: focusBreathing,
                tint: MoriColors.botanicalInk,
                onSelect: onSelectFocusBreathing
            )

            PomodoroBreathingPicker(
                title: "Break breathing",
                selection: breakBreathing,
                tint: MoriColors.botanicalMoss,
                onSelect: onSelectBreakBreathing
            )
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(MoriColors.botanicalInk)
        .padding(14)
        .background(MoriColors.botanicalPaperDeep.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct PomodoroSessionCueSettings: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Binding var animationEnabled: Bool
    @Binding var darkRoomEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            quietToggle("Sound cues", isOn: $soundEnabled)
            Divider().opacity(0.42)
            quietToggle("Haptic cues", isOn: $hapticsEnabled)
            Divider().opacity(0.42)
            quietToggle("Forest movement", isOn: $animationEnabled)
            Divider().opacity(0.42)
            quietToggle("Dark room", isOn: $darkRoomEnabled)
        }
        .padding(.horizontal, 14)
        .background(MoriV2Palette.raisedPaper.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(MoriV2Palette.hairline, lineWidth: 1)
        }
    }

    private func quietToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(MoriL10n.display(title))
                .font(MoriV2Type.supporting)
                .foregroundColor(MoriV2Palette.forestInk)
        }
        .tint(MoriV2Palette.primaryForest)
        .frame(minHeight: MoriV2Layout.minimumHitTarget)
    }
}

private struct PomodoroBreathingPicker: View {
    let title: String
    let selection: MoriPomodoroBreakBreathing
    let tint: Color
    let onSelect: (MoriPomodoroBreakBreathing) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(MoriL10n.display(title))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)

            FlowLayout(spacing: 8) {
                ForEach(MoriPomodoroBreakBreathing.allCases) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        MoriPill(
                            title: option.title,
                            icon: option.icon,
                            isSelected: selection == option,
                            tint: option.hasTechnique ? option.tint : tint
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
            .padding(12)
            .background(darkRoomEnabled ? Color.white.opacity(0.08) : activeBreathing.tint.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var activePrimaryColor: Color {
        darkRoomEnabled ? .white.opacity(0.92) : MoriColors.botanicalInk
    }

    private var activeSecondaryColor: Color {
        darkRoomEnabled ? .white.opacity(0.62) : MoriColors.botanicalMuted
    }
}
