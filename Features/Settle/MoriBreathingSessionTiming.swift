import SwiftUI

enum MoriBreathingSessionDurationOptions {
    static let pickerOptions = [1, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120, 180]
    static let presets = [5, 10, 20, 45, 60, 90, 120, 180]
}

enum MoriBreathingCyclePhase: Equatable {
    case idle
    case inhale
    case holdAfterInhale
    case exhale
    case holdAfterExhale

    var cue: SettleBreathingCue? {
        switch self {
        case .inhale: return .inhale
        case .holdAfterInhale, .holdAfterExhale: return .hold
        case .exhale: return .exhale
        case .idle: return nil
        }
    }
}

struct MoriBreathingCycleSegment: Equatable {
    let phase: MoriBreathingCyclePhase
    let label: String
    let duration: TimeInterval

    init(phase: MoriBreathingCyclePhase, label: String, duration: TimeInterval) {
        self.phase = phase
        self.label = label
        self.duration = max(0, duration)
    }
}

struct MoriBreathingCycleVisualState: Equatable {
    let label: String
    let phase: MoriBreathingCyclePhase
    let progress: Double
    let scale: CGFloat
    let opacity: Double
    let blur: CGFloat

    static let idle = MoriBreathingCycleVisualState(
        label: "Settle",
        phase: .idle,
        progress: 0,
        scale: 1,
        opacity: 1,
        blur: 0
    )
}

enum MoriBreathingCycle {
    static func visualState(
        for segments: [MoriBreathingCycleSegment],
        elapsedTime: TimeInterval,
        minimumScale: CGFloat = 0.88,
        maximumScale: CGFloat = 1.16,
        minimumOpacity: Double = 0.78,
        maximumOpacity: Double = 1.0,
        maximumBlur: CGFloat = 2.8
    ) -> MoriBreathingCycleVisualState {
        let activeSegments = segments.filter { $0.duration > 0 }
        guard !activeSegments.isEmpty else { return .idle }

        let cycleDuration = activeSegments.reduce(0) { $0 + $1.duration }
        guard cycleDuration > 0 else { return .idle }

        let elapsedInCycle = positiveRemainder(elapsedTime, cycleDuration)
        var cursor: TimeInterval = 0

        for (index, segment) in activeSegments.enumerated() {
            let start = cursor
            cursor += segment.duration
            if elapsedInCycle < cursor || index == activeSegments.count - 1 {
                let rawProgress = (elapsedInCycle - start) / max(segment.duration, 0.001)
                let progress = min(1, max(0, rawProgress))
                let eased = cosineEaseInOut(progress)
                let scale = scaleForPhase(segment.phase, easedProgress: eased, minimumScale: minimumScale, maximumScale: maximumScale)

                return MoriBreathingCycleVisualState(
                    label: segment.label,
                    phase: segment.phase,
                    progress: progress,
                    scale: scale,
                    opacity: opacityForScale(scale, minimumScale: minimumScale, maximumScale: maximumScale, minimumOpacity: minimumOpacity, maximumOpacity: maximumOpacity),
                    blur: blurForPhase(segment.phase, easedProgress: eased, maximumBlur: maximumBlur)
                )
            }
        }

        return .idle
    }

    static func phaseIndex(for segments: [MoriBreathingCycleSegment], elapsedTime: TimeInterval) -> Int {
        let activeSegments = segments.filter { $0.duration > 0 }
        let cycleDuration = activeSegments.reduce(0) { $0 + $1.duration }
        guard cycleDuration > 0 else { return 0 }
        let elapsedInCycle = positiveRemainder(elapsedTime, cycleDuration)
        var cursor: TimeInterval = 0

        for (index, segment) in activeSegments.enumerated() {
            cursor += segment.duration
            if elapsedInCycle < cursor || index == activeSegments.count - 1 {
                return index
            }
        }

        return 0
    }

    static func phaseRemaining(for segments: [MoriBreathingCycleSegment], elapsedTime: TimeInterval) -> TimeInterval {
        let activeSegments = segments.filter { $0.duration > 0 }
        let cycleDuration = activeSegments.reduce(0) { $0 + $1.duration }
        guard cycleDuration > 0 else { return 0 }
        let elapsedInCycle = positiveRemainder(elapsedTime, cycleDuration)
        var cursor: TimeInterval = 0

        for (index, segment) in activeSegments.enumerated() {
            cursor += segment.duration
            if elapsedInCycle < cursor || index == activeSegments.count - 1 {
                return max(0, cursor - elapsedInCycle)
            }
        }

        return 0
    }

    static func segments(inhale: TimeInterval, inhaleHold: TimeInterval? = nil, exhale: TimeInterval, exhaleHold: TimeInterval? = nil) -> [MoriBreathingCycleSegment] {
        var segments = [
            MoriBreathingCycleSegment(phase: .inhale, label: MoriL10n.string("breath.phase.inhale", defaultValue: "Inhale"), duration: inhale)
        ]

        if let inhaleHold, inhaleHold > 0 {
            segments.append(MoriBreathingCycleSegment(phase: .holdAfterInhale, label: MoriL10n.string("breath.phase.hold", defaultValue: "Hold"), duration: inhaleHold))
        }

        segments.append(MoriBreathingCycleSegment(phase: .exhale, label: MoriL10n.string("breath.phase.exhale", defaultValue: "Exhale"), duration: exhale))

        if let exhaleHold, exhaleHold > 0 {
            segments.append(MoriBreathingCycleSegment(phase: .holdAfterExhale, label: MoriL10n.string("breath.phase.hold", defaultValue: "Hold"), duration: exhaleHold))
        }

        return segments
    }

    private static func positiveRemainder(_ value: TimeInterval, _ divisor: TimeInterval) -> TimeInterval {
        let remainder = value.truncatingRemainder(dividingBy: divisor)
        return remainder >= 0 ? remainder : remainder + divisor
    }

    private static func cosineEaseInOut(_ progress: Double) -> Double {
        0.5 - 0.5 * cos(.pi * progress)
    }

    private static func scaleForPhase(_ phase: MoriBreathingCyclePhase, easedProgress: Double, minimumScale: CGFloat, maximumScale: CGFloat) -> CGFloat {
        let range = maximumScale - minimumScale
        switch phase {
        case .inhale:
            return minimumScale + range * CGFloat(easedProgress)
        case .holdAfterInhale:
            return maximumScale
        case .exhale:
            return maximumScale - range * CGFloat(easedProgress)
        case .holdAfterExhale, .idle:
            return minimumScale
        }
    }

    private static func opacityForScale(_ scale: CGFloat, minimumScale: CGFloat, maximumScale: CGFloat, minimumOpacity: Double, maximumOpacity: Double) -> Double {
        guard maximumScale > minimumScale else { return maximumOpacity }
        let normalized = Double((scale - minimumScale) / (maximumScale - minimumScale))
        return minimumOpacity + (maximumOpacity - minimumOpacity) * min(1, max(0, normalized))
    }

    private static func blurForPhase(_ phase: MoriBreathingCyclePhase, easedProgress: Double, maximumBlur: CGFloat) -> CGFloat {
        switch phase {
        case .exhale:
            return maximumBlur * CGFloat(easedProgress)
        case .holdAfterExhale:
            return maximumBlur
        default:
            return 0
        }
    }
}

enum MoriBreathingHapticStyle: String, CaseIterable, Identifiable {
    case symmetry = "Symmetry"
    case minimalist = "Minimalist"

    var id: String { rawValue }
}
