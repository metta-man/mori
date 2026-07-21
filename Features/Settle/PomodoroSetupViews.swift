import SwiftUI

struct PomodoroSetupHeroVisual: View {
    let phase: MoriPomodoroPhase
    let progress: CGFloat
    let timeText: String

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(MoriV2Palette.raisedPaper)

                Image("MoriDeepSessionForest")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.92)

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
                .padding(.bottom, 28)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 248)
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(MoriV2Palette.hairline, lineWidth: 1)
        }
        .shadow(color: MoriV2Palette.shadow, radius: 20, x: 0, y: 10)
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
    let focusMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let cycles: Int
    let canChangeDuration: Bool
    let onSelectPhase: (MoriPomodoroPhase) -> Void

    var body: some View {
        VStack(spacing: 8) {
            row(
                title: "Deep Session",
                subtitle: MoriL10n.string("deep_session.settings.focus_minutes", defaultValue: "%d quiet minutes", arguments: [focusMinutes]),
                icon: .timer,
                tint: MoriColors.botanicalInk,
                isSelected: selectedPhase == .focus
            ) {
                onSelectPhase(.focus)
            }

            row(
                title: "Quiet pause",
                subtitle: MoriL10n.string("deep_session.settings.short_break_minutes", defaultValue: "%d minutes", arguments: [shortBreakMinutes]),
                icon: .leaf,
                tint: MoriColors.botanicalMist,
                isSelected: selectedPhase == .shortBreak
            ) {
                onSelectPhase(.shortBreak)
            }

            row(
                title: "Long pause",
                subtitle: MoriL10n.string("deep_session.settings.long_break_minutes", defaultValue: "%d minutes", arguments: [longBreakMinutes]),
                icon: .focus,
                tint: MoriColors.botanicalSeed,
                isSelected: selectedPhase == .longBreak
            ) {
                onSelectPhase(.longBreak)
            }

            row(
                title: "Repeats",
                subtitle: MoriL10n.string("deep_session.settings.repeats", defaultValue: "%d session", arguments: [cycles]),
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

                Text(MoriL10n.display(isCompleted ? "Begin again" : "Start Deep Session"))
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
