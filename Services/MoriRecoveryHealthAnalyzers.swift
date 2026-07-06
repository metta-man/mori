import Foundation
import HealthKit

enum MoriRecoverySleepAnalyzer {
    static func summary(from samples: [HKCategorySample]) -> MoriRecoverySleepSummary {
        guard !samples.isEmpty else { return .unavailable }

        var sleepDuration: TimeInterval = 0
        var deepDuration: TimeInterval = 0
        var remDuration: TimeInterval = 0
        var coreDuration: TimeInterval = 0
        var awakeDuration: TimeInterval = 0

        for sample in samples {
            let duration = max(0, sample.endDate.timeIntervalSince(sample.startDate))
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { continue }

            switch value {
            case .asleepUnspecified:
                sleepDuration += duration
            case .asleepCore:
                sleepDuration += duration
                coreDuration += duration
            case .asleepDeep:
                sleepDuration += duration
                deepDuration += duration
            case .asleepREM:
                sleepDuration += duration
                remDuration += duration
            case .awake:
                awakeDuration += duration
            default:
                continue
            }
        }

        guard sleepDuration > 0 else { return .unavailable }

        let score = sleepScore(
            duration: sleepDuration,
            deepDuration: deepDuration,
            remDuration: remDuration,
            wakeAfterSleep: awakeDuration
        )
        return MoriRecoverySleepSummary(
            duration: sleepDuration,
            deepDuration: deepDuration > 0 ? deepDuration : nil,
            remDuration: remDuration > 0 ? remDuration : nil,
            coreDuration: coreDuration > 0 ? coreDuration : nil,
            wakeAfterSleepOnset: awakeDuration > 0 ? awakeDuration : nil,
            score: score
        )
    }

    static func baselineDuration(from samples: [HKCategorySample], calendar: Calendar) -> TimeInterval? {
        let grouped = Dictionary(grouping: samples) { sample in
            calendar.startOfDay(for: sample.endDate)
        }
        let durations = grouped.values.map { samples in
            summary(from: samples).duration ?? 0
        }.filter { $0 > 0 }

        return average(durations)
    }

    private static func sleepScore(
        duration: TimeInterval,
        deepDuration: TimeInterval,
        remDuration: TimeInterval,
        wakeAfterSleep: TimeInterval
    ) -> Double {
        let hours = duration / 3_600.0
        let durationScore: Double

        switch hours {
        case 7.5...:
            durationScore = 100
        case 7.0..<7.5:
            durationScore = 88
        case 6.0..<7.0:
            durationScore = 68
        case 5.0..<6.0:
            durationScore = 48
        default:
            durationScore = 30
        }

        var stageAdjustment: Double = 0
        if deepDuration > 0 && deepDuration < 45 * 60 {
            stageAdjustment -= 8
        }
        if remDuration > 0 && remDuration < 60 * 60 {
            stageAdjustment -= 5
        }
        if wakeAfterSleep > 60 * 60 {
            stageAdjustment -= 8
        }

        return max(20, min(100, durationScore + stageAdjustment))
    }

    private static func average(_ values: [Double]) -> Double? {
        let filtered = values.filter { $0.isFinite && $0 > 0 }
        guard !filtered.isEmpty else { return nil }
        return filtered.reduce(0, +) / Double(filtered.count)
    }
}

enum MoriRecoveryTrainingLoadAnalyzer {
    static func summary(
        dayWorkouts: [MoriRecoveryWorkoutSample],
        sevenWorkouts: [MoriRecoveryWorkoutSample],
        twentyEightWorkouts: [MoriRecoveryWorkoutSample],
        highIntensityMinutes: Double
    ) -> MoriRecoveryTrainingSummary {
        let day = load(dayWorkouts)
        let sevenDailyAverage = load(sevenWorkouts).points / 7.0
        let twentyEightDailyAverage = load(twentyEightWorkouts).points / 28.0
        let baseline = max(sevenDailyAverage, twentyEightDailyAverage)
        let isElevated = day.points > 35 && baseline > 0 && day.points > baseline * 1.45

        return MoriRecoveryTrainingSummary(
            lastDayMinutes: day.minutes,
            sevenDayDailyAverage: sevenDailyAverage > 0 ? sevenDailyAverage : nil,
            twentyEightDayDailyAverage: twentyEightDailyAverage > 0 ? twentyEightDailyAverage : nil,
            highIntensityMinutes: highIntensityMinutes > 0 ? highIntensityMinutes : nil,
            loadPoints: day.points,
            isElevated: isElevated
        )
    }

    private static func load(_ workouts: [MoriRecoveryWorkoutSample]) -> (minutes: Double, points: Double) {
        workouts.reduce(into: (minutes: 0.0, points: 0.0)) { result, workout in
            let minutes = workout.duration / 60.0
            let energy = workout.activeEnergyKilocalories
            let distanceKm = workout.distanceMeters / 1_000.0
            result.minutes += minutes
            result.points += minutes + (energy * 0.08) + (distanceKm * 4)
        }
    }
}
