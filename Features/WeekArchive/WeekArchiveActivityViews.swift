import SwiftUI

struct WeekArchiveActivitySection: View {
    let habitEntries: [HabitEntry]
    let journalEntries: [GratitudeEntry]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeekArchiveBitmapLabel(title: "Already captured this week", icon: .pulse, iconSize: 17, iconOpacity: 0.86)
                .font(.headline)
                .foregroundColor(MoriColors.botanicalMoss)

            ForEach(journalEntries.prefix(4)) { entry in
                WeekArchiveActivityRow(
                    icon: entry.weekArchiveSourceIcon,
                    tint: entry.photoAttachments.isEmpty ? MoriColors.botanicalInk : MoriColors.botanicalMist,
                    title: entry.sourceLabel,
                    subtitle: dateFormatter.string(from: entry.date),
                    bodyText: entry.displayContent
                )
            }

            ForEach(habitEntries.filter(\.hasPatternLog).prefix(3)) { entry in
                WeekArchiveActivityRow(
                    icon: .refresh,
                    tint: MoriColors.botanicalSeed,
                    title: "Pattern Log",
                    subtitle: "\(dateFormatter.string(from: entry.date)) · \(entry.tone.title)",
                    bodyText: patternSummary(for: entry)
                )
            }

            let noteEntries = habitEntries.filter { entry in
                entry.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && !entry.hasPatternLog
            }

            ForEach(noteEntries.prefix(3)) { entry in
                WeekArchiveActivityRow(
                    icon: .journal,
                    tint: entry.tone.color,
                    title: "\(entry.tone.title) day",
                    subtitle: dateFormatter.string(from: entry.date),
                    bodyText: entry.note ?? ""
                )
            }
        }
        .padding(16)
        .background(MoriColors.botanicalSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.botanicalHairline, lineWidth: 1)
        )
    }

    private func patternSummary(for entry: HabitEntry) -> String {
        [
            entry.trigger.map { "Trigger: \($0)" },
            entry.feeling.map { "Feeling: \($0)" },
            entry.responsePlan.map { "Next: \($0)" }
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
    }
}

private struct WeekArchiveActivityRow: View {
    let icon: MoriBitmapIcon
    let tint: Color
    let title: String
    let subtitle: String
    let bodyText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MoriBitmapIconImage(icon: icon, size: 14, opacity: 0.86)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(MoriL10n.display(title))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(MoriL10n.display(subtitle))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MoriColors.botanicalMuted)
                }

                Text(MoriL10n.display(bodyText))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
