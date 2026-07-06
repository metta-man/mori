import Foundation

extension MoriRecoveryHealthService {
    func hrvSignal(_ reading: QuantityBaseline, score: Double) -> MoriRecoverySignal {
        let current = reading.current.map { "\(Int($0.rounded())) ms" } ?? "--"
        let baseline = reading.preferredBaseline.map {
            MoriL10n.string("recovery.baseline.value", defaultValue: "%@ baseline", arguments: ["\(Int($0.rounded())) ms"])
        }
        let ratio = ratio(reading)
        let comparison = comparisonText(
            ratio: ratio,
            lowText: MoriL10n.display("below baseline"),
            steadyText: MoriL10n.display("near baseline"),
            highText: MoriL10n.display("above baseline")
        )

        return MoriRecoverySignal(
            id: "hrv",
            title: "HRV",
            valueText: current,
            baselineText: baseline,
            comparisonText: comparison,
            impact: Int((score - 70).rounded()),
            status: score >= 80 ? .supportive : score >= 60 ? .steady : .caution,
            icon: .pulse
        )
    }

    func restingHeartRateSignal(_ reading: QuantityBaseline, score: Double) -> MoriRecoverySignal {
        let current = reading.current.map { "\(Int($0.rounded())) bpm" } ?? "--"
        let baseline = reading.preferredBaseline.map {
            MoriL10n.string("recovery.baseline.value", defaultValue: "%@ baseline", arguments: ["\(Int($0.rounded())) bpm"])
        }
        let delta = delta(reading)
        let comparison: String

        if let delta {
            if delta >= 6 {
                comparison = MoriL10n.display("elevated versus baseline")
            } else if delta >= 3 {
                comparison = MoriL10n.display("slightly above baseline")
            } else {
                comparison = MoriL10n.display("near baseline")
            }
        } else {
            comparison = MoriL10n.display("baseline unavailable")
        }

        return MoriRecoverySignal(
            id: "resting-heart-rate",
            title: "Resting HR",
            valueText: current,
            baselineText: baseline,
            comparisonText: comparison,
            impact: Int((score - 70).rounded()),
            status: score >= 80 ? .supportive : score >= 60 ? .steady : .elevated,
            icon: .heart
        )
    }

    func sleepSignal(
        _ sleep: MoriRecoverySleepSummary,
        baselineDuration: TimeInterval?,
        score: Double
    ) -> MoriRecoverySignal {
        let baselineText = baselineDuration.map {
            MoriL10n.string("recovery.baseline.value", defaultValue: "%@ baseline", arguments: [MoriRecoveryFormatter.duration($0)])
        }

        return MoriRecoverySignal(
            id: "sleep",
            title: "Sleep",
            valueText: sleep.durationText,
            baselineText: baselineText,
            comparisonText: sleep.impactText,
            impact: Int((score - 70).rounded()),
            status: score >= 82 ? .supportive : score >= 62 ? .steady : .caution,
            icon: .quiet
        )
    }

    func respiratorySignal(_ reading: QuantityBaseline) -> MoriRecoverySignal {
        guard reading.current != nil || reading.preferredBaseline != nil else {
            return unavailableSignal(id: "respiratory-rate", title: "Respiratory Rate", icon: .breathe)
        }

        let current = reading.current.map { String(format: "%.1f / min", $0) } ?? "--"
        let baseline = reading.preferredBaseline.map {
            MoriL10n.string(
                "recovery.baseline.value",
                defaultValue: "%@ baseline",
                arguments: [String(format: "%.1f / min", $0)]
            )
        }
        let comparison = comparisonText(
            ratio: ratio(reading),
            lowText: MoriL10n.display("below baseline"),
            steadyText: MoriL10n.display("near baseline"),
            highText: MoriL10n.display("above baseline")
        )

        return MoriRecoverySignal(
            id: "respiratory-rate",
            title: "Respiratory Rate",
            valueText: current,
            baselineText: baseline,
            comparisonText: comparison,
            impact: 0,
            status: ratio(reading).map { $0 > 1.07 ? .elevated : .steady } ?? .steady,
            icon: .breathe
        )
    }

    func temperatureSignal(_ reading: QuantityBaseline) -> MoriRecoverySignal {
        guard reading.current != nil || reading.preferredBaseline != nil else {
            return unavailableSignal(id: "temperature", title: "Temperature", icon: .leaf)
        }

        let current = reading.current.map { String(format: "%.1f C", $0) } ?? "--"
        let baseline = reading.preferredBaseline.map {
            MoriL10n.string(
                "recovery.baseline.value",
                defaultValue: "%@ baseline",
                arguments: [String(format: "%.1f C", $0)]
            )
        }
        let comparison: String

        if let delta = delta(reading), delta > 0.45 {
            comparison = MoriL10n.display("above baseline")
        } else {
            comparison = MoriL10n.display("near baseline")
        }

        return MoriRecoverySignal(
            id: "temperature",
            title: "Temperature",
            valueText: current,
            baselineText: baseline,
            comparisonText: comparison,
            impact: 0,
            status: delta(reading).map { $0 > 0.45 ? .elevated : .steady } ?? .steady,
            icon: .leaf
        )
    }

    func unavailableSignal(id: String, title: String, icon: MoriBitmapIcon) -> MoriRecoverySignal {
        MoriRecoverySignal(
            id: id,
            title: title,
            valueText: "--",
            baselineText: nil,
            comparisonText: MoriL10n.display("unavailable"),
            impact: 0,
            status: .unavailable,
            icon: icon
        )
    }

    func comparisonText(
        ratio: Double?,
        lowText: String,
        steadyText: String,
        highText: String
    ) -> String {
        guard let ratio else { return MoriL10n.display("baseline unavailable") }

        if ratio < 0.92 {
            return lowText
        }

        if ratio > 1.08 {
            return highText
        }

        return steadyText
    }
}
