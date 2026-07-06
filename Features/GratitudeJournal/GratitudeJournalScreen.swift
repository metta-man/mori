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

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GratitudeJournalViewModel()
    @StateObject private var dailySparkStore = DailySparkStore.shared
    @StateObject private var appLimitManager = AppLimitManager.shared

    @State private var navigationPath: [GratitudeJournalRoute] = []
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success
    @State private var showImporter = false
    @State private var todayHabitEntry: HabitEntry?
    @State private var selectedTone: HabitDayTone?
    @State private var dailyEntryNote = ""
    @State private var dailyEntryPhotos: [GratitudePhotoAttachment] = []
    @State private var persistedDailyEntryPhotos: [GratitudePhotoAttachment] = []
    @State private var selectedDailyPhotoItems: [PhotosPickerItem] = []
    @State private var activeSheet: GratitudeJournalSheet?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MoriRootScrollScreen(
                title: "Log",
                subtitle: "Record today's state, signal, and one thing worth keeping.",
                backgroundVariant: .journal,
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
                    selectedTone: selectedTone,
                    todayHabitEntry: todayHabitEntry,
                    dailyEntryNote: $dailyEntryNote,
                    dailyEntryPhotos: $dailyEntryPhotos,
                    selectedDailyPhotoItems: $selectedDailyPhotoItems,
                    recentEntries: viewModel.recentEntries,
                    onDailySparkSaved: handleDailySparkSaved,
                    onSelectTone: selectToneFromJournal,
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
            .navigationDestination(for: GratitudeJournalRoute.self) { route in
                switch route {
                case .history:
                    GratitudeHistoryView()
                case .weekArchiveDetail:
                    WeekArchiveDetailView()
                }
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
                onReloadJournal: viewModel.loadData,
                onReloadHabitData: loadHabitData
            )
            .moriPhotoPickerImporter(
                selectedItems: $selectedDailyPhotoItems,
                onImport: attachDailyEntryPhoto
            )
        }
        .environment(\.moriOpenGratitudeJournalRoute, GratitudeJournalRouteAction { route in
            navigationPath.append(route)
        })
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
                        photoAttachments: dailyEntryPhotos,
                        promptForDifficultPattern: false
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
        showJournalToast(message: "Daily Spark saved to Log")
    }

    private func openRandomMemory() {
        activeSheet = .randomMemory
    }

    private func openHistory() {
        navigationPath.append(.history)
    }

    private func openWeekArchive() {
        navigationPath.append(.weekArchiveDetail)
    }

    private func selectEntry(_ entry: GratitudeEntry) {
        activeSheet = .entry(entry)
    }

    private func loadHabitData() {
        todayHabitEntry = HabitDataManager.shared.getTodayEntry()
        selectedTone = todayHabitEntry?.tone
        dailyEntryNote = todayHabitEntry?.note ?? ""
        loadDailyEntryPhotos()
    }

    private func prepareJournal() {
        viewModel.loadData()
        loadHabitData()
        startJournalAppLimitIfPossible()
    }

    private func selectToneFromJournal(_ tone: HabitDayTone) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        selectedTone = tone
    }

    private func saveDailyEntryFromJournal() {
        guard let tone = selectedTone ?? todayHabitEntry?.tone else { return }
        saveToneFromJournal(
            tone,
            note: dailyEntryNote,
            photoAttachments: dailyEntryPhotos,
            promptForDifficultPattern: true
        )
    }

    private func saveToneFromJournal(
        _ tone: HabitDayTone,
        note: String? = nil,
        trigger: String? = nil,
        thought: String? = nil,
        feeling: String? = nil,
        responsePlan: String? = nil,
        photoAttachments: [GratitudePhotoAttachment]? = nil,
        promptForDifficultPattern: Bool = false
    ) {
        let memoryNote = note ?? dailyEntryNote
        let photosToSave = photoAttachments

        let entry = HabitDataManager.shared.saveEntry(
            tone: tone,
            note: memoryNote,
            trigger: trigger,
            thought: thought,
            feeling: feeling,
            responsePlan: responsePlan
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
        selectedTone = tone
        dailyEntryNote = entry.note ?? ""
        if let photosToSave {
            dailyEntryPhotos = photosToSave
            persistedDailyEntryPhotos = photosToSave
        } else {
            loadDailyEntryPhotos(for: entry.date)
        }
        viewModel.loadData()

        let action = MoriClarityStore.shared.recordDailyOnce(
            kind: .dailyCheckIn,
            title: MoriPractice.dailyCheckIn.title,
            seeds: MoriPractice.dailyCheckIn.seeds,
            minutes: MoriPractice.dailyCheckIn.minutes,
            note: MoriPractice.dailyCheckIn.note
        )

        showJournalToast(message: action.map { "\(tone.toastMessage) · +\($0.seeds) Seeds" } ?? tone.toastMessage)

        if appLimitFeature == .dailyCheckIn {
            endActiveAppLimit()
        }

        if promptForDifficultPattern, tone == .negative, !entry.hasPatternLog {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activeSheet = .patternLog(.negative)
            }
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
        activeSheet = .patternLog(selectedTone ?? todayHabitEntry?.tone ?? .neutral)
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
        case .failure(let error):
            showJournalToast(message: error.localizedDescription, type: .error)
        }
    }

    private func restoreFromCloudKit() {
        Task {
            let result = await viewModel.restoreFromCloudKit()

            switch result {
            case .success(let count):
                loadHabitData()
                showJournalToast(message: "Restored \(count) iCloud entries.")
            case .failure(let error):
                showJournalToast(message: error.localizedDescription, type: .error)
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
