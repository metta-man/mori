import SwiftUI

struct MoriAttentionResetBreathingState {
    let context: MoriAttentionResetContext
    let beforeFeedTechniqueID: String
    let morningGateTechniqueID: String
    let customInhaleSeconds: Double
    let customHoldSeconds: Double
    let customExhaleSeconds: Double
    let customUsesHold: Bool
    let isRunning: Bool
    let isComplete: Bool
    let elapsedTime: TimeInterval

    var selectedTechniqueID: String {
        switch context {
        case .beforeFeed:
            return beforeFeedTechniqueID
        case .morningGate:
            return morningGateTechniqueID
        }
    }

    var selectedTechnique: MoriBreathingTechnique? {
        guard selectedTechniqueID != MoriScreenTimeShared.beforeFeedBreathingNoneID else {
            return nil
        }

        let fallbackID: String
        switch context {
        case .beforeFeed:
            fallbackID = MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
        case .morningGate:
            fallbackID = MoriScreenTimeShared.defaultMorningGateBreathingTechniqueID
        }

        return MoriBreathingTechniqueRepository.getTechnique(id: selectedTechniqueID)
            ?? MoriBreathingTechniqueRepository.getTechnique(id: fallbackID)
    }

    var hasTechnique: Bool {
        selectedTechnique != nil
    }

    var headerSubtitle: String {
        context.subtitle(technique: selectedTechnique)
    }

    var cueText: String {
        if isRunning {
            return context.runningCue(
                hasTechnique: hasTechnique,
                breathingLabel: visualState.label
            )
        }

        return context.idleCue(hasTechnique: hasTechnique, isComplete: isComplete)
    }

    var segments: [MoriBreathingCycleSegment] {
        breathPattern?.segments ?? []
    }

    var visualState: MoriBreathingCycleVisualState {
        guard isRunning, !segments.isEmpty else { return .idle }
        return MoriBreathingCycle.visualState(
            for: segments,
            elapsedTime: elapsedTime
        )
    }

    var phaseRemaining: TimeInterval {
        MoriBreathingCycle.phaseRemaining(
            for: segments,
            elapsedTime: elapsedTime
        )
    }

    var tint: Color {
        guard let technique = selectedTechnique else {
            return MoriColors.botanicalMoss
        }
        return Color(hex: technique.gradientColors.first ?? "#687E5E")
    }

    private var breathPattern: MoriBreathPattern? {
        guard let technique = selectedTechnique else { return nil }

        if technique.id == MoriBreathingTechniqueID.custom.rawValue {
            return MoriBreathPattern(
                inhale: max(1, customInhaleSeconds),
                inhaleHold: customUsesHold && customHoldSeconds > 0 ? max(1, customHoldSeconds) : nil,
                exhale: max(1, customExhaleSeconds),
                exhaleHold: nil
            )
        }

        return technique.breathPattern
    }
}
