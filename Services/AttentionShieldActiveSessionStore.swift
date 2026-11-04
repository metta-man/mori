import Foundation

struct AttentionShieldActiveSessionStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = MoriAppGroup.defaults) {
        self.defaults = defaults
    }

    func startSession(
        feature: MoriScreenTimeFeature,
        endDate: Date,
        endPolicy: MoriScreenTimeSessionEndPolicy = .timed,
        now: Date = Date()
    ) -> MoriScreenTimeActiveSession {
        let session = MoriScreenTimeActiveSession(
            feature: feature,
            startedAt: now,
            endDate: endDate,
            endPolicy: endPolicy
        )
        persist(session)
        return session
    }

    func persist(_ session: MoriScreenTimeActiveSession) {
        return MoriShieldCoordination.legacy(fallback: ()) {

        guard let data = try? encoder.encode(session) else { return }
        defaults.set(data, forKey: MoriScreenTimeShared.activeSessionKey)

        }
    }

    func load() -> MoriScreenTimeActiveSession? {
        guard let data = defaults.data(forKey: MoriScreenTimeShared.activeSessionKey) else { return nil }
        return try? decoder.decode(MoriScreenTimeActiveSession.self, from: data)
    }

    /// Non-mutating; an expired valid session is distinct from unreadable data.
    func loadChecked(using reader: ProtectionCheckedInputReader) throws -> MoriScreenTimeActiveSession? {
        guard let session = try reader.decoded(MoriScreenTimeShared.activeSessionKey, as: MoriScreenTimeActiveSession.self, decoder: decoder) else { return nil }
        guard session.startedAt.timeIntervalSince1970.isFinite, session.endDate.timeIntervalSince1970.isFinite,
              session.endDate >= session.startedAt else { throw ProtectionCheckedInputError.invalidValue(MoriScreenTimeShared.activeSessionKey) }
        return session
    }

    func loadUnexpiredSession(now: Date = Date()) -> MoriScreenTimeActiveSession? {
        guard let session = load() else { return nil }
        guard !session.isExpired(at: now) else {
            clear()
            return nil
        }
        return session
    }

    func clear() {
        return MoriShieldCoordination.legacy(fallback: ()) {

        defaults.removeObject(forKey: MoriScreenTimeShared.activeSessionKey)

        }
    }
}
