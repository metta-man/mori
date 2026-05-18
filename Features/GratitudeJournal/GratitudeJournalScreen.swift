//
//  GratitudeJournalScreen.swift
//  Mori
//
//  Main screen for gratitude journal feature
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Gratitude Journal Screen
struct GratitudeJournalScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = GratitudeJournalViewModel()
    @StateObject private var dailySparkStore = DailySparkStore.shared
    
    @State private var showRandomMemory = false
    @State private var showHistory = false
    @State private var selectedEntry: GratitudeEntry?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success
    @State private var exportPackage: JournalExportPackage?
    @State private var showImporter = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    titleSection

                    DailySparkCard(store: dailySparkStore, onSaved: { _ in
                        toastMessage = "Daily Spark saved to Journal"
                        toastType = .success

                        withAnimation {
                            showToast = true
                        }
                    })
                    .padding(.horizontal, 24)

                    // Prompt Selection
                    PromptSelectionSection(selectedPrompt: $viewModel.selectedPrompt)
                        .padding(.horizontal, 24)
                    
                    // Editor
                    GratitudeEditorView(
                        content: $viewModel.content,
                        selectedPrompt: viewModel.selectedPrompt,
                        attachedPhotos: viewModel.attachedPhotos,
                        onAddPhoto: { data in
                            viewModel.addPhotoData(data)
                        },
                        onRemovePhoto: { attachment in
                            viewModel.removePhoto(attachment)
                        },
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
            .scrollDismissesKeyboard(.interactively)
            .background(MoriColors.moriDark)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Mori")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(MoriColors.moriDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Menu {
                            Button(action: exportJournal) {
                                Label("Export Journal", systemImage: "square.and.arrow.up")
                            }

                            Button(action: { showImporter = true }) {
                                Label("Import Backup", systemImage: "tray.and.arrow.down")
                            }

                            Button(action: restoreFromCloudKit) {
                                Label("Restore iCloud Backup", systemImage: "icloud.and.arrow.down")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(MoriColors.moriGold.opacity(0.8))
                        }
                        .accessibility(label: Text("Journal backup options"))

                        NavigationLink(destination: GratitudeHistoryView()) {
                            Image(systemName: "book.fill")
                                .foregroundColor(MoriColors.moriGold.opacity(0.8))
                        }
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        dismissKeyboard()
                    }
                    .foregroundColor(MoriColors.moriGold)
                }
            }
            .sheet(isPresented: $showRandomMemory) {
                RandomMemoryModal(entry: viewModel.randomEntry)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedEntry) { entry in
                GratitudeDetailView(entry: entry)
            }
            .sheet(item: $exportPackage) { package in
                ActivityView(activityItems: [package.url])
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                importJournal(result)
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
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.loadData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                viewModel.loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .gratitudeDataDidChange)) { _ in
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 10) {
            Text("Journal")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.moriCream)

            Text("Capture one thing worth remembering from today.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.moriCreamMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Toast View
    private var toastView: some View {
        HStack {
            Text(toastType == .success ? "✨" : "⚠️")
                .font(.system(size: 16))
            
            Text(toastMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(toastType == .success ? MoriColors.sageGreen : MoriColors.warmClay)
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

    private func exportJournal() {
        guard let url = viewModel.exportJournal() else {
            toastMessage = "Could not export journal."
            toastType = .error
            withAnimation {
                showToast = true
            }
            return
        }

        exportPackage = JournalExportPackage(url: url)
    }

    private func importJournal(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else {
            toastMessage = "Could not open that backup."
            toastType = .error
            withAnimation {
                showToast = true
            }
            return
        }

        switch viewModel.importJournal(from: url) {
        case .success(let count):
            toastMessage = "Imported \(count) journal entries."
            toastType = .success
        case .failure(let error):
            toastMessage = error.localizedDescription
            toastType = .error
        }

        withAnimation {
            showToast = true
        }
    }

    private func restoreFromCloudKit() {
        Task {
            let result = await viewModel.restoreFromCloudKit()

            switch result {
            case .success(let count):
                toastMessage = "Restored \(count) iCloud entries."
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

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Toast Type
enum ToastType {
    case success
    case error
}

struct JournalExportPackage: Identifiable {
    let id = UUID()
    let url: URL
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    GratitudeJournalScreen()
}
