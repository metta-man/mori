//
//  MoriDesignTokens.swift
//  Mori
//
//  Botanical watercolor design tokens.
//  Core Principle: quiet focus on textured paper.
//

import SwiftUI

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Mori Color System
/// Botanical watercolor palette for the shared app surface.
struct MoriColors {
    // MARK: Active Botanical Watercolor Palette
    /// Watercolor paper - Main background (#FBF7EF)
    static let sanctuaryPaper = Color(hex: "#FBF7EF")

    /// Warm paper layer for subtle depth (#F4EDE1)
    static let sanctuaryPaperWarm = Color(hex: "#F4EDE1")

    /// Seed paper - Card background (#FFFDF8)
    static let sanctuarySurface = Color(hex: "#FFFDF8")

    /// Deep leaf ink - Primary text (#14392F)
    static let sanctuaryInk = Color(hex: "#14392F")

    /// Softer deep leaf ink (#31584B)
    static let sanctuaryInkSoft = Color(hex: "#31584B")

    /// Muted leaf ink - Secondary text/icons (#5F6D64)
    static let sanctuaryMuted = Color(hex: "#5F6D64")

    /// Leaf wash - Focus/active states (#758C6B)
    static let sanctuarySage = Color(hex: "#758C6B")

    /// Soft fern - Growth/positive accents (#8FA883)
    static let sanctuaryFern = Color(hex: "#8FA883")

    /// Mist wash (#AFC9CB)
    static let sanctuaryMist = Color(hex: "#AFC9CB")

    /// Deep mist wash (#6E9298)
    static let sanctuaryMistDeep = Color(hex: "#6E9298")

    /// Sand wash (#D9C6A5)
    static let sanctuarySand = Color(hex: "#D9C6A5")

    /// Root wash (#8A765F)
    static let sanctuaryRoot = Color(hex: "#8A765F")

    /// Paper line - Borders (#DDD6C8)
    static let sanctuaryLine = Color(hex: "#DDD6C8")

    /// Botanical hairline
    static let sanctuaryHairline = Color(hex: "#14392F").opacity(0.11)

    /// Warm watercolor glow
    static let sanctuaryGlow = Color(hex: "#D9C6A5").opacity(0.22)

    /// Paper shadow
    static let sanctuaryShadow = Color(hex: "#14392F").opacity(0.12)

    // MARK: Semantic Colors
    /// Success - grounded growth
    static let success = sanctuaryFern

    /// Warning - gentle root nudge
    static let warning = sanctuarySand

    /// Neutral - quiet secondary ink
    static let neutral = sanctuaryMuted

    // MARK: Adaptive Colors
    /// Background color that adapts to color scheme
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#1A1F2E") : sanctuaryPaper
    }

    /// Surface/card color that adapts to color scheme
    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#12151C") : sanctuarySurface
    }

    /// Text color that adapts to color scheme
    static func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#E8E4DB") : sanctuaryInk
    }

    /// Secondary text color that adapts to color scheme
    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#9CA3AF") : sanctuaryMuted
    }

    /// Border color that adapts to color scheme
    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : sanctuaryLine
    }
}

// MARK: - Mori Typography System
/// Typography scale based on Dynamic Type text styles.
struct MoriTypography {
    /// Display - large hero number
    static let display = Font.system(.largeTitle, design: .rounded, weight: .light)

    /// Title 1 - screen titles
    static let title1 = Font.system(.title, design: .default, weight: .semibold)

    /// Title 2 - section headers
    static let title2 = Font.system(.title2, design: .default, weight: .semibold)

    /// Body - main content
    static let body = Font.system(.body, design: .default, weight: .regular)

    /// Callout - secondary info
    static let callout = Font.system(.callout, design: .default, weight: .regular)

    /// Caption - labels, hints
    static let caption = Font.system(.caption, design: .default, weight: .regular)

    /// Micro - timestamps and dense labels
    static let micro = Font.system(.caption2, design: .default, weight: .medium)

    /// Large metric display for archive and recovery surfaces
    static let largeMetric = Font.system(.largeTitle, design: .rounded, weight: .light)
}

