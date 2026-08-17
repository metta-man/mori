import Foundation

struct MoriRecoveryHistoryPersistence {
    private enum Key {
        static let indicators = "mori_recovery_daily_indicators_v1"
    }

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.encoder = encoder
        self.decoder = decoder
    }

    func loadIndicators() -> [MoriRecoveryDailyIndicator] {
        guard let data = defaults.data(forKey: Key.indicators),
              let decoded = try? decoder.decode([MoriRecoveryDailyIndicator].self, from: data) else {
            return []
        }

        return decoded.sorted { $0.date < $1.date }
    }

    func saveIndicators(_ indicators: [MoriRecoveryDailyIndicator]) {
        guard let data = try? encoder.encode(indicators) else { return }
        defaults.set(data, forKey: Key.indicators)
    }

    func clear() { defaults.removeObject(forKey: Key.indicators) }
}
