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
    
    // MARK: - UserDefaults Keys
    private let draftKey = "mori_gratitude_draft"
    
    // MARK: - Initialization
    init() {
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
        // Load from UserDefaults (in production, this would be CoreData/CloudKit)
        entries = GratitudeEntry.loadAllStored()
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
        // Load draft if no entry today
        guard !hasExistingEntryToday else { return }
        
        if let data = UserDefaults.standard.data(forKey: draftKey),
           let draft = try? JSONDecoder().decode(GratitudeDraft.self, from: data) {
            guard Calendar.current.isDate(draft.entryDate, inSameDayAs: Date()) else {
                clearDraft()
                return
            }

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
        
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: draftKey)
        }
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
        // Validate content
        let validation = GratitudeEntry.validate(content)
        guard validation.isValid else {
            return .failure(GratitudeError.validationFailed(validation.errorMessage ?? "Invalid content"))
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check for existing entry today
        if let existingIndex = entries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) && $0.sourceID == nil }) {
            // Update existing entry
            entries[existingIndex].content = content
            entries[existingIndex].promptType = selectedPrompt
            entries[existingIndex].photoAttachments = attachedPhotos
            entries[existingIndex].updatedAt = Date()
            todayEntry = entries[existingIndex]
        } else {
            // Create new entry
            let newEntry = GratitudeEntry(
                date: today,
                content: content,
                promptType: selectedPrompt,
                photoAttachments: attachedPhotos
            )
            entries.insert(newEntry, at: 0)
            todayEntry = newEntry
        }
        
        hasExistingEntryToday = true
        
        // Save to storage
        saveEntries()
        
        // Clear draft
        clearDraft()
        
        // Reload recent entries
        recentEntries = Array(entries.prefix(10))
        
        return .success(todayEntry!)
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
        GratitudeEntry.persist(entries)
    }
    
    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
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
        let backup = GratitudeJournalBackup(entries: getAllEntries())
        guard let data = try? GratitudeCloudBackup.encode(backup) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "Mori-Journal-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Import
    func importJournal(from url: URL) -> Result<Int, GratitudeError> {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let backup = try GratitudeCloudBackup.decode(data)
            let importedEntries = try backup.entries.map { try $0.gratitudeEntry() }
            let importedCount = mergeImportedEntries(importedEntries)
            return .success(importedCount)
        } catch {
            return .failure(.importFailed)
        }
    }

    func restoreFromCloudKit() async -> Result<Int, GratitudeError> {
        do {
            let importedEntries = try await GratitudeCloudBackup.shared.restore()
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
            return "Could not import this journal backup."
        case .iCloudRestoreFailed:
            return "Could not restore your iCloud journal backup."
        }
    }
}
