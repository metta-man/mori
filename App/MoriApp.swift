import SwiftUI

@main
struct MoriApp: App {
    @StateObject private var userSettings = UserSettings()
    
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
    }
}
