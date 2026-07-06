import SwiftUI

struct TodayWeekArchiveReferenceCard: View {
    @Environment(\.moriOpenTodayRoute) private var openTodayRoute

    let snapshot: TodayScreenSnapshot

    var body: some View {
        Button(action: openArchiveDetail) {
            HStack(alignment: .center, spacing: 12) {
                MoriProductSymbolBadge(
                    symbol: .weekArchive,
                    size: 38,
                    symbolScale: 0.68,
                    tint: MoriColors.botanicalInk,
                    fill: MoriColors.sanctuarySurface.opacity(0.74),
                    stroke: Color.white.opacity(0.88),
                    shadow: MoriColors.sanctuaryShadow.opacity(0.20)
                )

                VStack(alignment: .leading, spacing: 7) {
                    Text(MoriL10n.display("Week Archive"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.sanctuaryInk)

                    HStack(spacing: 9) {
                        TodayWeekArchiveReferenceMetric(
                            value: (snapshot.currentWeekIndex + 1).formatted(),
                            label: "archive week"
                        )

                        Divider()
                            .frame(height: 24)
                            .overlay(MoriColors.botanicalLine.opacity(0.9))

                        TodayWeekArchiveReferenceMetric(
                            value: snapshot.quietMinutes.formatted(),
                            label: "quiet minutes"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MoriBitmapIconImage(icon: .chevron, size: 14, opacity: 0.68)
            }
            .padding(.vertical, 2)
            .moriSanctuaryBox(cornerRadius: 18, padding: 14, tone: .sage)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MoriL10n.display("Open weeks archive"))
    }

    private func openArchiveDetail() {
        openTodayRoute(.weekArchiveDetail)
    }

}

private struct TodayWeekArchiveReferenceMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(MoriL10n.display(value))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.botanicalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .monospacedDigit()

            Text(MoriL10n.display(label))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MoriColors.botanicalMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
