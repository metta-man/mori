import Foundation

extension MoriRecoveryHealthService {
    struct RecoveryReadings {
        let hrv: QuantityBaseline
        let restingHeartRate: QuantityBaseline
        let respiratoryRate: QuantityBaseline
        let temperature: QuantityBaseline
        let sleep: MoriRecoverySleepSummary
        let sleepBaselineDuration: TimeInterval?
        let training: MoriRecoveryTrainingSummary
    }

    struct QuantityBaseline {
        let current: Double?
        let sevenDayAverage: Double?
        let thirtyDayAverage: Double?

        var preferredBaseline: Double? {
            thirtyDayAverage ?? sevenDayAverage
        }
    }

    struct WeightedScore {
        let value: Double
        let weight: Double
    }

    func average(_ values: [Double]) -> Double? {
        let filtered = values.filter { $0.isFinite && $0 > 0 }
        guard !filtered.isEmpty else { return nil }
        return filtered.reduce(0, +) / Double(filtered.count)
    }

    func hrvScore(current: Double?, baseline: Double?) -> Double? {
        guard let current, let baseline, baseline > 0 else { return nil }
        let ratio = current / baseline

        switch ratio {
        case 1.00...:
            return 100
        case 0.90..<1.00:
            return 84
        case 0.80..<0.90:
            return 66
        case 0.70..<0.80:
            return 48
        default:
            return 30
        }
    }

    func restingHeartRateScore(current: Double?, baseline: Double?) -> Double? {
        guard let current, let baseline else { return nil }
        let delta = current - baseline

        switch delta {
        case ...0:
            return 100
        case 0...3:
            return 84
        case 3...6:
            return 64
        case 6...9:
            return 44
        default:
            return 25
        }
    }

    func respiratoryTemperatureScore(
        respiratoryRate: QuantityBaseline,
        temperature: QuantityBaseline
    ) -> Double? {
        var scores: [Double] = []

        if let current = respiratoryRate.current,
           let baseline = respiratoryRate.preferredBaseline,
           baseline > 0 {
            let ratio = current / baseline
            if ratio <= 1.03 {
                scores.append(100)
            } else if ratio <= 1.07 {
                scores.append(72)
            } else if ratio <= 1.12 {
                scores.append(52)
            } else {
                scores.append(32)
            }
        }

        if let current = temperature.current,
           let baseline = temperature.preferredBaseline {
            let delta = current - baseline
            if delta <= 0.20 {
                scores.append(100)
            } else if delta <= 0.45 {
                scores.append(70)
            } else if delta <= 0.75 {
                scores.append(48)
            } else {
                scores.append(30)
            }
        }

        return average(scores)
    }

    func subjectiveMoodScore() -> Double {
        guard let tone = HabitDataManager.shared.getTodayEntry()?.tone else {
            return 70
        }

        switch tone {
        case .positive:
            return 100
        case .neutral:
            return 70
        case .negative:
            return 35
        }
    }

    func readinessState(for score: Int?) -> MoriRecoveryState {
        guard let score else { return .unknown }

        switch score {
        case 80...100:
            return .openReady
        case 60..<80:
            return .balanced
        case 40..<60:
            return .strained
        default:
            return .depleted
        }
    }

    func bodyLoadLabel(
        restingHeartRate: QuantityBaseline,
        hrv: QuantityBaseline,
        respiratoryRate: QuantityBaseline,
        temperature: QuantityBaseline,
        training: MoriRecoveryTrainingSummary
    ) -> String {
        let rhrDelta = delta(restingHeartRate)
        let hrvRatio = ratio(hrv)
        let respiratoryRatio = ratio(respiratoryRate)
        let tempDelta = delta(temperature)

        if (rhrDelta ?? 0) >= 6 && (hrvRatio ?? 1) < 0.85 {
            return MoriL10n.display("Elevated")
        }

        if training.isElevated || (respiratoryRatio ?? 1) > 1.07 || (tempDelta ?? 0) > 0.45 {
            return MoriL10n.display("Slightly elevated")
        }

        return MoriL10n.display("Steady")
    }

    func nervousSystemLabel(
        score: Int?,
        hrv: QuantityBaseline,
        restingHeartRate: QuantityBaseline
    ) -> String {
        guard let score else { return MoriL10n.display("Unavailable") }

        if score < 40 {
            return MoriL10n.display("Depleted")
        }

        if (ratio(hrv) ?? 1) < 0.85 || (delta(restingHeartRate) ?? 0) >= 5 {
            return MoriL10n.display("Strained")
        }

        if score >= 80 {
            return MoriL10n.display("Calm")
        }

        return MoriL10n.display("Balanced")
    }

    func suggestedPractice(
        score: Int?,
        hrv: QuantityBaseline,
        restingHeartRate: QuantityBaseline,
        sleep: MoriRecoverySleepSummary,
        training: MoriRecoveryTrainingSummary
    ) -> MoriPractice {
        if training.isElevated {
            return .walkReset
        }

        if sleep.score.map({ $0 < 55 }) == true {
            return .settleThree
        }

        if (ratio(hrv) ?? 1) < 0.85 && (delta(restingHeartRate) ?? 0) >= 4 {
            return .breatheMinute
        }

        guard let score else { return .breatheMinute }

        switch score {
        case 80...:
            return .focusFifteen
        case 60..<80:
            return .breatheMinute
        case 40..<60:
            return .breatheMinute
        default:
            return .settleThree
        }
    }

    func primaryMessage(
        state: MoriRecoveryState,
        hrv: QuantityBaseline,
        restingHeartRate: QuantityBaseline,
        sleep: MoriRecoverySleepSummary,
        training: MoriRecoveryTrainingSummary
    ) -> String {
        if training.isElevated {
            return MoriL10n.display("Yesterday's training load was high. Try a walk plus slow breathing before harder effort.")
        }

        if sleep.score.map({ $0 < 55 }) == true {
            return MoriL10n.display("Sleep may be limiting recovery today. Keep the first practice gentle.")
        }

        if (ratio(hrv) ?? 1) < 0.85 && (delta(restingHeartRate) ?? 0) >= 4 {
            return MoriL10n.display("Your system looks slightly activated today. Try a 5-minute slow breathing session.")
        }

        return state.guidance
    }

    func ratio(_ reading: QuantityBaseline) -> Double? {
        guard let current = reading.current,
              let baseline = reading.preferredBaseline,
              baseline > 0 else {
            return nil
        }

        return current / baseline
    }

    func delta(_ reading: QuantityBaseline) -> Double? {
        guard let current = reading.current,
              let baseline = reading.preferredBaseline else {
            return nil
        }

        return current - baseline
    }
}
