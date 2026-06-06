import SwiftUI
import UIKit

@main
struct MoriApp: App {
    @StateObject private var userSettings = UserSettings()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize analytics
        AnalyticsManager.shared.configure()
        MoriWatchSettingsSync.shared.activate()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            FocusShieldManager.shared.restoreActiveShieldIfNeeded()
            FocusShieldManager.shared.scheduleDailyThresholdMonitoring()
        }
    }
}
