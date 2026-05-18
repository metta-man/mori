//
//  MoriDesignTokens.swift
//  Mori
//
//  Design System v1.0 based on Flare's design spec
//  Core Principle: Warm Mortality Awareness
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
/// Warm, minimalist color palette for mortality awareness app
struct MoriColors {
    // MARK: Core Neutrals
    /// Cream White - Main background (#FFF8E7)
    static let creamWhite = Color(hex: "#FFF8E7")
    
    /// Soft Cream - Card background (#F5EFE0)
    static let softCream = Color(hex: "#F5EFE0")
    
    /// Warm Gray - Borders (#D4CFC4)
    static let warmGray = Color(hex: "#D4CFC4")
    
    /// Soft Taupe - Secondary text/icons (#8B7355)
    static let softTaupe = Color(hex: "#8B7355")
    
    /// Warm Charcoal - Primary text (#4A4A4A)
    static let warmCharcoal = Color(hex: "#4A4A4A")
    
    /// Deep Espresso - High contrast text (#2B2520)
    static let deepEspresso = Color(hex: "#2B2520")
    
    // MARK: Accent Colors
    /// Accent Amber - Focus/active states (#D4A574)
    static let accentAmber = Color(hex: "#D4A574")
    
    /// Soft Sage - Growth/positive (#A8B5A0)
    static let softSage = Color(hex: "#A8B5A0")
    
    /// Warm Clay - Missed/negative (#C4846C)
    static let warmClay = Color(hex: "#C4846C")
    
    /// Morning Gold - Celebration (#E8C78A)
    static let morningGold = Color(hex: "#E8C78A")
    
    // MARK: Semantic Colors
    /// Success - Habit done (#A8B5A0)
    static let success = softSage
    
    /// Warning - Gentle nudge (#E8C78A)
    static let warning = morningGold
    
    /// Neutral - Default (#8B7355)
    static let neutral = softTaupe
    
    // MARK: Adaptive Colors
    /// Background color that adapts to color scheme
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#1A1F2E") : creamWhite
    }
    
    /// Surface/card color that adapts to color scheme
    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#12151C") : softCream
    }
    
    /// Text color that adapts to color scheme
    static func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#E8E4DB") : warmCharcoal
    }
    
    /// Secondary text color that adapts to color scheme
    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#9CA3AF") : softTaupe
    }
    
    /// Border color that adapts to color scheme
    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : warmGray
    }
}

// MARK: - Mori Typography System
/// Typography scale based on design spec
struct MoriTypography {
    /// Display - 48pt Light (big countdown number)
    static let display = Font.system(size: 48, weight: .light)
    
    /// Title 1 - 28pt Semibold (screen titles)
    static let title1 = Font.system(size: 28, weight: .semibold)
    
    /// Title 2 - 22pt Semibold (section headers)
    static let title2 = Font.system(size: 22, weight: .semibold)
    
    /// Body - 17pt Regular (main content)
    static let body = Font.system(size: 17, weight: .regular)
    
    /// Callout - 16pt Regular (secondary info)
    static let callout = Font.system(size: 16, weight: .regular)
    
    /// Caption - 14pt Regular (labels, hints)
    static let caption = Font.system(size: 14, weight: .regular)
    
    /// Micro - 12pt Medium (timestamps)
    static let micro = Font.system(size: 12, weight: .medium)
    
    /// Large number display (e.g., days remaining)
    static let largeNumber = Font.system(size: 64, weight: .light, design: .rounded)
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
    
    /// Gentle pulse animation - for current week, celebrations
    static let gentle = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    
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

// MARK: - App-specific Colors (LifeGrid)
extension MoriColors {
    /// Main background for app
    static let background = creamWhite
    
    /// Card background
    static let cardBackground = softCream
    
    /// Primary text
    static let text = warmCharcoal
    
    /// Secondary text
    static let secondary = softTaupe
    
    /// Primary accent
    static let primary = warmCharcoal
    
    /// Accent for current week
    static let accent = accentAmber
    
