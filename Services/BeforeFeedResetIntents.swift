import AppIntents
import Foundation

struct StartBeforeFeedResetIntent: AppIntent, ForegroundContinuableIntent {
    static var title: LocalizedStringResource = "Start Before Feed Reset"
    static var description = IntentDescription("Open Mori for a short reset before entering a feed.")
    static var openAppWhenRun: Bool = false
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard BeforeFeedGate.requestResetLaunchIfNeeded(source: .shortcut) else {
            return .result(dialog: BeforeFeedShortcutDialog.alreadyComplete)
        }

        try await BeforeFeedShortcutLauncher.openBeforeFeedReset(intent: self)
        return .result(dialog: BeforeFeedShortcutDialog.opening)
    }
}

struct StartMorningResetIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Morning Reset"
    static var description = IntentDescription("Open Mori for an app-limited morning reset.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        MorningGate.requestResetLaunch(source: .shortcut)
        return .result(dialog: "Opening Mori for Morning Reset.")
    }
}

struct MoriAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartBeforeFeedResetIntent(),
            phrases: [
                "Start Before Feed Reset in \(.applicationName)",
                "Take a breath with \(.applicationName)",
                "Settle before feed with \(.applicationName)"
            ],
            shortTitle: "Before Feed",
            systemImageName: "leaf.arrow.circlepath"
        )
        AppShortcut(
            intent: StartMorningResetIntent(),
            phrases: [
                "Start Morning Reset in \(.applicationName)",
                "Start my morning with \(.applicationName)",
                "Protect my morning with \(.applicationName)"
            ],
            shortTitle: "Morning Reset",
            systemImageName: "sunrise"
        )
    }
}

private enum BeforeFeedShortcutDialog {
    static let opening: IntentDialog = "shortcut.before_feed.opening"
    static let alreadyComplete: IntentDialog = "shortcut.before_feed.already_complete"
}

private enum BeforeFeedShortcutLauncher {
    static let beforeFeedResetURL = URL(string: "mori://before-feed?source=shortcut")

    static func openBeforeFeedReset(intent: StartBeforeFeedResetIntent) async throws {
        if #available(iOS 26.0, *) {
            try await intent.continueInForeground(
                BeforeFeedShortcutDialog.opening,
                alwaysConfirm: false
            )
            await drainPendingRoutes()
            return
        }

        if #available(iOS 16.4, *) {
            try await intent.requestToContinueInForeground(BeforeFeedShortcutDialog.opening) {
                MoriAppRouteStore.shared.requestPendingRouteDrain()
            }
            return
        }

        await openBeforeFeedReset(opener: .shared)
    }

    @MainActor
    static func openBeforeFeedReset(opener: MoriSystemURLOpener) {
        guard let url = beforeFeedResetURL else { return }
        opener.open(url)
    }

    @MainActor
    private static func drainPendingRoutes() {
        MoriAppRouteStore.shared.requestPendingRouteDrain()
    }
}
