//
//  MoriThemeTokens.swift
//  Mori
//
//  Theme-specific color and typography aliases layered on the core design tokens.
//

import SwiftUI

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
