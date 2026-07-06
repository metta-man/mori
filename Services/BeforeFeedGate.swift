import Foundation

enum BeforeFeedGate {
    private static let store = BeforeFeedGateStore()

    static var isNativeGateEnabled: Bool {
        get {
            store.nativeGateEnabled()
        }
        set {
            store.saveNativeGateEnabled(newValue)
        }
    }

    static var durationSeconds: Int {
        get {
            store.durationSeconds()
        }
        set {
            store.saveDurationSeconds(newValue)
        }
    }

    static var graceWindowSeconds: Int {
        get {
            store.graceWindowSeconds()
        }
        set {
            store.saveGraceWindowSeconds(newValue)
        }
    }

    static var graceUntil: Date? {
        store.graceUntil()
    }

    static var isInGraceWindow: Bool {
        store.isInGraceWindow()
    }

    static var secondsUntilGraceExpires: TimeInterval? {
        store.secondsUntilGraceExpires()
    }

    static func migrateLegacyDurationIfNeeded() {
        store.migrateLegacyDurationIfNeeded()
    }

    static func normalizePersistedSettings(now: Date = Date()) {
        store.normalizePersistedSettings(now: now)
    }

    static func formattedDuration(_ seconds: Int) -> String {
        if let option = MoriScreenTimeShared.beforeFeedDurationOptions.first(where: { $0.seconds == seconds }) {
            return option.label
        }

        if seconds < 60 {
            return MoriL10n.string("duration.seconds", defaultValue: "%d seconds", arguments: [seconds])
        }

        let minutes = seconds / 60
        return MoriL10n.string(
            minutes == 1 ? "duration.minute_one" : "duration.minutes",
            defaultValue: minutes == 1 ? "%d minute" : "%d minutes",
            arguments: [minutes]
        )
    }

    @discardableResult
    static func requestResetLaunchIfNeeded(
        now: Date = Date(),
        source: MoriPendingResetLaunchSource = .screenTimeGate
    ) -> Bool {
        store.requestResetLaunchIfNeeded(now: now, source: source)
    }

    static func consumePendingResetLaunch() -> MoriPendingResetLaunchSource? {
        store.consumePendingResetLaunch()
    }

    @discardableResult
    static func clearExpiredGraceIfNeeded(now: Date = Date()) -> Bool {
        store.clearExpiredGraceIfNeeded(now: now)
    }
}
