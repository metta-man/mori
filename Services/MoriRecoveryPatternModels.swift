import Foundation

enum MoriRecoveryMetricKind: String, Codable, CaseIterable {
    case readiness
    case sleep
    case hrvSignal
    case restingHeartSignal
    case bodyLoad

    var title: String {
        switch self {
        case .readiness: return MoriL10n.display("readiness")
        case .sleep: return MoriL10n.display("sleep duration")
        case .hrvSignal: return MoriL10n.display("HRV signal")
        case .restingHeartSignal: return MoriL10n.display("resting heart-rate signal")
        case .bodyLoad: return MoriL10n.display("body load")
        }
    }

    var higherText: String {
        MoriL10n.display("higher")
    }

    var lowerText: String {
        MoriL10n.display("lower")
    }

    var minimumDelta: Double {
        switch self {
        case .readiness: return 5
        case .sleep: return 30
        case .hrvSignal, .restingHeartSignal: return 5
        case .bodyLoad: return 0.4
        }
    }
}

enum MoriPatternConfidence: String, Codable, Equatable {
    case emerging
    case medium
    case high

    var label: String {
        switch self {
        case .emerging: return MoriL10n.display("Emerging")
        case .medium: return MoriL10n.display("Medium")
        case .high: return MoriL10n.display("High")
        }
    }
}

struct RecoveryPatternInsight: Identifiable, Equatable {
    let id: String
    let factorTag: MoriFactorTagID
    let metric: MoriRecoveryMetricKind
    let delta: Double
    let sampleCount: Int
    let windowDays: Int
    let confidence: MoriPatternConfidence
    let summary: String
    let suggestedPractice: MoriPractice

    var directionText: String {
        delta >= 0 ? metric.higherText : metric.lowerText
    }

    var deltaText: String {
        switch metric {
        case .sleep:
            return MoriL10n.string("duration.minutes_short", defaultValue: "%dm", arguments: [Int(abs(delta).rounded())])
        case .bodyLoad:
            return MoriL10n.string("recovery.pattern.levels", defaultValue: "%.1f levels", arguments: [abs(delta)])
        default:
            return MoriL10n.string("recovery.pattern.points", defaultValue: "%d pts", arguments: [Int(abs(delta).rounded())])
        }
    }
}
