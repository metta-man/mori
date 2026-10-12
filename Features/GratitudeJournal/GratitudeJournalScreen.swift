//
//  GratitudeJournalScreen.swift
//  Mori
//
//  Main screen for gratitude journal feature
//

import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

private enum GratitudeJournalSheet: Identifiable {
    case randomMemory
    case patternLog(HabitDayTone)
    case logbook
    case entry(GratitudeEntry)
    case export(JournalExportPackage)

    var id: String {
        switch self {
        case .randomMemory:
            return "random-memory"
        case .patternLog(let tone):
            return "pattern-log-\(tone.id)"
        case .logbook:
            return "logbook"
        case .entry(let entry):
            return "entry-\(entry.id)"
        case .export(let package):
            return "export-\(package.id)"
        }
    }
}

// MARK: - Gratitude Journal Screen
struct GratitudeJournalScreen: View {
    var showsDismissButton = false
    var appLimitFeature: MoriScreenTimeFeature = .journal
    var usesAppShellNavigation = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.moriOpenGratitudeJournalRoute) private var openGratitudeRoute
    @StateObject private var viewModel = GratitudeJournalViewModel()
    @StateObject private var dailySparkStore = DailySparkStore.shared
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var settleStore = SettleSessionStore.shared
    @StateObject private var appLimitManager = AppLimitManager.shared

    @State private var navigationPath: [GratitudeJournalRoute] = []
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success
    @State private var showImporter = false
    @State private var todayHabitEntry: HabitEntry?
    @State private var guidedCheckIn = JournalGuidedCheckInState()
    @State private var moodValence: MoriJournalValence?
    @State private var newMoodRecordedAt = Date()
    @State private var isSharingMood = false
    @State private var moodSharePresentation = MoriJournalMoodSharePresentation()
    @State private var dailyEntryNote = ""
    @State private var dailyEntryPhotos: [GratitudePhotoAttachment] = []
    @State private var persistedDailyEntryPhotos: [GratitudePhotoAttachment] = []
    @State private var selectedDailyPhotoItems: [PhotosPickerItem] = []
    @State private var activeSheet: GratitudeJournalSheet?
    @State private var lifeGridSnapshot = JournalLifeGridSnapshot.current()
    #if DEBUG
    @State private var hasAppliedFreshLogUITestState = false
    #endif

    @ViewBuilder
    var body: some View {
        if usesAppShellNavigation {
            screenContent
        } else {
            NavigationStack(path: $navigationPath) {
                screenContent
                    .navigationDestination(for: GratitudeJournalRoute.self) { route in
                        gratitudeJournalDestination(route)
                    }
            }
            .environment(\.moriOpenGratitudeJournalRoute, GratitudeJournalRouteAction { route in
                navigationPath.append(route)
            })
        }
    }

    private var screenContent: some View {
        MoriRootScrollScreen(
            title: "Log",
            subtitle: "One small check-in is enough.",
            spacing: 16,
            backgroundVariant: .journal,
            showsBackground: !usesAppShellNavigation,
            minimumTopInset: 66,
            headerStyle: .editorial,
            headerTrailing: {
                GratitudeJournalHeaderActions(
                    onLogPreviousDay: openLogbook,
                    onExport: exportJournal,
                    onImport: openImporter,
                    onRestore: restoreFromCloudKit
                )
            }
        ) {
            GratitudeJournalHomeContent(
                dailySparkStore: dailySparkStore,
                guidedCheckIn: $guidedCheckIn,
                moodValence: moodValenceBinding,
                isSharingMood: isSharingMood,
                moodShareMessage: moodShareMessage,
                moodPayload: moodPreviewPayload,
                onShareMood: shareMoodWithHealth,
                todayHabitEntry: todayHabitEntry,
                dailyEntryNote: $dailyEntryNote,
                dailyEntryPhotos: $dailyEntryPhotos,
                selectedDailyPhotoItems: $selectedDailyPhotoItems,
                recentEntries: viewModel.recentEntries,
                lifeGridSnapshot: lifeGridSnapshot,
                onDailySparkSaved: handleDailySparkSaved,
                onSaveDailyEntry: saveDailyEntryFromJournal,
                onOpenPatternLog: openPatternLog,
                onOpenWeekArchive: openWeekArchive,
                onRemoveDailyPhoto: removeDailyEntryPhoto,
                onRandomMemory: openRandomMemory,
                onViewHistory: openHistory,
                onEntryTap: selectEntry
            )
        }
        .overlay(alignment: .topLeading) {
            if showsDismissButton {
                GratitudeJournalDismissButton {
                    dismiss()
                }
                .padding(.leading, 20)
                .padding(.top, 52)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .moriKeyboardDoneToolbar()
        .sheet(item: $activeSheet) { sheet in
            activeSheetContent(sheet)
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importJournal(result)
        }
        .gratitudeJournalToast(
            isPresented: $showToast,
            message: toastMessage,
            type: toastType
        )
        .gratitudeJournalLifecycle(
            scenePhase: scenePhase,
            onPrepare: prepareJournal,
            onCleanup: cleanupJournalSession,
            onReloadJournal: reloadJournalData,
            onReloadHabitData: loadHabitData
        )
        .moriOnChange(of: moodValence) { _ in clearMoodStatusIfChanged() }
        .moriOnChange(of: guidedCheckIn) { _ in clearMoodStatusIfChanged() }
        .moriOnChange(of: todayHabitEntry?.journalMood) { _ in clearMoodStatusIfChanged() }
        .moriOnChange(of: dailySparkStore.entries.count) { _ in
            reloadJournalData()
        }
        .moriOnChange(of: clarityStore.actions.count) { _ in
            refreshLifeGridSnapshot()
        }
        .moriOnChange(of: settleStore.sessions.count) { _ in
            refreshLifeGridSnapshot()
        }
        .moriPhotoPickerImporter(
            selectedItems: $selectedDailyPhotoItems,
            onImport: attachDailyEntryPhoto
        )
    }

    @ViewBuilder
    private func gratitudeJournalDestination(_ route: GratitudeJournalRoute) -> some View {
        switch route {
        case .history:
            GratitudeHistoryView()
        case .weekArchiveDetail:
            WeekArchiveDetailView()
                .moriHidesMainTabBar()
        }
    }

    @ViewBuilder
    private func activeSheetContent(_ sheet: GratitudeJournalSheet) -> some View {
        switch sheet {
        case .randomMemory:
            RandomMemoryModal(entry: viewModel.randomEntry)
                .presentationDetents([.medium, .large])
        case .patternLog(let tone):
            PatternLogSheet(
                existingEntry: todayHabitEntry,
                initialTone: tone,
                onSave: { tone, trigger, thought, feeling, responsePlan in
                    saveToneFromJournal(
                        tone,
                        note: dailyEntryNote,
                        trigger: trigger,
                        thought: thought,
                        feeling: feeling,
                        responsePlan: responsePlan,
                        photoAttachments: dailyEntryPhotos
                    )
                }
            )
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
        case .entry(let entry):
            GratitudeDetailView(entry: entry)
        case .export(let package):
            ActivityView(activityItems: [package.url])
        }
    }

    private func handleDailySparkSaved(_ entry: DailySparkEntry) {
        reloadJournalData()
        showJournalToast(message: "Daily Spark saved to Log")
    }

    private func openRandomMemory() {
        activeSheet = .randomMemory
    }

    private func openHistory() {
        openGratitudeRoute(.history)
    }

    private func openWeekArchive() {
        openGratitudeRoute(.weekArchiveDetail)
    }

    private func selectEntry(_ entry: GratitudeEntry) {
        activeSheet = .entry(entry)
    }

    private func loadHabitData() {
        #if DEBUG
        if !hasAppliedFreshLogUITestState,
           ProcessInfo.processInfo.arguments.contains("-MoriStartFreshLogForUITest") {
            hasAppliedFreshLogUITestState = true
            todayHabitEntry = nil
            guidedCheckIn = JournalGuidedCheckInState()
            dailyEntryNote = ""
            dailyEntryPhotos = []
            persistedDailyEntryPhotos = []
            refreshLifeGridSnapshot()
            return
        }
        #endif

        todayHabitEntry = HabitDataManager.shared.getTodayEntry()
        guidedCheckIn = JournalGuidedCheckInState(restoring: todayHabitEntry)
        moodValence = todayHabitEntry?.journalMood?.valence
        dailyEntryNote = todayHabitEntry?.note ?? ""
        loadDailyEntryPhotos()
        refreshLifeGridSnapshot()
    }

    private func prepareJournal() {
        reloadJournalData()
        loadHabitData()
        startJournalAppLimitIfPossible()
    }

    private func reloadJournalData() {
        viewModel.loadData()
        refreshLifeGridSnapshot()
    }

    private var moodValenceBinding: Binding<MoriJournalValence?> {
        Binding(get: { moodValence }, set: { selection in
            if todayHabitEntry?.journalMood == nil, selection != nil { newMoodRecordedAt = Date() }
            moodValence = selection
            clearMoodStatusIfChanged()
        })
    }
    private var moodDraft: MoriJournalMoodDraft {
        .init(valence: moodValence, emotionID: guidedCheckIn.emotion?.id,
              contextID: guidedCheckIn.context?.id)
    }
    private var moodPreviewPayload: MoriJournalMoodHealthPayload? {
        guard let valence = moodValence else { return nil }
        return MoriJournalMood.editing(todayHabitEntry?.journalMood, valence: valence,
            emotionID: guidedCheckIn.emotion?.id, contextID: guidedCheckIn.context?.id,
            now: newMoodRecordedAt).healthPayload
    }
    private var moodShareMessage: String {
        switch moodSharePresentation.outcome {
        case .written: return MoriL10n.string("journal.mood.shared", defaultValue: "Shared with Apple Health")
        case .previouslyShared: return MoriL10n.string("journal.mood.previously_shared", defaultValue: "This version was shared earlier. No new Health record was saved.")
        case .failed: return MoriL10n.string("journal.mood.not_shared", defaultValue: "Saved in Mori. This share did not complete. Check Health access and try again.")
        case nil: return ""
        }
    }
    private func clearMoodStatusIfChanged() {
        moodSharePresentation.clearIfChanged(draft: moodDraft, persisted: todayHabitEntry?.journalMood)
    }
    private func shareMoodWithHealth() {
        guard !isSharingMood, moodValence != nil, guidedCheckIn.canSave else { return }
        saveDailyEntryFromJournal()
        guard let mood = todayHabitEntry?.journalMood else { return }
        isSharingMood = true
        moodSharePresentation.begin(mood)
        Task { @MainActor in
            defer { isSharingMood = false }
            let outcome: MoriJournalMoodSharePresentation.Outcome
            do {
                let result = try await MoriJournalMoodHealth.shared.share(mood)
                if result == .written { HabitDataManager.shared.markMoodShared(mood) }
                outcome = result == .written ? .written : .previouslyShared
            } catch { outcome = .failed }
            moodSharePresentation.complete(mood, outcome: outcome, draft: moodDraft,
                persisted: HabitDataManager.shared.persistedMood(id: mood.id))
        }
    }

    private func saveDailyEntryFromJournal() {
        guard let action = MoriJournalGuidedSaveAction(checkIn: guidedCheckIn,
            existingEntry: todayHabitEntry, note: dailyEntryNote, valence: moodValence,
            recordedAt: newMoodRecordedAt) else { return }
        let entry = action.save(using: .shared)
        saveToneFromJournal(entry.tone, note: entry.note, trigger: entry.trigger,
            thought: entry.thought, feeling: entry.feeling, responsePlan: entry.responsePlan,
            journalEmotionID: entry.journalEmotionID, journalContextID: entry.journalContextID,
            journalResponseID: entry.journalResponseID, photoAttachments: dailyEntryPhotos,
            savedEntry: entry)
    }

    private func saveToneFromJournal(
        _ tone: HabitDayTone,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil,
        journalEmotionID: String? = nil,
        journalContextID: String? = nil,
        journalResponseID: String? = nil,
        photoAttachments: [GratitudePhotoAttachment]? = nil,
        moodEdit: MoriJournalMoodEdit = .preserve,
        savedEntry: HabitEntry? = nil
    ) {
        let memoryNote = note ?? dailyEntryNote
        let photosToSave = photoAttachments

        let entry = savedEntry ?? HabitDataManager.shared.saveEntry(
            tone: tone,
            note: memoryNote,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan,
            journalEmotionID: journalEmotionID,
            journalContextID: journalContextID,
            journalResponseID: journalResponseID,
            moodEdit: moodEdit
        )

        GratitudeEntryStore.live.saveDayLogEntry(
            on: entry.date,
            tone: tone,
            note: memoryNote,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan,
            photoAttachments: photosToSave
        )

        todayHabitEntry = entry
        guidedCheckIn = JournalGuidedCheckInState(restoring: entry)
        moodValence = entry.journalMood?.valence
        dailyEntryNote = entry.note ?? ""
        if let photosToSave {
            dailyEntryPhotos = photosToSave
            persistedDailyEntryPhotos = photosToSave
        } else {
            loadDailyEntryPhotos(for: entry.date)
        }
        viewModel.loadData()
        refreshLifeGridSnapshot()

        _ = MoriClarityStore.shared.recordDailyOnce(
            kind: .dailyCheckIn,
            title: MoriPractice.dailyCheckIn.title,
            seeds: MoriPractice.dailyCheckIn.seeds,
            minutes: MoriPractice.dailyCheckIn.minutes,
            note: MoriPractice.dailyCheckIn.note
        )

        showJournalToast(message: tone.toastMessage)

        if appLimitFeature == .dailyCheckIn {
            endActiveAppLimit()
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

        viewModel.loadData()
        loadHabitData()
        showJournalToast(message: "Previous day logged")
    }

    private func loadDailyEntryPhotos(for date: Date = Date()) {
        let photos = GratitudeEntryStore.live.dayLogEntry(on: date)?.photoAttachments ?? []
        dailyEntryPhotos = photos
        persistedDailyEntryPhotos = photos
    }

    private func refreshLifeGridSnapshot() {
        lifeGridSnapshot = JournalLifeGridSnapshot.current(
            dailySparks: dailySparkStore.entries,
            journalEntries: viewModel.getAllEntries(),
            actions: clarityStore.actions,
            sessions: settleStore.sessions
        )
    }

    private func attachDailyEntryPhoto(from data: Data) {
        guard dailyEntryPhotos.count < 6 else { return }

        if let attachment = try? GratitudePhotoStore.savePhotoData(data) {
            dailyEntryPhotos.append(attachment)
        }
    }

    private func removeDailyEntryPhoto(_ attachment: GratitudePhotoAttachment) {
        dailyEntryPhotos.removeAll { $0.id == attachment.id }

        if !persistedDailyEntryPhotos.contains(attachment) {
            GratitudePhotoStore.deletePhoto(attachment)
        }
    }

    private func cleanupUnsavedDailyEntryPhotos() {
        let unsavedPhotos = dailyEntryPhotos.filter { !persistedDailyEntryPhotos.contains($0) }
        unsavedPhotos.forEach(GratitudePhotoStore.deletePhoto)
        dailyEntryPhotos = persistedDailyEntryPhotos
        selectedDailyPhotoItems = []
    }

    private func openLogbook() {
        activeSheet = .logbook
    }

    private func openImporter() {
        showImporter = true
    }

    private func openPatternLog() {
        activeSheet = .patternLog(guidedCheckIn.selectedTone ?? todayHabitEntry?.tone ?? .neutral)
    }

    private func startJournalAppLimitIfPossible() {
        guard appLimitFeature == .journal else { return }
        appLimitManager.perform(.startTimedAppLimit(feature: .journal, duration: 60 * 60))
    }

    private func endActiveAppLimit() {
        appLimitManager.perform(.endAppLimit(feature: appLimitFeature))
    }

    private func cleanupJournalSession() {
        cleanupUnsavedDailyEntryPhotos()
        endActiveAppLimit()
    }

    private func exportJournal() {
        guard let url = viewModel.exportJournal() else {
            showJournalToast(message: "Could not export log.", type: .error)
            return
        }

        activeSheet = .export(JournalExportPackage(url: url))
    }

    private func importJournal(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else {
            showJournalToast(message: "Could not open that backup.", type: .error)
            return
        }

        switch viewModel.importJournal(from: url) {
        case .success(let count):
            loadHabitData()
            showJournalToast(message: "Imported \(count) log entries.")
        case .failure:
            showJournalToast(message: "Could not import that backup.", type: .error)
        }
    }

    private func restoreFromCloudKit() {
        Task {
            let result = await viewModel.restoreFromCloudKit()

            switch result {
            case .success(let count):
                loadHabitData()
                showJournalToast(message: "Restored \(count) iCloud entries.")
            case .failure:
                showJournalToast(message: "Could not restore from iCloud.", type: .error)
            }
        }
    }

    private func showJournalToast(message: String, type: ToastType = .success) {
        toastMessage = message
        toastType = type

        withAnimation {
            showToast = true
        }
    }
}

// MARK: - Preview
#Preview {
    GratitudeJournalScreen()
}
