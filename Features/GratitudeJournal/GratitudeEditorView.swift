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
                        .foregroundColor(MoriColors.moriCreamMuted)
                        .italic()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                }
                
                TextEditor(text: $content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.moriCream)
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
                .background(MoriColors.moriHairline)

            if !attachedPhotos.isEmpty {
                photoStrip

                Divider()
                    .background(MoriColors.moriHairline)
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
                        .foregroundColor(MoriColors.moriGold)
                }
                .accessibility(label: Text("Add photos to journal entry"))
                
                Spacer()
                
                // Save button
                Button(action: save) {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.moriDark)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(isValid ? MoriColors.moriGold : MoriColors.moriCreamMuted.opacity(0.45))
                        .cornerRadius(8)
                }
                .disabled(!isValid)
                .accessibility(label: Text("Save gratitude entry"))
            }
            .padding(20)
        }
        .background(MoriColors.moriDarkSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MoriColors.moriHairline, lineWidth: 1)
        )
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
            return MoriColors.moriCreamMuted
        case .warning:
            return MoriColors.moriGold
        case .error:
            return MoriColors.warmClay
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
                        .foregroundColor(MoriColors.moriCreamMuted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(MoriColors.moriDark.opacity(0.4))
                }
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(MoriColors.moriCream, Color.black.opacity(0.62))
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
    .background(Color(hex: "FDF5E6"))
}
