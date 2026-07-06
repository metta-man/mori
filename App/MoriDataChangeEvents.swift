import SwiftUI
import UIKit

enum MoriDataChangeEvent {
    case dailySpark
    case gratitude
    case habit
    case significantTime

    var notificationName: Notification.Name {
        switch self {
        case .dailySpark:
            return .dailySparkDataDidChange
        case .gratitude:
            return .gratitudeDataDidChange
        case .habit:
            return .habitDataDidChange
        case .significantTime:
            return UIApplication.significantTimeChangeNotification
        }
    }

    func post(notificationCenter: NotificationCenter = .default) {
        notificationCenter.post(name: notificationName, object: nil)
    }
}

extension Notification.Name {
    static let dailySparkDataDidChange = Notification.Name("dailySparkDataDidChange")
    static let gratitudeDataDidChange = Notification.Name("gratitudeDataDidChange")
    static let habitDataDidChange = Notification.Name("habitDataDidChange")
}

extension View {
    func onMoriDataChange(
        _ event: MoriDataChangeEvent,
        perform action: @escaping () -> Void
    ) -> some View {
        onReceive(NotificationCenter.default.publisher(for: event.notificationName)) { _ in
            action()
        }
    }
}
