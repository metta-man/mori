import Foundation
import UserNotifications

struct BeforeFeedWindowEndNotificationPlan: Equatable {
    let identifier: String
    let fireDate: Date
    let title: String
    let body: String

    static func make(graceUntil: Date, now: Date = Date()) -> Self? {
        guard graceUntil.timeIntervalSince(now) > 1 else { return nil }

        return Self(
            identifier: MoriScreenTimeShared.beforeFeedWindowEndNotificationIdentifier,
            fireDate: graceUntil,
            title: MoriL10n.string(
                "notification.before_feed_window_complete.title",
                defaultValue: "Feed window complete"
            ),
            body: MoriL10n.string(
                "notification.before_feed_window_complete.body",
                defaultValue: "Time’s up. Returning to your life."
            )
        )
    }
}

protocol BeforeFeedWindowEndNotificationCenter: AnyObject {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAlertAuthorization() async -> Bool
    func add(_ request: UNNotificationRequest) async
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

final class SystemBeforeFeedWindowEndNotificationCenter: BeforeFeedWindowEndNotificationCenter {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAlertAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert])) ?? false
    }

    func add(_ request: UNNotificationRequest) async {
        try? await center.add(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

/// Optional feedback at the end of a Before Feed window. Shield enforcement
/// does not depend on this scheduler or on notification permission.
@MainActor
final class BeforeFeedWindowEndNotificationScheduler {
    static let shared = BeforeFeedWindowEndNotificationScheduler()

    private let center: any BeforeFeedWindowEndNotificationCenter
    private let gateStore: BeforeFeedGateStore
    private var schedulingGeneration = 0

    init(
        center: any BeforeFeedWindowEndNotificationCenter = SystemBeforeFeedWindowEndNotificationCenter(),
        gateStore: BeforeFeedGateStore = BeforeFeedGateStore()
    ) {
        self.center = center
        self.gateStore = gateStore
    }

    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch await center.authorizationStatus() {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .notDetermined:
                completion(await center.requestAlertAuthorization())
            case .denied:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }

    /// Checks current permission without prompting. Scheduling failure is
    /// intentionally silent so opening and re-shielding continue normally.
    func scheduleIfPermitted(at graceUntil: Date, now: Date = Date()) {
        schedulingGeneration += 1
        let generation = schedulingGeneration
        center.removePendingNotificationRequests(
            withIdentifiers: [MoriScreenTimeShared.beforeFeedWindowEndNotificationIdentifier]
        )

        guard gateStore.windowEndReminderEnabled(),
              let plan = BeforeFeedWindowEndNotificationPlan.make(graceUntil: graceUntil, now: now)
        else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let authorizationStatus = await center.authorizationStatus()
            guard generation == schedulingGeneration else { return }
            switch authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                guard let request = notificationRequest(for: plan, now: Date()) else { return }
                await center.add(request)
                if generation != schedulingGeneration {
                    center.removePendingNotificationRequests(withIdentifiers: [plan.identifier])
                }
            case .notDetermined, .denied:
                return
            @unknown default:
                return
            }
        }
    }

    func cancel() {
        schedulingGeneration += 1
        center.removePendingNotificationRequests(
            withIdentifiers: [MoriScreenTimeShared.beforeFeedWindowEndNotificationIdentifier]
        )
    }

    private func notificationRequest(
        for plan: BeforeFeedWindowEndNotificationPlan,
        now: Date
    ) -> UNNotificationRequest? {
        let remaining = plan.fireDate.timeIntervalSince(now)
        guard remaining > 1 else { return nil }

        let content = UNMutableNotificationContent()
        content.title = plan.title
        content.body = plan.body
        content.userInfo = MoriNotificationRouter.userInfo(for: .beforeFeedWindowComplete)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remaining, repeats: false)
        return UNNotificationRequest(
            identifier: plan.identifier,
            content: content,
            trigger: trigger
        )
    }
}
