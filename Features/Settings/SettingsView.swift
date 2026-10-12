import SwiftUI

private enum SettingsRoute: Hashable {
    case appLimits
    case blockLists
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
            MoriRootScrollScreen(
                title: "Settings",
                subtitle: "App limits, preferences, and your data.",
                spacing: 20,
                bottomPadding: 12,
                backgroundVariant: .settings,
                minimumTopInset: 18,
                headerStyle: .editorial,
                layout: .settings,
                headerTrailing: {
                    Button(MoriL10n.display("Done")) {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .padding(.horizontal, 16)
                    .frame(minHeight: MoriV2Layout.minimumHitTarget)
                    .background(MoriColors.botanicalSurface.opacity(0.78))
                    .clipShape(Capsule())
                }
            ) {
                SettingsLinkSection(title: "App use") {
                    NavigationLink(value: SettingsRoute.appLimits) {
                        SettingsCompactLink(
                            title: "App Limits",
                            subtitle: screenTimeStatusText,
                            icon: .appLimit
                        )
                    }
                    SettingsLinkDivider()
                    NavigationLink(value: SettingsRoute.blockLists) {
                        SettingsCompactLink(
                            title: "Block Lists",
                            subtitle: "Save app groups to apply later.",
                            icon: .pattern
                        )
                    }
                    .accessibilityIdentifier("settings-block-lists")
                }

                SettingsLinkSection(title: "Personal preferences") {
                    NavigationLink(value: SettingsRoute.archive) {
                        SettingsCompactLink(
                            title: "Life Grid",
                            subtitle: "Start date and archive range.",
                            icon: .roots
                        )
                    }

                    SettingsLinkDivider()

                    NavigationLink(value: SettingsRoute.reminders) {
                        SettingsCompactLink(
                            title: "Reminders",
                            subtitle: "Optional, gentle nudges.",
                            icon: .bell
                        )
                    }

                    SettingsLinkDivider()

                    NavigationLink(value: SettingsRoute.language) {
                        SettingsCompactLink(
                            title: "Language",
                            value: settings.localePreference.displayName,
                            icon: .language
                        )
                    }
                }

                SettingsLinkSection(title: "Data and about") {
                    NavigationLink(value: SettingsRoute.appAndData) {
                        SettingsCompactLink(
                            title: "App and Data",
                            subtitle: "Onboarding and saved check-ins.",
                            icon: .appData
                        )
                    }

                    SettingsLinkDivider()

                    NavigationLink(value: SettingsRoute.about) {
                        SettingsCompactLink(
                            title: "About Mori",
                            subtitle: "Pause. Notice. Choose.",
                            icon: .leaf
                        )
                    }
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .appLimits:
                    LockedScreenTimeSettingsView()
                case .blockLists:
                    LockedScreenTimeSettingsView(showsBlockLists: true)
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
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-MoriOpenAppAndDataForUITest"),
               navigationPath.isEmpty {
                navigationPath.append(.appAndData)
            }
        }
    }

    private var screenTimeStatusText: String {
        ScreenTimeSettingsLinkPresentation(appLimitManager: appLimitManager).statusText
    }
}

private struct SettingsLinkSection<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(MoriL10n.display(title))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                content
            }
            .moriSanctuaryBox(cornerRadius: 20, padding: 0, tone: .paper, castsShadow: false)
        }
    }
}

private struct SettingsCompactLink: View {
    let title: String
    var subtitle: String?
    var value: String?
    let icon: MoriBitmapIcon

