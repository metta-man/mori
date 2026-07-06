import Foundation

struct MoriClarityPersistence {
    enum Key {
        static let actions = "mori_clarity_actions"
        static let selectedTopics = "mori_pulse_selected_topics"
        static let topicOrder = "mori_pulse_topic_order"
        static let customTopics = "mori_pulse_custom_topics"
        static let customTopicSymbols = "mori_pulse_custom_topic_symbols"
        static let latestPulse = "mori_latest_pulse"
    }

    static let standard = MoriClarityPersistence()

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        userDefaults.set(data, forKey: key)
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
