import SwiftUI

private enum SettingsRoute: Hashable {
    case appLimits
    case archive
    case reminders
    case language
    case appAndData
    case about
}

struct SettingsView: View {
    @EnvironmentObject var settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appLimitManager = AppLimitManager.shared
    @State private var navigationPath: [SettingsRoute] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Form {
                Section {
                    NavigationLink(value: SettingsRoute.appLimits) {
                        SettingsNavigationLabel(
                            title: MoriL10n.display("App Limits"),
                            subtitle: screenTimeStatusText,
                            icon: .lockShield
                        )
                    }

                    NavigationLink(value: SettingsRoute.archive) {
                        SettingsNavigationLabel(
                            title: MoriL10n.display("Week Archive"),
                            subtitle: MoriL10n.display("Start date and archive range."),
                            icon: .roots
                        )
                    }
                } header: {
                    SettingsSectionHeader(title: MoriL10n.display("Attention"))
                }
                .listRowBackground(settingsRowBackground)

                Section {
                    NavigationLink(value: SettingsRoute.reminders) {
                        SettingsNavigationLabel(
                            title: MoriL10n.display("Reminders"),
                            subtitle: MoriL10n.display("Optional, gentle nudges."),
                            icon: .bell
                        )
                    }

                    NavigationLink(value: SettingsRoute.language) {
                        SettingsNavigationLabel(
                            title: MoriL10n.display("Language"),
                            value: settings.localePreference.displayName,
                            icon: .journal
                        )
                    }
                } header: {
                    SettingsSectionHeader(title: MoriL10n.display("Preferences"))
                }
                .listRowBackground(settingsRowBackground)

                Section {
                    NavigationLink(value: SettingsRoute.appAndData) {
                        SettingsNavigationLabel(
                            title: MoriL10n.display("App and Data"),
                            subtitle: MoriL10n.display("Onboarding and saved check-ins."),
                            icon: .refresh
                        )
                    }

                    NavigationLink(value: SettingsRoute.about) {
                        SettingsNavigationLabel(
                            title: MoriL10n.display("About Mori"),
                            subtitle: MoriL10n.display("Pause. Notice. Choose."),
                            icon: .leaf
                        )
                    }
                } header: {
                    SettingsSectionHeader(title: MoriL10n.display("Mori"))
                }
                .listRowBackground(settingsRowBackground)
            }
            .moriSettingsForm()
            .listStyle(.insetGrouped)
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .frame(minHeight: MoriV2Layout.minimumHitTarget)
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .appLimits:
                    LockedScreenTimeSettingsView()
                case .archive:
                    ArchiveSettingsView()
                case .reminders:
                    ReminderSettingsView()
                case .language:
                    LanguageSettingsView()
                case .appAndData:
                    AppAndDataSettingsView(dismissSettings: { dismiss() })
                case .about:
                    AboutMoriSettingsView()
                }
            }
        }
    }

    private var settingsRowBackground: Color {
        MoriColors.botanicalSurface.opacity(0.74)
    }

    private var screenTimeStatusText: String {
        ScreenTimeSettingsLinkPresentation(appLimitManager: appLimitManager).statusText
    }
}

private struct SettingsNavigationLabel: View {
    let title: String
    var subtitle: String?
    var value: String?
    let icon: MoriBitmapIcon

    init(
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        icon: MoriBitmapIcon
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 11) {
            MoriBitmapIconImage(icon: icon, size: 17, opacity: 0.76)
                .frame(width: 21)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 6)

            if let value {
                Text(value)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(MoriColors.botanicalMuted)
    }
}

private struct ArchiveSettingsView: View {
    @EnvironmentObject private var settings: UserSettings
    @State private var isEditingArchiveStartDate = false
    @State private var draftArchiveStartDate = Date()

