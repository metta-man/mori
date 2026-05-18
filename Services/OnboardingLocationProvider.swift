import CoreLocation
import Foundation

enum OnboardingLocationError: Error {
    case permissionDenied
    case locationUnavailable
    case countryUnavailable
}

final class OnboardingLocationProvider: NSObject {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func requestCountry() async throws -> LocationCountry {
        let location = try await requestLocation()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)

        guard let countryCode = placemarks.first?.isoCountryCode else {
            throw OnboardingLocationError.countryUnavailable
        }

        return LocationCountry(
            code: countryCode,
            name: LifeExpectancyService.countryName(for: countryCode)
        )
    }

    private func requestLocation() async throws -> CLLocation {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            throw OnboardingLocationError.permissionDenied
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            throw OnboardingLocationError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }
}

extension OnboardingLocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            continuation?.resume(throwing: OnboardingLocationError.permissionDenied)
            continuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            continuation?.resume(throwing: OnboardingLocationError.locationUnavailable)
            continuation = nil
            return
        }

        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
