import SwiftUI
import PhotosUI
import UIKit

struct LogbookEntrySheet: View {
    let onSave: (
        Date,
        HabitDayTone,
        String?,
        String?,
        String?,
        String?,
        String?,
        String?,
        [GratitudePhotoAttachment]
    ) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    @State private var selectedTone: HabitDayTone = .positive
    @State private var note = ""
    @State private var trigger = ""
    @State private var thought = ""
    @State private var feeling = ""
    @State private var responsePlan = ""
    @State private var journalText = ""
    @State private var attachedPhotos: [GratitudePhotoAttachment] = []
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var validationMessage: String?
    @State private var didSave = false

    private var maximumDate: Date {
        Date()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Log Previous Day")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.moriCream)

                        Text("Add a missed day, then attach a memory if there is one.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(MoriColors.moriCreamMuted)
                    }

                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: ...maximumDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .tint(MoriColors.moriGold)
                    .foregroundColor(MoriColors.moriCream)

                    Picker("Day tone", selection: $selectedTone) {
                        ForEach(HabitDayTone.allCases) { tone in
                            Text(tone.logbookTitle).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(MoriColors.moriGold)

                    LogbookTextField(
                        title: "Note",
                        placeholder: "A short note about the day.",
                        text: $note,
                        minHeight: 72
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        Label("Pattern Log", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MoriColors.moriGold)

                        LogbookTextField(title: "Trigger", placeholder: "What set it off?", text: $trigger)
                        LogbookTextField(title: "Thought", placeholder: "What did your mind say?", text: $thought)
                        LogbookTextField(title: "Feeling", placeholder: "Name the feeling or body signal.", text: $feeling)
                        LogbookTextField(title: "Next response", placeholder: "If this shows up again, I will...", text: $responsePlan)
                    }

                    LogbookTextField(
                        title: "Journal",
                        placeholder: "Optional memory from that day.",
                        text: $journalText,
                        minHeight: 110
                    )

                    if !attachedPhotos.isEmpty {
                        photoStrip
                    }

                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: 6,
                        matching: .images
                    ) {
                        Label("Add photos", systemImage: "photo.on.rectangle.angled")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MoriColors.moriGold)
                    }
                    .accessibility(label: Text("Add photos to logbook entry"))

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MoriColors.warmClay)
                    }

                    Button(action: save) {
                        Label("Save to logbook", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MoriColors.moriDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(MoriColors.moriGold)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(24)
            }
            .background(MoriColors.moriDark.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(MoriColors.moriDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: save)
                        .foregroundColor(MoriColors.moriGold)
                }
            }
        }
        .presentationDetents([.large])
        .onChange(of: selectedPhotoItems) { newItems in
            importPhotos(from: newItems)
        }
        .onDisappear {
            if !didSave {
                attachedPhotos.forEach(GratitudePhotoStore.deletePhoto)
            }
        }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(attachedPhotos) { attachment in
                    LogbookPhotoThumbnail(attachment: attachment) {
                        removePhoto(attachment)
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedJournal = journalText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedJournal.isEmpty {
            let validation = GratitudeEntry.validate(trimmedJournal)
            guard validation.isValid else {
                validationMessage = validation.errorMessage
                return
            }
        }

        onSave(
            selectedDate,
            selectedTone,
            note.trimmedOptional,
            trigger.trimmedOptional,
            thought.trimmedOptional,
            feeling.trimmedOptional,
            responsePlan.trimmedOptional,
            trimmedJournal.isEmpty ? nil : trimmedJournal,
            attachedPhotos
        )
        didSave = true
        dismiss()
    }

    private func importPhotos(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let attachment = try? GratitudePhotoStore.savePhotoData(data) {
                    await MainActor.run {
                        attachedPhotos.append(attachment)
                    }
                }
            }

            await MainActor.run {
                selectedPhotoItems = []
            }
        }
    }

    private func removePhoto(_ attachment: GratitudePhotoAttachment) {
        attachedPhotos.removeAll { $0.id == attachment.id }
        GratitudePhotoStore.deletePhoto(attachment)
    }
}

private struct LogbookTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 68

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.moriCreamMuted)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.moriCreamMuted.opacity(0.76))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }

                TextEditor(text: $text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.moriCream)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: minHeight)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(MoriColors.moriDarkSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoriColors.moriHairline, lineWidth: 1)
            )
        }
    }
}

private struct LogbookPhotoThumbnail: View {
    let attachment: GratitudePhotoAttachment
    let onRemove: () -> Void

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
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

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

private extension HabitDayTone {
    var logbookTitle: String {
        switch self {
        case .positive: return "Good"
        case .neutral: return "Neutral"
        case .negative: return "Difficult"
        }
    }
}

private extension String {
    var trimmedOptional: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
