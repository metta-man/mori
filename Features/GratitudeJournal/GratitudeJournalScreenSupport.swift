//
//  GratitudeJournalScreenSupport.swift
//  Mori
//
//  Support views and bridges for the gratitude journal screen.
//

import SwiftUI
import PhotosUI
import UIKit

struct JournalLifeGridSnapshot: Equatable {
    let summary: String
    let days: [MoriLifeGridPreviewDay]

    static func current(
        now: Date = Date(),
        calendar: Calendar = .current,
        dataManager: HabitDataManager = .shared,
        dailySparks: [DailySparkEntry] = [],
        journalEntries: [GratitudeEntry] = [],
        actions: [MoriMindfulAction] = [],
        sessions: [SettleSession] = []
    ) -> JournalLifeGridSnapshot {
        let today = calendar.startOfDay(for: now)
        let monthInterval = calendar.dateInterval(of: .month, for: today)
        let monthStart = monthInterval?.start ?? today
        let monthEnd = calendar.date(byAdding: .day, value: -1, to: monthInterval?.end ?? today) ?? today
        let recentStart = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        let habitEntries = dataManager.getEntries(from: min(monthStart, recentStart), to: today)
        let recordedDays = Set(
            dailySparks.compactMap { WeekArchiveData.date(fromDateKey: $0.dateKey) } +
                journalEntries.map(\.date) +
                actions.map(\.createdAt) +
                sessions.map(\.startedAt) +
                habitEntries.map(\.date)
        ).map { calendar.startOfDay(for: $0) }
        let recordedDaySet = Set(recordedDays)
        let rememberedDays = recordedDaySet.filter {
            $0 >= monthStart && $0 <= min(today, monthEnd)
        }.count

        let monthFormatter = DateFormatter()
        monthFormatter.locale = MoriLocalePreference.load().locale
        monthFormatter.setLocalizedDateFormatFromTemplate("LLLL")
        let monthName = monthFormatter.string(from: today)
        let rememberedLabel = MoriL10n.display(
            rememberedDays == 1 ? "day remembered" : "days remembered"
        )

        let previewDays = (0..<30).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: recentStart) ?? recentStart
            let entry = habitEntries.first { calendar.isDate($0.date, inSameDayAs: date) }

