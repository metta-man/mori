import Foundation

struct SettleSessionPersistence {
    private enum Key {
        static let sessions = "mori_settle_sessions"
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

    func loadSessions() -> [SettleSession] {
        guard let data = defaults.data(forKey: Key.sessions),
              let decoded = try? decoder.decode([SettleSession].self, from: data)
        else {
            return []
        }

        return decoded.sorted { $0.startedAt > $1.startedAt }
    }

    func saveSessions(_ sessions: [SettleSession]) {
        guard let data = try? encoder.encode(sessions) else { return }
        defaults.set(data, forKey: Key.sessions)
    }
}
