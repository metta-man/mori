//
//  GratitudeJournalScreenSupport.swift
//  Mori
//
//  Support views and bridges for the gratitude journal screen.
//

import SwiftUI
import PhotosUI
import UIKit

enum GratitudeJournalRoute: Hashable {
    case history
    case weekArchiveDetail
}

struct GratitudeJournalRouteAction {
    private let handler: ((GratitudeJournalRoute) -> Void)?

    init(_ handler: ((GratitudeJournalRoute) -> Void)? = nil) {
        self.handler = handler
    }

    @discardableResult
    func callAsFunction(_ route: GratitudeJournalRoute) -> Bool {
        guard let handler else { return false }
        handler(route)
        return true
    }
}

private struct GratitudeJournalRouteActionKey: EnvironmentKey {
    static let defaultValue = GratitudeJournalRouteAction()
}

extension EnvironmentValues {
    var moriOpenGratitudeJournalRoute: GratitudeJournalRouteAction {
        get { self[GratitudeJournalRouteActionKey.self] }
        set { self[GratitudeJournalRouteActionKey.self] = newValue }
    }
}

struct GratitudeJournalHeaderActions: View {
    @Environment(\.moriOpenGratitudeJournalRoute) private var openGratitudeRoute

    let onLogPreviousDay: () -> Void
    let onExport: () -> Void
    let onImport: () -> Void
    let onRestore: () -> Void

