import Foundation
import Combine
import UserNotifications
import WatchKit

final class MoriWatchNotificationCenter: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = MoriWatchNotificationCenter()

    @Published var quickBreathingRequestID: UUID?

    private override init() {
        super.init()
    }

    func configure() {
        let category = UNNotificationCategory(
            identifier: MoriWatchBellDefaults.categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([category])
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.content.categoryIdentifier == MoriWatchBellDefaults.categoryIdentifier {
            MoriWatchBellScheduler.shared.playBellHaptic()
            completionHandler([.banner, .sound])
        } else {
            completionHandler([])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.categoryIdentifier == MoriWatchBellDefaults.categoryIdentifier,
           response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            DispatchQueue.main.async {
                self.quickBreathingRequestID = UUID()
            }
        }

        completionHandler()
    }
}

final class MoriWatchBellScheduler {
    static let shared = MoriWatchBellScheduler()

    private init() {}

    func refreshIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: MoriWatchBellDefaults.isActiveKey) else { return }

        let nextTimestamp = defaults.double(forKey: MoriWatchBellDefaults.nextFireKey)
        guard nextTimestamp == 0 || Date(timeIntervalSince1970: nextTimestamp) <= Date().addingTimeInterval(60) else {
            return
        }

        scheduleUpcomingBells()
    }

    func scheduleUpcomingBells(maxCount: Int = 48) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: MoriWatchBellDefaults.isActiveKey)

        let settings = MoriWatchBellScheduleSettings(defaults: defaults)
        let fireDates = computeFireDates(settings: settings, maxCount: maxCount)

        cancelAll {
            for (index, date) in fireDates.enumerated() {
                self.scheduleBell(at: date, identifier: "\(MoriWatchBellDefaults.identifierPrefix)\(index)")
            }
            defaults.set(fireDates.first?.timeIntervalSince1970 ?? 0, forKey: MoriWatchBellDefaults.nextFireKey)
        }
    }

    func cancelAll(completion: (() -> Void)? = nil) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(MoriWatchBellDefaults.identifierPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            UserDefaults.standard.set(0, forKey: MoriWatchBellDefaults.nextFireKey)
            completion?()
        }
    }

    func playBellHaptic() {
        WKInterfaceDevice.current().play(.notification)
    }

    private func scheduleBell(at date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        let message = MoriWatchBellMessage.next(identifier: identifier)
        content.title = message.title
        content.body = message.body
        content.categoryIdentifier = MoriWatchBellDefaults.categoryIdentifier
        content.userInfo = [
            "sessionType": "quickBreathing",
            "techniqueName": MoriWatchBreathPreset.coherent5.title,
            "inhaleDuration": MoriWatchBreathPreset.coherent5.inhale,
            "exhaleDuration": MoriWatchBreathPreset.coherent5.exhale,
            "cycleCount": 3
        ]
        content.sound = .default

        if #available(watchOS 8.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func computeFireDates(
        settings: MoriWatchBellScheduleSettings,
        maxCount: Int
    ) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var dates: [Date] = []

        if settings.randomMode {
            var hourCursor = calendar.dateInterval(of: .hour, for: now)?.start ?? now
            let maxIterations = 24 * 14
            var iterations = 0

            while dates.count < maxCount && iterations < maxIterations {
                iterations += 1
                defer {
                    hourCursor = calendar.date(byAdding: .hour, value: 1, to: hourCursor) ?? hourCursor.addingTimeInterval(3600)
                }

                guard hourIsActive(hourCursor, settings: settings, calendar: calendar) else { continue }

                let effectiveStart = max(now.addingTimeInterval(60), hourCursor)
                let effectiveEnd = min(
                    hourCursor.addingTimeInterval(3600),
                    endDate(for: hourCursor, settings: settings, calendar: calendar)
                )
                guard effectiveEnd > effectiveStart else { continue }

                let window = Int(effectiveEnd.timeIntervalSince(effectiveStart))
                let bellsThisHour = min(settings.bellsPerHour, max(1, Int(Double(settings.bellsPerHour) * Double(window) / 3600.0 + 0.5)))

                for index in 0..<bellsThisHour {
                    let offset = deterministicOffset(
                        baseDate: hourCursor,
                        index: index,
                        upperBound: window,
                        seed: settings.randomSeed
                    )
                    let date = effectiveStart.addingTimeInterval(TimeInterval(offset))
                    if date > now, dates.count < maxCount {
                        dates.append(date)
                    }
                }
            }
        } else {
            let interval = TimeInterval(max(1, settings.intervalMinutes) * 60)
            var candidate = now.addingTimeInterval(interval)
            let maxIterations = maxCount * 80
            var iterations = 0

            while dates.count < maxCount && iterations < maxIterations {
                iterations += 1
                if dateIsActive(candidate, settings: settings, calendar: calendar) {
                    dates.append(candidate)
                }
                candidate = candidate.addingTimeInterval(interval)
            }
        }

        return Array(Set(dates)).sorted().prefix(maxCount).map { $0 }
    }

    private func deterministicOffset(
        baseDate: Date,
        index: Int,
        upperBound: Int,
        seed: UInt64
    ) -> Int {
        let hourValue = UInt64(Int(baseDate.timeIntervalSince1970 / 3600))
        var value = seed ^ hourValue &* 0x9E3779B185EBCA87 ^ UInt64(index + 1)
        value ^= value >> 30
        value &*= 0xBF58476D1CE4E5B9
        value ^= value >> 27
        value &*= 0x94D049BB133111EB
        value ^= value >> 31
        return Int(value % UInt64(max(1, upperBound)))
    }

    private func hourIsActive(
        _ date: Date,
        settings: MoriWatchBellScheduleSettings,
        calendar: Calendar
    ) -> Bool {
        dateIsActive(date.addingTimeInterval(1800), settings: settings, calendar: calendar)
    }

    private func dateIsActive(
        _ date: Date,
        settings: MoriWatchBellScheduleSettings,
        calendar: Calendar
    ) -> Bool {
        let hour = calendar.component(.hour, from: date)
        if settings.startHour <= settings.endHour {
            return hour >= settings.startHour && hour < settings.endHour
        }
        return hour >= settings.startHour || hour < settings.endHour
    }

    private func endDate(
        for date: Date,
        settings: MoriWatchBellScheduleSettings,
        calendar: Calendar
    ) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = settings.endHour
        components.minute = 0
        components.second = 0
        let sameDayEnd = calendar.date(from: components) ?? date.addingTimeInterval(3600)

        if settings.startHour <= settings.endHour {
            return sameDayEnd
        }

        let hour = calendar.component(.hour, from: date)
        if hour >= settings.startHour {
            return calendar.date(byAdding: .day, value: 1, to: sameDayEnd) ?? sameDayEnd.addingTimeInterval(24 * 3600)
        }
        return sameDayEnd
    }
}
