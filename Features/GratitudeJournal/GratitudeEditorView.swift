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
                        .foregroundColor(MoriColors.botanicalMuted.opacity(0.72))
                        .italic()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                }
                
                TextEditor(text: $content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 80)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .focused($isEditorFocused)
            }
            .frame(minHeight: 120)
            
            Divider()
                .background(MoriColors.botanicalLine.opacity(0.58))

            if !attachedPhotos.isEmpty {
                photoStrip

                Divider()
                    .background(MoriColors.botanicalLine.opacity(0.58))
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
                    HStack(spacing: 6) {
                        MoriBitmapIconImage(icon: .journal, size: 14, opacity: 0.82)

                        Text("Add photos")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MoriColors.botanicalInk)
                }
                .accessibility(label: Text("Add photos to log entry"))
                
                Spacer()
                
                // Save button
                Button(action: save) {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isValid ? MoriColors.botanicalSurface : MoriColors.botanicalMuted)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(isValid ? MoriColors.botanicalInk : MoriColors.botanicalInk.opacity(0.08))
                        .cornerRadius(8)
                }
                .disabled(!isValid)
                .accessibility(label: Text("Save log entry"))
            }
            .padding(20)
        }
        .background(MoriColors.botanicalSurface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(MoriColors.botanicalHairline, lineWidth: 1)
        )
        .shadow(color: MoriColors.botanicalShadow.opacity(0.50), radius: 18, x: 0, y: 10)
        .gratitudeEditorLifecycle(
            entryContent: content,
            characterCountStatus: $charCountStatus,
            selectedPhotoItems: $selectedPhotoItems,
            onAddPhoto: onAddPhoto
        )
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

    private var characterCountColor: Color {
        switch charCountStatus {
        case .normal:
            return MoriColors.botanicalMuted
        case .warning:
            return MoriColors.botanicalSeed
        case .error:
            return MoriColors.botanicalClay
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
                    MoriBitmapIconImage(icon: .journal, size: 24, opacity: 0.62)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(MoriColors.botanicalPaperDeep.opacity(0.72))
                }
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: onRemove) {
                MoriBitmapIconImage(icon: .minus, size: 13, opacity: 0.92)
                    .frame(width: 24, height: 24)
                    .background(MoriColors.botanicalInk.opacity(0.74))
                    .clipShape(Circle())
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
    .background(MoriColors.botanicalPaper)
}
