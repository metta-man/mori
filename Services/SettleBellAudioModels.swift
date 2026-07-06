import Foundation

enum SettleBellTone: String, CaseIterable, Identifiable {
    case singingBowlA = "Singing Bowl A.wav"
    case defaultChime = "Default.mp3"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singingBowlA: return MoriL10n.string("bell_tone.singing_bowl", defaultValue: "Singing Bowl")
        case .defaultChime: return MoriL10n.string("bell_tone.soft_chime", defaultValue: "Soft Chime")
        }
    }

    var fileName: String {
        rawValue
    }
}

enum SettleBreathingCue {
    case inhale
    case exhale
    case hold

    static let fadeDuration: TimeInterval = 1.5

    var fileName: String {
        switch self {
        case .inhale: return "Singing Bowl E_2.wav"
        case .exhale: return "Singing Bowl A.wav"
        case .hold: return "Mokugyo.wav"
        }
    }

    var volume: Float {
        switch self {
        case .inhale, .exhale: return 0.6
        case .hold: return 0.7
        }
    }

    var phaseLeadTime: TimeInterval {
        switch self {
        case .inhale, .hold: return 0.2
        case .exhale: return 1.0
        }
    }

    var fadesBeforeNextCue: Bool {
        switch self {
        case .inhale, .exhale: return true
        case .hold: return false
        }
    }
}
