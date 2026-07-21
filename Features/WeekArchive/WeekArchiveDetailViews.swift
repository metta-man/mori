import SwiftUI
import UIKit

private enum WeekArchiveWeekDetailSheetDestination: Identifiable {
    case reflection

    var id: String {
        switch self {
        case .reflection:
            return "reflection"
        }
    }
}

struct WeekArchiveWeekDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let summary: WeekArchiveWeekSummary
    let settings: UserSettings

    @State private var activeSheet: WeekArchiveWeekDetailSheetDestination?

    private var title: String {
        "Week \(summary.coordinate.week + 1), Archive year \(summary.coordinate.year + 1)"
    }

    private var dateRangeText: String {
        "\(summary.startDate.formatted(date: .abbreviated, time: .omitted)) - \(summary.endDate.formatted(date: .abbreviated, time: .omitted))"
    }

    init(summary: WeekArchiveWeekSummary, settings: UserSettings) {
        self.summary = summary
        self.settings = settings
    }

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .roots) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        WeekArchiveDetailHeader(title: title, subtitle: dateRangeText, icon: .journal)

                        WeekArchiveMetricsRow(
                            quietActions: summary.quietActionCount,
                            journalCount: summary.journalEntries.count,
                            quietMinutes: summary.quietMinutes
                        )

                        WeekArchiveSectionCard(title: "Week Notes", icon: .journal) {
                            if summary.weeklyIntentions.isEmpty {
                                Text("No week note was recorded for this week.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(MoriColors.botanicalMuted)
                            } else {
                                ForEach(summary.weeklyIntentions) { intention in
                                    WeekArchiveIntentionRow(intention: intention)
                                }
                            }
                        }

                        if !summary.dailySparks.isEmpty {
                            WeekArchiveSectionCard(title: "Daily Spark", icon: .pulse) {
                                ForEach(summary.dailySparks) { spark in
                                    WeekArchiveDailySparkBlock(spark: spark)
                                }
                            }
                        }

                        if !summary.journalEntries.isEmpty {
                            WeekArchiveSectionCard(title: "Log", icon: .journal) {
                                ForEach(summary.journalEntries.prefix(5)) { entry in
                                    WeekArchiveJournalRow(entry: entry)
                                }
                            }
                        }

                        if !summary.actions.isEmpty {
                            WeekArchiveSectionCard(title: "Daily Records", icon: .quiet) {
                                ForEach(summary.actions.prefix(8)) { action in
                                    WeekArchiveActionRow(action: action)
                                }
                            }
                        }

                        if !summary.sessions.isEmpty {
                            WeekArchiveSectionCard(title: "Quiet Sessions", icon: .quiet) {
                                ForEach(summary.sessions.prefix(8)) { session in
                                    WeekArchiveSessionRow(session: session)
                                }
                            }
                        }

                        MoriSanctuaryPrimaryButton(
                            title: "Review this week",
                            icon: .journal,
                            isEnabled: true,
                            action: openReflection
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 44)
                }
            }
            .navigationTitle("Weeks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MoriColors.botanicalInk)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .reflection:
                    WeekArchiveReflectionSheet(
                        week: summary.coordinate,
                        settings: settings,
                        habitEntries: summary.habitEntries,
                        journalEntries: summary.journalEntries
                    )
                }
            }
        }
    }

    private func openReflection() {
        activeSheet = .reflection
    }
}

struct WeekArchiveDayDetailSheet: View {
    let summary: WeekArchiveDaySummary

    @State private var isShowingFullEntry = false

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(
            identifier: MoriLocalePreference.load().resolvedLocaleIdentifier
        )
        formatter.setLocalizedDateFormatFromTemplate("MMMMdyyyy")
        return formatter.string(from: summary.date)
    }

    private var moodTitle: String {
        guard let tone = summary.habitEntry?.tone else {
            return MoriL10n.display("No mood recorded")
        }

        if usesReferenceFixturePhoto, tone == .positive {
            return MoriL10n.display("Calm")
        }

        return tone.title
    }

    private var moodColor: Color {
        summary.habitEntry?.tone.color ?? MoriTheme.Colors.mutedText
    }

    private var dayLogEntry: GratitudeEntry? {
        summary.journalEntries.first { $0.sourceKind == .dayLog }
    }

    private var photoAttachments: [GratitudePhotoAttachment] {
        dayLogEntry?.photoAttachments ?? []
    }

    private var displayedPhotoCount: Int {
        if usesReferenceFixturePhoto, photoAttachments.isEmpty {
            return 1
        }

        return photoAttachments.count
    }

    private var photoCountText: String {
        switch displayedPhotoCount {
        case 0:
            return MoriL10n.display("No photos")
        case 1:
            return MoriL10n.display("1 photo")
        default:
            return MoriL10n.display("\(displayedPhotoCount) photos")
        }
    }

    private var firstPhoto: UIImage? {
        photoAttachments.lazy.compactMap { attachment in
            UIImage(contentsOfFile: attachment.fileURL.path)
        }.first
    }

    private var usesReferenceFixturePhoto: Bool {
#if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-MoriUseLifeGridReferenceFixtureForUITest") else {
            return false
        }

        let components = Calendar(identifier: .gregorian).dateComponents(
            [.year, .month, .day],
            from: summary.date
        )
        return components.year == 2026 && components.month == 7 && components.day == 17
