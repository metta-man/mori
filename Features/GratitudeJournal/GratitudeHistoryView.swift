//
//  GratitudeHistoryView.swift
//  Mori
//
//  Full history view for gratitude journal
//

import SwiftUI

// MARK: - Gratitude History View
struct GratitudeHistoryView: View {
    @StateObject private var viewModel = GratitudeJournalViewModel()
    @State private var selectedEntry: GratitudeEntry?
    
    var body: some View {
        MoriForestBackground {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 18) {
                    if viewModel.getAllEntries().isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedEntries.keys.sorted(by: >), id: \.self) { month in
                            monthSection(month: month)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Journal History")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(item: $selectedEntry) { entry in
            GratitudeDetailView(entry: entry)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundColor(MoriColors.forestMuted.opacity(0.62))
            
            Text("No entries yet")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)
            
            Text("Start your gratitude journey today.\nEvery small note makes a difference.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }
    
    // MARK: - Month Section
    private func monthSection(month: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month Header
            Text(month)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)
            
            // Entries for this month
            VStack(spacing: 0) {
                ForEach(groupedEntries[month] ?? []) { entry in
                    entryRow(entry: entry)
                    
                    if entry.id != groupedEntries[month]?.last?.id {
                        Divider()
                            .background(MoriColors.forestLine.opacity(0.58))
                    }
                }
            }
            .moriSanctuaryCard(cornerRadius: 22, padding: 0)
        }
    }
    
    // MARK: - Entry Row
    private func entryRow(entry: GratitudeEntry) -> some View {
        Button(action: { selectedEntry = entry }) {
            HStack(alignment: .top, spacing: 12) {
                // Date
                VStack(alignment: .center, spacing: 2) {
                    Text(dayOfMonth(entry.date))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestMoss)
                    
                    Text(shortMonth(entry.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MoriColors.forestMuted)
                }
                .frame(width: 44)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Label(entry.sourceLabel, systemImage: entry.sourceSymbolName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(sourceColor(for: entry))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(sourceColor(for: entry).opacity(0.10))
                        .cornerRadius(4)

                    if !entry.photoAttachments.isEmpty {
                        Label("\(entry.photoAttachments.count)", systemImage: "photo")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MoriColors.forestMuted)
                    }
                    
                    Text(entry.displayContent)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.forestCanopy)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(MoriColors.forestMuted.opacity(0.58))
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Grouped Entries
    private var groupedEntries: [String: [GratitudeEntry]] {
        let entries = viewModel.getAllEntries()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        return Dictionary(grouping: entries) { entry in
            formatter.string(from: entry.date)
        }
    }
    
    // MARK: - Date Formatters
    private func dayOfMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func shortMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private func sourceColor(for entry: GratitudeEntry) -> Color {
        switch entry.sourceKind {
        case .journal: return MoriColors.forestMuted
        case .dayLog: return MoriColors.forestClay
        case .dailySpark: return MoriColors.forestSeed
        case .weeklyIntention: return MoriColors.forestMoss
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        GratitudeHistoryView()
    }
}
