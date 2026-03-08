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
    
    @Published var hasExistingEntryToday: Bool = false
    @Published var todayEntry: GratitudeEntry?
    
    // MARK: - Private Properties
    private var autoSaveTimer: Timer?
    private var entries: [GratitudeEntry] = []
    
    // MARK: - UserDefaults Keys
    private let entriesKey = "mori_gratitude_entries"
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
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([GratitudeEntry].self, from: data) {
            entries = decoded.sorted { $0.date > $1.date }
            recentEntries = Array(entries.prefix(10))
        }
    }
    
    private func checkTodayEntry() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let existingEntry = entries.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            hasExistingEntryToday = true
            todayEntry = existingEntry
            content = existingEntry.content
            selectedPrompt = existingEntry.promptType
        } else {
            hasExistingEntryToday = false
            todayEntry = nil
        }
    }
    
    private func loadDraft() {
        // Load draft if no entry today
        guard !hasExistingEntryToday else { return }
        
        if let data = UserDefaults.standard.data(forKey: draftKey),
           let draft = try? JSONDecoder().decode(GratitudeDraft.self, from: data) {
            content = draft.content
            selectedPrompt = draft.promptType
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
        guard !content.isEmpty, !hasExistingEntryToday else { return }
        
        let draft = GratitudeDraft(
            content: content,
            promptType: selectedPrompt,
            lastSaved: Date()
        )
        
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: draftKey)
        }
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
        if let existingIndex = entries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            // Update existing entry
            entries[existingIndex].content = content
            entries[existingIndex].promptType = selectedPrompt
            entries[existingIndex].updatedAt = Date()
            todayEntry = entries[existingIndex]
        } else {
            // Create new entry
            let newEntry = GratitudeEntry(
                date: today,
                content: content,
                promptType: selectedPrompt
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
        saveEntries()
        recentEntries = Array(entries.prefix(10))
        
        // Check if deleted was today's entry
        let calendar = Calendar.current
        if calendar.isDate(entry.date, inSameDayAs: Date()) {
            hasExistingEntryToday = false
            todayEntry = nil
            content = ""
            selectedPrompt = nil
        }
    }
    
    // MARK: - Private Helpers
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
    
    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
    }
    
    // MARK: - Get All Entries (for history)
    func getAllEntries() -> [GratitudeEntry] {
        return entries.sorted { $0.date > $1.date }
    }
}

// MARK: - Gratitude Error
enum GratitudeError: LocalizedError {
    case validationFailed(String)
    case saveFailed
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .saveFailed:
            return "Failed to save entry. Please try again."
        case .loadFailed:
            return "Failed to load entries."
        }
    }
}
