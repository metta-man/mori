import SwiftUI

struct LockedScreenTimeSettingsView: View {
    var showsBlockLists = false

    @StateObject private var lockStore = ScreenTimeSettingsLockStore.shared
    @State private var isUnlocked = false

    @ViewBuilder
    private var unlockedContent: some View {
        if showsBlockLists {
            MoriBlockListsView()
        } else {
            ScreenTimeSettingsView()
        }
    }

    var body: some View {
        Group {
            if isUnlocked {
                unlockedContent
            } else if lockStore.isConfigured {
                ScreenTimeSettingsUnlockView {
                    isUnlocked = true
                }
            } else {
                unlockedContent
            }
        }
        .screenTimeSettingsLockLifecycle(onRefresh: lockStore.refresh)
    }
}
