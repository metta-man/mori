import SwiftUI

/// The canonical dark-forest commitment action from the approved Mori design.
/// Large primary buttons should be reserved for actions such as starting or
/// confirming a session.
struct MoriPrimaryButton: View {
    enum Style {
        case editorial
        case v2Compatibility
    }

    let title: String
    let icon: MoriBitmapIcon?
    let isEnabled: Bool
    let style: Style
    let action: () -> Void

    init(
        title: String,
        icon: MoriBitmapIcon? = nil,
        isEnabled: Bool = true,
        style: Style = .editorial,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.style = style
        self.action = action
    }

    @ViewBuilder
    var body: some View {
        switch style {
        case .editorial:
            editorialButton
        case .v2Compatibility:
            v2CompatibilityButton
        }
    }

    private var editorialButton: some View {
        Button(action: action) {
            HStack(spacing: MoriTheme.Spacing.xSmall) {
                if let icon {
                    MoriBitmapIconImage(
                        icon: icon,
                        size: 18,
                        opacity: isEnabled ? 1 : 0.46
                    )
                    .frame(width: 26, height: 26)
                    .background(
                        MoriTheme.Colors.onPrimary.opacity(isEnabled ? 0.92 : 0.42)
                    )
                    .clipShape(Circle())
                }

                Text(MoriL10n.display(title))
            }
        }
        .buttonStyle(MoriTheme.ButtonStyles.Primary())
        .disabled(!isEnabled)
        .accessibilityLabel(MoriL10n.display(title))
    }

    private var v2CompatibilityButton: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let icon {
                    MoriBitmapIconImage(
                        icon: icon,
                        size: 17,
                        opacity: isEnabled ? 0.96 : 0.46
                    )
                    .frame(width: 26, height: 26)
                    .background(
                        MoriTheme.Colors.onPrimary.opacity(isEnabled ? 0.92 : 0.42)
                    )
                    .clipShape(Circle())
                }

                Text(MoriL10n.display(title))
                    .font(MoriTheme.Typography.control)
            }
            .foregroundColor(
                isEnabled
                    ? MoriTheme.Colors.onPrimary
                    : MoriTheme.Colors.mutedText
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 18)
            .background(
                isEnabled
                    ? MoriTheme.Colors.primaryAction
                    : MoriTheme.Colors.hairline
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: MoriTheme.CornerRadius.control,
                    style: .continuous
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: MoriTheme.CornerRadius.control,
                    style: .continuous
                )
            )
        }
        .buttonStyle(MoriV2PressButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(MoriL10n.display(title))
    }
}

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
    enum Style {
        case editorial
        case watercolorCompatibility
    }

    let title: String
    let action: () -> Void
    let isEnabled: Bool
    let style: Style

    init(
        title: String,
        isEnabled: Bool = true,
        style: Style = .editorial,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
        self.style = style
    }

    @ViewBuilder
    var body: some View {
        switch style {
        case .editorial:
            editorialButton
        case .watercolorCompatibility:
            watercolorCompatibilityButton
        }
    }

    private var editorialButton: some View {
        Button(action: action) {
            Text(MoriL10n.display(title))
        }
        .buttonStyle(MoriTheme.ButtonStyles.Secondary())
        .disabled(!isEnabled)
        .accessibilityLabel(MoriL10n.display(title))
    }

    private var watercolorCompatibilityButton: some View {
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
        .accessibilityLabel(MoriL10n.display(title))
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
            .clipShape(RoundedRectangle(cornerRadius: MoriCornerRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
