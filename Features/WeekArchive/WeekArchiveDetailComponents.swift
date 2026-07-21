import SwiftUI

struct WeekArchiveBitmapLabel: View {
    let title: String
    let icon: MoriBitmapIcon
    var iconSize: CGFloat = 16
    var iconOpacity: Double = 0.86
    var spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            MoriBitmapIconImage(icon: icon, size: iconSize, opacity: iconOpacity)

            Text(MoriL10n.display(title))
        }
    }
}

extension LifeDomain {
    var weekArchiveIcon: MoriBitmapIcon {
        switch self {
        case .body: return .timer
        case .mind: return .pulse
        case .love: return .heart
        case .craft: return .focus
        case .courage: return .lockShield
        case .service: return .leaf
        case .wonder: return .pulse
        case .rest: return .quiet
        }
    }
}

extension GratitudeEntry {
    var weekArchiveSourceIcon: MoriBitmapIcon {
        switch sourceKind {
        case .journal: return .journal
        case .dayLog: return .timer
        case .dailySpark: return .pulse
        case .weeklyIntention: return .journal
        }
    }
}

struct WeekArchiveDetailHeader: View {
    let title: String
    let subtitle: String
    let icon: MoriBitmapIcon

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            MoriBitmapIconImage(icon: icon, size: 20, opacity: 0.90)
                .frame(width: 44, height: 44)
                .background(MoriColors.botanicalMoss.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(MoriL10n.display(title))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.botanicalInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(MoriL10n.display(subtitle))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
            }
        }
    }
}

struct WeekArchiveMetricsRow: View {
    let quietActions: Int
    let journalCount: Int
    let quietMinutes: Int

    var body: some View {
        MoriCompactStatStrip {
            MoriCompactStatItem(title: "Quiet actions", value: "\(quietActions)", icon: .quiet, tint: MoriColors.botanicalMoss)
            MoriCompactStatItem(title: "Quiet minutes", value: "\(quietMinutes)m", icon: .quiet, tint: MoriColors.botanicalMist)
            MoriCompactStatItem(title: "Notes", value: "\(journalCount)", icon: .journal, tint: MoriColors.botanicalInk)
        }
    }
}

struct WeekArchiveSectionCard<Content: View>: View {
    let title: String
    let icon: MoriBitmapIcon
    private let content: Content

    init(title: String, icon: MoriBitmapIcon, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeekArchiveBitmapLabel(
                title: title,
                icon: icon,
                iconSize: 16,
                iconOpacity: 0.88
            )
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.botanicalInk)

            content
        }
        .moriSanctuaryCard(cornerRadius: 20, padding: 16)
    }
}

struct WeekArchiveIntentionRow: View {
    let intention: WeeklyIntention

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(icon: intention.domain.weekArchiveIcon, size: 15, opacity: 0.88)
                .frame(width: 32, height: 32)
                .background(intention.domain.moriTint.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(intention.action)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(MoriL10n.string(
                    intention.isCompleted ? "week_archive.domain_completed" : "week_archive.domain_chosen",
                    defaultValue: intention.isCompleted ? "%@ completed" : "%@ chosen",
                    arguments: [intention.domain.title]
                ))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(MoriColors.botanicalMuted)
            }
        }
    }
}

struct WeekArchiveDailySparkBlock: View {
    let spark: DailySparkEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WeekArchiveKeyValueRow(title: "Focus", value: spark.focus)
            WeekArchiveKeyValueRow(title: "Desired feeling", value: spark.desiredFeeling)
            WeekArchiveKeyValueRow(title: "Avoid", value: spark.thingToAvoid)
            WeekArchiveKeyValueRow(title: "Plan", value: spark.ifThenPlan)
        }
    }
}

struct WeekArchiveJournalRow: View {
    let entry: GratitudeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WeekArchiveBitmapLabel(
                title: entry.sourceLabel,
                icon: entry.weekArchiveSourceIcon,
                iconSize: 13,
                iconOpacity: 0.82
            )
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMoss)

            Text(entry.displayContent)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.botanicalInk)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(MoriColors.botanicalPaperDeep.opacity(0.46))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct WeekArchiveActionRow: View {
    let action: MoriMindfulAction

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(icon: action.kind.archiveIcon, size: 14, opacity: 0.86)
                .frame(width: 30, height: 30)
                .background(MoriColors.botanicalMoss.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(action.weekArchiveDisplayTitle))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text(action.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)

                if let note = action.weekArchiveDisplayNote {
                    Text(note)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct WeekArchiveSessionRow: View {
    let session: SettleSession

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MoriBitmapIconImage(
                icon: session.completed ? .leaf : .stop,
                size: 16,
                opacity: session.completed ? 0.95 : 0.82
            )
                .frame(width: 30, height: 30)
                .background((session.completed ? MoriColors.botanicalMoss : MoriColors.botanicalClay).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(MoriL10n.display(session.title))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.botanicalInk)

                Text("\(session.durationText) \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.botanicalMuted)
            }
            Spacer(minLength: 0)
        }
    }
}

private extension MoriMindfulAction {
    var weekArchiveDisplayTitle: String {
        containsRewardLanguage(title) ? kind.title : title
    }

    var weekArchiveDisplayNote: String? {
        guard let note = note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty,
              !containsRewardLanguage(note)
        else {
            return nil
        }
        return note
    }

    func containsRewardLanguage(_ text: String) -> Bool {
        let tokens = Set(text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
        let rewardTokens: Set<String> = [
            "seed", "seeds", "streak", "streaks", "reward", "rewards", "earned",
            "bloom", "blooms", "growth", "grow", "growing", "grown", "level", "levels",
            "xp", "coin", "coins"
        ]
        return !tokens.isDisjoint(with: rewardTokens)
    }
}

struct WeekArchiveKeyValueRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(MoriL10n.display(title))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoriColors.botanicalMuted)

            Text(value.isEmpty ? MoriL10n.display("Not recorded") : MoriL10n.display(value))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(value.isEmpty ? MoriColors.botanicalMuted : MoriColors.botanicalInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