            return MoriLifeGridPreviewDay(
                id: offset,
                tone: entry?.tone.moriMoodTone,
                isRemembered: recordedDaySet.contains(calendar.startOfDay(for: date))
            )
        }

        return JournalLifeGridSnapshot(
            summary: "\(monthName) · \(rememberedDays) \(rememberedLabel)",
            days: previewDays
        )
    }
}

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
    @Environment(\.moriOpenRoute) private var openRoute

    let onLogPreviousDay: () -> Void
    let onExport: () -> Void
    let onImport: () -> Void
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 8) {
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
                floatingHeaderSymbol("calendar")
            }
            .buttonStyle(.plain)
            .foregroundColor(MoriColors.sanctuaryInk)
            .accessibility(label: Text(MoriL10n.display("Log actions")))

            Button(action: openSettings) {
                floatingHeaderSymbol("gearshape")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MoriL10n.display("Settings"))
        }
        .padding(.trailing, 8)
    }

    private func openHistory() {
        openGratitudeRoute(.history)
    }

    private func openSettings() {
        openRoute(.settings)
    }

    private func floatingHeaderSymbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .regular))
            .foregroundColor(MoriColors.sanctuaryInk)
            .opacity(0.84)
            .frame(width: 44, height: 44)
            .background(MoriColors.sanctuarySurface.opacity(0.82))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            )
            .contentShape(Circle())
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
            HStack(spacing: 6) {
                MoriBitmapIconImage(icon: .chevron, size: 14, opacity: 0.9)
                    .rotationEffect(.degrees(180))

                Text(MoriL10n.display("Back"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.sanctuaryInk)
            }
            .padding(.leading, 13)
            .padding(.trailing, 16)
            .frame(minHeight: 44)
            .background(MoriColors.sanctuarySurface.opacity(0.94))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(MoriColors.botanicalLine.opacity(0.62), lineWidth: 1)
            )
            .clipShape(Capsule(style: .continuous))
            .shadow(color: MoriColors.sanctuaryShadow.opacity(0.10), radius: 10, x: 0, y: 5)
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
    let lifeGridSnapshot: JournalLifeGridSnapshot
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
        VStack(alignment: .leading, spacing: 21) {
            JournalTodayPanel(
                selectedTone: selectedTone ?? todayHabitEntry?.tone,
                note: $dailyEntryNote,
                attachedPhotos: $dailyEntryPhotos,
                selectedPhotoItems: $selectedDailyPhotoItems,
                onSelect: onSelectTone,
                onSave: onSaveDailyEntry,
                onRemovePhoto: onRemoveDailyPhoto
            )

            JournalLifeGridSection(
                dailySparkStore: dailySparkStore,
                selectedTone: selectedTone ?? todayHabitEntry?.tone,
                recentEntries: recentEntries,
                lifeGridSnapshot: lifeGridSnapshot,
                onDailySparkSaved: onDailySparkSaved,
                onOpenPatternLog: onOpenPatternLog,
                onOpenWeekArchive: onOpenWeekArchive,
                onRandomMemory: onRandomMemory,
                onViewHistory: onViewHistory,
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
    let onRemovePhoto: (GratitudePhotoAttachment) -> Void

    private var canSave: Bool {
        selectedTone != nil
    }

    private var canAddPhotos: Bool {
        attachedPhotos.count < 6
    }

    private var photoCountText: String {
        switch attachedPhotos.count {
        case 0:
            return MoriL10n.display("(optional)")
        case 1:
            return MoriL10n.display("(1 photo attached)")
        default:
            return MoriL10n.display("(\(attachedPhotos.count) photos attached)")
        }
    }

    private var toneSelection: Binding<HabitDayTone?> {
        Binding(
            get: { selectedTone },
            set: { tone in
                guard let tone else { return }
                onSelect(tone)
            }
        )
    }

    private var moodOptions: [MoriMoodOption<HabitDayTone>] {
        [
            MoriMoodOption(id: .positive, title: "Good", tone: .good),
            MoriMoodOption(id: .neutral, title: "Neutral", tone: .neutral),
            MoriMoodOption(id: .negative, title: "Difficult", tone: .difficult)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(MoriL10n.display("Mood"))
                    .font(MoriTypography.sanctuarySection)
                    .foregroundColor(MoriColors.sanctuaryInk)

                Text(MoriL10n.display("Notice how today feels."))
                    .font(MoriTypography.callout)
                    .foregroundColor(MoriColors.botanicalMuted)
            }

            MoriMoodSelector(
                options: moodOptions,
                selection: toneSelection,
                optionSpacing: 12,
                optionMinimumHeight: 97
            )

            VStack(alignment: .leading, spacing: 11) {
                Text(MoriL10n.display("One sentence"))
                    .font(MoriTypography.callout.weight(.semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                ZStack(alignment: .topLeading) {
                    if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(MoriL10n.display("One thing worth keeping..."))
                            .font(MoriTypography.body)
                            .foregroundColor(MoriColors.botanicalMuted.opacity(0.76))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $note)
                        .font(MoriTypography.body)
                        .foregroundColor(MoriColors.botanicalInk)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 72)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
                .background(MoriColors.botanicalPaperDeep.opacity(0.58))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MoriColors.botanicalLine.opacity(0.55), lineWidth: 1)
                )
            }
            .padding(.top, 5)

            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: max(1, 6 - attachedPhotos.count),
                matching: .images
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(
                            canAddPhotos
                                ? MoriColors.botanicalMuted
                                : MoriColors.botanicalMuted.opacity(0.42)
                        )
                        .frame(width: 22, height: 22)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(MoriL10n.display(canAddPhotos ? "Add a photo" : "Photo limit reached"))
                            .font(MoriTypography.callout.weight(.semibold))
                            .foregroundColor(canAddPhotos ? MoriColors.botanicalInk : MoriColors.botanicalMuted)

                        Text(photoCountText)
                            .font(MoriTypography.caption)
                            .foregroundColor(MoriColors.botanicalMuted)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(
                            MoriColors.botanicalMuted.opacity(canAddPhotos ? 0.52 : 0.28)
                        )
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 50)
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
            .padding(.top, 4)

            if !attachedPhotos.isEmpty {
                DailyLogPhotoStrip(
                    attachments: attachedPhotos,
                    onRemove: onRemovePhoto
                )
            }

            Button(action: onSave) {
                Text(MoriL10n.display("Save entry"))
                    .font(MoriTypography.callout.weight(.semibold))
                    .foregroundColor(canSave ? MoriColors.botanicalSurface : MoriColors.botanicalMuted)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(
                        canSave
                            ? MoriColors.botanicalInk
                            : MoriTheme.Colors.sage.opacity(0.18)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .accessibilityLabel(MoriL10n.display("Save today's log"))
            .padding(.top, 5)
        }
        .padding(.horizontal, 19)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(
            MoriSanctuaryBoxBackground(
                cornerRadius: 20,
                tone: .paper
            )
        )
        .shadow(
            color: MoriColors.sanctuaryShadow.opacity(0.24),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

private struct JournalLifeGridSection: View {
    @ObservedObject var dailySparkStore: DailySparkStore
    let selectedTone: HabitDayTone?
    let recentEntries: [GratitudeEntry]
    let lifeGridSnapshot: JournalLifeGridSnapshot
    let onDailySparkSaved: (DailySparkEntry) -> Void
    let onOpenPatternLog: () -> Void
    let onOpenWeekArchive: () -> Void
    let onRandomMemory: () -> Void
    let onViewHistory: () -> Void
    let onEntryTap: (GratitudeEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MoriLifeGridPreview(
                summary: lifeGridSnapshot.summary,
                days: lifeGridSnapshot.days,
                columnCount: 10,
                columnSpacing: 19,
                rowSpacing: 10,
                cardPadding: 20,
                cornerRadius: 20,
                shadow: nil,
                contentSpacing: 22,
                contentOffsetY: -3,
                action: onOpenWeekArchive
            )

            VStack(alignment: .leading, spacing: 16) {
                DailySparkCard(store: dailySparkStore, onSaved: onDailySparkSaved)

                JournalLogUtilitiesCard(
                    selectedTone: selectedTone,
                    onOpenPatternLog: onOpenPatternLog,
                    onOpenWeekArchive: onOpenWeekArchive,
                    onRandomMemory: onRandomMemory,
                    onViewHistory: onViewHistory
                )

                RecentEntriesSection(
                    entries: recentEntries,
                    onViewAll: nil,
                    onEntryTap: onEntryTap
                )
            }
            .padding(.top, MoriMainTabBarMetrics.reservedBottomInset)
        }
    }
}

private extension HabitDayTone {
    var moriMoodTone: MoriMoodTone {
        switch self {
        case .positive: return .good
        case .neutral: return .neutral
        case .negative: return .difficult
        }
    }
}

private struct JournalLogUtilitiesCard: View {
    let selectedTone: HabitDayTone?
    let onOpenPatternLog: () -> Void
    let onOpenWeekArchive: () -> Void
    let onRandomMemory: () -> Void
    let onViewHistory: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if selectedTone != nil {
                utilityButton(
                    title: selectedTone == .negative ? "Add trigger detail" : "Pattern details",
                    subtitle: "Notice a trigger, thought, or response.",
                    icon: .refresh,
                    action: onOpenPatternLog
                )

                utilityDivider
            }

            utilityButton(
                title: "Week Archive",
                subtitle: "Return to recorded weeks when you choose.",
                icon: .roots,
                action: onOpenWeekArchive
            )

            utilityDivider

            utilityButton(
                title: "Random memory",
                subtitle: "Revisit one past entry.",
                icon: .journal,
                action: onRandomMemory
            )

            utilityDivider

            utilityButton(
                title: "Log history",
                subtitle: "See all saved entries.",
                icon: .journal,
                action: onViewHistory
            )
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 8)
    }

    private func utilityButton(
        title: String,
        subtitle: String,
        icon: MoriBitmapIcon,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                MoriBitmapIconImage(icon: icon, size: 17, opacity: 0.82)
                    .frame(width: 36, height: 36)
                    .background(MoriColors.botanicalInk.opacity(0.07))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(MoriL10n.display(title))
                        .font(MoriTypography.callout.weight(.semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display(subtitle))
                        .font(MoriTypography.caption)
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                MoriBitmapIconImage(icon: .chevron, size: 12, opacity: 0.48)
                    .frame(width: 24, height: 44)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display(title))
        .accessibilityHint(MoriL10n.display(subtitle))
    }

    private var utilityDivider: some View {
        Divider()
            .overlay(MoriColors.botanicalLine.opacity(0.48))
            .padding(.leading, 58)
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
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .offset(x: 12, y: -12)
            .accessibility(label: Text(MoriL10n.display("Remove photo")))
        }
        .frame(width: 88, height: 88)
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
                    .font(MoriTypography.caption.weight(.semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 82)
            .background(isSelected ? tone.color.opacity(0.12) : MoriColors.sanctuarySurface.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? tone.color.opacity(0.45) : MoriColors.botanicalHairline.opacity(0.78), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.string("habit.tone_day", defaultValue: "%@ day", arguments: [label]))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
