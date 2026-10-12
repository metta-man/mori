import Foundation

final class MoriCoordinatedPreferences: UserDefaults {
    private let base: UserDefaults
    private let snapshot: ProtectionPreferenceSnapshot
    static func manages(_ key: String) -> Bool {
        key.hasPrefix("mori_screen_time_") || key.hasPrefix("mori_before_feed_") || key.hasPrefix("mori_morning_gate_")
    }
    init(base: UserDefaults, directory: URL) throws {
        self.base = base
        snapshot = .init(url: directory.appendingPathComponent("preferences-v1"), lockURL: directory.appendingPathComponent("writers.lock"))
        // The zero-argument convenience initializer dynamically calls
        // init(suiteName:) on the subclass, which is not inherited here.
        super.init(suiteName: nil)!
        try snapshot.migrate(base.dictionaryRepresentation().filter { Self.manages($0.key) })
    }
    func validateSnapshot() throws { try snapshot.validate() }
    override func object(forKey key: String) -> Any? {
        guard Self.manages(key) else { return base.object(forKey: key) }
        return try? snapshot.object(for: key)
    }
    func objectChecked(forKey key: String) throws -> Any? {
        Self.manages(key) ? try snapshot.object(for: key) : base.object(forKey: key)
    }
    func setChecked(_ value: Any?, forKey key: String) throws {
        try MoriShieldCoordination.exclusive {
            if Self.manages(key) { try snapshot.set(value, for: key) }
            base.set(value, forKey: key)
            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: self)
        }
    }
    override func set(_ value: Any?, forKey key: String) {
        // UserDefaults/AppStorage cannot throw. Critical compensation callers use
        // setChecked/objectChecked and must retain recovery on any failure.
        try? setChecked(value, forKey: key)
    }
    override func removeObject(forKey key: String) { set(nil, forKey: key) }
    override func data(forKey key: String) -> Data? { object(forKey: key) as? Data }
    override func string(forKey key: String) -> String? { object(forKey: key) as? String }
    override func stringArray(forKey key: String) -> [String]? { object(forKey: key) as? [String] }
    override func bool(forKey key: String) -> Bool { (object(forKey: key) as? NSNumber)?.boolValue ?? false }
    override func integer(forKey key: String) -> Int { (object(forKey: key) as? NSNumber)?.intValue ?? 0 }
    override func double(forKey key: String) -> Double { (object(forKey: key) as? NSNumber)?.doubleValue ?? 0 }
}
