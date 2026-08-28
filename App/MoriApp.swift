import SwiftUI
import UIKit
import UserNotifications

final class MoriAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: MindfulnessBellDefaults.categoryIdentifier,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        ])
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard notification.request.content.categoryIdentifier == MindfulnessBellDefaults.categoryIdentifier else {
            return []
        }

        await MainActor.run {
            SettleBellService.shared.playIntervalBell()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        MindfulnessBellScheduler.shared.refreshIfNeeded()
        return []
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        MoriNotificationRouter.handleNotificationResponse(response)
        if response.notification.request.content.categoryIdentifier == MindfulnessBellDefaults.categoryIdentifier {
            MindfulnessBellScheduler.shared.refreshIfNeeded()
        }
    }
}

@main
struct MoriApp: App {
    @UIApplicationDelegateAdaptor(MoriAppDelegate.self) private var appDelegate
    @StateObject private var userSettings = UserSettings()
    
    init() {
        // Initialize analytics
        AnalyticsManager.shared.configure()
        MoriWatchSettingsSync.shared.activate()
        let beforeFeedPausePreferences = MoriBeforeFeedPausePreferences()
        beforeFeedPausePreferences.migrateLegacyPausePreferencesIfNeeded()
        BeforeFeedGate.migrateLegacyDurationIfNeeded()
        beforeFeedPausePreferences.normalizePersistedSettings()
        BeforeFeedGate.normalizePersistedSettings()
        MorningGate.normalizePersistedSettings()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .environment(\.locale, userSettings.localePreference.locale)
                .id(userSettings.localePreference.rawValue)
                .moriAppTheme()
                .moriAppLifecycle(userSettings: userSettings)
        }
    }
}
