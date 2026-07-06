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
                        .foregroundColor(MoriColors.botanicalMoss)

                    EntrySourceBadge(entry: entry)

                    if !entry.photoAttachments.isEmpty {
                        HStack(spacing: 4) {
                            MoriBitmapIconImage(icon: .journal, size: 11, opacity: 0.62)

                            Text("\(entry.photoAttachments.count)")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(MoriColors.botanicalMuted)
                    }
                }

                Text(entry.displayContent)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
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
                MoriBitmapIconImage(icon: .journal, size: 17, opacity: 0.82)
                
                Text("Recent Log")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)
                
                Spacer()
                
                if entries.count > 3 {
                    Button(action: { onViewAll?() }) {
                        Text("View All →")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MoriColors.botanicalInk)
                    }
                    .accessibility(label: Text("View all log entries"))
                }
            }
            
            Divider()
                .background(MoriColors.botanicalLine.opacity(0.58))
            
            if entries.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    MoriBitmapIconBadge(
                        icon: .journal,
                        size: 42,
                        iconScale: 0.58,
                        fill: MoriColors.sanctuarySurface.opacity(0.76),
                        stroke: Color.white.opacity(0.88),
                        shadow: MoriColors.sanctuaryShadow.opacity(0.16)
                    )
                    
                    Text("No entries yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MoriColors.botanicalInk)
                    
                    Text("Start with one daily log")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
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
                            .background(MoriColors.botanicalLine.opacity(0.58))
                    }
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct EntrySourceBadge: View {
    let entry: GratitudeEntry

    var body: some View {
        HStack(spacing: 5) {
            MoriBitmapIconImage(icon: entry.sourceIcon, size: 12, opacity: 0.78)

            Text(entry.sourceLabel)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(foregroundColor)
        .lineLimit(1)
    }

    private var foregroundColor: Color {
        switch entry.sourceKind {
        case .journal: return MoriColors.botanicalMuted
        case .dayLog: return MoriColors.botanicalClay
        case .dailySpark: return MoriColors.botanicalSeed
        case .weeklyIntention: return MoriColors.botanicalMoss
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
    .background(MoriColors.botanicalPaper)
}
