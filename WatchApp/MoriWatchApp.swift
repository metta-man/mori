import SwiftUI

@main
struct MoriWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var notificationCenter = MoriWatchNotificationCenter.shared
    @StateObject private var routeStore = MoriWatchRouteStore.shared
    @AppStorage(MoriLocalePreference.defaultsKey, store: MoriSharedDefaults.shared) private var localePreferenceRaw = MoriLocalePreference.system.rawValue

    init() {
        MoriWatchSettingsReceiver.shared.activate()
        MoriWatchNotificationCenter.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            MoriWatchResetHub(notificationCenter: notificationCenter, routeStore: routeStore)
                .environment(\.locale, localePreference.locale)
                .id(localePreference.rawValue)
                .onOpenURL { url in
                    routeStore.open(url)
                    MoriWatchSettingsReceiver.shared.activate()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        MoriWatchSettingsReceiver.shared.activate()
                        MoriWatchBellScheduler.shared.refreshIfNeeded()
                    }
                }
        }
    }

    private var localePreference: MoriLocalePreference {
        MoriLocalePreference(rawValue: localePreferenceRaw) ?? .system
    }
}
