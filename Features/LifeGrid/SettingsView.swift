import SwiftUI
import UserNotifications
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject var settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearHabitDataAlert = false
    @State private var showingRestartOnboardingAlert = false
    @State private var isLoadingLifeExpectancy = false
    @State private var lifeExpectancyStatusText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Birth Date",
                        selection: $settings.birthDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    
                    Stepper(
                        "Life Expectancy: \(settings.lifeExpectancy) years",
                        value: $settings.lifeExpectancy,
                        in: 60...100
                    )

                    Picker("Gender", selection: $settings.gender) {
                        ForEach(UserGender.allCases) { gender in
                            Text(gender.title).tag(gender)
                        }
                    }

                    Picker("Location", selection: $settings.locationCountryCode) {
                        ForEach(LifeExpectancyService.countries) { country in
                            Text(country.name).tag(country.code)
                        }
                    }

                    if isLoadingLifeExpectancy {
                        ProgressView("Looking up life expectancy...")
                    } else if !lifeExpectancyStatusText.isEmpty {
                        Text(lifeExpectancyStatusText)
                            .font(.footnote)
                            .foregroundColor(MoriColors.secondary)
                    }
                } header: {
                    Text("Your Life")
                } footer: {
                    Text("Mori can estimate life expectancy from World Bank country and gender data. You can still adjust the estimate manually.")
                }

                Section {
                    Picker("Countdown unit", selection: $settings.clockTimeUnit) {
                        ForEach(ClockTimeUnit.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                } header: {
                    Text("Clock")
                }

                Section {
                    ClockReminderSettingsRow()
                    DailySparkReminderSettingsRow()
                    JournalReminderSettingsRow()
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Choose when Mori should gently nudge you. The time can be changed before or after a reminder is enabled.")
                }
                
                Section {
                    LabeledContent("Age", value: "\(settings.age)")
                    LabeledContent("Total Weeks", value: "\(settings.totalWeeks)")
                    LabeledContent("Weeks Lived", value: "\(settings.weeksLived)")
                    LabeledContent("Weeks Remaining", value: "\(settings.weeksRemaining)")
                } header: {
                    Text("Statistics")
                }

                Section {
                    Button("Restart Onboarding") {
                        showingRestartOnboardingAlert = true
                    }

                    Button("Clear All Habit Data", role: .destructive) {
                        showingClearHabitDataAlert = true
                    }
                } header: {
                    Text("App")
                } footer: {
                    Text("Restarting onboarding keeps your saved data. Clearing habit data removes all saved good day and difficult day check-ins.")
                }
                
                Section {
                    Text("Mori reminds us that time is precious. Use this grid to visualize your life and make each week count.")
                        .font(.footnote)
                        .foregroundColor(MoriColors.secondary)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear all habit data?", isPresented: $showingClearHabitDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear Data", role: .destructive) {
                    HabitDataManager.shared.clearAllEntries()
                }
            } message: {
                Text("This cannot be undone.")
            }
            .alert("Restart onboarding?", isPresented: $showingRestartOnboardingAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Restart") {
                    settings.hasCompletedOnboarding = false
                    dismiss()
                }
            } message: {
                Text("You can go through onboarding again without deleting your saved data.")
            }
            .task {
                if lifeExpectancyStatusText.isEmpty {
                    lifeExpectancyStatusText = "Using \(settings.locationCountryName) and \(settings.gender.title.lowercased()) profile."
                }
            }
            .onChange(of: settings.gender) { _ in
                Task {
                    await refreshLifeExpectancy()
                }
            }
            .onChange(of: settings.locationCountryCode) { newValue in
                settings.locationCountryName = LifeExpectancyService.countryName(for: newValue)
                Task {
                    await refreshLifeExpectancy()
                }
            }
        }
    }

    @MainActor
    private func refreshLifeExpectancy() async {
        isLoadingLifeExpectancy = true
        let estimate = await LifeExpectancyService.shared.estimate(
            countryCode: settings.locationCountryCode,
            gender: settings.gender
        )
        settings.lifeExpectancy = estimate.years
        lifeExpectancyStatusText = estimate.sourceDescription
        isLoadingLifeExpectancy = false
    }
}

private struct ClockReminderSettingsRow: View {
    @AppStorage("clockReminderEnabled") private var isEnabled = false
    @AppStorage("clockReminderHour") private var reminderHour = 8
    @AppStorage("clockReminderMinute") private var reminderMinute = 0
    @State private var authorizationDenied = false

    var body: some View {
        ReminderSettingsRow(
            title: "Clock reminder",
            subtitle: "A daily nudge to make today count.",
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

private struct JournalReminderSettingsRow: View {
    @AppStorage("journalReminderEnabled", store: MoriSharedDefaults.shared) private var isEnabled = false
    @AppStorage("journalReminderHour", store: MoriSharedDefaults.shared) private var reminderHour = 21
    @AppStorage("journalReminderMinute", store: MoriSharedDefaults.shared) private var reminderMinute = 0
    @State private var authorizationDenied = false

    var body: some View {
        ReminderSettingsRow(
            title: "Journal reminder",
            subtitle: "A quiet nudge to write one line.",
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

private struct DailySparkReminderSettingsRow: View {
    @AppStorage("dailySparkReminderEnabled") private var isEnabled = false
    @AppStorage("dailySparkReminderHour") private var reminderHour = 8
    @AppStorage("dailySparkReminderMinute") private var reminderMinute = 15
    @State private var authorizationDenied = false

    var body: some View {
        ReminderSettingsRow(
            title: "Daily Spark reminder",
            subtitle: "Three quick lines to make today real.",
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
                    Text(title)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(MoriColors.secondary)
                }
            }
            .onChange(of: isEnabled, perform: onToggle)

            DatePicker("Time", selection: reminderDate, displayedComponents: .hourAndMinute)

            if authorizationDenied {
                Text("Notifications are off. Enable them in iOS Settings to use this reminder.")
                    .font(.footnote)
                    .foregroundColor(MoriColors.warmClay)
            }
        }
        .padding(.vertical, 4)
    }
}

private enum ReminderScheduler {
    static let clockIdentifier = "dailyReminder"
    static let dailySparkIdentifier = "dailySparkDailyReminder"
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
            title: "Mori",
            body: "What meaningful memory will you create today?",
            hour: hour,
            minute: minute
        )
    }

    static func scheduleJournalReminder(hour: Int, minute: Int) {
        schedule(
            identifier: journalIdentifier,
            title: "Time to write one line",
            body: "Capture one thing worth remembering from today.",
            hour: hour,
            minute: minute
        )
    }

    static func scheduleDailySparkReminder(hour: Int, minute: Int) {
        schedule(
            identifier: dailySparkIdentifier,
            title: "Daily Spark",
            body: "What deserves your best attention today?",
            hour: hour,
            minute: minute
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

    private static func schedule(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserSettings())
}
