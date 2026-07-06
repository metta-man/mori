import Foundation

struct TodayFocusDraftStore {
    static let live = TodayFocusDraftStore()

    private let keyPrefix = "mori_life_focus_draft"
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

    private func key(for date: Date) -> String {
        "\(keyPrefix)_\(MoriDateKey.value(for: date))"
    }
}
