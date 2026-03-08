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
                // Date
                Text(formatDate(entry.date))
                    .font(.custom("Poppins", size: 12))
                    .foregroundColor(Color(hex: "788c5d"))
                
                // Content preview
                Text(entry.content)
                    .font(.custom("Poppins", size: 14))
                    .foregroundColor(Color(hex: "666666"))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(label: Text("\(formatDate(entry.date)) entry: \(entry.content.prefix(50))..."))
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
                Text("📅")
                    .font(.system(size: 18))
                
                Text("Recent Gratitude")
                    .font(.custom("Poppins", size: 14))
                    .foregroundColor(Color(hex: "333333"))
                
                Spacer()
                
                if entries.count > 3 {
                    Button(action: { onViewAll?() }) {
                        Text("View All →")
                            .font(.custom("Poppins", size: 14))
                            .foregroundColor(Color(hex: "788c5d"))
                    }
                    .accessibility(label: Text("View all gratitude entries"))
                }
            }
            
            Divider()
                .background(Color(hex: "E8E8E8"))
            
            if entries.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "CCCCCC"))
                    
                    Text("No entries yet")
                        .font(.custom("Poppins", size: 14))
                        .foregroundColor(Color(hex: "666666"))
                    
                    Text("Start your gratitude journey today")
                        .font(.custom("Poppins", size: 12))
                        .foregroundColor(Color(hex: "888888"))
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
                            .background(Color(hex: "F5F5F5"))
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "E8E8E8"), lineWidth: 1)
        )
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
