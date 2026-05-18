import Foundation
import HealthKit

enum HealthProfileError: Error {
    case healthDataUnavailable
    case dateOfBirthUnavailable
}

struct HealthProfile {
    let birthDate: Date?
    let gender: UserGender
}

final class HealthProfileProvider {
    private let healthStore = HKHealthStore()

    func requestProfile() async throws -> HealthProfile {
        guard HKHealthStore.isHealthDataAvailable(),
              let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
              let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex) else {
            throw HealthProfileError.healthDataUnavailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: [dateOfBirthType, biologicalSexType])

        return HealthProfile(
            birthDate: try? requestAuthorizedBirthDate(),
            gender: requestAuthorizedGender()
        )
    }

    func requestBirthDate() async throws -> Date {
        let profile = try await requestProfile()
        guard let birthDate = profile.birthDate else {
            throw HealthProfileError.dateOfBirthUnavailable
        }

        return birthDate
    }

    private func requestAuthorizedBirthDate() throws -> Date {
        let components = try healthStore.dateOfBirthComponents()
        guard let birthDate = Calendar.current.date(from: components) else {
            throw HealthProfileError.dateOfBirthUnavailable
        }

        return birthDate
    }

    private func requestAuthorizedGender() -> UserGender {
        guard let biologicalSex = try? healthStore.biologicalSex().biologicalSex else {
            return .unspecified
        }

        switch biologicalSex {
        case .female:
            return .female
        case .male:
            return .male
        default:
            return .unspecified
        }
    }
}
