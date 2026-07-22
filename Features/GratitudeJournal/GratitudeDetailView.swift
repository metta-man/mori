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
                        entryHeader
                        entryContent

                        if !entry.photoAttachments.isEmpty {
                            photoGrid
                        }

                        entryMetadata
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 22)
                    .padding(.bottom, 36)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MoriL10n.display("Done")) {
                        dismiss()
                    }
                    .foregroundColor(MoriColors.botanicalInk)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel(MoriL10n.display("Delete entry"))
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
        .presentationDragIndicator(.visible)
    }

    private var entryHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(formatFullDate(entry.date))
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundColor(MoriColors.botanicalInk)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                MoriBitmapIconImage(icon: entry.sourceIcon, size: 14, opacity: 0.84)

                Text(sourceDisplayText)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Text("·")
                    .foregroundColor(MoriColors.botanicalMuted.opacity(0.72))
                    .accessibilityHidden(true)

                Text(formatTime(entry.createdAt))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundColor(sourceColor)
        }
    }

    private var entryContent: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("“")
                .font(.system(size: 34, weight: .regular, design: .serif))
                .foregroundColor(sourceColor.opacity(0.78))
                .offset(y: -5)
                .accessibilityHidden(true)

            Text(entry.displayContent)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(MoriColors.botanicalInk)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(18)
        .background(MoriColors.sanctuarySurface.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MoriColors.botanicalLine.opacity(0.48), lineWidth: 1)
        }
    }

    private var photoGrid: some View {
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
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var entryMetadata: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .overlay(MoriColors.botanicalLine.opacity(0.58))

            metadataRow(title: "Created", value: formatDateTime(entry.createdAt))

            if entry.updatedAt != entry.createdAt {
                metadataRow(title: "Updated", value: formatDateTime(entry.updatedAt))
            }
        }
        .padding(.top, 4)
    }

    private func metadataRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(MoriL10n.display(title))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriColors.botanicalMuted)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .multilineTextAlignment(.trailing)
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
