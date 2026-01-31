import SwiftUI
import SwiftData

@main
struct MoriApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GratitudeEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error). This may be caused by schema conflicts or storage permission issues. Try reinstalling the app.")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
