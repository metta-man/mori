import SwiftUI

struct PomodoroSetupHeroVisual: View {
    let phase: MoriPomodoroPhase
    let progress: CGFloat
    let timeText: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(MoriV2Palette.forestInk.opacity(0.13), lineWidth: 4)
                .frame(width: 242, height: 242)

            Circle()
                .trim(from: 0, to: max(0.018, progress))
                .stroke(
                    MoriV2Palette.primaryForest,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 242, height: 242)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 8) {
                Text(timeText)
                    .font(.system(size: 62, weight: .regular, design: .serif))
                    .foregroundColor(MoriV2Palette.forestInk)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(MoriL10n.display(quietPhaseTitle))
                    .font(MoriV2Type.supporting)
                    .foregroundColor(MoriV2Palette.stone)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 270)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriL10n.string(
            "deep_session.timer.accessibility",
            defaultValue: "Deep Session, %@, %@",
            arguments: [timeText, quietPhaseTitle]
        ))
    }

    private var quietPhaseTitle: String {
        switch phase {
        case .focus:
            return "Stay in the forest"
        case .shortBreak:
            return "Quiet pause"
        case .longBreak:
            return "Long pause"
        case .completed:
            return "Session complete"
        }
    }
}

struct PomodoroFocusCycleRows: View {
    let selectedPhase: MoriPomodoroPhase
    @Binding var focusMinutes: Int
    @Binding var shortBreakMinutes: Int
    @Binding var longBreakMinutes: Int
    @Binding var cycles: Int
    let canChangeDuration: Bool
    let onSelectPhase: (MoriPomodoroPhase) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PomodoroSettingsSectionHeader(
                title: "Session rhythm",
                subtitle: "Choose a starting phase, timing, and repeats."
            )

            VStack(spacing: 0) {
                phaseRow(
                    title: "Deep Session",
                    valueLabel: MoriL10n.string(
                        "deep_session.settings.focus_minutes",
                        defaultValue: "%d quiet minutes",
                        arguments: [focusMinutes]
                    ),
                    phase: .focus,
                    value: $focusMinutes,
                    range: 5...90,
                    step: 5
                )

                rowDivider

                phaseRow(
                    title: "Quiet pause",
                    valueLabel: MoriL10n.string(
                        "deep_session.settings.short_break_minutes",
                        defaultValue: "%d minutes",
                        arguments: [shortBreakMinutes]
                    ),
                    phase: .shortBreak,
                    value: $shortBreakMinutes,
                    range: 1...30,
                    step: 1
                )

                rowDivider

                phaseRow(
                    title: "Long pause",
                    valueLabel: MoriL10n.string(
                        "deep_session.settings.long_break_minutes",
                        defaultValue: "%d minutes",
                        arguments: [longBreakMinutes]
                    ),
                    phase: .longBreak,
                    value: $longBreakMinutes,
                    range: 5...45,
                    step: 5
                )

                rowDivider

                repeatsRow
            }
            .background(MoriV2Palette.raisedPaper.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MoriV2Palette.hairline, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func phaseRow(
        title: String,
        valueLabel: String,
        phase: MoriPomodoroPhase,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        let isSelected = selectedPhase == phase

        return HStack(spacing: 8) {
            Button {
                onSelectPhase(phase)
            } label: {
                HStack(spacing: 11) {
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? MoriV2Palette.primaryForest : MoriV2Palette.hairline,
                                lineWidth: 1.5
                            )

                        if isSelected {
                            Circle()
                                .fill(MoriV2Palette.primaryForest)
                                .padding(4)
                        }
                    }
                    .frame(width: 20, height: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(MoriL10n.display(title))
                            .font(MoriV2Type.control)
                            .foregroundColor(MoriV2Palette.forestInk)

                        Text(valueLabel)
                            .font(MoriV2Type.caption)
                            .foregroundColor(MoriV2Palette.stone)
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canChangeDuration)
            .accessibilityLabel(MoriL10n.string(
                "deep_session.phase.accessibility",
                defaultValue: "Start with %@",
                arguments: [MoriL10n.display(title)]
            ))
            .accessibilityValue(isSelected ? MoriL10n.display("Selected") : valueLabel)

            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
                .disabled(!canChangeDuration)
                .accessibilityLabel(MoriL10n.string(
                    "deep_session.duration.accessibility",
                    defaultValue: "%@ duration",
                    arguments: [MoriL10n.display(title)]
                ))
                .accessibilityValue(valueLabel)
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .background(isSelected ? MoriV2Palette.sage.opacity(0.10) : Color.clear)
    }

    private var repeatsRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 11) {
                MoriBitmapIconImage(icon: .roots, size: 17, opacity: 0.70)
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(MoriL10n.display("Repeats"))
                        .font(MoriV2Type.control)
                        .foregroundColor(MoriV2Palette.forestInk)

                    Text(MoriL10n.string(
                        "deep_session.settings.repeats",
                        defaultValue: "%d sessions",
                        arguments: [cycles]
                    ))
                    .font(MoriV2Type.caption)
                    .foregroundColor(MoriV2Palette.stone)
                    .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)

            Stepper("", value: $cycles, in: 1...8, step: 1)
                .labelsHidden()
                .disabled(!canChangeDuration)
                .accessibilityLabel(MoriL10n.display("Repeats"))
                .accessibilityValue("\(cycles)")
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(MoriV2Palette.hairline)
            .padding(.leading, 45)
    }
}

struct PomodoroSetupStartButton: View {
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                MoriBitmapIconImage(icon: .play, size: 16, opacity: 0.94)
                    .frame(width: 24, height: 24)
                    .background(MoriColors.sanctuarySurface.opacity(0.86))
                    .clipShape(Circle())

                Text(MoriL10n.display(isCompleted ? "Begin again" : "Start Deep Session"))
            }
            .font(MoriV2Type.control)
            .foregroundColor(MoriColors.botanicalSurface)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal, 16)
            .background(MoriColors.botanicalInk)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
