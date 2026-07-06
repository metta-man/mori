import SwiftUI

struct PomodoroSetupHeroVisual: View {
    let phase: MoriPomodoroPhase
    let progress: CGFloat
    let timeText: String

    var body: some View {
        ZStack {
            MoriWatercolorHeroWash(variant: .today, placement: .corner)
                .clipShape(Circle())
                .frame(width: 218, height: 218)
                .opacity(0.94)
                .shadow(color: MoriColors.sanctuaryShadow.opacity(0.18), radius: 28, x: 0, y: 16)

            Circle()
                .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                .frame(width: 202, height: 202)

            MoriTimerProgressRing(
                progress: progress,
                tint: phase.tint,
                trackTint: Color.white.opacity(0.58),
                lineWidth: 9
            )
            .frame(width: 196, height: 196)

            VStack(spacing: 8) {
                MoriBitmapIconBadge(
                    icon: phase.icon,
                    size: 42,
                    iconScale: 0.50,
                    fill: MoriColors.sanctuarySurface.opacity(0.50),
                    stroke: Color.white.opacity(0.74),
                    shadow: .clear
                )

                Text(timeText)
                    .font(.system(size: 56, weight: .regular, design: .rounded))
                    .foregroundColor(MoriColors.sanctuaryInk)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(phase.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(phase.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 224)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(MoriL10n.string(
            "pomodoro.timer.accessibility",
            defaultValue: "Pomodoro timer %@, %@",
            arguments: [timeText, phase.title]
        ))
    }
}

struct PomodoroFocusCycleRows: View {
    let selectedPhase: MoriPomodoroPhase
    let focusMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let cycles: Int
    let canChangeDuration: Bool
    let onSelectPhase: (MoriPomodoroPhase) -> Void

    var body: some View {
        VStack(spacing: 8) {
            row(
                title: "Focus",
                subtitle: MoriL10n.string("pomodoro.settings.focus_minutes", defaultValue: "Focus %dm", arguments: [focusMinutes]),
                icon: .timer,
                tint: MoriColors.botanicalInk,
                isSelected: selectedPhase == .focus
            ) {
                onSelectPhase(.focus)
            }

            row(
                title: "Short Break",
                subtitle: MoriL10n.string("pomodoro.settings.short_break_minutes", defaultValue: "Short break %dm", arguments: [shortBreakMinutes]),
                icon: .leaf,
                tint: MoriColors.botanicalMist,
                isSelected: selectedPhase == .shortBreak
            ) {
                onSelectPhase(.shortBreak)
            }

            row(
                title: "Long Break",
                subtitle: MoriL10n.string("pomodoro.settings.long_break_minutes", defaultValue: "Long break %dm", arguments: [longBreakMinutes]),
                icon: .focus,
                tint: MoriColors.botanicalSeed,
                isSelected: selectedPhase == .longBreak
            ) {
                onSelectPhase(.longBreak)
            }

            row(
                title: "Cycles",
                subtitle: MoriL10n.string("pomodoro.settings.cycles", defaultValue: "Cycles %d", arguments: [cycles]),
                icon: .roots,
                tint: MoriColors.botanicalMoss,
                isSelected: false
            ) {
                onSelectPhase(.focus)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func row(
        title: String,
        subtitle: String,
        icon: MoriBitmapIcon,
        tint: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            OrganicCard(
                fill: MoriColors.sanctuarySurface.opacity(isSelected ? 0.78 : 0.68),
                radius: 22,
                padding: 6
            ) {
                ZStack(alignment: .trailing) {
                    HStack(spacing: 10) {
                        MoriBitmapIconImage(icon: icon, size: 20, opacity: isSelected ? 0.88 : 0.54)
                            .frame(width: 40, height: 40)
                            .background(MoriColors.sanctuarySurface.opacity(0.58))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.72), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(MoriL10n.display(title))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(MoriColors.sanctuaryInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.76)

                            Text(MoriL10n.display(subtitle))
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(MoriColors.sanctuaryMuted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 30)
                    }

                    MoriBitmapIconImage(icon: .chevron, size: 11, opacity: 0.62)
                        .frame(width: 26, height: 26)
                        .background(MoriColors.sanctuarySurface.opacity(0.60))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 42)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.48) : Color.clear, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canChangeDuration)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(MoriL10n.display(title)). \(MoriL10n.display(subtitle))")
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

                Text(MoriL10n.display(isCompleted ? "Begin again" : "Start"))
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
}
