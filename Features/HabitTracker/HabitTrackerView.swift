import SwiftUI

private enum HabitTrackerSheet: Identifiable {
    case settings
    case logbook
    case patternLog(HabitDayTone)

    var id: String {
        switch self {
        case .settings:
            return "settings"
        case .logbook:
            return "logbook"
        case .patternLog(let tone):
            return "pattern-log-\(tone.id)"
        }
    }
}

// MARK: - Daily Review View
/// Daily tone tracking backed by the shared HabitEntry store.
struct HabitTrackerView: View {
    let showsDismissButton: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.moriOpenRoute) private var openRoute
    @EnvironmentObject var settings: UserSettings
    @StateObject private var appLimitManager = AppLimitManager.shared
    @State private var dashboard = HabitTrackerDashboardSnapshot.empty
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var selectedTone: HabitDayTone?
    @State private var reflectionNote = ""
    @State private var activeSheet: HabitTrackerSheet?

    private var currentTone: HabitDayTone? {
        selectedTone ?? dashboard.todayEntry?.tone
    }

    init(showsDismissButton: Bool = false) {
        self.showsDismissButton = showsDismissButton
    }

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .journal) {
                GeometryReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            MoriPageHeader(
                                eyebrow: "Daily Review",
                                title: "What happened today?",
                                subtitle: "One tone. One optional memory. The archive gets the signal."
                            )

                            HStack(spacing: 14) {
                                HabitButton(
                                    type: .positive,
                                    isSelected: currentTone == .positive
                                ) {
                                    selectToneForReflection(.positive)
                                }

                                HabitButton(
                                    type: .neutral,
                                    isSelected: currentTone == .neutral
                                ) {
                                    selectToneForReflection(.neutral)
                                }

                                HabitButton(
                                    type: .negative,
                                    isSelected: currentTone == .negative
                                ) {
                                    selectToneForReflection(.negative)
                                }
                            }
                            .padding(.vertical, 4)

                            DailyReflectionCard(
                                selectedTone: currentTone,
                                note: $reflectionNote,
                                onSave: saveReflection,
                                onOpenPatternLog: openPatternLog
                            )

                            MoriFactorTagReviewCard(
                                date: Date(),
                                title: "Local signals",
                                subtitle: "Optional labels from today's review, log, resets, and recovery context."
                            )

                            RecentDayPatternCard(
                                entries: dashboard.weeklyEntries,
                                todayEntry: dashboard.todayEntry
                            )
                                .padding(.bottom, 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, showsDismissButton ? 72 : max(18, proxy.safeAreaInsets.top + 12))
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if showsDismissButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            MoriBitmapIconImage(icon: .chevron, size: 16, opacity: 0.88)
                                .rotationEffect(.degrees(180))
                        }
                        .accessibilityLabel("Back")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            openPatternLog()
                        } label: {
                            MoriBitmapIconImage(icon: .refresh, size: 18, opacity: 0.82)
                        }
                        .accessibility(label: Text(MoriL10n.display("Open pattern log")))

                        Button {
                            openLogbook()
                        } label: {
                            MoriBitmapIconImage(icon: .journal, size: 18, opacity: 0.82)
                        }
                        .accessibility(label: Text(MoriL10n.display("Log a previous day")))

                        Button {
                            openSettings()
                        } label: {
                            MoriBitmapIconImage(icon: .settings, size: 18, opacity: 0.82)
                        }
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                activeSheetContent(sheet)
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    Text(toastMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MoriColors.botanicalSurface)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(MoriColors.botanicalInk)
                        .cornerRadius(8)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
            .onAppear {
                loadData()
            }
            .onMoriDataChange(.habit, perform: loadData)
            .moriKeyboardDoneToolbar()
        }
    }

    @ViewBuilder
    private func activeSheetContent(_ sheet: HabitTrackerSheet) -> some View {
        switch sheet {
        case .settings:
            SettingsView()
                .environmentObject(settings)
                .moriKeyboardDoneToolbar()
        case .logbook:
            LogbookEntrySheet { date, tone, note, trigger, thought, feeling, responsePlan, journalText, photoAttachments in
                saveBackdatedEntry(
                    date: date,
                    tone: tone,
                    note: note,
                    trigger: trigger,
                    thought: thought,
                    feeling: feeling,
                    responsePlan: responsePlan,
                    journalText: journalText,
                    photoAttachments: photoAttachments
                )
            }
        case .patternLog(let tone):
            PatternLogSheet(
                existingEntry: dashboard.todayEntry,
                initialTone: tone,
                onSave: { tone, trigger, thought, feeling, responsePlan in
                    saveTone(
                        tone,
                        note: PatternLogSheet.summary(
                            trigger: trigger,
                            thought: thought,
                            feeling: feeling,
                            responsePlan: responsePlan
                        ),
                        trigger: trigger,
                        thought: thought,
                        feeling: feeling,
                        responsePlan: responsePlan,
                        promptForDifficultPattern: false
                    )
                }
            )
        }
    }

    private func loadData() {
        dashboard = HabitDataManager.shared.dashboardSnapshot()
        selectedTone = dashboard.todayEntry?.tone
        reflectionNote = dashboard.todayEntry?.note ?? ""
    }

    private func selectToneForReflection(_ tone: HabitDayTone) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        selectedTone = tone
    }

    private func saveReflection() {
        guard let tone = currentTone else { return }
        saveTone(tone, note: reflectionNote, promptForDifficultPattern: true)
    }

    private func openPatternLog() {
        activeSheet = .patternLog(currentTone ?? .neutral)
    }

    private func openLogbook() {
        activeSheet = .logbook
    }

    private func openSettings() {
        if !openRoute(.settings) {
            activeSheet = .settings
        }
    }

    private func saveTone(
        _ tone: HabitDayTone,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil,
        promptForDifficultPattern: Bool = false
    ) {
        let entry = HabitDataManager.shared.saveEntry(
            tone: tone,
            note: note,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan
        )

        GratitudeEntryStore.live.saveDayLogEntry(
            on: entry.date,
            tone: tone,
            note: note,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan
        )

        dashboard = HabitDataManager.shared.dashboardSnapshot()
        selectedTone = entry.tone
        reflectionNote = entry.note ?? ""

        let action = MoriClarityStore.shared.recordDailyOnce(
            kind: .dailyCheckIn,
            title: MoriPractice.dailyCheckIn.title,
            seeds: MoriPractice.dailyCheckIn.seeds,
            minutes: MoriPractice.dailyCheckIn.minutes,
            note: MoriPractice.dailyCheckIn.note
        )

        if let action {
            toastMessage = MoriL10n.string("habit.toast.with_seeds", defaultValue: "%@ · +%d Seeds", arguments: [tone.toastMessage, action.seeds])
        } else {
            toastMessage = tone.toastMessage
        }
        showToast = true
        appLimitManager.perform(.endAppLimit(feature: .dailyCheckIn))

        if promptForDifficultPattern, tone == .negative, !entry.hasPatternLog {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activeSheet = .patternLog(.negative)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }

    private func saveBackdatedEntry(
        date: Date,
        tone: HabitDayTone,
        note: String?,
        trigger: String?,
        thought: String?,
        feeling: String?,
        responsePlan: String?,
        journalText: String?,
        photoAttachments: [GratitudePhotoAttachment]
    ) {
        let memoryNote = journalText ?? note

        _ = HabitDataManager.shared.saveEntry(
            on: date,
            tone: tone,
            note: memoryNote,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan
        )

        GratitudeEntryStore.live.saveDayLogEntry(
            on: date,
            tone: tone,
            note: memoryNote,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan,
            photoAttachments: photoAttachments
        )

        if Calendar.current.isDateInToday(date) {
            MoriClarityStore.shared.recordDailyOnce(
                kind: .dailyCheckIn,
                title: MoriPractice.dailyCheckIn.title,
                seeds: MoriPractice.dailyCheckIn.seeds,
                minutes: MoriPractice.dailyCheckIn.minutes,
                note: MoriPractice.dailyCheckIn.note
            )
        }

        loadData()
        toastMessage = MoriL10n.display("Previous day logged")
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }

}
