import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var selectedTab: AppTab = .today
    
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
            TodayView(onOpenSettle: {
                selectedTab = .settle
            })
                .tabItem {
                    Label("Today", systemImage: "leaf.fill")
                }
                .tag(AppTab.today)

            LifeGridView()
                .tabItem {
                    Label("Life Grid", systemImage: "square.grid.3x3.fill")
                }
                .tag(AppTab.grid)

            SettleView()
                .tabItem {
                    Label("Settle", systemImage: "figure.mind.and.body")
                }
                .tag(AppTab.settle)

            ClarityPulseView(onOpenSettle: {
                selectedTab = .settle
            })
                .tabItem {
                    Label("Pulse", systemImage: "sparkles")
                }
                .tag(AppTab.pulse)

            RootsGrowthView()
                .tabItem {
                    Label("Roots", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.roots)
        }
        .tint(MoriColors.forestCanopy)
        .onOpenURL { url in
            if url.host == "journal" || url.path.contains("journal") {
                selectedTab = .roots
            } else if url.host == "spark" || url.path.contains("spark") {
                selectedTab = .today
            } else if url.host == "pulse" || url.path.contains("pulse") {
                selectedTab = .pulse
            } else if url.host == "settle" || url.path.contains("settle") {
                selectedTab = .settle
            } else if url.host == "quiet" || url.path.contains("quiet") {
                selectedTab = .today
            }
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(MoriColors.forestCard)
            appearance.shadowColor = UIColor(MoriColors.forestLine.opacity(0.65))
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(MoriColors.forestCanopy)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(MoriColors.forestCanopy)]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(MoriColors.forestMuted)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(MoriColors.forestMuted)]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

private enum AppTab: Hashable {
    case today
    case grid
    case settle
    case pulse
    case roots
}

#Preview {
    ContentView()
        .environmentObject(UserSettings())
}
