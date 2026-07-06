import SwiftUI

struct MoriButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            Text(MoriL10n.display(title))
                .font(MoriTypography.body.weight(.semibold))
                .foregroundColor(isEnabled ? MoriColors.sanctuarySurface : MoriColors.botanicalMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MoriSpacing.buttonVertical)
                .background(
                    Group {
                        if isEnabled {
                            MoriGeneratedArtImage(art: .buttonWash, contentMode: .fill)
                                .overlay(MoriColors.botanicalInk.opacity(0.08))
                        } else {
                            MoriColors.botanicalLine.opacity(0.72)
                        }
                    }
                )
                .cornerRadius(MoriCornerRadius.button)
        }
        .buttonStyle(MoriPressScaleButtonStyle())
        .disabled(!isEnabled)
    }
}

struct MoriSecondaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            Text(MoriL10n.display(title))
                .font(MoriTypography.body.weight(.medium))
                .foregroundColor(isEnabled ? MoriColors.botanicalInk : MoriColors.botanicalMuted.opacity(0.65))
                .frame(maxWidth: .infinity)
                .padding(.vertical, MoriSpacing.buttonVertical)
                .background(
                    MoriPlainWatercolorCardBackground(
                        cornerRadius: MoriCornerRadius.button,
                        fill: MoriColors.sanctuarySurface.opacity(isEnabled ? 0.76 : 0.88),
                        paperOpacity: isEnabled ? 0.07 : 0.04,
                        edgeOpacity: isEnabled ? 0.04 : 0.02
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: MoriCornerRadius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: MoriCornerRadius.button)
                        .stroke(
                            isEnabled ? MoriColors.botanicalLine : MoriColors.botanicalLine.opacity(0.5),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(MoriPressScaleButtonStyle())
        .disabled(!isEnabled)
    }
}

struct MoriIconButton: View {
    let icon: MoriBitmapIcon
    let action: () -> Void
    var size: CGFloat = 44
    var iconSize: CGFloat = 24
    var isActive: Bool = false

    init(
        icon: MoriBitmapIcon,
        size: CGFloat = 44,
        iconSize: CGFloat = 24,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.iconSize = iconSize
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            MoriBitmapIconImage(
                icon: icon,
                size: iconSize,
                opacity: isActive ? 0.92 : 0.54
            )
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isActive ? MoriColors.botanicalMoss.opacity(0.14) : Color.clear)
                )
        }
        .buttonStyle(MoriPressScaleButtonStyle(pressedScale: 0.9))
    }
}

struct MoriHabitButton: View {
    let isDone: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MoriBitmapIconImage(icon: isDone ? .leaf : .minus, size: 32, opacity: 0.92)
        }
        .buttonStyle(MoriPressScaleButtonStyle(pressedScale: 0.9))
    }
}

private struct MoriPressScaleButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = MoriAnimation.buttonTapScale

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(MoriAnimation.fast, value: configuration.isPressed)
    }
}

struct MoriSanctuaryPrimaryButton: View {
    let title: String
    let icon: MoriBitmapIcon
    let isEnabled: Bool
    let action: () -> Void

    init(
        title: String,
        icon: MoriBitmapIcon,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                MoriBitmapIconImage(
                    icon: icon,
                    size: 16,
                    opacity: isEnabled ? 0.94 : 0.42
                )
                Text(MoriL10n.display(title))
            }
            .font(MoriTypography.callout.weight(.semibold))
            .foregroundColor(isEnabled ? MoriColors.sanctuarySurface : MoriColors.sanctuaryMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isEnabled {
                        MoriGeneratedArtImage(art: .buttonWash, contentMode: .fill)
                            .overlay(MoriColors.sanctuaryInk.opacity(0.15))
                    } else {
                        MoriColors.sanctuaryInk.opacity(0.08)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
