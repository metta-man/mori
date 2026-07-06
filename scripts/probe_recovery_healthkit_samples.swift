import Foundation
import HealthKit

enum MoriBitmapIcon: String {
    case lockShield
    case leaf
    case breathe
    case quiet
    case pulse
    case heart

    var legacySystemName: String { rawValue }
}

struct MoriPractice: Equatable {
    let title: String

    static let breatheMinute = MoriPractice(title: "Breathe")
    static let quietNote = MoriPractice(title: "Quiet Note")
    static let focusFifteen = MoriPractice(title: "Focus 15")
    static let walkReset = MoriPractice(title: "Walk Reset")
    static let settleThree = MoriPractice(title: "Settle")
}

enum MoriL10n {
    static func display(_ value: String) -> String {
        value
    }

    static func string(_ key: String, defaultValue: String, arguments: [CVarArg] = []) -> String {
        String(format: defaultValue, arguments: arguments)
    }
}

enum HabitTone {
    case positive
    case neutral
    case negative
}

struct HabitEntry {
    let tone: HabitTone
}

final class HabitDataManager {
    static let shared = HabitDataManager()

    func getTodayEntry() -> HabitEntry? {
        nil
    }
}

final class ProbeRecoveryHealthSampleStore: MoriRecoveryHealthSampleServing {
    private let now: Date
    private let calendar: Calendar
    private(set) var didRequestAuthorization = false

    init(now: Date, calendar: Calendar) {
        self.now = now
        self.calendar = calendar
    }

    func requestAuthorization(readTypes: Set<HKObjectType>) async throws {
        didRequestAuthorization = true

        let requiredTypeIdentifiers = [
            HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue,
            HKQuantityTypeIdentifier.restingHeartRate.rawValue,
            HKQuantityTypeIdentifier.heartRate.rawValue,
            HKQuantityTypeIdentifier.respiratoryRate.rawValue,
            HKQuantityTypeIdentifier.bodyTemperature.rawValue,
            HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue
        ]

        let readTypeIdentifiers = readTypes.map(\.identifier)
        for identifier in requiredTypeIdentifiers where !readTypeIdentifiers.contains(identifier) {
            throw ProbeError.missingReadType(identifier)
        }

        if !readTypes.contains(HKObjectType.workoutType()) {
            throw ProbeError.missingReadType(HKObjectType.workoutType().identifier)
        }

        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
           !readTypes.contains(sleepType) {
            throw ProbeError.missingReadType(sleepType.identifier)
        }
    }

    func quantitySamples(
        identifier: HKQuantityTypeIdentifier,
        start: Date,
        end: Date
    ) async throws -> [HKQuantitySample] {
        switch identifier {
        case .heartRateVariabilitySDNN:
            return filtered(quantitySamples(identifier: identifier, unit: .secondUnit(with: .milli), current: 72, baseline: 68), start: start, end: end)
        case .restingHeartRate:
            return filtered(quantitySamples(identifier: identifier, unit: HKUnit.count().unitDivided(by: .minute()), current: 58, baseline: 61), start: start, end: end)
        case .respiratoryRate:
            return filtered(quantitySamples(identifier: identifier, unit: HKUnit.count().unitDivided(by: .minute()), current: 14.8, baseline: 15.1), start: start, end: end)
        case .bodyTemperature:
            return filtered(quantitySamples(identifier: identifier, unit: .degreeCelsius(), current: 36.4, baseline: 36.5), start: start, end: end)
        case .heartRate:
            return filtered(heartRateWorkoutSamples(), start: start, end: end)
        default:
            return []
        }
    }

    func quantitySamples(
        quantityType: HKQuantityType,
        start: Date,
        end: Date
    ) async throws -> [HKQuantitySample] {
        if quantityType.identifier.contains("AppleSleepingWristTemperature") {
            return filtered(quantitySamples(quantityType: quantityType, unit: .degreeCelsius(), current: 36.4, baseline: 36.5), start: start, end: end)
        }

        return []
    }

    func categorySamples(
        type: HKCategoryType,
        start: Date,
        end: Date
    ) async throws -> [HKCategorySample] {
        filtered(sleepSamples(type: type), start: start, end: end)
    }

    func workouts(start: Date, end: Date) async throws -> [MoriRecoveryWorkoutSample] {
        filtered(workoutSamples(), start: start, end: end)
    }

    private func quantitySamples(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        current: Double,
        baseline: Double
    ) -> [HKQuantitySample] {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return []
        }

