import Foundation
import HealthKit

enum MoriRecoveryHealthServiceError: Error {
    case healthDataUnavailable
}

final class MoriRecoveryHealthService {
    private let sampleStore: MoriRecoveryHealthSampleServing
    private let calendar: Calendar
    private let healthDataAvailable: () -> Bool
    private let nowProvider: () -> Date

    init(
        sampleStore: MoriRecoveryHealthSampleServing = MoriRecoveryHealthSampleStore(),
        calendar: Calendar = .current,
        healthDataAvailable: @escaping () -> Bool = { HKHealthStore.isHealthDataAvailable() },
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.sampleStore = sampleStore
        self.calendar = calendar
        self.healthDataAvailable = healthDataAvailable
        self.nowProvider = nowProvider
    }

    func snapshot(requestAuthorization: Bool) async throws -> MoriRecoverySnapshot {
        guard healthDataAvailable() else {
            throw MoriRecoveryHealthServiceError.healthDataUnavailable
        }

        if requestAuthorization {
            try await sampleStore.requestAuthorization(readTypes: readTypes)
        }

        let now = nowProvider()
        async let hrv = quantityCurrentAndBaseline(
            identifier: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            now: now,
            currentWindowHours: 36
        )
        async let restingHeartRate = quantityCurrentAndBaseline(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            now: now,
            currentWindowHours: 36
        )
        async let respiratoryRate = quantityCurrentAndBaseline(
            identifier: .respiratoryRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            now: now,
            currentWindowHours: 36
        )
        async let bodyTemperature = temperatureCurrentAndBaseline(now: now)
        async let sleep = sleepSummary(now: now)
        async let sleepBaseline = sleepBaselineDuration(now: now)
        async let training = trainingSummary(now: now)

        let readings = try await RecoveryReadings(
            hrv: hrv,
            restingHeartRate: restingHeartRate,
            respiratoryRate: respiratoryRate,
            temperature: bodyTemperature,
            sleep: sleep,
            sleepBaselineDuration: sleepBaseline,
            training: training
        )

        return makeSnapshot(from: readings, now: now)
    }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]

        [
            HKQuantityTypeIdentifier.heartRateVariabilitySDNN,
            .restingHeartRate,
            .heartRate,
            .respiratoryRate,
            .bodyTemperature,
            .activeEnergyBurned,
            .distanceWalkingRunning
        ].compactMap { HKObjectType.quantityType(forIdentifier: $0) }
            .forEach { types.insert($0) }

        if let wristTemperatureType = HKObjectType.quantityType(forIdentifier: Self.wristTemperatureIdentifier) {
            types.insert(wristTemperatureType)
        }

        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }

        return types
    }

    private static let wristTemperatureIdentifier = HKQuantityTypeIdentifier(
        rawValue: "HKQuantityTypeIdentifierAppleSleepingWristTemperature"
    )

    private func makeSnapshot(from readings: RecoveryReadings, now: Date) -> MoriRecoverySnapshot {
        var weightedScores: [WeightedScore] = []
        var signals: [MoriRecoverySignal] = []
        var missingSignals: [String] = []

        if let score = hrvScore(current: readings.hrv.current, baseline: readings.hrv.preferredBaseline) {
            weightedScores.append(WeightedScore(value: score, weight: 35))
            signals.append(hrvSignal(readings.hrv, score: score))
        } else {
            missingSignals.append(MoriL10n.display("HRV"))
        }

        if let score = restingHeartRateScore(
            current: readings.restingHeartRate.current,
            baseline: readings.restingHeartRate.preferredBaseline
        ) {
            weightedScores.append(WeightedScore(value: score, weight: 25))
            signals.append(restingHeartRateSignal(readings.restingHeartRate, score: score))
        } else {
            missingSignals.append(MoriL10n.display("Resting heart rate"))
        }

        if let score = readings.sleep.score {
            weightedScores.append(WeightedScore(value: score, weight: 25))
            signals.append(sleepSignal(readings.sleep, baselineDuration: readings.sleepBaselineDuration, score: score))
        } else {
            missingSignals.append(MoriL10n.display("Sleep"))
        }

        if let score = respiratoryTemperatureScore(
            respiratoryRate: readings.respiratoryRate,
            temperature: readings.temperature
        ) {
            weightedScores.append(WeightedScore(value: score, weight: 10))
            signals.append(respiratorySignal(readings.respiratoryRate))
            signals.append(temperatureSignal(readings.temperature))
        } else {
            missingSignals.append(MoriL10n.display("Respiratory / temperature"))
        }

        let moodScore = subjectiveMoodScore()
        weightedScores.append(WeightedScore(value: moodScore, weight: 5))

        let finalScore: Int?
        if weightedScores.isEmpty {
            finalScore = nil
        } else {
            let weightedTotal = weightedScores.reduce(0) { $0 + ($1.value * $1.weight) }
            let weightTotal = weightedScores.reduce(0) { $0 + $1.weight }
            finalScore = Int((weightedTotal / max(weightTotal, 1)).rounded())
        }

        let state = readinessState(for: finalScore)
        let bodyLoadLabel = bodyLoadLabel(
            restingHeartRate: readings.restingHeartRate,
            hrv: readings.hrv,
            respiratoryRate: readings.respiratoryRate,
            temperature: readings.temperature,
            training: readings.training
        )
        let nervousSystemLabel = nervousSystemLabel(score: finalScore, hrv: readings.hrv, restingHeartRate: readings.restingHeartRate)
        let suggestedPractice = suggestedPractice(
            score: finalScore,
            hrv: readings.hrv,
            restingHeartRate: readings.restingHeartRate,
            sleep: readings.sleep,
            training: readings.training
        )
        let primaryMessage = primaryMessage(
            state: state,
            hrv: readings.hrv,
            restingHeartRate: readings.restingHeartRate,
            sleep: readings.sleep,
            training: readings.training
        )

        return MoriRecoverySnapshot(
            date: now,
            score: finalScore,
            state: state,
            status: finalScore == nil && signals.isEmpty ? .missingData : .ready,
            nervousSystemLabel: nervousSystemLabel,
            bodyLoadLabel: bodyLoadLabel,
            sleepSummary: readings.sleep,
            trainingSummary: readings.training,
            suggestedPractice: suggestedPractice,
            primaryMessage: primaryMessage,
            signals: signals.filter { $0.status != .unavailable },
            missingSignals: missingSignals
        )
    }

    private func quantityCurrentAndBaseline(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        now: Date,
        currentWindowHours: Int
    ) async throws -> QuantityBaseline {
        let currentStart = calendar.date(byAdding: .hour, value: -currentWindowHours, to: now) ?? now
        let currentSamples = try await sampleStore.quantitySamples(identifier: identifier, start: currentStart, end: now)
        let current = average(currentSamples, unit: unit)

        let todayStart = calendar.startOfDay(for: now)
        let sevenStart = calendar.date(byAdding: .day, value: -7, to: todayStart) ?? todayStart
        let thirtyStart = calendar.date(byAdding: .day, value: -30, to: todayStart) ?? todayStart
        let baselineSamples = try await sampleStore.quantitySamples(identifier: identifier, start: thirtyStart, end: todayStart)
        let daily = dailyAverages(samples: baselineSamples, unit: unit)

        return QuantityBaseline(
            current: current,
            sevenDayAverage: average(daily.filter { $0.date >= sevenStart }.map(\.value)),
            thirtyDayAverage: average(daily.map(\.value))
        )
    }

    private func temperatureCurrentAndBaseline(now: Date) async throws -> QuantityBaseline {
        if let wristType = HKObjectType.quantityType(forIdentifier: Self.wristTemperatureIdentifier) {
            let wrist = try await quantityCurrentAndBaseline(
                quantityType: wristType,
                unit: .degreeCelsius(),
                now: now,
                currentWindowHours: 36
            )

            if wrist.current != nil || wrist.preferredBaseline != nil {
                return wrist
            }
        }

        return try await quantityCurrentAndBaseline(
            identifier: .bodyTemperature,
            unit: .degreeCelsius(),
            now: now,
            currentWindowHours: 36
        )
    }

    private func quantityCurrentAndBaseline(
        quantityType: HKQuantityType,
        unit: HKUnit,
        now: Date,
        currentWindowHours: Int
    ) async throws -> QuantityBaseline {
        let currentStart = calendar.date(byAdding: .hour, value: -currentWindowHours, to: now) ?? now
        let currentSamples = try await sampleStore.quantitySamples(quantityType: quantityType, start: currentStart, end: now)
        let current = average(currentSamples, unit: unit)

        let todayStart = calendar.startOfDay(for: now)
        let sevenStart = calendar.date(byAdding: .day, value: -7, to: todayStart) ?? todayStart
        let thirtyStart = calendar.date(byAdding: .day, value: -30, to: todayStart) ?? todayStart
        let baselineSamples = try await sampleStore.quantitySamples(quantityType: quantityType, start: thirtyStart, end: todayStart)
        let daily = dailyAverages(samples: baselineSamples, unit: unit)

        return QuantityBaseline(
            current: current,
            sevenDayAverage: average(daily.filter { $0.date >= sevenStart }.map(\.value)),
            thirtyDayAverage: average(daily.map(\.value))
        )
    }

    private func sleepSummary(now: Date) async throws -> MoriRecoverySleepSummary {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return .unavailable
        }

        let start = calendar.date(byAdding: .hour, value: -36, to: now) ?? now
        let samples = try await sampleStore.categorySamples(type: sleepType, start: start, end: now)
        return MoriRecoverySleepAnalyzer.summary(from: samples)
    }

    private func sleepBaselineDuration(now: Date) async throws -> TimeInterval? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let todayStart = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -30, to: todayStart) ?? todayStart
        let samples = try await sampleStore.categorySamples(type: sleepType, start: start, end: todayStart)
        return MoriRecoverySleepAnalyzer.baselineDuration(from: samples, calendar: calendar)
    }

    private func trainingSummary(now: Date) async throws -> MoriRecoveryTrainingSummary {
        let dayStart = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let sevenStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let twentyEightStart = calendar.date(byAdding: .day, value: -28, to: now) ?? now

        let dayWorkouts = try await sampleStore.workouts(start: dayStart, end: now)
        let sevenWorkouts = try await sampleStore.workouts(start: sevenStart, end: now)
        let twentyEightWorkouts = try await sampleStore.workouts(start: twentyEightStart, end: now)
        let highIntensityMinutes = try await highIntensityMinutes(in: dayWorkouts)

        return MoriRecoveryTrainingLoadAnalyzer.summary(
            dayWorkouts: dayWorkouts,
            sevenWorkouts: sevenWorkouts,
            twentyEightWorkouts: twentyEightWorkouts,
            highIntensityMinutes: highIntensityMinutes
        )
    }

    private func highIntensityMinutes(in workouts: [MoriRecoveryWorkoutSample]) async throws -> Double {
        var seconds: TimeInterval = 0
        let unit = HKUnit.count().unitDivided(by: .minute())

        for workout in workouts {
            let samples = try await sampleStore.quantitySamples(identifier: .heartRate, start: workout.startDate, end: workout.endDate)
            guard !samples.isEmpty else { continue }

            for index in samples.indices {
                let sample = samples[index]
                let bpm = sample.quantity.doubleValue(for: unit)
                guard bpm >= 140 else { continue }

                let nextDate = samples.indices.contains(index + 1) ? samples[index + 1].startDate : sample.endDate
                let sampleSeconds = max(0, min(60, nextDate.timeIntervalSince(sample.startDate)))
                seconds += sampleSeconds
            }
        }

        return seconds / 60.0
    }

    private func dailyAverages(samples: [HKQuantitySample], unit: HKUnit) -> [(date: Date, value: Double)] {
        let grouped = Dictionary(grouping: samples) { sample in
            calendar.startOfDay(for: sample.startDate)
        }

        return grouped.map { date, samples in
            (date, average(samples, unit: unit) ?? 0)
        }.filter { $0.value > 0 }
    }

    private func average(_ samples: [HKQuantitySample], unit: HKUnit) -> Double? {
        average(samples.map { $0.quantity.doubleValue(for: unit) })
    }
}
