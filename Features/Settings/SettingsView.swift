import SwiftUI

private enum SettingsRoute: Hashable {
    case appLimits
}

struct SettingsView: View {
    @EnvironmentObject var settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appLimitManager = AppLimitManager.shared
    @State private var navigationPath: [SettingsRoute] = []
    @State private var showingClearDayCheckinsAlert = false
    @State private var showingRestartOnboardingAlert = false
    @State private var isEditingArchiveStartDate = false
    @State private var draftArchiveStartDate = Date()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                appLimitsSection
                weekArchiveSection
                remindersSection
                languageSection
                appSection
                aboutSection
            }
            .moriSettingsForm()
            .navigationTitle(MoriL10n.display("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(MoriL10n.display("Done")) {
                        dismiss()
                    }
                }
            }
            .alert(MoriL10n.display("Clear day check-ins?"), isPresented: $showingClearDayCheckinsAlert) {
                Button(MoriL10n.display("Cancel"), role: .cancel) {}
                Button(MoriL10n.display("Clear Check-ins"), role: .destructive) {
                    HabitDataManager.shared.clearAllEntries()
                }
            } message: {
                Text(MoriL10n.display("This removes saved daily check-ins and pattern notes. It cannot be undone."))
            }
            .alert(MoriL10n.display("Restart onboarding?"), isPresented: $showingRestartOnboardingAlert) {
                Button(MoriL10n.display("Cancel"), role: .cancel) {}
                Button(MoriL10n.display("Restart")) {
                    settings.hasCompletedOnboarding = false
                    dismiss()
                }
            } message: {
                Text(MoriL10n.display("You can go through onboarding again without deleting your saved data."))
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .appLimits:
                    LockedScreenTimeSettingsView()
                }
            }
        }
    }

    private var appLimitsSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.appLimits) {
                HStack(alignment: .center, spacing: 12) {
                    MoriProductSymbolView(
                        symbol: .appLimit,
                        size: 21,
                        tint: MoriColors.botanicalInk,
                        opacity: 0.88
                    )
                        .frame(width: 34, height: 34)
                        .background(MoriColors.botanicalInk.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(MoriL10n.display("First App Limit"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MoriColors.botanicalInk)
                        Text(screenTimeStatusText)
                            .font(.footnote)
                            .foregroundColor(MoriColors.botanicalMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text(MoriL10n.display("App Limits"))
        } footer: {
            Text(MoriL10n.display("Choose one app or website. The gate slows it before the next feed opens."))
        }
    }

    private var weekArchiveSection: some View {
        Section {
            archiveStartEditor

            Stepper(
                MoriL10n.string("settings.week_archive.years_shown", defaultValue: "Archive Span: %d years", arguments: [settings.archiveSpanYears]),
                value: $settings.archiveSpanYears,
                in: 60...100
            )

            LabeledContent(MoriL10n.display("Current archive week"), value: "\(settings.currentWeekIndex + 1)")
        } header: {
            Text(MoriL10n.display("Week Archive"))
        } footer: {
            Text(MoriL10n.display("This calibrates the Week Archive grid only. Mori does not need an estimated lifetime to protect your attention."))
        }
    }

    private var archiveStartEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(MoriL10n.display("Archive start"))
                    Text(Self.archiveStartDateFormatter.string(from: settings.archiveStartDate))
                        .font(.footnote)
                        .foregroundColor(MoriColors.botanicalMuted)
                }

                Spacer()

                if !isEditingArchiveStartDate {
                    Button(MoriL10n.display("Edit")) {
                        beginArchiveStartDateEdit()
                    }
                    .font(.footnote.weight(.semibold))
                }
            }

            if isEditingArchiveStartDate {
                DatePicker(
                    MoriL10n.display("Archive start date"),
                    selection: $draftArchiveStartDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                HStack {
                    Button(MoriL10n.display("Cancel")) {
                        cancelArchiveStartDateEdit()
                    }

                    Spacer()

                    Button(MoriL10n.display("Save")) {
                        saveArchiveStartDateEdit()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var remindersSection: some View {
        Section {
            ClockReminderSettingsRow()
            DailySparkReminderSettingsRow()
            JournalReminderSettingsRow()
        } header: {
            Text(MoriL10n.display("Reminders"))
        } footer: {
            Text(MoriL10n.display("Choose when reminders should gently nudge you. The time can be changed before or after a reminder is enabled."))
        }
    }

    private var languageSection: some View {
        Section {
            Picker(MoriL10n.display("Language"), selection: $settings.localePreference) {
                ForEach(MoriLocalePreference.allCases) { preference in
                    Text(preference.displayName).tag(preference)
                }
            }
        } header: {
            Text(MoriL10n.display("Language"))
        } footer: {
            Text(MoriL10n.display("System follows your iPhone language order. Choosing a language overrides this app only."))
        }
    }

    private var appSection: some View {
        Section {
            Button(MoriL10n.display("Restart Onboarding")) {
                showingRestartOnboardingAlert = true
            }

            Button(MoriL10n.display("Clear Day Check-ins"), role: .destructive) {
                showingClearDayCheckinsAlert = true
            }
        } header: {
            Text(MoriL10n.display("App"))
        } footer: {
            Text(MoriL10n.display("Restarting onboarding keeps saved data. Clearing day check-ins removes saved daily moods and pattern notes."))
        }
    }

    private var aboutSection: some View {
        Section {
            Text(MoriL10n.display("Today helps set one App Limit, choose one focus, and change the next minute before a feed opens."))
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)
        } header: {
            Text(MoriL10n.display("About"))
        }
    }

    private var screenTimeStatusText: String {
        ScreenTimeSettingsLinkPresentation(appLimitManager: appLimitManager).statusText
    }

    private static let archiveStartDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private func beginArchiveStartDateEdit() {
        draftArchiveStartDate = settings.archiveStartDate
        isEditingArchiveStartDate = true
    }

    private func cancelArchiveStartDateEdit() {
        draftArchiveStartDate = settings.archiveStartDate
        isEditingArchiveStartDate = false
    }

    private func saveArchiveStartDateEdit() {
        settings.archiveStartDate = draftArchiveStartDate
        isEditingArchiveStartDate = false
    }

}

#Preview {
    SettingsView()
        .environmentObject(UserSettings())
}