        return quantitySamples(quantityType: quantityType, unit: unit, current: current, baseline: baseline)
    }

    private func quantitySamples(
        quantityType: HKQuantityType,
        unit: HKUnit,
        current: Double,
        baseline: Double
    ) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = [
            quantitySample(type: quantityType, unit: unit, value: current, at: calendar.date(byAdding: .hour, value: -4, to: now) ?? now)
        ]

        let todayStart = calendar.startOfDay(for: now)
        for dayOffset in 1...30 {
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: todayStart) ?? todayStart
            let sampleDate = calendar.date(byAdding: .hour, value: 7, to: day) ?? day
            samples.append(quantitySample(type: quantityType, unit: unit, value: baseline, at: sampleDate))
        }

        return samples
    }

    private func quantitySample(
        type: HKQuantityType,
        unit: HKUnit,
        value: Double,
        at date: Date
    ) -> HKQuantitySample {
        HKQuantitySample(
            type: type,
            quantity: HKQuantity(unit: unit, doubleValue: value),
            start: date,
            end: calendar.date(byAdding: .minute, value: 1, to: date) ?? date
        )
    }

    private func sleepSamples(type: HKCategoryType) -> [HKCategorySample] {
        var samples: [HKCategorySample] = []

        let currentStart = calendar.date(byAdding: .hour, value: -10, to: now) ?? now
        samples.append(sleepSample(type: type, value: .asleepDeep, start: currentStart, minutes: 82))
        samples.append(sleepSample(type: type, value: .asleepREM, start: offset(currentStart, minutes: 82), minutes: 96))
        samples.append(sleepSample(type: type, value: .asleepCore, start: offset(currentStart, minutes: 178), minutes: 294))
        samples.append(sleepSample(type: type, value: .awake, start: offset(currentStart, minutes: 472), minutes: 11))

        let todayStart = calendar.startOfDay(for: now)
        for dayOffset in 1...14 {
            let nightEnd = calendar.date(byAdding: .day, value: -dayOffset, to: todayStart) ?? todayStart
            let nightStart = calendar.date(byAdding: .hour, value: -8, to: nightEnd) ?? nightEnd
            samples.append(sleepSample(type: type, value: .asleepDeep, start: nightStart, minutes: 74))
            samples.append(sleepSample(type: type, value: .asleepREM, start: offset(nightStart, minutes: 74), minutes: 88))
            samples.append(sleepSample(type: type, value: .asleepCore, start: offset(nightStart, minutes: 162), minutes: 292))
        }

        return samples
    }

    private func sleepSample(
        type: HKCategoryType,
        value: HKCategoryValueSleepAnalysis,
        start: Date,
        minutes: Int
    ) -> HKCategorySample {
        HKCategorySample(
            type: type,
            value: value.rawValue,
            start: start,
            end: offset(start, minutes: minutes)
        )
    }

    private func workoutSamples() -> [MoriRecoveryWorkoutSample] {
        let todayStart = calendar.startOfDay(for: now)
        let currentStart = calendar.date(byAdding: .hour, value: -18, to: now) ?? now
        var workouts = [
            workout(start: currentStart, minutes: 24, energy: 180, distanceMeters: 2_400)
        ]

        for dayOffset in 2...28 {
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: todayStart) ?? todayStart
            let start = calendar.date(byAdding: .hour, value: 17, to: day) ?? day
            workouts.append(workout(start: start, minutes: 28, energy: 160, distanceMeters: 2_800))
        }

        return workouts
    }

    private func workout(start: Date, minutes: Int, energy: Double, distanceMeters: Double) -> MoriRecoveryWorkoutSample {
        MoriRecoveryWorkoutSample(
            startDate: start,
            endDate: offset(start, minutes: minutes),
            duration: TimeInterval(minutes * 60),
            activeEnergyKilocalories: energy,
            distanceMeters: distanceMeters
        )
    }

    private func heartRateWorkoutSamples() -> [HKQuantitySample] {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return []
        }

        let currentWorkoutStart = calendar.date(byAdding: .hour, value: -18, to: now) ?? now
        return (0..<6).map { minute in
            let date = offset(currentWorkoutStart, minutes: minute)
            return quantitySample(
                type: heartRateType,
                unit: HKUnit.count().unitDivided(by: .minute()),
                value: 146,
                at: date
            )
        }
    }

    private func offset(_ date: Date, minutes: Int) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: date) ?? date
    }

    private func filtered<Sample: HKSample>(_ samples: [Sample], start: Date, end: Date) -> [Sample] {
        samples.filter { sample in
            sample.startDate >= start && sample.endDate <= end
        }
    }

    private func filtered(
        _ samples: [MoriRecoveryWorkoutSample],
        start: Date,
        end: Date
    ) -> [MoriRecoveryWorkoutSample] {
        samples.filter { sample in
            sample.startDate >= start && sample.endDate <= end
        }
    }
}

enum ProbeError: Error, CustomStringConvertible {
    case missingReadType(String)
    case assertion(String)

    var description: String {
        switch self {
        case .missingReadType(let identifier):
            return "Missing required read type: \(identifier)"
        case .assertion(let message):
            return message
        }
    }
}

@main
struct RecoveryHealthKitSampleProbe {
    static func main() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 26, hour: 9, minute: 0))!
        let sampleStore = ProbeRecoveryHealthSampleStore(now: now, calendar: calendar)
        let service = MoriRecoveryHealthService(
            sampleStore: sampleStore,
            calendar: calendar,
            healthDataAvailable: { true },
            nowProvider: { now }
        )

        let snapshot = try await service.snapshot(requestAuthorization: true)
        try assert(sampleStore.didRequestAuthorization, "authorization request was not issued")
        try assert(snapshot.status == .ready, "expected ready status, got \(snapshot.status)")
        try assert(snapshot.state == .openReady, "expected openReady state, got \(snapshot.state)")
        try assert(snapshot.score.map { $0 >= 80 } == true, "expected score >= 80, got \(snapshot.scoreText)")
        try assert(snapshot.sleepSummary.duration != nil, "expected sleep duration")
        try assert(snapshot.trainingSummary.lastDayMinutes > 0, "expected training minutes")
        try assert(snapshot.missingSignals.isEmpty, "expected no missing signals, got \(snapshot.missingSignals)")

        let signalIDs = Set(snapshot.signals.map(\.id))
        for expected in ["hrv", "resting-heart-rate", "sleep", "respiratory-rate", "temperature"] {
            try assert(signalIDs.contains(expected), "missing signal \(expected)")
        }

        print("OK: Recovery HealthKit sample probe produced ready snapshot")
        print("score=\(snapshot.scoreText)")
        print("state=\(snapshot.state.rawValue)")
        print("signals=\(snapshot.signals.map(\.id).joined(separator: ","))")
        print("sleep=\(snapshot.sleepSummary.durationText)")
        print("trainingMinutes=\(Int(snapshot.trainingSummary.lastDayMinutes.rounded()))")
    }

    private static func assert(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw ProbeError.assertion(message)
        }
    }
}
