//
//  GratitudeJournalViewModel.swift
//  Mori
//
//  ViewModel for gratitude journal feature
//

import Foundation
import Combine
import SwiftUI

// MARK: - Gratitude Journal View Model
@MainActor
class GratitudeJournalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var content: String = ""
    @Published var selectedPrompt: GratitudePrompt?
    @Published var recentEntries: [GratitudeEntry] = []
    @Published var randomEntry: GratitudeEntry?
    @Published var attachedPhotos: [GratitudePhotoAttachment] = []
    
    @Published var hasExistingEntryToday: Bool = false
    @Published var todayEntry: GratitudeEntry?
    
    // MARK: - Private Properties
    private var autoSaveTimer: Timer?
    private var entries: [GratitudeEntry] = []
    private let entryStore: GratitudeEntryStore
    private let draftStore: GratitudeDraftStore
    private let transferStore: GratitudeJournalTransferStore
    
    // MARK: - Initialization
    init(
        entryStore: GratitudeEntryStore = .live,
        draftStore: GratitudeDraftStore = GratitudeDraftStore(),
        transferStore: GratitudeJournalTransferStore = GratitudeJournalTransferStore()
    ) {
        self.entryStore = entryStore
        self.draftStore = draftStore
        self.transferStore = transferStore
        setupAutoSave()
    }
    
    deinit {
        autoSaveTimer?.invalidate()
    }
    
    // MARK: - Data Loading
    func loadData() {
        loadEntries()
        checkTodayEntry()
        loadDraft()
    }
    
    private func loadEntries() {
        entries = entryStore.loadEntries()
        recentEntries = Array(entries.prefix(10))
    }
    
    private func checkTodayEntry() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let existingEntry = entries.first(where: { calendar.isDate($0.date, inSameDayAs: today) && $0.sourceID == nil }) {
            hasExistingEntryToday = true
            todayEntry = existingEntry
            content = existingEntry.content
            selectedPrompt = existingEntry.promptType
            attachedPhotos = existingEntry.photoAttachments
        } else {
            hasExistingEntryToday = false
            todayEntry = nil
            content = ""
            selectedPrompt = nil
            attachedPhotos = []
        }
    }
    
    private func loadDraft() {
        guard !hasExistingEntryToday else { return }

        if let draft = draftStore.loadForToday() {
            content = draft.content
            selectedPrompt = draft.promptType
            attachedPhotos = draft.photoAttachments
        }
    }
    
    // MARK: - Auto Save
    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveDraft()
            }
        }
    }
    
    private func saveDraft() {
        guard !hasExistingEntryToday else { return }

        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachedPhotos.isEmpty {
            clearDraft()
            return
        }

        let draft = GratitudeDraft(
            content: content,
            promptType: selectedPrompt,
            photoAttachments: attachedPhotos,
            entryDate: Date(),
            lastSaved: Date()
        )

        draftStore.save(draft)
    }

    // MARK: - Photos
    func addPhotoData(_ data: Data) {
        do {
            let attachment = try GratitudePhotoStore.savePhotoData(data)
            attachedPhotos.append(attachment)
            saveDraft()
        } catch {
            // Keep the editor responsive if one image fails to copy.
        }
    }

    func removePhoto(_ attachment: GratitudePhotoAttachment) {
        attachedPhotos.removeAll { $0.id == attachment.id }
        GratitudePhotoStore.deletePhoto(attachment)
        saveDraft()
    }
    
    // MARK: - Save Entry
    func saveEntry() -> Result<GratitudeEntry, GratitudeError> {
        let result = entryStore.saveJournalEntry(
            on: Date(),
            content: content,
            promptType: selectedPrompt,
            photoAttachments: attachedPhotos
        )

        switch result {
        case .success(let entry):
            entries = entryStore.loadEntries()
            todayEntry = entry
            hasExistingEntryToday = true
            clearDraft()
            recentEntries = Array(entries.prefix(10))
        case .failure:
            break
        }

        return result
    }
    
    // MARK: - Random Entry
    func loadRandomEntry() {
        guard !entries.isEmpty else {
            randomEntry = nil
            return
        }
        
        randomEntry = entries.randomElement()
    }
    
    // MARK: - Delete Entry
    func deleteEntry(_ entry: GratitudeEntry) {
        entries.removeAll { $0.id == entry.id }
        entry.photoAttachments.forEach(GratitudePhotoStore.deletePhoto)
        saveEntries()
        recentEntries = Array(entries.prefix(10))
        
        // Check if deleted was today's entry
        let calendar = Calendar.current
        if entry.sourceID == nil && calendar.isDate(entry.date, inSameDayAs: Date()) {
            hasExistingEntryToday = false
            todayEntry = nil
            content = ""
            selectedPrompt = nil
            attachedPhotos = []
        }
    }
    
    // MARK: - Private Helpers
    private func saveEntries() {
        entryStore.saveEntries(entries)
    }
    
    private func clearDraft() {
        draftStore.clear()
    }
    
    // MARK: - Get All Entries (for history)
    func getAllEntries() -> [GratitudeEntry] {
        return entries.sorted { $0.date > $1.date }
    }

    @discardableResult
    private func mergeImportedEntries(_ importedEntries: [GratitudeEntry]) -> Int {
        var mergedByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })

        for importedEntry in importedEntries {
            if let existingEntry = mergedByID[importedEntry.id] {
                existingEntry.photoAttachments.forEach(GratitudePhotoStore.deletePhoto)
            }

            mergedByID[importedEntry.id] = importedEntry
        }

        entries = mergedByID.values.sorted { $0.date > $1.date }
        saveEntries()
        recentEntries = Array(entries.prefix(10))
        checkTodayEntry()
        clearDraft()

        return importedEntries.count
    }

    // MARK: - Export
    func exportJournal() -> URL? {
        try? transferStore.export(entries: getAllEntries())
    }

    // MARK: - Import
    func importJournal(from url: URL) -> Result<Int, GratitudeError> {
        do {
            let importedEntries = try transferStore.importEntries(from: url)
            let importedCount = mergeImportedEntries(importedEntries)
            return .success(importedCount)
        } catch {
            return .failure(.importFailed)
        }
    }

    func restoreFromCloudKit() async -> Result<Int, GratitudeError> {
        do {
            let importedEntries = try await entryStore.restoreFromCloudBackup()
            let importedCount = mergeImportedEntries(importedEntries)
            return .success(importedCount)
        } catch {
            return .failure(.iCloudRestoreFailed)
        }
    }
}

// MARK: - Gratitude Error
enum GratitudeError: LocalizedError {
    case validationFailed(String)
    case saveFailed
    case loadFailed
    case importFailed
    case iCloudRestoreFailed
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .saveFailed:
            return "Failed to save entry. Please try again."
        case .loadFailed:
            return "Failed to load entries."
        case .importFailed:
            return MoriL10n.display("Could not import this log backup.")
        case .iCloudRestoreFailed:
            return MoriL10n.display("Could not restore your iCloud log backup.")
        }
    }
}
