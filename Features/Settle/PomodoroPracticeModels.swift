import SwiftUI

struct MoriPomodoroBreakBreathing: Identifiable, Equatable {
    static let none = MoriPomodoroBreakBreathing(rawValue: "none")

    let rawValue: String

    init(rawValue: String) {
        self.rawValue = Self.migratedRawValue(rawValue)
    }

    var id: String { rawValue }

    static var allCases: [MoriPomodoroBreakBreathing] {
        [.none] + MoriBreathingTechniqueRepository.techniques.map { MoriPomodoroBreakBreathing(rawValue: $0.id) }
    }

    var title: String {
        if rawValue == "none" {
            return MoriL10n.string("None", defaultValue: "None")
        }
        return technique?.name ?? MoriL10n.string("None", defaultValue: "None")
    }

    var icon: MoriBitmapIcon {
        if rawValue == "none" {
            return .minus
        }
        return technique?.icon ?? .breathe
    }

    var symbolName: String { icon.legacySystemName }

    var tint: Color {
        if rawValue == "none" {
            return MoriColors.botanicalMuted
        }
        return Color(hex: technique?.gradientColors.first ?? "#687E5E")
    }

    var hasTechnique: Bool {
        technique != nil
    }

    var timingDescription: String {
        guard let pattern = technique?.breathPattern else {
            return MoriL10n.string("pomodoro.break_breathing.no_cues", defaultValue: "No break cues")
        }
        return MoriBreathingTechnique.patternDisplay(for: pattern)
    }

    var segments: [MoriBreathingCycleSegment] {
        technique?.breathPattern.segments ?? []
    }

    func visualState(at elapsedTime: TimeInterval) -> MoriBreathingCycleVisualState {
        MoriBreathingCycle.visualState(for: segments, elapsedTime: elapsedTime)
    }

    private var technique: MoriBreathingTechnique? {
        MoriBreathingTechniqueRepository.getTechnique(id: rawValue)
    }

    private static func migratedRawValue(_ rawValue: String) -> String {
        switch rawValue {
        case "none":
            return "none"
        case "calm":
            return MoriBreathingTechniqueID.nadiShodhana.rawValue
        case "box":
            return MoriBreathingTechniqueID.box4.rawValue
        case "reset":
            return MoriBreathingTechniqueID.coherent5.rawValue
        default:
            if MoriBreathingTechniqueRepository.getTechnique(id: rawValue) != nil {
                return rawValue
            }
            return "none"
        }
    }
}

enum MoriPomodoroPhase: String, Equatable {
    case focus
    case shortBreak
    case longBreak
    case completed

    var title: String {
        switch self {
        case .focus: return MoriL10n.string("pomodoro.phase.focus", defaultValue: "Focus")
        case .shortBreak: return MoriL10n.string("pomodoro.phase.short_break", defaultValue: "Short Break")
        case .longBreak: return MoriL10n.string("pomodoro.phase.long_break", defaultValue: "Long Break")
        case .completed: return MoriL10n.string("pomodoro.phase.completed", defaultValue: "Completed")
        }
    }

    var icon: MoriBitmapIcon {
        switch self {
        case .focus: return .timer
        case .shortBreak: return .leaf
        case .longBreak: return .focus
        case .completed: return .leaf
        }
    }

    var symbolName: String { icon.legacySystemName }

    var tint: Color {
        switch self {
        case .focus: return MoriColors.botanicalInk
        case .shortBreak: return MoriColors.botanicalMist
        case .longBreak: return MoriColors.botanicalSeed
        case .completed: return MoriColors.botanicalMoss
        }
    }

    var isBreak: Bool {
        self == .shortBreak || self == .longBreak
    }

    func durationSeconds(focusMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int) -> Int {
        switch self {
        case .focus: return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        case .completed: return 0
        }
    }
}
