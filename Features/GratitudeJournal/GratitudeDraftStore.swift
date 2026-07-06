import Foundation

struct GratitudeDraftStore {
    private enum Key {
        static let draft = "mori_gratitude_draft"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        self.encoder = encoder
        self.decoder = decoder
    }

    func loadForToday() -> GratitudeDraft? {
        guard let data = defaults.data(forKey: Key.draft),
              let draft = try? decoder.decode(GratitudeDraft.self, from: data) else {
            return nil
        }

        guard calendar.isDate(draft.entryDate, inSameDayAs: now()) else {
            clear()
            return nil
        }

        return draft
    }

    func save(_ draft: GratitudeDraft) {
        guard let data = try? encoder.encode(draft) else { return }
        defaults.set(data, forKey: Key.draft)
    }

    func clear() {
        defaults.removeObject(forKey: Key.draft)
    }
}
