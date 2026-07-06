import Foundation

struct MoriNotificationRouteStore {
    private enum Key {
        static let pendingTarget = "mori_pending_deep_link_target"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func savePendingTarget(_ target: MoriDeepLinkTarget) {
        defaults.set(target.rawValue, forKey: Key.pendingTarget)
    }

    func consumePendingTarget() -> MoriDeepLinkTarget? {
        guard let rawValue = defaults.string(forKey: Key.pendingTarget),
              let target = MoriDeepLinkTarget(rawValue: rawValue) else {
            return nil
        }

        defaults.removeObject(forKey: Key.pendingTarget)
        return target
    }
}
