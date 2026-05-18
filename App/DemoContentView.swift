import SwiftUI

struct DemoContentView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var showDemo = false
    
    var body: some View {
        Group {
            if showDemo {
                DesignSystemDemoScreen()
            } else {
                ContentViewWithDemoButton(showDemo: $showDemo)
            }
        }
    }
}

struct ContentViewWithDemoButton: View {
    @Binding var showDemo: Bool
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        ZStack {
            ContentView()
            
            VStack {
                Spacer()
                
                MoriButton(title: "Design System Demo") {
                    showDemo = true
                }
                .padding(.bottom, 100)
                .padding(.horizontal, MoriSpacing.space7)
            }
        }
    }
}

#Preview {
    DemoContentView()
        .environmentObject(UserSettings())
}