    var body: some View {
        HStack(spacing: 12) {
            MoriInterfaceIcon(icon: icon, size: 22)
                .frame(width: 30, height: 30)
                .background(MoriColors.botanicalInk.opacity(0.055))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(MoriL10n.display(title))
                    .font(.body.weight(.medium))
                    .foregroundColor(MoriColors.botanicalInk)

                if let subtitle {
                    Text(MoriL10n.display(subtitle))
                        .font(.subheadline)
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            MoriInterfaceIcon(icon: .chevron, size: 13, opacity: 0.7)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
        .multilineTextAlignment(.leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsLinkDivider: View {
    var body: some View {
        Divider()
            .overlay(MoriColors.botanicalLine.opacity(0.56))
            .padding(.leading, 56)
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
    @State private var categoryToDelete: MoriDataCategory?
    @State private var showingDeleteAllAlert = false
    @State private var deletionMessage: String?
    @State private var isDeleting = false

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
                Text(MoriL10n.string(
                    "settings.data.restart_footer",
                    defaultValue: "Restarting onboarding keeps saved data. Clearing day check-ins removes saved daily moods and pattern notes."
                ))
                .font(.footnote)
                .foregroundColor(MoriColors.botanicalMuted)
            }
            .listRowBackground(MoriColors.botanicalSurface.opacity(0.74))

            MoriDataDeletionSection(
                categoryToDelete: $categoryToDelete,
                showingDeleteAllAlert: $showingDeleteAllAlert,
                isDeleting: isDeleting
            )
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
        .alert(
            MoriL10n.display("Delete this data?"),
            isPresented: Binding(
                get: { categoryToDelete != nil },
                set: { if !$0 { categoryToDelete = nil } }
            ),
            presenting: categoryToDelete
        ) { category in
            Button(MoriL10n.display("Cancel"), role: .cancel) {
                categoryToDelete = nil
            }
            Button(MoriL10n.display("Delete"), role: .destructive) {
                categoryToDelete = nil
                delete(category)
            }
        } message: { _ in
            Text(MoriL10n.display("This cannot be undone."))
        }
        .alert(MoriL10n.display("Delete all Mori data?"), isPresented: $showingDeleteAllAlert) {
            Button(MoriL10n.display("Cancel"), role: .cancel) {}
            Button(MoriL10n.display("Delete All"), role: .destructive) { deleteEverything() }
        } message: {
            Text(MoriL10n.display("This removes all Mori data from this device and its iCloud backup, then returns to onboarding. Apple Health records are not changed."))
        }
        .alert(
            MoriL10n.display("Data Deletion"),
            isPresented: Binding(get: { deletionMessage != nil }, set: { if !$0 { deletionMessage = nil } })
        ) {
            Button(MoriL10n.display("OK")) { deletionMessage = nil }
        } message: {
            Text(deletionMessage ?? "")
        }
    }

    private func delete(_ category: MoriDataCategory) {
        isDeleting = true
        Task {
            do {
                try await MoriDataDeletionService.shared.delete(category)
                deletionMessage = MoriL10n.string(
                    "settings.data.deleted",
                    defaultValue: "Selected data was deleted."
                )
            } catch {
                deletionMessage = error.localizedDescription
            }
            isDeleting = false
        }
    }

    private func deleteEverything() {
        isDeleting = true
        Task {
            do {
                try await MoriDataDeletionService.shared.deleteEverything()
                settings.prepareForOnboardingAfterDataDeletion()
                dismissSettings()
            } catch {
                // deleteEverything always completes the local reset before it
                // reports any retryable remote iCloud/analytics failure.
                settings.prepareForOnboardingAfterDataDeletion()
                deletionMessage = error.localizedDescription
                isDeleting = false
            }
        }
    }
}

private struct MoriDataDeletionSection: View {
    @Binding var categoryToDelete: MoriDataCategory?
    @Binding var showingDeleteAllAlert: Bool
    let isDeleting: Bool

    var body: some View {
        Section {
            ForEach(MoriDataCategory.allCases) { category in
                Button(role: .destructive) {
                    categoryToDelete = category
                } label: {
                    Text(MoriL10n.display(category.title))
                }
                .disabled(isDeleting)
            }

            Button(MoriL10n.display("Delete All Mori Data"), role: .destructive) {
                showingDeleteAllAlert = true
            }
            .fontWeight(.semibold)
            .disabled(isDeleting)
        } header: {
            Text(MoriL10n.display("Delete Data"))
        } footer: {
            Text(MoriL10n.string(
                "settings.data.health_footer",
                defaultValue: "Apple Health records are never deleted. Recovery removes only Mori's local summaries. iCloud deletion requires a network connection."
            ))
        }
        .listRowBackground(MoriColors.botanicalSurface.opacity(0.74))
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

            Section {
                Link(MoriL10n.display("Privacy Policy"), destination: URL(string: "https://mori-gray.vercel.app/privacy")!)
                Link(MoriL10n.display("Terms of Use"), destination: URL(string: "https://mori-gray.vercel.app/terms")!)
                Link(MoriL10n.display("Support"), destination: URL(string: "https://mori-gray.vercel.app/support")!)
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