    var body: some View {
        Menu {
            Button(action: onLogPreviousDay) {
                menuActionLabel(title: "Log a previous day", icon: .plus)
            }

            Button(action: openHistory) {
                menuActionLabel(title: "Log history", icon: .journal)
            }

            Divider()

            Button(action: onExport) {
                menuActionLabel(title: "Export Log", icon: .journal)
            }

            Button(action: onImport) {
                menuActionLabel(title: "Import Backup", icon: .plus)
            }

            Button(action: onRestore) {
                menuActionLabel(title: "Restore iCloud Backup", icon: .refresh)
            }
        } label: {
            MoriBitmapIconImage(icon: .journal, size: 21, opacity: 0.95)
                .frame(width: 44, height: 44)
                .background(MoriColors.sanctuarySurface.opacity(0.74))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundColor(MoriColors.sanctuaryInk)
        .accessibility(label: Text("Log actions"))
    }

    private func openHistory() {
        openGratitudeRoute(.history)
    }

    private func menuActionLabel(title: String, icon: MoriBitmapIcon) -> some View {
        HStack(spacing: 8) {
            MoriBitmapIconImage(icon: icon, size: 16, opacity: 0.86)

            Text(MoriL10n.display(title))
        }
    }
}

struct GratitudeJournalDismissButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MoriBitmapIconImage(icon: .chevron, size: 15, opacity: 0.88)
                .rotationEffect(.degrees(180))
                .frame(width: 40, height: 40)
                .background(MoriColors.sanctuarySurface.opacity(0.84))
                .overlay(
                    Circle()
                        .stroke(MoriColors.botanicalLine.opacity(0.55), lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

struct GratitudeJournalHomeContent: View {
    @ObservedObject var dailySparkStore: DailySparkStore
    let selectedTone: HabitDayTone?
    let todayHabitEntry: HabitEntry?
    @Binding var dailyEntryNote: String
    @Binding var dailyEntryPhotos: [GratitudePhotoAttachment]
    @Binding var selectedDailyPhotoItems: [PhotosPickerItem]
    let recentEntries: [GratitudeEntry]
    let onDailySparkSaved: (DailySparkEntry) -> Void
    let onSelectTone: (HabitDayTone) -> Void
    let onSaveDailyEntry: () -> Void
    let onOpenPatternLog: () -> Void
    let onOpenWeekArchive: () -> Void
    let onRemoveDailyPhoto: (GratitudePhotoAttachment) -> Void
    let onRandomMemory: () -> Void
    let onViewHistory: () -> Void
    let onEntryTap: (GratitudeEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JournalTopRowsCard(
                onOpenWeekArchive: onOpenWeekArchive
            )

            JournalTodayPanel(
                selectedTone: selectedTone ?? todayHabitEntry?.tone,
                note: $dailyEntryNote,
                attachedPhotos: $dailyEntryPhotos,
                selectedPhotoItems: $selectedDailyPhotoItems,
                onSelect: onSelectTone,
                onSave: onSaveDailyEntry,
                onOpenPatternLog: onOpenPatternLog,
                onRemovePhoto: onRemoveDailyPhoto
            )

            DailySparkCard(store: dailySparkStore, onSaved: onDailySparkSaved)

            RecentEntriesSection(
                entries: recentEntries,
                onViewAll: onViewHistory,
                onEntryTap: onEntryTap
            )
        }
    }
}

struct JournalTodayPanel: View {
    let selectedTone: HabitDayTone?
    @Binding var note: String
    @Binding var attachedPhotos: [GratitudePhotoAttachment]
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    let onSelect: (HabitDayTone) -> Void
    let onSave: () -> Void
    let onOpenPatternLog: () -> Void
    let onRemovePhoto: (GratitudePhotoAttachment) -> Void

    private var canSave: Bool {
        selectedTone != nil
    }

    private var canAddPhotos: Bool {
        attachedPhotos.count < 6
    }

    private var selectedToneTitle: String {
        selectedTone?.title ?? MoriL10n.display("Not logged")
    }

    private var photoCountText: String {
        switch attachedPhotos.count {
        case 0:
            return MoriL10n.display("No photos attached")
        case 1:
            return MoriL10n.display("1 photo attached")
        default:
            return MoriL10n.display("\(attachedPhotos.count) photos attached")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(MoriL10n.display("Today"))
                        .font(MoriTypography.sanctuarySection)
                        .foregroundColor(MoriColors.sanctuaryInk)

                    Text(MoriL10n.display("Choose a tone. Add a line or photo if it helps."))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                }

                Spacer(minLength: 10)

                Text(selectedToneTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(selectedTone?.color ?? MoriColors.botanicalMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background((selectedTone?.color ?? MoriColors.botanicalLine).opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                JournalToneButton(
                    tone: .positive,
                    icon: .plus,
                    label: "Good",
                    isSelected: selectedTone == .positive,
                    action: { onSelect(.positive) }
                )

                JournalToneButton(
                    tone: .neutral,
                    icon: .leaf,
                    productSymbol: .neutralDay,
                    label: "Neutral",
                    isSelected: selectedTone == .neutral,
                    action: { onSelect(.neutral) }
                )

                JournalToneButton(
                    tone: .negative,
                    icon: .minus,
                    label: "Difficult",
                    isSelected: selectedTone == .negative,
                    action: { onSelect(.negative) }
                )
            }

            ZStack(alignment: .topLeading) {
                if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(MoriL10n.display("One thing I want to remember about today..."))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted.opacity(0.72))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }

                TextEditor(text: $note)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 76)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(MoriColors.botanicalPaperDeep.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoriColors.botanicalLine.opacity(0.55), lineWidth: 1)
            )

            if !attachedPhotos.isEmpty {
                DailyLogPhotoStrip(
                    attachments: attachedPhotos,
                    onRemove: onRemovePhoto
                )
            }

            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: max(1, 6 - attachedPhotos.count),
                matching: .images
            ) {
                HStack(spacing: 10) {
                    MoriBitmapIconImage(icon: .journal, size: 16, opacity: canAddPhotos ? 0.88 : 0.38)
                        .frame(width: 34, height: 34)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(MoriL10n.display(canAddPhotos ? "Add photos" : "Photo limit reached"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(canAddPhotos ? MoriColors.botanicalInk : MoriColors.botanicalMuted)

                        Text(photoCountText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MoriColors.botanicalMuted)
                    }

                    Spacer(minLength: 0)

                    MoriBitmapIconImage(icon: .plus, size: 14, opacity: canAddPhotos ? 0.74 : 0.32)
                }
                .padding(12)
                .background(MoriColors.botanicalPaperDeep.opacity(0.44))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MoriColors.botanicalLine.opacity(0.50), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAddPhotos)
            .accessibilityLabel(MoriL10n.display("Add photos to daily log"))

            HStack(spacing: 10) {
                Button(action: onSave) {
                    HStack(spacing: 8) {
                        MoriBitmapIconImage(icon: .leaf, size: 17, opacity: canSave ? 0.96 : 0.42)
                            .frame(width: 24, height: 24)
                            .background(canSave ? MoriColors.sanctuarySurface.opacity(0.86) : Color.clear)
                            .clipShape(Circle())

                        Text(MoriL10n.display("Save daily entry"))
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(canSave ? MoriColors.botanicalSurface : MoriColors.botanicalMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(canSave ? MoriColors.botanicalInk : MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)

                Button(action: onOpenPatternLog) {
                    MoriBitmapIconImage(icon: .refresh, size: 18, opacity: canSave ? 0.90 : 0.38)
                        .frame(width: 44, height: 44)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .accessibilityLabel(selectedTone == .negative ? "Add trigger detail" : "Open pattern log")
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct JournalTopRowsCard: View {
    let onOpenWeekArchive: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            JournalTopRow(
                title: "Daily Log",
                subtitle: "One place for tone, note, and photo memory.",
                icon: .journal,
                productSymbol: .dailyLog
            )

            Button(action: onOpenWeekArchive) {
                JournalTopRow(
                    title: "Week Archive",
                    subtitle: "Weeks, logs, quiet minutes.",
                    icon: .roots,
                    productSymbol: .weekArchive,
                    detail: "Weeks",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.display("Open Week Archive"))
        }
        .moriSanctuaryCard(cornerRadius: 18, padding: 8)
    }
}

private struct JournalTopRow: View {
    let title: String
    let subtitle: String
    let icon: MoriBitmapIcon
    var productSymbol: MoriProductSymbol? = nil
    var detail: String?
    var showsChevron: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            leadingGraphic

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(MoriL10n.display(subtitle))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if let detail {
                Text(MoriL10n.display(detail))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(MoriColors.sanctuaryInk.opacity(0.07))
                    .clipShape(Capsule())
            }

            if showsChevron {
                MoriBitmapIconImage(icon: .chevron, size: 12, opacity: 0.52)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(MoriColors.botanicalPaperDeep.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    @ViewBuilder
    private var leadingGraphic: some View {
        if let productSymbol {
            MoriProductSymbolBadge(
                symbol: productSymbol,
                size: 34,
                symbolScale: 0.66,
                tint: productSymbol == .weekArchive ? MoriColors.botanicalMoss : MoriColors.botanicalInk,
                fill: MoriColors.sanctuarySurface.opacity(0.78),
                stroke: Color.white.opacity(0.88),
                shadow: MoriColors.sanctuaryShadow.opacity(0.16)
            )
        } else {
            MoriBitmapIconBadge(
                icon: icon,
                size: 34,
                iconScale: 0.58,
                fill: MoriColors.sanctuarySurface.opacity(0.78),
                stroke: Color.white.opacity(0.88),
                shadow: MoriColors.sanctuaryShadow.opacity(0.16)
            )
        }
    }
}

private struct DailyLogPhotoStrip: View {
    let attachments: [GratitudePhotoAttachment]
    let onRemove: (GratitudePhotoAttachment) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(attachments) { attachment in
                    DailyLogPhotoThumbnail(attachment: attachment) {
                        onRemove(attachment)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct DailyLogPhotoThumbnail: View {
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

struct JournalWeekArchiveCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MoriFeatureBox(
                title: "Week Archive",
                subtitle: "Review recorded weeks, daily logs, quiet minutes, and reset history.",
                icon: .roots,
                detail: "Weeks",
                tone: .sage,
                iconSize: 52,
                minHeight: 92
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display("Open Week Archive"))
    }
}

struct JournalDailyEntryCard: View {
    let selectedTone: HabitDayTone?
    @Binding var note: String
    let onSelect: (HabitDayTone) -> Void
    let onSave: () -> Void
    let onOpenPatternLog: () -> Void

    private var canSave: Bool {
        selectedTone != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Daily Log",
                subtitle: "Choose a tone, then keep one small memory for the weeks archive."
            )

            HStack(spacing: 10) {
                JournalToneButton(
                    tone: .positive,
                    icon: .plus,
                    label: "Good",
                    isSelected: selectedTone == .positive,
                    action: { onSelect(.positive) }
                )

                JournalToneButton(
                    tone: .neutral,
                    icon: .leaf,
                    productSymbol: .neutralDay,
                    label: "Neutral",
                    isSelected: selectedTone == .neutral,
                    action: { onSelect(.neutral) }
                )

                JournalToneButton(
                    tone: .negative,
                    icon: .minus,
                    label: "Difficult",
                    isSelected: selectedTone == .negative,
                    action: { onSelect(.negative) }
                )
            }

            ZStack(alignment: .topLeading) {
                if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(MoriL10n.display("One thing I want to remember about today..."))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted.opacity(0.72))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }

                TextEditor(text: $note)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.botanicalInk)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 96)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .background(MoriColors.botanicalPaperDeep.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MoriColors.botanicalLine.opacity(0.55), lineWidth: 1)
            )

            HStack(spacing: 10) {
                Button(action: onSave) {
                    HStack(spacing: 8) {
                        MoriBitmapIconImage(icon: .leaf, size: 17, opacity: canSave ? 0.96 : 0.42)
                            .frame(width: 24, height: 24)
                            .background(canSave ? MoriColors.sanctuarySurface.opacity(0.86) : Color.clear)
                            .clipShape(Circle())

                        Text(MoriL10n.display("Save daily entry"))
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(canSave ? MoriColors.botanicalSurface : MoriColors.botanicalMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSave ? MoriColors.botanicalInk : MoriColors.botanicalInk.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)

                Button(action: onOpenPatternLog) {
                    MoriBitmapIconImage(icon: .refresh, size: 18, opacity: canSave ? 0.90 : 0.38)
                        .frame(width: 46, height: 46)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .accessibilityLabel(selectedTone == .negative ? "Add trigger detail" : "Open pattern log")
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

struct GratitudeJournalToastView: View {
    let message: String
    let type: ToastType

    var body: some View {
        HStack {
            MoriBitmapIconImage(icon: type == .success ? .leaf : .lockShield, size: 16, opacity: 0.92)

            Text(message)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(MoriColors.botanicalSurface)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(type == .success ? MoriColors.botanicalMoss : MoriColors.botanicalClay)
        .cornerRadius(8)
        .shadow(color: MoriColors.botanicalShadow.opacity(0.35), radius: 8, x: 0, y: 4)
        .padding(.bottom, 32)
    }
}

enum ToastType {
    case success
    case error
}

struct JournalExportPackage: Identifiable {
    let id = UUID()
    let url: URL
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct JournalToneButton: View {
    let tone: HabitDayTone
    let icon: MoriBitmapIcon
    var productSymbol: MoriProductSymbol? = nil
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                toneGraphic
                    .frame(width: 44, height: 44)
                    .background(isSelected ? MoriColors.sanctuarySurface.opacity(0.90) : MoriColors.botanicalSurface)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(tone.color.opacity(isSelected ? 0.32 : 0.45), lineWidth: 1.4)
                    )

                Text(MoriL10n.display(label))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 82)
            .background(isSelected ? tone.color.opacity(0.12) : MoriColors.sanctuarySurface.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? tone.color.opacity(0.45) : MoriColors.botanicalHairline.opacity(0.78), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.string("habit.tone_day", defaultValue: "%@ day", arguments: [label]))
    }

    @ViewBuilder
    private var toneGraphic: some View {
        if let productSymbol {
            MoriProductSymbolView(
                symbol: productSymbol,
                size: 24,
                tint: productSymbol == .neutralDay ? MoriColors.botanicalMoss : tone.color,
                opacity: isSelected ? 0.98 : 0.84
            )
        } else {
            MoriBitmapIconImage(icon: icon, size: 22, opacity: isSelected ? 0.98 : 0.84)
        }
    }
}
