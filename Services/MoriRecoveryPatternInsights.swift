import Foundation

enum MoriRecoveryCorrelationEngine {
    static func insights(from logs: [MoriDailyFactorLog], windowDays: Int = 60, limit: Int = 3) -> [RecoveryPatternInsight] {
        let logsByKey = Dictionary(uniqueKeysWithValues: logs.map { (MoriDateKey.value(for: $0.date), $0) })
        let indicatorLogs = logs.compactMap(\.recoveryIndicator)
        guard indicatorLogs.count >= 4 else { return [] }

        var insights: [RecoveryPatternInsight] = []
        for factor in MoriFactorTagID.allCases {
            let taggedLogs = logs.filter { log in
                log.factorTags.contains { $0.id == factor }
            }
            guard taggedLogs.count >= 3 else { continue }

            for metric in MoriRecoveryMetricKind.allCases {
                let baselineValues = indicatorLogs.compactMap { value(for: metric, indicator: $0) }
                guard let baseline = average(baselineValues) else { continue }

                let taggedValues = taggedLogs.compactMap { log -> Double? in
                    guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: log.date) else { return nil }
                    return logsByKey[MoriDateKey.value(for: nextDay)]?.recoveryIndicator.flatMap {
                        value(for: metric, indicator: $0)
                    }
                }
                guard taggedValues.count >= 3,
                      let taggedAverage = average(taggedValues) else { continue }

                let delta = taggedAverage - baseline
                guard abs(delta) >= metric.minimumDelta else { continue }

                let confidence = confidence(sampleCount: taggedValues.count, delta: abs(delta), metric: metric)
                insights.append(
                    RecoveryPatternInsight(
                        id: "\(factor.rawValue)-\(metric.rawValue)",
                        factorTag: factor,
                        metric: metric,
                        delta: delta,
                        sampleCount: taggedValues.count,
                        windowDays: windowDays,
                        confidence: confidence,
                        summary: summary(factor: factor, metric: metric, delta: delta, samples: taggedValues.count),
                        suggestedPractice: factor.suggestedPractice
                    )
                )
            }
        }

        return insights
            .sorted { lhs, rhs in
                if lhs.confidence != rhs.confidence {
                    return confidenceRank(lhs.confidence) > confidenceRank(rhs.confidence)
                }
                if lhs.sampleCount != rhs.sampleCount {
                    return lhs.sampleCount > rhs.sampleCount
                }
                return abs(lhs.delta) > abs(rhs.delta)
            }
            .prefix(limit)
            .map { $0 }
    }

    private static func value(for metric: MoriRecoveryMetricKind, indicator: MoriRecoveryDailyIndicator) -> Double? {
        switch metric {
        case .readiness:
            return indicator.readinessScore
        case .sleep:
            return indicator.sleepMinutes
        case .hrvSignal:
            return indicator.hrvImpact
        case .restingHeartSignal:
            return indicator.restingHeartImpact
        case .bodyLoad:
            return indicator.bodyLoadScore
        }
    }

    private static func average(_ values: [Double]) -> Double? {
        let filtered = values.filter(\.isFinite)
        guard !filtered.isEmpty else { return nil }
        return filtered.reduce(0, +) / Double(filtered.count)
    }

    private static func confidence(sampleCount: Int, delta: Double, metric: MoriRecoveryMetricKind) -> MoriPatternConfidence {
        if sampleCount >= 8 && delta >= metric.minimumDelta * 1.6 {
            return .high
        }
        if sampleCount >= 5 {
            return .medium
        }
        return .emerging
    }

    private static func confidenceRank(_ confidence: MoriPatternConfidence) -> Int {
        switch confidence {
        case .high: return 3
        case .medium: return 2
        case .emerging: return 1
        }
    }

    private static func summary(
        factor: MoriFactorTagID,
        metric: MoriRecoveryMetricKind,
        delta: Double,
        samples: Int
    ) -> String {
        let direction = delta >= 0 ? metric.higherText : metric.lowerText
        let amount: String
        switch metric {
        case .sleep:
            amount = MoriL10n.string("duration.minutes", defaultValue: "%d minutes", arguments: [Int(abs(delta).rounded())])
        case .bodyLoad:
            amount = MoriL10n.string("recovery.pattern.levels", defaultValue: "%.1f levels", arguments: [abs(delta)])
        default:
            amount = MoriL10n.string("recovery.pattern.points_full", defaultValue: "%d points", arguments: [Int(abs(delta).rounded())])
        }

        return MoriL10n.string(
            "recovery.pattern.summary",
            defaultValue: "On days tagged %@, next-day %@ tends to be %@ by %@ across %d samples.",
            arguments: [factor.label, metric.title, direction, amount, samples]
        )
    }
}
