import Foundation

struct MoriFactorTagOverride: Codable, Equatable {
    var added: Set<MoriFactorTagID> = []
    var hidden: Set<MoriFactorTagID> = []
}

struct MoriRecoveryTagOverrideStore {
    private enum Key {
        static let overrides = "mori_factor_tag_overrides_v1"
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

    func loadOverrides() -> [String: MoriFactorTagOverride] {
        guard let data = defaults.data(forKey: Key.overrides),
              let decoded = try? decoder.decode([String: MoriFactorTagOverride].self, from: data) else {
            return [:]
        }

        return decoded
    }

    func saveOverrides(_ overrides: [String: MoriFactorTagOverride]) {
        guard let data = try? encoder.encode(overrides) else { return }
        defaults.set(data, forKey: Key.overrides)
    }

    func clear() { defaults.removeObject(forKey: Key.overrides) }
}
