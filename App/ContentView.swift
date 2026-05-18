import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var selectedTab: AppTab = .grid
    
    var body: some View {
        Group {
            if !settings.hasCompletedOnboarding {
                MoriOnboardingView()
            } else {
                mainTabView
            }
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            LifeGridView()
                .tabItem {
                    Label("Grid", systemImage: "square.grid.3x3.fill")
                }
                .tag(AppTab.grid)
            
            HabitTrackerView()
                .tabItem {
                    Label("Days", systemImage: "plus.forwardslash.minus")
                }
                .tag(AppTab.habits)
            
            ClockView()
                .tabItem {
                    Label("Clock", systemImage: "clock.fill")
                }
                .tag(AppTab.clock)
            
            GratitudeJournalScreen()
                .tabItem {
                    Label("Journal", systemImage: "heart.text.square.fill")
                }
                .tag(AppTab.journal)
        }
        .tint(MoriColors.moriGold)
        .onOpenURL { url in
            if url.host == "journal" || url.path.contains("journal") {
                selectedTab = .journal
            } else if url.host == "spark" || url.path.contains("spark") {
                selectedTab = .clock
            }
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(MoriColors.moriDark)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(MoriColors.moriGold)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(MoriColors.moriGold)]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(MoriColors.moriCreamMuted)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(MoriColors.moriCreamMuted)]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

private enum AppTab: Hashable {
    case grid
    case habits
    case clock
    case journal
}

#Preview {
    ContentView()
        .environmentObject(UserSettings())
}