    /// Filled dot (past weeks)
    static let filledDot = warmCharcoal.opacity(0.6)
    
    /// Empty dot (future weeks)
    static let emptyDot = warmGray
}

// MARK: - Design Spec v1.0 Compatibility Layer
// These aliases map the spec-required names to our implemented colors
// This ensures compatibility with the Flare design system v1.0
extension MoriColors {
    // Primary Colors (from spec)
    /// Mori Gold - Primary Accent (#D4AF37)
    static let moriGold = Color(hex: "#D4AF37")
    static let moriGoldLight = Color(hex: "#E8C547")
    static let moriGoldDark = Color(hex: "#B8942D")
    
    /// Zen Cream - Background (#FDF5E6)
    static let zenCream = Color(hex: "#FDF5E6")
    static let zenCreamDark = Color(hex: "#FFF8E7")
    static let zenCreamLight = Color(hex: "#FFFCF5")
    
    /// Charcoal - Text (#333333)
    static let charcoal = Color(hex: "#333333")
    static let charcoalLight = Color(hex: "#4A4A4A")
    static let charcoalMuted = Color(hex: "#666666")
    
    // Secondary Colors (from spec)
    /// Sage Green - Success (#788c5d)
    static let sageGreen = Color(hex: "#788c5d")
    static let sageGreenLight = Color(hex: "#8FA072")
    
    /// Mist Blue - Calm (#6a9bcc)
    static let mistBlue = Color(hex: "#6a9bcc")
    static let mistBlueLight = Color(hex: "#8BB5D9")
    
    /// Ember Orange - Energy (#FF6B35)
    static let emberOrange = Color(hex: "#FF6B35")
    static let emberOrangeLight = Color(hex: "#FF8A5B")
    
    // Neutral Colors (from spec)
    static let textPrimary = Color(hex: "#333333")
    static let textSecondary = Color(hex: "#666666")
    static let textTertiary = Color(hex: "#888888")
    static let textDisabled = Color(hex: "#AAAAAA")
    
    static let bgPrimary = Color(hex: "#FDF5E6")
    static let bgSecondary = Color(hex: "#FFF8E7")
    static let bgTertiary = Color(hex: "#F5EFE0")
    static let bgDark = Color(hex: "#333333")
    
    static let borderLight = Color(hex: "#E8E8E8")
    static let borderMedium = Color(hex: "#CCCCCC")
    static let borderDark = Color(hex: "#999999")
    
    static let shadowSoft = Color.black.opacity(0.05)
    static let shadowMedium = Color.black.opacity(0.1)
    static let shadowStrong = Color.black.opacity(0.15)

    static let gray = textSecondary
    static let gold = moriGold
}

extension MoriTypography {
    static let headline1 = Font.system(size: 34, weight: .semibold)
    static let display2 = Font.system(size: 44, weight: .light, design: .rounded)
    static let subhead = Font.system(size: 17, weight: .semibold)
}

// MARK: - CSS Variable Names (for documentation)
// These represent the CSS variable names from the design spec:
// --mori-gold: #D4AF37
// --zen-cream: #FDF5E6
// --charcoal: #333333
// --sage-green: #788c5d
// --mist-blue: #6a9bcc
// --ember-orange: #FF6B35

// MARK: - Dark Theme Colors (Design Brief v1.0)
// Clock and contemplative screens use warm dark theme
extension MoriColors {
    /// Deep Black - Dark theme background (#0A0A0A)
    static let moriDark = Color(hex: "#0A0A0A")
    static let moriDarkElevated = Color(hex: "#111111")
    static let moriDarkSurface = Color(hex: "#171717")
    
    /// Soft Cream - Text on dark backgrounds (#FDF5E6)
    static let moriCream = Color(hex: "#FDF5E6")
    
    /// Mori Cream Light - Subtle cream (#FFF8E7)
    static let moriCreamLight = Color(hex: "#FFF8E7")

    static let moriCreamMuted = Color(hex: "#A9A39A")
    static let moriHairline = moriGold.opacity(0.18)
}
