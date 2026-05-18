import Foundation

struct LocationCountry: Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }
}

struct LifeExpectancyEstimate: Equatable {
    let years: Int
    let sourceDescription: String
}

enum LifeExpectancyLookupError: Error {
    case invalidResponse
    case valueUnavailable
}

final class LifeExpectancyService {
    static let shared = LifeExpectancyService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    static var countries: [LocationCountry] {
        Locale.Region.isoRegions
            .map(\.identifier)
            .map { LocationCountry(code: $0, name: countryName(for: $0)) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func countryName(for code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    static func fallbackEstimate(countryCode: String, gender: UserGender) -> LifeExpectancyEstimate {
        let countryEstimate = fallbackLifeExpectancies[countryCode.uppercased()] ?? fallbackLifeExpectancies["001"]!
        let years: Int

        switch gender {
        case .female:
            years = countryEstimate.female
        case .male:
            years = countryEstimate.male
        case .unspecified:
            years = countryEstimate.total
        }

        return LifeExpectancyEstimate(
            years: years,
            sourceDescription: "Using bundled estimate for \(countryName(for: countryCode))"
        )
    }

    func estimate(countryCode: String, gender: UserGender) async -> LifeExpectancyEstimate {
        do {
            return try await fetchWorldBankEstimate(countryCode: countryCode, gender: gender)
        } catch {
            return Self.fallbackEstimate(countryCode: countryCode, gender: gender)
        }
    }

    private func fetchWorldBankEstimate(countryCode: String, gender: UserGender) async throws -> LifeExpectancyEstimate {
        let indicator = worldBankIndicator(for: gender)
        let urlString = "https://api.worldbank.org/v2/country/\(countryCode)/indicator/\(indicator)?format=json&per_page=1&mrv=1"
        guard let url = URL(string: urlString) else {
            throw LifeExpectancyLookupError.invalidResponse
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LifeExpectancyLookupError.invalidResponse
        }

        let payload = try JSONDecoder().decode([WorldBankResponse].self, from: data)
        guard payload.count > 1,
              let latest = payload[1].first,
              let value = latest.value else {
            throw LifeExpectancyLookupError.valueUnavailable
        }

        return LifeExpectancyEstimate(
            years: Int(value.rounded()),
            sourceDescription: "World Bank \(latest.date) estimate for \(Self.countryName(for: countryCode))"
        )
    }

    private func worldBankIndicator(for gender: UserGender) -> String {
        switch gender {
        case .female:
            return "SP.DYN.LE00.FE.IN"
        case .male:
            return "SP.DYN.LE00.MA.IN"
        case .unspecified:
            return "SP.DYN.LE00.IN"
        }
    }
}

private struct LifeExpectancyFallback {
    let female: Int
    let male: Int
    let total: Int
}

private let fallbackLifeExpectancies: [String: LifeExpectancyFallback] = [
    "001": .init(female: 76, male: 71, total: 73),
    "AU": .init(female: 85, male: 81, total: 83),
    "BR": .init(female: 76, male: 70, total: 73),
    "CA": .init(female: 84, male: 80, total: 82),
    "CN": .init(female: 81, male: 75, total: 78),
    "DE": .init(female: 83, male: 78, total: 81),
    "ES": .init(female: 86, male: 81, total: 84),
    "FR": .init(female: 86, male: 80, total: 83),
    "GB": .init(female: 83, male: 79, total: 81),
    "HK": .init(female: 88, male: 82, total: 85),
    "IN": .init(female: 72, male: 69, total: 70),
    "IT": .init(female: 85, male: 81, total: 83),
    "JP": .init(female: 88, male: 82, total: 85),
    "KR": .init(female: 87, male: 81, total: 84),
    "MX": .init(female: 78, male: 72, total: 75),
    "NL": .init(female: 84, male: 81, total: 82),
    "SG": .init(female: 86, male: 82, total: 84),
    "TW": .init(female: 84, male: 78, total: 81),
    "US": .init(female: 80, male: 75, total: 78)
]

private struct WorldBankIndicatorValue: Decodable {
    let date: String
    let value: Double?
}

private enum WorldBankResponse: Decodable {
    case metadata
    case values([WorldBankIndicatorValue])

    init(from decoder: Decoder) throws {
        if let values = try? [WorldBankIndicatorValue](from: decoder) {
            self = .values(values)
        } else {
            self = .metadata
        }
    }

    var first: WorldBankIndicatorValue? {
        if case .values(let values) = self {
            return values.first
        }

        return nil
    }
}
