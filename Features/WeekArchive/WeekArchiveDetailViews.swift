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
