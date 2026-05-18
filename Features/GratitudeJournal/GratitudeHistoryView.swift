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
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.getAllEntries().isEmpty {
                    emptyState
                } else {
                    ForEach(groupedEntries.keys.sorted(by: >), id: \.self) { month in
                        monthSection(month: month)
                    }
                }
            }
            .padding(24)
        }
        .background(Color(hex: "FDF5E6"))
        .navigationTitle("Journal History")
        .navigationBarTitleDisplayMode(.large)
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
                .foregroundColor(Color(hex: "CCCCCC"))
            
            Text("No entries yet")
                .font(.custom("Poppins", size: 18))
                .foregroundColor(Color(hex: "666666"))
            
            Text("Start your gratitude journey today.\nEvery small note makes a difference.")
                .font(.custom("Poppins", size: 14))
                .foregroundColor(Color(hex: "888888"))
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
                .font(.custom("Poppins", size: 14))
                .foregroundColor(Color(hex: "333333"))
            
            // Entries for this month
            VStack(spacing: 0) {
                ForEach(groupedEntries[month] ?? []) { entry in
                    entryRow(entry: entry)
                    
                    if entry.id != groupedEntries[month]?.last?.id {
                        Divider()
                            .background(Color(hex: "F5F5F5"))
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Entry Row
    private func entryRow(entry: GratitudeEntry) -> some View {
        Button(action: { selectedEntry = entry }) {
            HStack(alignment: .top, spacing: 12) {
                // Date
                VStack(alignment: .center, spacing: 2) {
                    Text(dayOfMonth(entry.date))
                        .font(.custom("Poppins", size: 18))
                        .foregroundColor(Color(hex: "788c5d"))
                    
                    Text(shortMonth(entry.date))
                        .font(.custom("Poppins", size: 12))
                        .foregroundColor(Color(hex: "888888"))
                }
                .frame(width: 44)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Label(entry.sourceLabel, systemImage: entry.sourceSymbolName)
                        .font(.custom("Poppins", size: 11))
                        .foregroundColor(sourceColor(for: entry))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: "FDF5E6"))
                        .cornerRadius(4)

                    if !entry.photoAttachments.isEmpty {
                        Label("\(entry.photoAttachments.count)", systemImage: "photo")
                            .font(.custom("Poppins", size: 11))
                            .foregroundColor(Color(hex: "888888"))
                    }
                    
                    Text(entry.displayContent)
                        .font(.custom("Poppins", size: 14))
                        .foregroundColor(Color(hex: "666666"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "CCCCCC"))
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
        case .journal: return Color(hex: "D4AF37")
        case .dailySpark: return Color(hex: "B8942D")
        case .weeklyIntention: return Color(hex: "788c5d")
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        GratitudeHistoryView()
    }
}
