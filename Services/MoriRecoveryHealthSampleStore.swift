import Foundation
import HealthKit

protocol MoriRecoveryHealthSampleServing {
    func requestAuthorization(readTypes: Set<HKObjectType>) async throws

    func quantitySamples(
        identifier: HKQuantityTypeIdentifier,
        start: Date,
        end: Date
    ) async throws -> [HKQuantitySample]

    func quantitySamples(
        quantityType: HKQuantityType,
        start: Date,
        end: Date
    ) async throws -> [HKQuantitySample]

    func categorySamples(
        type: HKCategoryType,
        start: Date,
        end: Date
    ) async throws -> [HKCategorySample]

    func workouts(start: Date, end: Date) async throws -> [MoriRecoveryWorkoutSample]
}

final class MoriRecoveryHealthSampleStore: MoriRecoveryHealthSampleServing {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func requestAuthorization(readTypes: Set<HKObjectType>) async throws {
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func quantitySamples(
        identifier: HKQuantityTypeIdentifier,
        start: Date,
        end: Date
    ) async throws -> [HKQuantitySample] {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { return [] }
        return try await quantitySamples(quantityType: quantityType, start: start, end: end)
    }

    func quantitySamples(
        quantityType: HKQuantityType,
        start: Date,
        end: Date
    ) async throws -> [HKQuantitySample] {
        let samples: [HKQuantitySample] = try await sampleQuery(
            sampleType: quantityType,
            start: start,
            end: end
        )
        return samples
    }

    func categorySamples(
        type: HKCategoryType,
        start: Date,
        end: Date
    ) async throws -> [HKCategorySample] {
        let samples: [HKCategorySample] = try await sampleQuery(
            sampleType: type,
            start: start,
            end: end
        )
        return samples
    }

    func workouts(start: Date, end: Date) async throws -> [MoriRecoveryWorkoutSample] {
        let samples: [HKWorkout] = try await sampleQuery(
            sampleType: HKObjectType.workoutType(),
            start: start,
            end: end
        )
        return samples.map(Self.workoutSample)
    }

    private static func workoutSample(from workout: HKWorkout) -> MoriRecoveryWorkoutSample {
        MoriRecoveryWorkoutSample(
            startDate: workout.startDate,
            endDate: workout.endDate,
            duration: workout.duration,
            activeEnergyKilocalories: quantitySum(
                in: workout,
                identifier: .activeEnergyBurned,
                unit: .kilocalorie()
            ),
            distanceMeters: distanceMeters(in: workout)
        )
    }

    private static func distanceMeters(in workout: HKWorkout) -> Double {
        let distanceIdentifiers: [HKQuantityTypeIdentifier] = [
            .distanceWalkingRunning,
            .distanceCycling,
            .distanceSwimming,
            .distanceWheelchair,
            .distanceDownhillSnowSports
        ]

        return distanceIdentifiers.reduce(0) { total, identifier in
            total + quantitySum(in: workout, identifier: identifier, unit: .meter())
        }
    }

    private static func quantitySum(
        in workout: HKWorkout,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) -> Double {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier),
              let quantity = workout.statistics(for: quantityType)?.sumQuantity()
        else {
            return 0
        }

        return quantity.doubleValue(for: unit)
    }

    private func sampleQuery<Sample: HKSample>(
        sampleType: HKSampleType,
        start: Date,
        end: Date
    ) async throws -> [Sample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples as? [Sample] ?? [])
            }
            healthStore.execute(query)
        }
    }
}
