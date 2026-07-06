import SwiftUI

struct PomodoroAdvancedSettingsCard: View {
    let canChangeDuration: Bool
    @Binding var focusMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var cycles: Int
    let focusBreathing: MoriPomodoroBreakBreathing
    let breakBreathing: MoriPomodoroBreakBreathing
    let isGuidedBreathing: Bool
    let activeBreathing: MoriPomodoroBreakBreathing
    let currentPhaseElapsedSeconds: Int
    let darkRoomEnabled: Bool
    let completedSummary: MindfulCompletionSummary?
    let onSelectFocusBreathing: (MoriPomodoroBreakBreathing) -> Void
    let onSelectBreakBreathing: (MoriPomodoroBreakBreathing) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MoriSectionTitle(
                title: "Advanced Settings",
                subtitle: "Fine tune the rhythm after the first screen stays calm."
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
            }

            if canChangeDuration {
                ScreenTimeLimitControls(contextTitle: "Pomodoro", feature: .pomodoroFocus)
            }

            if let completedSummary {
                mindfulCompletionBanner(completedSummary)
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
                MoriL10n.string("pomodoro.settings.focus_minutes", defaultValue: "Focus %dm", arguments: [focusMinutes]),
                value: $focusMinutes,
                in: 5...90,
                step: 5
            )
            Stepper(
                MoriL10n.string("pomodoro.settings.short_break_minutes", defaultValue: "Short break %dm", arguments: [shortBreakMinutes]),
                value: $shortBreakMinutes,
                in: 1...30,
                step: 1
            )
            Stepper(
                MoriL10n.string("pomodoro.settings.long_break_minutes", defaultValue: "Long break %dm", arguments: [longBreakMinutes]),
                value: $longBreakMinutes,
                in: 5...45,
                step: 5
            )
            Stepper(
                MoriL10n.string("pomodoro.settings.cycles", defaultValue: "Cycles %d", arguments: [cycles]),
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
