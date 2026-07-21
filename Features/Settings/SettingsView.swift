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
    @State private var showsArchiveSettings = false
    @State private var showsReminderSettings = false
    @State private var showsLanguageSettings = false
    @State private var showsAppSettings = false
    @State private var showsAbout = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MoriPaperBackground(variant: .settings) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        MoriPageHeader(
                            eyebrow: "Mori",
                            title: "Settings",
                            subtitle: "Adjust only what helps."
                        )

                        appLimitsSection
                        weekArchiveSection
                        remindersSection
                        languageSection
                        appSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 42)
                }
            }
            .environment(\.colorScheme, .light)
            .tint(MoriV2Palette.primaryForest)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(MoriL10n.display("Done")) {
                        dismiss()
                    }
                    .font(MoriV2Type.control)
                    .foregroundColor(MoriV2Palette.forestInk)
                    .frame(minHeight: MoriV2Layout.minimumHitTarget)
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
        NavigationLink(value: SettingsRoute.appLimits) {
            MoriV2QuietActionRow(
                title: "App Limits",
                subtitle: screenTimeStatusText,
                icon: .lockShield
            )
        }
        .buttonStyle(MoriV2PressButtonStyle())
    }

    private var weekArchiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriV2QuietDisclosureRow(
                title: showsArchiveSettings ? "Hide archive settings" : "Week Archive",
                subtitle: "Start date and archive range.",
                isExpanded: showsArchiveSettings,
                action: { showsArchiveSettings.toggle() }
            )

            if showsArchiveSettings {
                MoriV2PaperCard(padding: 16, cornerRadius: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        archiveStartEditor

                        settingsDivider

                        Stepper(
                            MoriL10n.string("settings.week_archive.years_shown", defaultValue: "Archive Span: %d years", arguments: [settings.archiveSpanYears]),
                            value: $settings.archiveSpanYears,
                            in: 60...100
                        )
                        .frame(minHeight: MoriV2Layout.minimumHitTarget)

                        settingsDivider

                        LabeledContent(MoriL10n.display("Current archive week"), value: "\(settings.currentWeekIndex + 1)")
                            .frame(minHeight: MoriV2Layout.minimumHitTarget)

                        Text(MoriL10n.display("These details only shape how older notes are organized."))
                            .font(MoriV2Type.caption)
                            .foregroundColor(MoriV2Palette.mutedStone)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .transition(.opacity)
            }
        }
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsArchiveSettings)
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
        VStack(alignment: .leading, spacing: 12) {
            MoriV2QuietDisclosureRow(
                title: showsReminderSettings ? "Hide reminders" : "Reminders",
                subtitle: "Optional, gentle nudges.",
                isExpanded: showsReminderSettings,
                action: { showsReminderSettings.toggle() }
            )

            if showsReminderSettings {
                MoriV2PaperCard(padding: 16, cornerRadius: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        ClockReminderSettingsRow()
                        settingsDivider
                        DailySparkReminderSettingsRow()
                        settingsDivider
                        JournalReminderSettingsRow()
                    }
                }
                .transition(.opacity)
            }
        }
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsReminderSettings)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriV2QuietDisclosureRow(
                title: showsLanguageSettings ? "Hide language" : "Language",
                subtitle: settings.localePreference.displayName,
                isExpanded: showsLanguageSettings,
                action: { showsLanguageSettings.toggle() }
            )

            if showsLanguageSettings {
                MoriV2PaperCard(padding: 16, cornerRadius: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker(MoriL10n.display("Language"), selection: $settings.localePreference) {
                            ForEach(MoriLocalePreference.allCases) { preference in
                                Text(preference.displayName).tag(preference)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget, alignment: .leading)

                        Text(MoriL10n.display("System follows your iPhone language order."))
                            .font(MoriV2Type.caption)
                            .foregroundColor(MoriV2Palette.mutedStone)
                    }
                }
                .transition(.opacity)
            }
        }
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsLanguageSettings)
    }

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriV2QuietDisclosureRow(
                title: showsAppSettings ? "Hide app and data" : "App and data",
                subtitle: "Onboarding and saved check-ins.",
                isExpanded: showsAppSettings,
                action: { showsAppSettings.toggle() }
            )

            if showsAppSettings {
                MoriV2PaperCard(padding: 16, cornerRadius: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Button(MoriL10n.display("Restart Onboarding")) {
                            showingRestartOnboardingAlert = true
                        }
                        .font(MoriV2Type.control)
                        .foregroundColor(MoriV2Palette.forestInk)
                        .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget, alignment: .leading)

                        settingsDivider

                        Button(MoriL10n.display("Clear Day Check-ins")) {
                            showingClearDayCheckinsAlert = true
                        }
                        .font(MoriV2Type.control)
                        .foregroundColor(MoriV2Palette.stone)
                        .frame(maxWidth: .infinity, minHeight: MoriV2Layout.minimumHitTarget, alignment: .leading)
                    }
                }
                .transition(.opacity)
            }
        }
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsAppSettings)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriV2QuietDisclosureRow(
                title: showsAbout ? "Hide about Mori" : "About Mori",
                subtitle: "Pause. Notice. Choose.",
                isExpanded: showsAbout,
                action: { showsAbout.toggle() }
            )

            if showsAbout {
                MoriV2PaperCard(padding: 16, cornerRadius: 20) {
                    Text(MoriL10n.display("Mori creates one quiet moment before a feed opens."))
                        .font(MoriV2Type.body)
                        .foregroundColor(MoriV2Palette.stone)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity)
            }
        }
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsAbout)
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(MoriV2Palette.hairline)
            .frame(height: 1)
            .accessibilityHidden(true)
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
