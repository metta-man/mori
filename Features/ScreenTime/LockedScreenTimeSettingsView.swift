import SwiftUI

struct LockedScreenTimeSettingsView: View {
    @StateObject private var lockStore = ScreenTimeSettingsLockStore.shared
    @State private var isUnlocked = false

    var body: some View {
        Group {
            if isUnlocked {
                ScreenTimeSettingsView()
            } else if lockStore.isConfigured {
                ScreenTimeSettingsUnlockView {
                    isUnlocked = true
                }
            } else {
                ScreenTimeSettingsPINSetupView {
                    isUnlocked = true
                }
            }
        }
        .screenTimeSettingsLockLifecycle(onRefresh: lockStore.refresh)
    }
}
