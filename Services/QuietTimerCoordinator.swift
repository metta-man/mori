import Foundation
import UserNotifications

@MainActor
enum QuietTimerCoordinator {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private static var defaults: UserDefaults {
        MoriAppGroup.defaults
    }

    static func loadSession() -> MoriQuietTimerSession? {
        guard let data = defaults.data(forKey: MoriScreenTimeShared.quietTimerSessionKey) else {
            return nil
        }
        return try? decoder.decode(MoriQuietTimerSession.self, from: data)
    }

    static func saveSession(_ session: MoriQuietTimerSession) {
        guard let data = try? encoder.encode(session) else { return }
        defaults.set(data, forKey: MoriScreenTimeShared.quietTimerSessionKey)
    }

    static func clearSession() {
        defaults.removeObject(forKey: MoriScreenTimeShared.quietTimerSessionKey)
    }

    @discardableResult
    static func reconcileExpiredSession(
        clarityStore: MoriClarityStore? = nil,
        appLimitManager: AppLimitManager? = nil,
        now: Date = Date()
    ) -> MoriQuietTimerSession? {
        guard var session = loadSession() else { return nil }

        let clarityStore = clarityStore ?? .shared
        let appLimitManager = appLimitManager ?? .shared

        if session.isRunning && session.remainingSeconds(at: now) <= 0 {
            completeSession(session, clarityStore: clarityStore, appLimitManager: appLimitManager)
            return nil
        }

        if session.isRunning {
            session.remainingSeconds = session.remainingSeconds(at: now)
            saveSession(session)
        }

        return session
    }

    static func completeSession(
        _ session: MoriQuietTimerSession,
        clarityStore: MoriClarityStore? = nil,
        appLimitManager: AppLimitManager? = nil
    ) {
        let clarityStore = clarityStore ?? .shared
        let appLimitManager = appLimitManager ?? .shared
        guard var completedSession = loadSession() ?? (session.didRecordCompletion ? session : nil) else {
            cancelCompletionNotification()
            appLimitManager.perform(.endAppLimit(feature: .quiet))
            return
        }

        guard !completedSession.didRecordCompletion else {
            cancelCompletionNotification()
            appLimitManager.perform(.endAppLimit(feature: .quiet))
            clearSession()
            return
        }

        completedSession.didRecordCompletion = true
        saveSession(completedSession)

        let minutes = max(1, completedSession.durationSeconds / 60)
        let title = "\(MoriQuietTimerDuration.formattedTitle(completedSession.durationSeconds)) quiet timer"
        clarityStore.record(
            kind: .quietTimer,
            title: title,
            seeds: max(2, minutes / 5),
            minutes: minutes,
            note: "Completed a social detox timer"
        )

        if completedSession.quietShieldWasActive {
            clarityStore.record(
                kind: .screenTimeLimitKept,
                title: "App-Limited Quiet Mode",
                seeds: 1,
                minutes: minutes,
                note: "Kept selected apps limited during Quiet Mode"
            )
        }

        cancelCompletionNotification()
        appLimitManager.perform(.endAppLimit(feature: .quiet))
        clearSession()
    }

    static func scheduleCompletionNotification(for session: MoriQuietTimerSession) {
        let secondsUntilEnd = session.endDate.timeIntervalSinceNow
        guard secondsUntilEnd > 1 else { return }

        cancelCompletionNotification()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    guard granted else { return }
                    addCompletionNotification(after: secondsUntilEnd, durationSeconds: session.durationSeconds)
                }
            case .authorized, .provisional, .ephemeral:
                addCompletionNotification(after: secondsUntilEnd, durationSeconds: session.durationSeconds)
            case .denied:
                return
            @unknown default:
                return
            }
        }
    }

    static func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [MoriScreenTimeShared.quietTimerCompletionNotificationIdentifier]
        )
    }

    private nonisolated static func addCompletionNotification(after seconds: TimeInterval, durationSeconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = MoriL10n.string("notification.quiet_timer_complete", defaultValue: "Quiet timer complete")
        content.body = MoriL10n.string(
            "notification.quiet_timer_body",
            defaultValue: "Your %@ detox is complete.",
            arguments: [MoriQuietTimerDuration.formattedTitle(durationSeconds)]
        )
        content.sound = .default
        content.userInfo = MoriNotificationRouter.userInfo(for: .practice)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: MoriScreenTimeShared.quietTimerCompletionNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
        UNUserNotificationCenter.current().add(request)
    }
}
