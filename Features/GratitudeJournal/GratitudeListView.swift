//
//  GratitudeListView.swift
//  Mori
//
//  Recent entries list for gratitude journal
//

import SwiftUI

// MARK: - Gratitude Entry Preview
struct GratitudeEntryPreview: View {
    let entry: GratitudeEntry
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(formatDate(entry.date))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MoriColors.moriGold)

                    EntrySourceBadge(entry: entry)

                    if !entry.photoAttachments.isEmpty {
                        Label("\(entry.photoAttachments.count)", systemImage: "photo")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MoriColors.moriCreamMuted)
                    }
                }

                Text(entry.displayContent)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.moriCream.opacity(0.82))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(label: Text("\(formatDate(entry.date)) \(entry.sourceLabel): \(entry.displayContent.prefix(50))..."))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Recent Entries Section
struct RecentEntriesSection: View {
    let entries: [GratitudeEntry]
    var onViewAll: (() -> Void)?
    var onEntryTap: ((GratitudeEntry) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MoriColors.moriGold)
                
                Text("Recent Journal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MoriColors.moriCream)
                
                Spacer()
                
                if entries.count > 3 {
                    Button(action: { onViewAll?() }) {
                        Text("View All →")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MoriColors.moriGold)
                    }
                    .accessibility(label: Text("View all gratitude entries"))
                }
            }
            
            Divider()
                .background(MoriColors.moriHairline)
            
            if entries.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 32))
                        .foregroundColor(MoriColors.moriCreamMuted)
                    
                    Text("No entries yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MoriColors.moriCream)
                    
                    Text("Start your gratitude journey today")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.moriCreamMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Entry previews
                ForEach(entries.prefix(3)) { entry in
                    GratitudeEntryPreview(entry: entry) {
                        onEntryTap?(entry)
                    }
                    
                    if entry.id != entries.prefix(3).last?.id {
                        Divider()
                            .background(MoriColors.moriHairline)
                    }
                }
            }
        }
        .padding(20)
        .background(MoriColors.moriDarkSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MoriColors.moriHairline, lineWidth: 1)
        )
    }
}

private struct EntrySourceBadge: View {
    let entry: GratitudeEntry

    var body: some View {
        Label(entry.sourceLabel, systemImage: entry.sourceSymbolName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(foregroundColor)
            .lineLimit(1)
    }

    private var foregroundColor: Color {
        switch entry.sourceKind {
        case .journal: return MoriColors.moriCreamMuted
        case .dailySpark: return MoriColors.moriGold
        case .weeklyIntention: return MoriColors.sageGreen
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        RecentEntriesSection(entries: [
            GratitudeEntry(
                date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!,
                content: "Today I'm grateful for the warm sunshine that greeted me this morning. It reminded me that every day is a new beginning.",
                promptType: .today
            ),
            GratitudeEntry(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                content: "A small joy I noticed: the smell of fresh coffee and the quiet morning moments.",
                promptType: .smallJoy
            ),
            GratitudeEntry(
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                content: "I want to remember this moment: sitting by the window watching the rain.",
                promptType: .moment
            )
        ])
        
        RecentEntriesSection(entries: [])
    }
    .padding()
    .background(Color(hex: "FDF5E6"))
}
