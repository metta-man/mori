//
//  GratitudeEditorView.swift
//  Mori
//
//  Text input editor for gratitude entries with validation
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - Gratitude Editor View
struct GratitudeEditorView: View {
    @Binding var content: String
    let selectedPrompt: GratitudePrompt?
    let attachedPhotos: [GratitudePhotoAttachment]
    var onAddPhoto: (Data) -> Void
    var onRemovePhoto: (GratitudePhotoAttachment) -> Void
    var onSave: () -> Void
    
    @State private var charCountStatus: CharacterCountStatus = .normal
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @FocusState private var isEditorFocused: Bool
    
    private var isValid: Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 10 && trimmed.count <= GratitudeEntry.maxContentCharacterCount
    }
    
    private var placeholder: String {
        selectedPrompt?.displayText ?? "What are you grateful for today?"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text Editor
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted.opacity(0.72))
                        .italic()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                }
                
                TextEditor(text: $content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.forestCanopy)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 80)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .focused($isEditorFocused)
                    .onChange(of: content) { newValue in
                        charCountStatus = CharacterCountStatus.status(for: newValue.count)
                    }
            }
            .frame(minHeight: 120)
            
            Divider()
                .background(MoriColors.forestLine.opacity(0.58))

            if !attachedPhotos.isEmpty {
                photoStrip

                Divider()
                    .background(MoriColors.forestLine.opacity(0.58))
            }
            
            // Footer
            HStack {
                // Character count
                Text("\(content.count)/\(GratitudeEntry.maxContentCharacterCount.formatted())")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(characterCountColor)

                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 6,
                    matching: .images
                ) {
                    Label("Add photos", systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MoriColors.forestCanopy)
                }
                .accessibility(label: Text("Add photos to journal entry"))
                
                Spacer()
                
                // Save button
                Button(action: save) {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isValid ? MoriColors.forestCard : MoriColors.forestMuted)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(isValid ? MoriColors.forestCanopy : MoriColors.forestCanopy.opacity(0.08))
                        .cornerRadius(8)
                }
                .disabled(!isValid)
                .accessibility(label: Text("Save gratitude entry"))
            }
            .padding(20)
        }
        .background(MoriColors.forestCard.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(MoriColors.forestHairline, lineWidth: 1)
        )
        .shadow(color: MoriColors.forestShadow.opacity(0.50), radius: 18, x: 0, y: 10)
        .onChange(of: selectedPhotoItems) { newItems in
            importPhotos(from: newItems)
        }
        .accessibilityElement(children: .combine)
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(attachedPhotos) { attachment in
                    JournalPhotoThumbnail(
                        attachment: attachment,
                        onRemove: {
                            onRemovePhoto(attachment)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func save() {
        isEditorFocused = false
        onSave()
    }

    private func importPhotos(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        onAddPhoto(data)
                    }
                }
            }

            await MainActor.run {
                selectedPhotoItems = []
            }
        }
    }

    private var characterCountColor: Color {
        switch charCountStatus {
        case .normal:
            return MoriColors.forestMuted
        case .warning:
            return MoriColors.forestSeed
        case .error:
            return MoriColors.forestClay
        }
    }
}

private struct JournalPhotoThumbnail: View {
    let attachment: GratitudePhotoAttachment
    var onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = UIImage(contentsOfFile: attachment.fileURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundColor(MoriColors.forestMuted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(MoriColors.forestPaperDeep.opacity(0.72))
                }
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(MoriColors.forestCard, MoriColors.forestCanopy.opacity(0.72))
            }
            .offset(x: 6, y: -6)
            .accessibility(label: Text("Remove photo"))
        }
        .frame(width: 82, height: 82)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        GratitudeEditorView(
            content: .constant(""),
            selectedPrompt: .today,
            attachedPhotos: [],
            onAddPhoto: { _ in },
            onRemovePhoto: { _ in },
            onSave: {}
        )
        
        GratitudeEditorView(
            content: .constant("Today I'm grateful for the warm sunshine that greeted me this morning."),
            selectedPrompt: .today,
            attachedPhotos: [],
            onAddPhoto: { _ in },
            onRemovePhoto: { _ in },
            onSave: {}
        )
    }
    .padding()
    .background(MoriColors.forestPaper)
}
