import SwiftUI

struct MoriRecoveryPatternsCard: View {
    @StateObject private var store = MoriPatternInsightStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Patterns",
                subtitle: "Local correlations from check-ins, tags, resets, and recovery history."
            )

            HStack(spacing: 8) {
                MoriPill(title: store.localLLMAvailability.displayText, icon: .settings, tint: MoriColors.botanicalMist)
                MoriPill(
                    title: MoriL10n.string("recovery.pattern.health_days", defaultValue: "%d health days", arguments: [store.sampleDays]),
                    icon: .roots,
                    tint: MoriColors.botanicalMoss
                )
            }

            if store.insights.isEmpty {
                Text(MoriL10n.display("Not enough local recovery history yet. Mori needs at least 3 tagged days with next-day recovery samples before it shows a pattern."))
                    .font(.system(size: 13))
                    .foregroundColor(MoriColors.botanicalMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(store.insights) { insight in
                    MoriPatternInsightRow(insight: insight)
                }
            }

            Text(MoriL10n.display("These are correlations, not diagnoses or proof of cause."))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MoriColors.botanicalMuted)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
        .task {
            store.refresh()
        }
    }
}

struct MoriFactorTagReviewCard: View {
    @StateObject private var tagStore = MoriFactorTagStore.shared

    let date: Date
    var title: String = "Today's Tags"
    var subtitle: String = "Suggested locally from check-ins, log text, resets, and health context."

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                MoriSectionTitle(title: title, subtitle: subtitle)

                Menu {
                    ForEach(MoriFactorTagID.allCases) { tagID in
                        Button {
                            tagStore.add(tagID, date: date)
                        } label: {
                            HStack(spacing: 8) {
                                MoriBitmapIconImage(icon: tagID.icon, size: 16, opacity: 0.86)

                                Text(MoriL10n.display(tagID.label))
                            }
                        }
                    }
                } label: {
                    MoriBitmapIconImage(icon: .plus, size: 16, opacity: 0.88)
                        .frame(width: 36, height: 36)
                        .background(MoriColors.botanicalInk.opacity(0.08))
                        .clipShape(Circle())
                }
            }

            if tagStore.todayTags.isEmpty {
                Text(MoriL10n.display("No tags suggested yet. Add one manually if something clearly shaped the day."))
                    .font(.system(size: 13))
                    .foregroundColor(MoriColors.botanicalMuted)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(tagStore.todayTags) { tag in
                        Button {
                            tagStore.hide(tag, date: date)
                        } label: {
                            MoriPill(
                                title: tag.id.label,
                                icon: tag.id.icon,
                                isSelected: tag.userEdited,
                                tint: tint(for: tag.id.category)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(MoriL10n.string("recovery.tag.remove_accessibility", defaultValue: "Remove %@ tag", arguments: [tag.id.label]))
                    }
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
        .task {
            tagStore.refresh(date: date)
        }
        .onMoriDataChange(.habit) {
            tagStore.refresh(date: date)
        }
        .onMoriDataChange(.gratitude) {
            tagStore.refresh(date: date)
        }
    }

    private func tint(for category: MoriFactorTagCategory) -> Color {
        switch category {
        case .body:
            return MoriColors.botanicalClay
        case .mind:
            return MoriColors.botanicalMist
        case .sleep:
            return MoriColors.botanicalMuted
        case .movement:
            return MoriColors.botanicalMoss
        case .practice:
            return MoriColors.botanicalSeed
        case .context:
            return MoriColors.botanicalRoot
        }
    }
}

private struct MoriPatternInsightRow: View {
    let insight: RecoveryPatternInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                MoriBitmapIconImage(icon: insight.factorTag.icon, size: 18, opacity: 0.86)
                    .frame(width: 34, height: 34)
                    .background(MoriColors.sanctuarySurface.opacity(0.74))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(insight.factorTag.label)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.botanicalInk)

                    Text(insight.summary)
                        .font(.system(size: 13))
                        .foregroundColor(MoriColors.botanicalMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                MoriPill(title: insight.confidence.label, icon: .pulse, tint: MoriColors.botanicalMist)
                MoriPill(
                    title: MoriL10n.string("recovery.pattern.samples", defaultValue: "%d samples", arguments: [insight.sampleCount]),
                    icon: .roots,
                    tint: MoriColors.botanicalMoss
                )
                MoriPill(title: insight.suggestedPractice.title, icon: insight.suggestedPractice.icon, tint: MoriColors.botanicalSeed)
            }
        }
        .padding(12)
        .background(MoriColors.botanicalPaperDeep.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
