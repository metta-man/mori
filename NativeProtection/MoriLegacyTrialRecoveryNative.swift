#if os(iOS)
import Foundation
import DeviceActivity
import ManagedSettings

enum MoriLegacyTrialRecoveryNative {
    static func recover() -> MoriLegacyTrialRecovery.Outcome {
        guard let root = root() else { return .pending }
        return MoriLegacyTrialRecovery.recover(root: root, effects: effects())
    }

    /// Consume old trial callbacks before any legacy stores are initialized.
    static func callback(_ activity: DeviceActivityName) -> Bool {
        guard activity.rawValue.hasPrefix(MoriLegacyTrialRecovery.namespace) else { return false }
        guard MoriLegacyTrialRecovery.runID(activity.rawValue) != nil, let root = root() else { return true }
        _ = MoriLegacyTrialRecovery.recoverCallback(activity.rawValue, root: root, effects: effects())
        return true
    }

    private static func root() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MoriAppGroup.identifier)?
            .appendingPathComponent("DebugDeviceTrial-v1", isDirectory: true)
    }

    private static func effects() -> MoriLegacyTrialRecovery.Effects {
        .init(activities: { DeviceActivityCenter().activities.map(\.rawValue) },
              stop: { names in
                  // Empty means stop all activities in this SDK API. Never pass it.
                  guard !names.isEmpty else { return }
                  DeviceActivityCenter().stopMonitoring(names.map { DeviceActivityName($0) })
              },
              clearStore: { name in
                  // Defense at the SDK boundary, in addition to core UUID bounds.
                  guard name.hasPrefix(MoriLegacyTrialRecovery.namespace),
                        let id = UUID(uuidString: String(name.dropFirst(MoriLegacyTrialRecovery.namespace.count))),
                        name == MoriLegacyTrialRecovery.namespace + id.uuidString.lowercased() else { return false }
                  let store = ManagedSettingsStore(named: .init(name))
                  store.shield.applications = nil
                  store.shield.webDomains = nil
                  store.shield.applicationCategories = nil
                  store.shield.webDomainCategories = nil
                  if #available(iOS 26.5, *) { store.isActive = false }
                  let fieldsClear = store.shield.applications == nil && store.shield.webDomains == nil
                      && store.shield.applicationCategories == nil && store.shield.webDomainCategories == nil
                  if #available(iOS 26.5, *) { return fieldsClear && !store.isActive }
                  return fieldsClear
              })
    }
}
#endif