    var body: some View {
        Form {
            Section {
                archiveStartEditor

                Stepper(
                    MoriL10n.string(
                        "settings.week_archive.years_shown",
                        defaultValue: "Archive Span: %d years",
                        arguments: [settings.archiveSpanYears]
                    ),
                    value: $settings.archiveSpanYears,
                    in: 60...100
                )
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .frame(minHeight: MoriV2Layout.minimumHitTarget)

                LabeledContent(
                    MoriL10n.display("Current archive week"),
                    value: "\(settings.currentWeekIndex + 1)"
                )
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .frame(minHeight: MoriV2Layout.minimumHitTarget)
            } footer: {
                Text(
                    MoriL10n.display(
                        "This calibrates the Week Archive grid only. Mori does not need an estimated lifetime to protect your attention."
                    )
                )
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)
            }
            .listRowBackground(settingsRowBackground)

            Section {
                NavigationLink {
                    WeekArchiveDetailView()
                } label: {
                    HStack(spacing: 11) {
                        MoriBitmapIconImage(icon: .roots, size: 17, opacity: 0.76)
                            .frame(width: 21)

                        Text(MoriL10n.display("Open Life Grid"))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(MoriColors.botanicalInk)
                    }
                    .frame(minHeight: MoriV2Layout.minimumHitTarget)
                }
            }
            .listRowBackground(settingsRowBackground)
        }
        .moriSettingsForm()
        .listStyle(.insetGrouped)
        .navigationTitle(MoriL10n.display("Week Archive"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var archiveStartEditor: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(MoriL10n.display("Archive start"))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(Self.archiveStartDateFormatter.string(from: settings.archiveStartDate))
                        .font(.footnote)
                        .foregroundColor(MoriColors.botanicalMuted)
                }

                Spacer()

                if !isEditingArchiveStartDate {
                    Button(MoriL10n.display("Edit")) {
                        beginArchiveStartDateEdit()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                }
            }
            .frame(minHeight: MoriV2Layout.minimumHitTarget)

            if isEditingArchiveStartDate {
                DatePicker(
                    MoriL10n.display("Archive start date"),
                    selection: $draftArchiveStartDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(MoriColors.botanicalInk)

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
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .frame(minHeight: MoriV2Layout.minimumHitTarget)
            }
        }
        .padding(.vertical, 1)
    }

    private var settingsRowBackground: Color {
        MoriColors.botanicalSurface.opacity(0.74)
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

private struct ReminderSettingsView: View {
    var body: some View {
        Form {
            Section {
                ClockReminderSettingsRow()
                DailySparkReminderSettingsRow()
                JournalReminderSettingsRow()
            } footer: {
                Text(
                    MoriL10n.display(
                        "Choose when Mori should gently nudge you. The time can be changed before or after a reminder is enabled."
                    )
                )
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)
            }
            .listRowBackground(MoriColors.botanicalSurface.opacity(0.74))
        }
        .moriSettingsForm()
        .listStyle(.insetGrouped)
        .navigationTitle(MoriL10n.display("Reminders"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LanguageSettingsView: View {
    @EnvironmentObject private var settings: UserSettings

    var body: some View {
        Form {
            Section {
                Picker(MoriL10n.display("Language"), selection: $settings.localePreference) {
                    ForEach(MoriLocalePreference.allCases) { preference in
                        Text(preference.displayName).tag(preference)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } footer: {
                Text(
                    MoriL10n.display(
                        "System follows your iPhone language order. Choosing a language overrides Mori only."
                    )
                )
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)
            }
            .listRowBackground(MoriColors.botanicalSurface.opacity(0.74))
        }
        .moriSettingsForm()
        .listStyle(.insetGrouped)
        .navigationTitle(MoriL10n.display("Language"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AppAndDataSettingsView: View {
    @EnvironmentObject private var settings: UserSettings
    let dismissSettings: () -> Void
    @State private var showingClearDayCheckinsAlert = false
    @State private var showingRestartOnboardingAlert = false

    var body: some View {
        Form {
            Section {
                Button(MoriL10n.display("Restart Onboarding")) {
                    showingRestartOnboardingAlert = true
                }
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget, alignment: .leading)

                Button(MoriL10n.display("Clear Day Check-ins")) {
                    showingClearDayCheckinsAlert = true
                }
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(MoriColors.botanicalClay)
                .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget, alignment: .leading)
            } footer: {
                Text(
                    MoriL10n.display(
                        "Restarting onboarding keeps saved data. Clearing day check-ins removes saved daily moods and pattern notes."
                    )
                )
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)
            }
            .listRowBackground(MoriColors.botanicalSurface.opacity(0.74))
        }
        .moriSettingsForm()
        .listStyle(.insetGrouped)
        .navigationTitle(MoriL10n.display("App and Data"))
        .navigationBarTitleDisplayMode(.inline)
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
                dismissSettings()
            }
        } message: {
            Text(MoriL10n.display("You can go through onboarding again without deleting your saved data."))
        }
    }
}

private struct AboutMoriSettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(MoriL10n.display("Pause. Notice. Choose."))
                        .font(.system(size: 19, weight: .medium, design: .serif))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display("Mori creates one quiet moment before a feed opens."))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(MoriColors.botanicalSurface.opacity(0.74))
        }
        .moriSettingsForm()
        .listStyle(.insetGrouped)
        .navigationTitle(MoriL10n.display("About Mori"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserSettings())
}
