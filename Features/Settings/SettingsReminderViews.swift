import SwiftUI
import UserNotifications
import WidgetKit

struct ClockReminderSettingsRow: View {
    @AppStorage("clockReminderEnabled") private var isEnabled = false
    @AppStorage("clockReminderHour") private var reminderHour = 8
    @AppStorage("clockReminderMinute") private var reminderMinute = 0
    @State private var authorizationDenied = false

    var body: some View {
        ReminderSettingsRow(
            title: MoriL10n.display("Clock reminder"),
            subtitle: MoriL10n.display("A daily nudge to see the time before the day starts."),
            isEnabled: $isEnabled,
            reminderDate: reminderDate,
            authorizationDenied: authorizationDenied,
            onToggle: handleToggle
        )
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: { ReminderScheduler.date(hour: reminderHour, minute: reminderMinute) },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderHour = components.hour ?? reminderHour
                reminderMinute = components.minute ?? reminderMinute

                if isEnabled {
                    ReminderScheduler.scheduleClockReminder(hour: reminderHour, minute: reminderMinute)
                }
            }
        )
    }

    private func handleToggle(_ enabled: Bool) {
        authorizationDenied = false

        guard enabled else {
            ReminderScheduler.cancelClockReminder()
            return
        }

        ReminderScheduler.requestAuthorization { granted in
            if granted {
                ReminderScheduler.scheduleClockReminder(hour: reminderHour, minute: reminderMinute)
            } else {
                isEnabled = false
                authorizationDenied = true
            }
        }
    }
}

struct JournalReminderSettingsRow: View {
    @AppStorage("journalReminderEnabled", store: MoriSharedDefaults.shared) private var isEnabled = false
    @AppStorage("journalReminderHour", store: MoriSharedDefaults.shared) private var reminderHour = 21
    @AppStorage("journalReminderMinute", store: MoriSharedDefaults.shared) private var reminderMinute = 0
    @State private var authorizationDenied = false

    var body: some View {
        ReminderSettingsRow(
            title: MoriL10n.display("Log reminder"),
            subtitle: MoriL10n.display("A quiet nudge to write one line."),
            isEnabled: $isEnabled,
            reminderDate: reminderDate,
            authorizationDenied: authorizationDenied,
            onToggle: handleToggle
        )
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: { ReminderScheduler.date(hour: reminderHour, minute: reminderMinute) },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderHour = components.hour ?? reminderHour
                reminderMinute = components.minute ?? reminderMinute

                if isEnabled {
                    ReminderScheduler.scheduleJournalReminder(hour: reminderHour, minute: reminderMinute)
                }

                WidgetCenter.shared.reloadTimelines(ofKind: "MoriJournalQuickStartWidget")
            }
        )
    }

    private func handleToggle(_ enabled: Bool) {
        authorizationDenied = false

        guard enabled else {
            ReminderScheduler.cancelJournalReminder()
            WidgetCenter.shared.reloadTimelines(ofKind: "MoriJournalQuickStartWidget")
            return
        }

        ReminderScheduler.requestAuthorization { granted in
            if granted {
                ReminderScheduler.scheduleJournalReminder(hour: reminderHour, minute: reminderMinute)
            } else {
                isEnabled = false
                authorizationDenied = true
            }

            WidgetCenter.shared.reloadTimelines(ofKind: "MoriJournalQuickStartWidget")
        }
    }
}

struct DailySparkReminderSettingsRow: View {
    @AppStorage("dailySparkReminderEnabled") private var isEnabled = false
    @AppStorage("dailySparkReminderHour") private var reminderHour = 8
    @AppStorage("dailySparkReminderMinute") private var reminderMinute = 15
    @State private var authorizationDenied = false

    var body: some View {
        ReminderSettingsRow(
            title: MoriL10n.display("Daily Spark reminder"),
            subtitle: MoriL10n.display("Three quick lines to choose today's focus."),
            isEnabled: $isEnabled,
            reminderDate: reminderDate,
            authorizationDenied: authorizationDenied,
            onToggle: handleToggle
        )
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: { ReminderScheduler.date(hour: reminderHour, minute: reminderMinute) },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderHour = components.hour ?? reminderHour
                reminderMinute = components.minute ?? reminderMinute

                if isEnabled {
                    ReminderScheduler.scheduleDailySparkReminder(hour: reminderHour, minute: reminderMinute)
                }
            }
        )
    }

    private func handleToggle(_ enabled: Bool) {
        authorizationDenied = false

        guard enabled else {
            ReminderScheduler.cancelDailySparkReminder()
            return
        }

        ReminderScheduler.requestAuthorization { granted in
            if granted {
                ReminderScheduler.scheduleDailySparkReminder(hour: reminderHour, minute: reminderMinute)
            } else {
                isEnabled = false
                authorizationDenied = true
            }
        }
    }
}

private struct ReminderSettingsRow: View {
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool
    let reminderDate: Binding<Date>
    let authorizationDenied: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $isEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(MoriL10n.display(title))
                    Text(MoriL10n.display(subtitle))
                        .font(.caption)
                        .foregroundColor(MoriColors.botanicalMuted)
                }
            }
            .moriOnChange(of: isEnabled, perform: onToggle)
            .frame(minHeight: MoriV2Layout.minimumHitTarget)

            if isEnabled {
                DatePicker(MoriL10n.display("Time"), selection: reminderDate, displayedComponents: .hourAndMinute)
                    .frame(minHeight: MoriV2Layout.minimumHitTarget)
                    .transition(.opacity)
            }

            if authorizationDenied {
                Text(MoriL10n.display("Notifications are off. Enable them in iOS Settings to use this reminder."))
                    .font(.footnote)
                    .foregroundColor(MoriColors.botanicalClay)
            }
        }
        .padding(.vertical, 4)
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: isEnabled)
    }
}

private enum ReminderScheduler {
    static let clockIdentifier = "dailyReminder"
    static let dailySparkIdentifier = MoriNotificationRouter.dailySparkReminderIdentifier
    static let journalIdentifier = "journalDailyReminder"

    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    static func scheduleClockReminder(hour: Int, minute: Int) {
        schedule(
            identifier: clockIdentifier,
            title: MoriL10n.display("Today"),
            body: MoriL10n.display("What meaningful memory will you create today?"),
            hour: hour,
            minute: minute
        )
    }

    static func scheduleJournalReminder(hour: Int, minute: Int) {
        schedule(
            identifier: journalIdentifier,
            title: MoriL10n.display("Time to write one line"),
            body: MoriL10n.display("Capture one thing worth remembering from today."),
            hour: hour,
            minute: minute
        )
    }

    static func scheduleDailySparkReminder(hour: Int, minute: Int) {
        schedule(
            identifier: dailySparkIdentifier,
            title: MoriL10n.display("Daily Spark"),
            body: MoriL10n.display("Start with one small action for today."),
            hour: hour,
            minute: minute,
            userInfo: MoriNotificationRouter.userInfo(for: .dailySpark)
        )
    }

    static func cancelClockReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [clockIdentifier])
    }

    static func cancelJournalReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [journalIdentifier])
    }

    static func cancelDailySparkReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailySparkIdentifier])
    }

    static func date(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func schedule(
        identifier: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        userInfo: [AnyHashable: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().add(request)
    }
}
