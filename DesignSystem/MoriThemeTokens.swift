//
//  MoriThemeTokens.swift
//  Mori
//
//  Theme-specific color and typography aliases layered on the core design tokens.
//

import SwiftUI

// MARK: - Mori Editorial Theme

/// Canonical semantic tokens for Mori's warm-paper, editorial visual language.
enum MoriTheme {
    /// A reusable SwiftUI shadow recipe.
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }

    enum Typography {
        static let pageTitle = Font.system(.largeTitle, design: .serif, weight: .regular)
        static let detailTitle = Font.system(.title, design: .serif, weight: .regular)
        static let sectionTitle = Font.system(.title3, design: .serif, weight: .regular)
        static let cardTitle = Font.system(.title, design: .serif, weight: .regular)
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let supporting = Font.system(.subheadline, design: .default, weight: .regular)
        static let control = Font.system(.body, design: .default, weight: .semibold)
        static let caption = Font.system(.caption, design: .default, weight: .medium)
        static let micro = Font.system(.caption2, design: .default, weight: .medium)
        static let metric = Font.system(.largeTitle, design: .serif, weight: .light)
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 32
        static let section: CGFloat = 26
        static let screenEdge: CGFloat = 21
        static let cardPadding: CGFloat = 20
        static let minimumHitTarget: CGFloat = 44
    }

    enum CornerRadius {
        static let small: CGFloat = 10
        static let control: CGFloat = 16
        static let card: CGFloat = 24
        static let floatingPanel: CGFloat = 22
        static let bottomSheet: CGFloat = 28
        static let calendarCell: CGFloat = 10
    }

    enum Colors {
        static let paper = Color(hex: "#F7F1E7")
        static let raisedPaper = Color(hex: "#FBF7EF")
        static let ink = Color(hex: "#203C33")
        static let primaryAction = Color(hex: "#21493C")
        static let secondaryText = Color(hex: "#4D5650")
        static let mutedText = Color(hex: "#69716C")
        static let sage = Color(hex: "#728478")
        static let moss = Color(hex: "#687E5E")
        static let mist = Color(hex: "#82929A")
        static let ochre = Color(hex: "#D8B86F")
        static let rose = Color(hex: "#B9856D")
        static let line = Color(hex: "#DDD6C8")
        static let hairline = ink.opacity(0.14)
        static let shadow = ink.opacity(0.08)
        static let scrim = ink.opacity(0.38)
        static let onPrimary = Color(hex: "#FFFAF1")

        static let good = sage
        static let neutral = ochre
        static let difficult = rose
        static let noEntry = Color(hex: "#E6E1D8")
    }

    enum Shadows {
        static let card = Shadow(color: Colors.shadow, radius: 18, x: 0, y: 10)
        static let floatingPanel = Shadow(color: Colors.shadow, radius: 16, x: 0, y: 8)
        static let button = Shadow(color: Colors.shadow, radius: 10, x: 0, y: 5)
        static let sheet = Shadow(color: Colors.shadow, radius: 24, x: 0, y: -8)
    }

    enum Animation {
        static let standard = SwiftUI.Animation.easeOut(duration: 0.30)
        static let control = SwiftUI.Animation.easeOut(duration: 0.26)
        static let screen = SwiftUI.Animation.easeOut(duration: 0.46)
        static let disclosure = SwiftUI.Animation.easeInOut(duration: 0.36)
        static let ambient = SwiftUI.Animation.easeInOut(duration: 22).repeatForever(autoreverses: true)
        static let pressScale: CGFloat = 0.982
    }

    enum IllustrationSpacing {
        /// Positive bleed magnitudes; negate at a padding call site when extending art past an edge.
        static let edgeBleed: CGFloat = 24
        static let bottomBleed: CGFloat = 32
        static let textClearance: CGFloat = 96
        static let modeCardHeight: CGFloat = 164
        static let pageLandscapeHeightRatio: CGFloat = 0.44
        static let gridLandscapeHeight: CGFloat = 152
    }

    enum ButtonStyles {
        struct Primary: ButtonStyle {
            @Environment(\.accessibilityReduceMotion) private var reduceMotion
            @Environment(\.isEnabled) private var isEnabled

            init() {}

            func makeBody(configuration: Configuration) -> some View {
                let shadow = MoriTheme.Shadows.button

                configuration.label
                    .font(MoriTheme.Typography.control)
                    .foregroundColor(isEnabled ? MoriTheme.Colors.onPrimary : MoriTheme.Colors.mutedText)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .padding(.horizontal, MoriTheme.Spacing.medium)
                    .background(isEnabled ? MoriTheme.Colors.primaryAction : MoriTheme.Colors.hairline)
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
                    .shadow(
                        color: isEnabled ? shadow.color : .clear,
                        radius: shadow.radius,
                        x: shadow.x,
                        y: shadow.y
                    )
                    .scaleEffect(
                        reduceMotion || !configuration.isPressed
                            ? 1
                            : MoriTheme.Animation.pressScale
                    )
                    .opacity(configuration.isPressed ? 0.90 : 1)
                    .animation(
                        reduceMotion ? nil : MoriTheme.Animation.control,
                        value: configuration.isPressed
                    )
            }
        }

        struct Secondary: ButtonStyle {
            @Environment(\.accessibilityReduceMotion) private var reduceMotion
            @Environment(\.isEnabled) private var isEnabled

            init() {}

            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .font(MoriTheme.Typography.control)
                    .foregroundColor(isEnabled ? MoriTheme.Colors.ink : MoriTheme.Colors.mutedText)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .padding(.horizontal, MoriTheme.Spacing.medium)
                    .background(MoriTheme.Colors.raisedPaper.opacity(isEnabled ? 1 : 0.58))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: MoriTheme.CornerRadius.control,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: MoriTheme.CornerRadius.control,
                            style: .continuous
                        )
                        .stroke(
                            isEnabled ? MoriTheme.Colors.line : MoriTheme.Colors.hairline,
                            lineWidth: 1
                        )
                    )
                    .contentShape(
                        RoundedRectangle(
                            cornerRadius: MoriTheme.CornerRadius.control,
                            style: .continuous
                        )
                    )
                    .scaleEffect(
                        reduceMotion || !configuration.isPressed
                            ? 1
                            : MoriTheme.Animation.pressScale
                    )
                    .opacity(configuration.isPressed ? 0.88 : 1)
                    .animation(
                        reduceMotion ? nil : MoriTheme.Animation.control,
                        value: configuration.isPressed
                    )
            }
        }
    }
}

