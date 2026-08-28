import Foundation

struct TodayFocusDraftStore {
    static let live = TodayFocusDraftStore()

    private static let keyPrefix = "mori_life_focus_draft"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(for date: Date) -> String {
        defaults.string(forKey: key(for: date)) ?? ""
    }

    func save(_ value: String, for date: Date) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            defaults.removeObject(forKey: key(for: date))
        } else {
            defaults.set(value, forKey: key(for: date))
        }
    }

    func clearAll() {
        let ownedPrefix = "\(Self.keyPrefix)_"
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(ownedPrefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private func key(for date: Date) -> String {
        "\(Self.keyPrefix)_\(MoriDateKey.value(for: date))"
    }
}
