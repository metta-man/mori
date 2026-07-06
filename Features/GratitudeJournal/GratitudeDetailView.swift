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
            MoriPaperBackground(variant: .journal) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                    // Date & Time
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatFullDate(entry.date))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.botanicalInk)
                        
                        Text(formatTime(entry.createdAt))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(MoriColors.botanicalMuted)
                    }
                    .padding(.top, 8)
                    
                    HStack(spacing: 8) {
                        MoriBitmapIconImage(icon: entry.sourceIcon, size: 15, opacity: 0.84)

                        Text(sourceDisplayText)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(sourceColor)
                    .padding(12)
                    .background(sourceColor.opacity(0.10))
                    .cornerRadius(8)
                    
                    // Content
                    Text(entry.displayContent)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.botanicalInk)
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
                            .background(MoriColors.botanicalLine.opacity(0.58))
                        
                        HStack {
                            Text("Created:")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(MoriColors.botanicalMuted)
                            
                            Text(formatDateTime(entry.createdAt))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(MoriColors.botanicalInk)
                        }
                        
                        if entry.updatedAt != entry.createdAt {
                            HStack {
                                Text("Updated:")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(MoriColors.botanicalMuted)
                                
                                Text(formatDateTime(entry.updatedAt))
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(MoriColors.botanicalInk)
                            }
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(20)
                .moriSanctuaryCard(cornerRadius: 24, padding: 18)
                .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        MoriBitmapIconImage(icon: .chevron, size: 15, opacity: 0.88)
                            .rotationEffect(.degrees(180))
                    }
                    .accessibilityLabel("Back")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showDeleteConfirmation = true }) {
                            MoriBitmapIconImage(icon: .minus, size: 17, opacity: 0.86)
                                .frame(width: 34, height: 34)
                                .background(MoriColors.botanicalClay.opacity(0.10))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Delete entry")
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
                Text("Are you sure you want to delete this log entry? This action cannot be undone.")
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
        case .journal: return MoriColors.botanicalMuted
        case .dayLog: return MoriColors.botanicalClay
        case .dailySpark: return MoriColors.botanicalSeed
        case .weeklyIntention: return MoriColors.botanicalMoss
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
