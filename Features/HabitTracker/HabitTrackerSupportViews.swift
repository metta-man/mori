import SwiftUI

struct HabitTrackerBitmapLabel: View {
    let title: String
    let icon: MoriBitmapIcon
    var iconSize: CGFloat = 16
    var iconOpacity: Double = 0.88
    var spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            MoriBitmapIconImage(icon: icon, size: iconSize, opacity: iconOpacity)

            Text(MoriL10n.display(title))
        }
    }
}

struct DailyReflectionCard: View {
    let selectedTone: HabitDayTone?
    @Binding var note: String
    let onSave: () -> Void
    let onOpenPatternLog: () -> Void

    private var titleText: String {
        if let selectedTone {
            return MoriL10n.string("habit.today_felt", defaultValue: "Today felt %@", arguments: [selectedTone.title.lowercased()])
        }

        return MoriL10n.display("How did today feel?")
    }

    private var canSave: Bool {
        selectedTone != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: titleText,
                subtitle: "A sentence is enough. Leave it blank when the tone says enough."
            )

            ZStack(alignment: .topLeading) {
                if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(MoriL10n.display("One thing I want to remember about today..."))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted.opacity(0.72))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }

                TextEditor(text: $note)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 92)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(MoriColors.botanicalPaperDeep.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoriColors.botanicalLine.opacity(0.55), lineWidth: 1)
            )

            HStack(spacing: 10) {
                Button(action: onSave) {
                    HabitTrackerBitmapLabel(
                        title: "Save daily entry",
                        icon: .leaf,
                        iconSize: 16,
                        iconOpacity: canSave ? 0.94 : 0.42
                    )
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(canSave ? MoriColors.botanicalSurface : MoriColors.botanicalMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canSave ? MoriColors.botanicalInk : MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)

                Button(action: onOpenPatternLog) {
                    MoriBitmapIconImage(icon: .pattern, size: 16, opacity: canSave ? 0.86 : 0.38)
                        .frame(width: 46, height: 46)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .accessibilityLabel(MoriL10n.display("Add pattern detail"))
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

// MARK: - Habit Button
struct HabitButton: View {
    enum ButtonType {
        case positive
        case neutral
        case negative

        var icon: MoriBitmapIcon {
            switch self {
            case .positive: return .plus
            case .neutral: return .leaf
            case .negative: return .minus
            }
        }

        var label: String {
            switch self {
            case .positive: return "Good day"
            case .neutral: return "Neutral day"
            case .negative: return "Difficult day"
            }
        }

        var color: Color {
            switch self {
            case .positive: return HabitDayTone.positive.color
            case .neutral: return HabitDayTone.neutral.color
            case .negative: return HabitDayTone.negative.color
            }
        }

        var backgroundColor: Color {
            switch self {
            case .positive: return Color(hex: "#F0F5EB")
            case .neutral: return Color(hex: "#F5F1E8")
            case .negative: return Color(hex: "#FFF5F0")
            }
        }
    }

    let type: ButtonType
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                }
                action()
            }) {
                ZStack {
                    Circle()
                        .stroke(type.color, lineWidth: 2)
                        .background(
                            Circle()
                        .fill(isSelected ? type.color : MoriColors.botanicalSurface)
                        )
                        .frame(width: 54, height: 54)

                    MoriBitmapIconImage(icon: type.icon, size: 24, opacity: isSelected ? 0.96 : 0.86)
                        .frame(width: isSelected ? 34 : 24, height: isSelected ? 34 : 24)
                        .background(isSelected ? MoriColors.botanicalSurface.opacity(0.76) : Color.clear)
                        .clipShape(Circle())
                }
                .scaleEffect(isPressed ? 1.1 : (isSelected ? 1.05 : 1.0))
                .shadow(color: isSelected ? type.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())

            Text(MoriL10n.display(type.label))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MoriColors.botanicalMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isSelected ? type.color.opacity(0.12) : MoriColors.botanicalSurface.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? type.color.opacity(0.45) : MoriColors.botanicalHairline, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    HabitTrackerView()
        .environmentObject(UserSettings())
}

extension HabitDayTone {
    var color: Color {
        switch self {
        case .positive: return MoriColors.botanicalMoss
        case .neutral: return MoriColors.botanicalSeed
        case .negative: return MoriColors.botanicalClay
        }
    }

    var mutedColor: Color {
        color.opacity(0.42)
    }

    var title: String {
        switch self {
        case .positive: return MoriL10n.display("Good")
        case .neutral: return MoriL10n.display("Neutral")
        case .negative: return MoriL10n.display("Difficult")
        }
    }

    var toastMessage: String {
        switch self {
        case .positive: return MoriL10n.display("Recorded as a good day")
        case .neutral: return MoriL10n.display("Recorded as a neutral day")
        case .negative: return MoriL10n.display("Recorded as a difficult day")
        }
    }
}