#else
        false
#endif
    }

    private var quietMinutesText: String {
        switch summary.quietMinutes {
        case 0:
            return MoriL10n.display("No quiet minutes")
        case 1:
            return MoriL10n.display("1 quiet minute")
        default:
            return MoriL10n.display("\(summary.quietMinutes) quiet minutes")
        }
    }

    private var savedSentence: String? {
        if let habitNote = normalized(summary.habitEntry?.note) {
            return habitNote
        }

        if let dayLogSentence {
            return dayLogSentence
        }

        if let journalSentence = summary.journalEntries
            .first(where: { $0.sourceKind == .journal })
            .flatMap({ normalized($0.displayContent) }) {
            return journalSentence
        }

        if let spark = summary.dailySpark {
            if let focus = normalized(spark.focus) {
                return focus
            }

            if let smallAction = normalized(spark.smallAction) {
                return smallAction
            }
        }

        return summary.journalEntries
            .first(where: { $0.sourceKind == .dailySpark })
            .flatMap { normalized($0.displayContent) }
    }

    private var dayLogSentence: String? {
        guard let content = dayLogEntry?.displayContent else { return nil }

        return content
            .components(separatedBy: .newlines)
            .compactMap { line -> String? in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.hasPrefix("Note:") else { return nil }
                return normalized(String(trimmed.dropFirst("Note:".count)))
            }
            .first
    }

    init(summary: WeekArchiveDaySummary) {
        self.summary = summary
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(dateText)
                    .font(.system(.title, design: .serif, weight: .regular))
                    .foregroundColor(MoriTheme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 9) {
                    WeekArchiveDayLeafIcon()

                    Text(moodTitle)
                        .font(.system(.body, design: .serif, weight: .regular))
                        .foregroundColor(moodColor)
                }
                .padding(.leading, 4)
                .frame(minHeight: MoriTheme.Spacing.minimumHitTarget, alignment: .leading)
                .padding(.top, 9)
                .offset(y: 7)
                .accessibilityElement(children: .combine)

                WeekArchiveDayMemoryPanel(minimumHeight: 121, alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("“")
                            .font(.system(size: 31, weight: .semibold, design: .serif))
                            .foregroundColor(MoriTheme.Colors.ink.opacity(0.78))
                            .accessibilityHidden(true)

                        Text(savedSentence ?? MoriL10n.display("No sentence saved"))
                            .font(.system(.body, design: .serif, weight: .regular))
                            .foregroundColor(
                                savedSentence == nil
                                    ? MoriTheme.Colors.mutedText
                                    : MoriTheme.Colors.ink
                            )
                            .lineSpacing(3)
                            .frame(maxWidth: 190, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 4)
                }
                .padding(.top, 25)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(MoriL10n.display(savedSentence ?? "No sentence saved"))

                WeekArchiveDayMemoryPanel(minimumHeight: 79, verticalPadding: 6) {
                    HStack(spacing: 14) {
                        Text(photoCountText)
                            .font(MoriTheme.Typography.body)
                            .foregroundColor(
                                displayedPhotoCount == 0
                                    ? MoriTheme.Colors.mutedText
                                    : MoriTheme.Colors.ink
                            )
                            .padding(.leading, 5)

                        Spacer(minLength: 12)

                        if let firstPhoto {
                            Image(uiImage: firstPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 104, height: 62)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                .offset(x: 6)
                                .accessibilityHidden(true)
                        } else if usesReferenceFixturePhoto {
                            Image("MoriDeepSessionForest")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 104, height: 62)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                .offset(x: 6)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .padding(.top, 20)
                .accessibilityElement(children: .combine)

                WeekArchiveDayMemoryPanel(minimumHeight: 59) {
                    HStack(spacing: 10) {
                        WeekArchiveDayLeafIcon()

                        Text(quietMinutesText)
                            .font(MoriTheme.Typography.body)
                            .foregroundColor(
                                summary.quietMinutes == 0
                                    ? MoriTheme.Colors.mutedText
                                    : MoriTheme.Colors.ink
                            )

                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 5)
                }
                .padding(.top, 14)
                .accessibilityElement(children: .combine)

                Button {
                    isShowingFullEntry = true
                } label: {
                    Text(MoriL10n.display("View full entry"))
                        .font(.system(.body, design: .serif, weight: .medium))
                        .foregroundColor(MoriTheme.Colors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 69)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(MoriTheme.Colors.primaryAction)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 28)
                .accessibilityHint(MoriL10n.display("Opens all records saved for this day"))
            }
            .padding(.horizontal, 22)
            .padding(.top, 72)
            .padding(.bottom, 30)
        }
        .background(MoriTheme.Colors.raisedPaper.ignoresSafeArea())
        .fullScreenCover(isPresented: $isShowingFullEntry) {
            WeekArchiveFullDayEntryView(summary: summary)
        }
    }

    private func normalized(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }
}

