//
//  GratitudeJournalScreen.swift
//  Mori
//
//  Main screen for gratitude journal feature
//

import SwiftUI

// MARK: - Gratitude Journal Screen
struct GratitudeJournalScreen: View {
    @StateObject private var viewModel = GratitudeJournalViewModel()
    
    @State private var showRandomMemory = false
    @State private var showHistory = false
    @State private var selectedEntry: GratitudeEntry?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title Section
                    titleSection
                    
                    // Prompt Selection
                    PromptSelectionSection(selectedPrompt: $viewModel.selectedPrompt)
                        .padding(.horizontal, 24)
                    
                    // Editor
                    GratitudeEditorView(
                        content: $viewModel.content,
                        selectedPrompt: viewModel.selectedPrompt,
                        onSave: saveEntry
                    )
                    .padding(.horizontal, 24)
                    
                    // Random Memory Button
                    RandomMemoryButton {
                        showRandomMemory = true
                    }
                    .padding(.horizontal, 24)
                    .disabled(viewModel.recentEntries.isEmpty)
                    .opacity(viewModel.recentEntries.isEmpty ? 0.5 : 1)
                    
                    // Recent Entries
                    RecentEntriesSection(
                        entries: viewModel.recentEntries,
                        onViewAll: { showHistory = true },
                        onEntryTap: { entry in
                            selectedEntry = entry
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
                .padding(.top, 16)
            }
            .background(Color(hex: "FDF5E6"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: GratitudeHistoryView()) {
                        Image(systemName: "book.fill")
                            .foregroundColor(Color(hex: "333333"))
                    }
                }
            }
            .sheet(isPresented: $showRandomMemory) {
                RandomMemoryModal(entry: viewModel.randomEntry)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedEntry) { entry in
                GratitudeDetailView(entry: entry)
            }
            .navigationDestination(isPresented: $showHistory) {
                GratitudeHistoryView()
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    toastView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showToast = false
                                }
                            }
                        }
                }
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        Text("What are you grateful for today?")
            .font(.custom("Cormorant Garamond", size: 32))
            .foregroundColor(Color(hex: "333333"))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }
    
    // MARK: - Toast View
    private var toastView: some View {
        HStack {
            Text(toastType == .success ? "✨" : "⚠️")
                .font(.system(size: 16))
            
            Text(toastMessage)
                .font(.custom("Poppins", size: 14))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(toastType == .success ? Color(hex: "788c5d") : Color(hex: "DC3545"))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.bottom, 32)
    }
    
    // MARK: - Save Entry
    private func saveEntry() {
        let result = viewModel.saveEntry()
        
        switch result {
        case .success:
            toastMessage = "Entry saved!"
            toastType = .success
        case .failure(let error):
            toastMessage = error.localizedDescription
            toastType = .error
        }
        
        withAnimation {
            showToast = true
        }
    }
}

// MARK: - Toast Type
enum ToastType {
    case success
    case error
}

// MARK: - Preview
#Preview {
    GratitudeJournalScreen()
}
