import Foundation
import UserNotifications

enum MoriDeepLinkTarget: String {
    case dailySpark = "daily-spark"
    case practice
    case mindfulnessBellBreathing = "mindfulness-bell-breathing"
    case beforeFeedWindowComplete = "before-feed-window-complete"
}

enum MoriNotificationRouter {
    static let dailySparkReminderIdentifier = "dailySparkDailyReminder"
    static let quietTimerCompletionIdentifier = MoriScreenTimeShared.quietTimerCompletionNotificationIdentifier

    private static let targetUserInfoKey = "moriTarget"
    private static let routeStore = MoriNotificationRouteStore()

    static func userInfo(for target: MoriDeepLinkTarget) -> [AnyHashable: Any] {
        [targetUserInfoKey: target.rawValue]
    }

    static func handleNotificationResponse(_ response: UNNotificationResponse) {
        let content = response.notification.request.content
        let identifier = response.notification.request.identifier

        let target = Self.fallbackTarget(for: identifier)
            ?? (content.userInfo[targetUserInfoKey] as? String)
                .flatMap(MoriDeepLinkTarget.init(rawValue:))

        guard let target else { return }
        request(target)
    }

    static func request(_ target: MoriDeepLinkTarget) {
        routeStore.savePendingTarget(target)
        Task { @MainActor in
            MoriAppRouteStore.shared.requestPendingRouteDrain()
        }
    }

    static func consumePendingRouteRequest() -> MoriAppRouteRequest? {
        routeStore.consumePendingTarget().map { target in
            MoriAppRouteRequest(route(for: target), source: .notification)
        }
    }

    private static func route(for target: MoriDeepLinkTarget) -> MoriAppRoute {
        switch target {
        case .dailySpark:
            return .journalTab
        case .practice:
            return .practiceTab
        case .mindfulnessBellBreathing:
            return .practiceLaunch(.mindfulnessBellBreathing)
        case .beforeFeedWindowComplete:
            return .todayTab
        }
    }

    private static func fallbackTarget(for identifier: String) -> MoriDeepLinkTarget? {
        switch identifier {
        case dailySparkReminderIdentifier:
            return .dailySpark
        case quietTimerCompletionIdentifier:
            return .practice
        case MoriScreenTimeShared.beforeFeedWindowEndNotificationIdentifier:
            return .beforeFeedWindowComplete
        default:
            if identifier.hasPrefix(MindfulnessBellDefaults.identifierPrefix) {
                return .mindfulnessBellBreathing
            }
            return nil
        }
    }
}