private struct WeekArchiveDayLeafIcon: View {
    var body: some View {
        Image(systemName: "leaf")
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(MoriTheme.Colors.moss.opacity(0.82))
            .frame(width: 20, height: 22)
            .accessibilityHidden(true)
    }
}

private struct WeekArchiveDayMemoryPanel<Content: View>: View {
    let minimumHeight: CGFloat
    let verticalPadding: CGFloat
    let alignment: Alignment
    private let content: Content

    init(
        minimumHeight: CGFloat,
        verticalPadding: CGFloat = 12,
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumHeight = minimumHeight
        self.verticalPadding = verticalPadding
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: alignment)
            .background(MoriTheme.Colors.paper.opacity(0.34))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(MoriTheme.Colors.line.opacity(0.72), lineWidth: 1)
            )
    }
}

private struct WeekArchiveFullDayEntryView: View {
    @Environment(\.dismiss) private var dismiss

    let summary: WeekArchiveDaySummary

    private var title: String {
        summary.date.formatted(date: .complete, time: .omitted)
    }

    private var standaloneJournalEntries: [GratitudeEntry] {
        guard summary.habitEntry != nil else {
            return summary.journalEntries
        }

        return summary.journalEntries.filter { $0.sourceKind != .dayLog }
    }

    private var dayLogEntry: GratitudeEntry? {
        summary.journalEntries.first { $0.sourceKind == .dayLog }
    }

    init(summary: WeekArchiveDaySummary) {
        self.summary = summary
    }

    var body: some View {
        NavigationStack {
            MoriPaperBackground(variant: .roots) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        WeekArchiveDetailHeader(title: title, subtitle: "Day records", icon: .timer)

                        WeekArchiveMetricsRow(
                            quietActions: summary.quietActionCount,
                            journalCount: summary.journalEntries.count,
                            quietMinutes: summary.quietMinutes
                        )

                        if let spark = summary.dailySpark {
                            WeekArchiveSectionCard(title: "Daily Spark", icon: .pulse) {
                                WeekArchiveDailySparkBlock(spark: spark)
                            }
                        }

                        if let habitEntry = summary.habitEntry {
                            WeekArchiveSectionCard(title: "Daily Log", icon: habitEntry.tone.weekArchiveIcon) {
                                WeekArchiveBitmapLabel(
                                    title: MoriL10n.string(
                                        "habit.tone_day",
                                        defaultValue: "%@ day",
                                        arguments: [habitEntry.tone.title]
                                    ),
                                    icon: habitEntry.tone.weekArchiveIcon,
                                    iconSize: 14,
                                    iconOpacity: 0.84
                                )
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(habitEntry.tone.color)

                                if habitEntry.hasPatternLog {
                                    PatternLogSummaryCard(entry: habitEntry)
                                }

                                if let note = habitEntry.note?.trimmingCharacters(in: .whitespacesAndNewlines),
                                   !note.isEmpty {
                                    Text(note)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(MoriColors.botanicalInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if let dayLogEntry, !dayLogEntry.photoAttachments.isEmpty {
                                    WeekArchiveLogPhotoStrip(attachments: dayLogEntry.photoAttachments)
                                }
                            }
                        }

                        if !standaloneJournalEntries.isEmpty {
                            WeekArchiveSectionCard(title: "Log", icon: .journal) {
                                ForEach(standaloneJournalEntries) { entry in
                                    WeekArchiveJournalRow(entry: entry)
                                }
                            }
                        }

                        if !summary.actions.isEmpty {
                            WeekArchiveSectionCard(title: "Daily Records", icon: .quiet) {
                                ForEach(summary.actions) { action in
                                    WeekArchiveActionRow(action: action)
                                }
                            }
                        }

                        if !summary.sessions.isEmpty {
                            WeekArchiveSectionCard(title: "Quiet Sessions", icon: .quiet) {
                                ForEach(summary.sessions) { session in
                                    WeekArchiveSessionRow(session: session)
                                }
                            }
                        }

                        if !summary.hasRecords {
                            WeekArchiveSectionCard(title: "No records yet", icon: .journal) {
                                Text("No daily note, log entry, quiet action, session, or check-in was found for this day.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(MoriColors.botanicalMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 44)
                }
            }
            .navigationTitle("Day Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.botanicalPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MoriColors.botanicalInk)
                }
            }
        }
    }
}

private struct WeekArchiveLogPhotoStrip: View {
    let attachments: [GratitudePhotoAttachment]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(attachments) { attachment in
                    if let image = UIImage(contentsOfFile: attachment.fileURL.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .accessibilityLabel("\(attachments.count) daily log photos")
    }
}