// MARK: - Mori Spacing System
/// Spacing scale based on 4pt grid system
struct MoriSpacing {
    /// Space 1 - 4pt (micro gaps)
    static let space1: CGFloat = 4

    /// Space 2 - 8pt (tight spacing)
    static let space2: CGFloat = 8

    /// Space 3 - 12pt (default spacing)
    static let space3: CGFloat = 12

    /// Space 4 - 16pt (comfortable)
    static let space4: CGFloat = 16

    /// Space 5 - 24pt (section gaps)
    static let space5: CGFloat = 24

    /// Space 6 - 32pt (large gaps)
    static let space6: CGFloat = 32

    /// Space 7 - 48pt (screen margins)
    static let space7: CGFloat = 48

    /// Space 8 - 64pt (major sections)
    static let space8: CGFloat = 64

    // MARK: Screen Layout
    /// Standard horizontal screen margin
    static let screenHorizontal: CGFloat = 16

    /// Standard top screen margin
    static let screenTop: CGFloat = 24

    /// Card internal padding
    static let cardPadding: CGFloat = 16

    /// Button vertical padding
    static let buttonVertical: CGFloat = 16

    /// Button horizontal padding
    static let buttonHorizontal: CGFloat = 24

    /// Input field padding
    static let inputPadding: CGFloat = 12
}

// MARK: - Mori Corner Radius
/// Corner radius values
struct MoriCornerRadius {
    /// Small radius - 8pt
    static let small: CGFloat = 8

    /// Medium radius - 12pt
    static let medium: CGFloat = 12

    /// Large radius - 16pt
    static let large: CGFloat = 16

    /// Card radius - 16pt
    static let card: CGFloat = 16

    /// Button radius - 12pt
    static let button: CGFloat = 12

    /// Input radius - 12pt
    static let input: CGFloat = 12
}

// MARK: - Mori Animation System
/// Animation values for gentle, purposeful motion
struct MoriAnimation {
    /// Default ease-out animation (0.3s) - comfortable
    static let standard = Animation.easeOut(duration: 0.3)

    /// Spring animation - playful, used sparingly
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Gentle animation - repeat behavior must be opt-in and Reduce Motion guarded at call sites.
    static let gentle = Animation.easeInOut(duration: 2.0)

    /// Fast animation (0.2s)
    static let fast = Animation.easeOut(duration: 0.2)

    /// Standard animation (0.3s)
    static let standardDuration = Animation.easeOut(duration: 0.3)

    /// Slow animation (0.5s)
    static let slow = Animation.easeOut(duration: 0.5)

    /// Card appear animation
    static let cardAppear = Animation.easeOut(duration: 0.25)

    /// Screen transition animation
    static let screenTransition = Animation.easeOut(duration: 0.35)

    /// Button tap scale
    static let buttonTapScale: CGFloat = 0.97

    /// Grid square tap scale
    static let gridTapScale: CGFloat = 1.2
}

// MARK: - Mori Shadows
/// Shadow values for subtle depth
struct MoriShadow {
    /// Card shadow
    static let cardRadius: CGFloat = 8
    static let cardOpacity: Double = 0.04
    static let cardY: CGFloat = 2

    /// Button shadow
    static let buttonRadius: CGFloat = 8
    static let buttonOpacity: Double = 0.1
}

// MARK: - Mori Icon Sizes
/// Icon size specifications
struct MoriIconSize {
    /// Small icon - 16pt
    static let small: CGFloat = 16

    /// Standard icon - 24pt
    static let standard: CGFloat = 24

    /// Large icon - 32pt
    static let large: CGFloat = 32

    /// Tab bar icon
    static let tabBar: CGFloat = 24
}

// MARK: - Mori Hit Targets
/// Minimum tap target sizes (accessibility)
struct MoriHitTarget {
    /// Standard minimum tap target (44pt per Apple HIG)
    static let minimum: CGFloat = 44

    /// Comfortable tap target
    static let comfortable: CGFloat = 48
}
