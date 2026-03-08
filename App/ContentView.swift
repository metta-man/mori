import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: UserSettings
    
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
        TabView {
            LifeGridView()
                .tabItem {
                    Label("Life Grid", systemImage: "square.grid.3x3")
                }
            
            ClockView()
                .tabItem {
                    Label("Clock", systemImage: "clock")
                }
            
            GratitudeJournalScreen()
                .tabItem {
                    Label("Gratitude", systemImage: "heart.fill")
                }
            
            HabitTrackerView()
                .tabItem {
                    Label("Habit", systemImage: "plus.forwardslash.minus")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(MoriColors.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSettings())
}