// MARK: - App-specific Colors (Today / Weeks)
extension MoriColors {
    /// Main background for app
    static let background = sanctuaryPaper

    /// Card background
    static let cardBackground = sanctuarySurface

    /// Primary text
    static let text = sanctuaryInk

    /// Secondary text
    static let secondary = sanctuaryMuted

    /// Primary accent
    static let primary = sanctuaryInk

    /// Accent for the current week
    static let accent = sanctuarySage

    /// Filled dot (past weeks)
    static let filledDot = sanctuaryInk.opacity(0.6)

    /// Empty dot (future weeks)
    static let emptyDot = sanctuaryLine
}

// MARK: - Botanical Watercolor Semantic Palette
extension MoriColors {
    /// Watercolor paper used by full-screen app surfaces.
    static let botanicalPaper = sanctuaryPaper
    static let botanicalPaperDeep = sanctuaryPaperWarm
    static let botanicalSurface = sanctuarySurface
    static let botanicalCream = Color(hex: "#FFF8EA")

    /// Botanical ink for text, controls, and selected states.
    static let botanicalInk = sanctuaryInk
    static let botanicalInkSoft = sanctuaryInkSoft
    static let botanicalMuted = sanctuaryMuted

    /// Watercolor accent washes.
    static let botanicalMoss = Color(hex: "#687E5E")
    static let botanicalFern = sanctuaryFern
    static let botanicalSage = Color(hex: "#A8B5A0")
    static let botanicalMist = Color(hex: "#82929A")
    static let botanicalMistSoft = Color(hex: "#DCE5E4")
    static let botanicalSeed = Color(hex: "#D8B86F")
    static let botanicalClay = Color(hex: "#B9856D")
    static let botanicalRoot = sanctuaryRoot

    /// Lines and shadows tuned for premium watercolor paper.
    static let botanicalLine = sanctuaryLine
    static let botanicalHairline = sanctuaryHairline
    static let botanicalShadow = sanctuaryShadow
}

extension MoriTypography {
    static let sanctuaryDisplay = Font.system(.largeTitle, design: .serif, weight: .regular)
    static let sanctuaryRootTitle = Font.system(.title, design: .serif, weight: .regular)
    static let sanctuaryTitle = Font.system(.title, design: .serif, weight: .regular)
    static let sanctuarySection = Font.system(.title3, design: .serif, weight: .regular)
    static let sanctuaryMetric = Font.system(.largeTitle, design: .serif, weight: .light)
    static let sanctuaryBody = Font.system(.body, design: .default, weight: .regular)
    static let sanctuaryCaption = Font.system(.caption, design: .default, weight: .medium)
}
