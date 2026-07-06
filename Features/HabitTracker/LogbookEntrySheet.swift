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
            MoriPaperBackground(variant: .journal) {
                ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(MoriL10n.display("Log Previous Day"))
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.botanicalInk)

                        Text(MoriL10n.display("Add a missed day, then attach a memory if there is one."))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(MoriColors.botanicalMuted)
                    }

                    DatePicker(
                        MoriL10n.display("Date"),
                        selection: $selectedDate,
                        in: ...maximumDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .tint(MoriColors.botanicalMoss)
                    .foregroundColor(MoriColors.botanicalInk)

                    Picker(MoriL10n.display("Day tone"), selection: $selectedTone) {
                        ForEach(HabitDayTone.allCases) { tone in
                            Text(tone.logbookTitle).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(MoriColors.botanicalMoss)

                    LogbookTextField(
                        title: "Note",
                        placeholder: "A short note about the day.",
                        text: $note,
                        minHeight: 72
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        HabitTrackerBitmapLabel(title: "Pattern Log", icon: .refresh, iconSize: 16, iconOpacity: 0.86)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MoriColors.botanicalMoss)

                        LogbookTextField(title: "Trigger", placeholder: "What set it off?", text: $trigger)
                        LogbookTextField(title: "Thought", placeholder: "What did your mind say?", text: $thought)
                        LogbookTextField(title: "Feeling", placeholder: "Name the feeling or body signal.", text: $feeling)
                        LogbookTextField(title: "Next response", placeholder: "If this shows up again, I will...", text: $responsePlan)
                    }

                    LogbookTextField(
                        title: "Daily memory",
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
                        HabitTrackerBitmapLabel(title: "Add photos", icon: .journal, iconSize: 15, iconOpacity: 0.84)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MoriColors.botanicalInk)
                    }
                    .accessibility(label: Text(MoriL10n.display("Add photos to logbook entry")))

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MoriColors.botanicalClay)
                    }

                    Button(action: save) {
                        HabitTrackerBitmapLabel(title: "Save to logbook", icon: .leaf, iconSize: 16, iconOpacity: 0.94)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MoriColors.botanicalSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(MoriColors.botanicalInk)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(MoriL10n.display("Done"), action: save)
                        .foregroundColor(MoriColors.botanicalInk)
                }
            }
        }
        .moriKeyboardDoneToolbar()
        .presentationDetents([.large])
        .moriPhotoPickerImporter(selectedItems: $selectedPhotoItems, onImport: attachPhoto)
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

    private func attachPhoto(from data: Data) {
        if let attachment = try? GratitudePhotoStore.savePhotoData(data) {
            attachedPhotos.append(attachment)
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
            Text(MoriL10n.display(title))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(MoriL10n.display(placeholder))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted.opacity(0.86))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }

                TextEditor(text: $text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: minHeight)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(MoriColors.sanctuarySurface.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoriColors.botanicalLine.opacity(0.82), lineWidth: 1)
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
                    MoriBitmapIconImage(icon: .journal, size: 28, opacity: 0.54)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(MoriColors.botanicalPaperDeep.opacity(0.72))
                }
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button(action: onRemove) {
                MoriBitmapIconImage(icon: .minus, size: 13, opacity: 0.92)
                    .frame(width: 24, height: 24)
                    .background(MoriColors.botanicalSurface.opacity(0.92))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(MoriColors.botanicalInk.opacity(0.18), lineWidth: 1)
                    )
            }
            .offset(x: 6, y: -6)
            .accessibility(label: Text(MoriL10n.display("Remove photo")))
        }
        .frame(width: 82, height: 82)
    }
}

private extension HabitDayTone {
    var logbookTitle: String {
        switch self {
        case .positive: return MoriL10n.display("Good")
        case .neutral: return MoriL10n.display("Neutral")
        case .negative: return MoriL10n.display("Difficult")
        }
    }
}

private extension String {
    var trimmedOptional: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
