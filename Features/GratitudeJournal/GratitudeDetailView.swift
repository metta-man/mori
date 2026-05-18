//
//  GratitudeDetailView.swift
//  Mori
//
//  Full entry view for gratitude journal
//

import SwiftUI
import UIKit

// MARK: - Gratitude Detail View
struct GratitudeDetailView: View {
    let entry: GratitudeEntry
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Date & Time
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatFullDate(entry.date))
                            .font(.custom("Poppins", size: 18))
                            .foregroundColor(Color(hex: "333333"))
                        
                        Text(formatTime(entry.createdAt))
                            .font(.custom("Poppins", size: 14))
                            .foregroundColor(Color(hex: "888888"))
                    }
                    .padding(.top, 8)
                    
                    HStack(spacing: 8) {
                        Image(systemName: entry.sourceSymbolName)
                            .font(.system(size: 14, weight: .semibold))

                        Text(sourceDisplayText)
                            .font(.custom("Poppins", size: 14))
                    }
                    .foregroundColor(sourceColor)
                    .padding(12)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(8)
                    
                    // Content
                    Text(entry.displayContent)
                        .font(.custom("Poppins", size: 15))
                        .foregroundColor(Color(hex: "333333"))
                        .lineSpacing(1.6)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !entry.photoAttachments.isEmpty {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ],
                            spacing: 10
                        ) {
                            ForEach(entry.photoAttachments) { attachment in
                                if let image = UIImage(contentsOfFile: attachment.fileURL.path) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .background(Color(hex: "E8E8E8"))
                        
                        HStack {
                            Text("Created:")
                                .font(.custom("Poppins", size: 12))
                                .foregroundColor(Color(hex: "888888"))
                            
                            Text(formatDateTime(entry.createdAt))
                                .font(.custom("Poppins", size: 12))
                                .foregroundColor(Color(hex: "666666"))
                        }
                        
                        if entry.updatedAt != entry.createdAt {
                            HStack {
                                Text("Updated:")
                                    .font(.custom("Poppins", size: 12))
                                    .foregroundColor(Color(hex: "888888"))
                                
                                Text(formatDateTime(entry.updatedAt))
                                    .font(.custom("Poppins", size: 12))
                                    .foregroundColor(Color(hex: "666666"))
                            }
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(24)
            }
            .background(Color(hex: "FDF5E6"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(hex: "333333"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(Color(hex: "DC3545"))
                        }
                    }
                }
            }
            .alert("Delete Entry", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // Delete action will be handled by parent
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this gratitude entry? This action cannot be undone.")
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var sourceDisplayText: String {
        if entry.sourceKind == .journal, let prompt = entry.promptType {
            return prompt.displayText
        }

        return entry.sourceLabel
    }

    private var sourceColor: Color {
        switch entry.sourceKind {
        case .journal: return Color(hex: "666666")
        case .dailySpark: return Color(hex: "B8942D")
        case .weeklyIntention: return Color(hex: "788c5d")
        }
    }
}

// MARK: - Preview
#Preview {
    GratitudeDetailView(
        entry: GratitudeEntry(
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            content: "Today I'm grateful for the warm sunshine that greeted me this morning. It reminded me that every day is a new beginning. I felt peaceful drinking my coffee by the window.",
            promptType: .today
        )
    )
}
