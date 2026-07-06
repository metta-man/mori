import Foundation
import UserNotifications

final class MindfulnessBellScheduler {
    static let shared = MindfulnessBellScheduler()

    private let stateStore: MindfulnessBellStateStore

    private init(stateStore: MindfulnessBellStateStore = MindfulnessBellStateStore()) {
        self.stateStore = stateStore
    }

    func applyRecommendedDefaults(defaults: UserDefaults = .standard) {
        MindfulnessBellStateStore(defaults: defaults).applyRecommendedDefaults()
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    completion(true)
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            case .denied:
                DispatchQueue.main.async {
                    completion(false)
                }
            @unknown default:
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    func refreshIfNeeded() {
        guard stateStore.shouldRefresh() else { return }
        scheduleUpcomingBells()
    }

    func scheduleUpcomingBells(maxCount: Int = 48) {
        stateStore.markActive()
        let settings = stateStore.scheduleSettings()
        let fireDates = computeFireDates(settings: settings, maxCount: maxCount)

        cancelAll {
            for (index, date) in fireDates.enumerated() {
                self.scheduleBell(at: date, identifier: "\(MindfulnessBellDefaults.identifierPrefix)\(index)")
            }
            self.stateStore.saveNextFireDate(fireDates.first)
        }
    }

    func cancelAll(completion: (() -> Void)? = nil) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(MindfulnessBellDefaults.identifierPrefix) }

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            self.stateStore.saveNextFireDate(nil)
            completion?()
        }
    }

    private func scheduleBell(at date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        let message = MindfulnessBellMessage.next(identifier: identifier)
        content.title = message.title
        content.body = message.body
        content.categoryIdentifier = MindfulnessBellDefaults.categoryIdentifier
        content.sound = .default
        content.userInfo = MoriNotificationRouter.userInfo(for: .mindfulnessBellBreathing)

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func computeFireDates(
        settings: MindfulnessBellScheduleSettings,
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
                let bellsThisHour = min(
                    settings.bellsPerHour,
                    max(1, Int(Double(settings.bellsPerHour) * Double(window) / 3600.0 + 0.5))
                )

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
        settings: MindfulnessBellScheduleSettings,
        calendar: Calendar
    ) -> Bool {
        dateIsActive(date.addingTimeInterval(1800), settings: settings, calendar: calendar)
    }

    private func dateIsActive(
        _ date: Date,
        settings: MindfulnessBellScheduleSettings,
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
        settings: MindfulnessBellScheduleSettings,
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

enum MindfulnessBellDefaults {
    static let categoryIdentifier = "MORI_MINDFULNESS_BELL"
    static let identifierPrefix = "mori-phone-mindfulness-bell-"
    static let isActiveKey = "mori_mindfulness_bell_is_active"
    static let randomModeKey = "mori_mindfulness_bell_random_mode"
    static let intervalMinutesKey = "mori_mindfulness_bell_interval_minutes"
    static let bellsPerHourKey = "mori_mindfulness_bell_bells_per_hour"
    static let startHourKey = "mori_mindfulness_bell_start_hour"
    static let endHourKey = "mori_mindfulness_bell_end_hour"
    static let nextFireKey = "mori_mindfulness_bell_next_fire"
    static let randomSeedKey = "mori_mindfulness_bell_random_seed"
    static let breathingTechniqueIDKey = "mori_mindfulness_bell_breathing_technique_id"
    static let breathingDurationMinutesKey = "mori_mindfulness_bell_breathing_duration_minutes"
    static let promptDismissedKey = "mori_mindfulness_bell_prompt_dismissed"
    static let defaultBreathingTechniqueID = MoriBreathingTechniqueID.coherent5.rawValue
    static let defaultBreathingDurationMinutes = 1

    static func selectedBreathingTechniqueID(defaults: UserDefaults = .standard) -> String {
        let storedID = defaults.string(forKey: breathingTechniqueIDKey) ?? defaultBreathingTechniqueID
        guard MoriBreathingTechniqueRepository.getTechnique(id: storedID) != nil else {
            return defaultBreathingTechniqueID
        }
        return storedID
    }

    static func selectedBreathingDurationMinutes(defaults: UserDefaults = .standard) -> Int {
        let storedMinutes = defaults.integer(forKey: breathingDurationMinutesKey)
        guard storedMinutes > 0 else { return defaultBreathingDurationMinutes }
        return min(10, max(1, storedMinutes))
    }
}

enum MindfulnessBellMessage {
    private static let messages = [
        ("mindfulness_bell.message.1.title", "mindfulness_bell.message.1.body"),
        ("mindfulness_bell.message.2.title", "mindfulness_bell.message.2.body"),
        ("mindfulness_bell.message.3.title", "mindfulness_bell.message.3.body"),
        ("mindfulness_bell.message.4.title", "mindfulness_bell.message.4.body")
    ]

    static func next(identifier: String) -> (title: String, body: String) {
        let index = Int(identifier.hashValue.magnitude % UInt(messages.count))
        let message = messages[index]
        return (
            MoriL10n.string(message.0, defaultValue: defaultTitle(for: message.0)),
            MoriL10n.string(message.1, defaultValue: defaultBody(for: message.1))
        )
    }

    private static func defaultTitle(for key: String) -> String {
        switch key {
        case "mindfulness_bell.message.1.title": return "Mindfulness Bell"
        case "mindfulness_bell.message.2.title": return "A bell for now"
        case "mindfulness_bell.message.3.title": return "Return to the day"
        default: return "Small pause"
        }
    }

    private static func defaultBody(for key: String) -> String {
        switch key {
        case "mindfulness_bell.message.1.body": return "Pause. Take one full breath before the next thing."
        case "mindfulness_bell.message.2.body": return "Let this small sound be enough. Breathe in, breathe out."
        case "mindfulness_bell.message.3.body": return "Soften your shoulders and come back to this moment."
        default: return "One breath. One clear next step."
        }
    }
}
