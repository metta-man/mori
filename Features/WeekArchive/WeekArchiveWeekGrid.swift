import SwiftUI

struct WeekArchiveWeekGrid: View {
    let settings: UserSettings
    let recordedWeekIndexes: Set<Int>
    let onWeekSelected: (WeekCoordinate) -> Void

    private let spacing: CGFloat = 2.1
    private let focusedSpacing: CGFloat = 7
    @State private var showsYearMap = false
    @State private var showsFullArchive = false

    private var currentArchiveYear: Int {
        min(max(settings.currentWeekIndex / 52, 0), max(settings.archiveSpanYears - 1, 0))
    }

    private var currentWeekOfYear: Int {
        min(max(settings.currentWeekIndex - currentArchiveYear * 52, 0), 51)
    }

    private var recordedWeeksInCurrentYear: Int {
        let yearStart = currentArchiveYear * 52
        return (0..<52).filter { recordedWeekIndexes.contains(yearStart + $0) }.count
    }

    private var currentWeekCoordinate: WeekCoordinate {
        WeekCoordinate(year: currentArchiveYear, week: currentWeekOfYear)
    }

    private var currentWeekDetail: String {
        if recordedWeekIndexes.contains(settings.currentWeekIndex) {
            return "Week \(currentWeekOfYear + 1) · A note is waiting here."
        }
        return "Week \(currentWeekOfYear + 1) · Nothing needed from you."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MoriSectionTitle(
                title: "This archive year",
                subtitle: "Return only when there is something worth keeping."
            )

            Button {
                onWeekSelected(currentWeekCoordinate)
            } label: {
                MoriV2QuietActionRow(
                    title: "Open the current week",
                    subtitle: currentWeekDetail,
                    icon: .journal
                )
            }
            .buttonStyle(MoriV2PressButtonStyle())

            MoriV2QuietDisclosureRow(
                title: showsYearMap ? "Fold the archive map" : "Browse earlier weeks",
                subtitle: showsYearMap
                    ? "Return to the current week."
                    : "The archive map stays folded until you need it.",
                isExpanded: showsYearMap,
                action: { showsYearMap.toggle() }
            )

            if showsYearMap {
                VStack(alignment: .leading, spacing: 14) {
                    MoriSectionTitle(
                        title: "Archive year \(currentArchiveYear + 1)",
                        subtitle: "\(recordedWeeksInCurrentYear) weeks hold a note."
                    )

                    GeometryReader { proxy in
                        let availableWidth = max(proxy.size.width, 260)
                        let dotSize = max(12, min(20, (availableWidth - CGFloat(12) * focusedSpacing) / 13))

                        WeekArchiveFocusedYearCanvas(
                            archiveYear: currentArchiveYear,
                            archiveWeeksElapsed: settings.archiveWeeksElapsed,
                            currentWeekIndex: settings.currentWeekIndex,
                            recordedWeekIndexes: recordedWeekIndexes,
                            dotSize: dotSize,
                            spacing: focusedSpacing,
                            onWeekSelected: onWeekSelected
                        )
                        .frame(width: proxy.size.width, height: dotSize * 4 + focusedSpacing * 3)
                    }
                    .frame(height: 94)

                    WeekArchiveFocusedYearLegend()

                    Divider()
                        .overlay(MoriColors.botanicalHairline.opacity(0.7))

                    Button {
                        showsFullArchive.toggle()
                    } label: {
                        HStack(spacing: 8) {
                            MoriBitmapIconImage(icon: .chevron, size: 11, opacity: 0.72)
                                .rotationEffect(.degrees(showsFullArchive ? -90 : 90))

                            Text(MoriL10n.display(showsFullArchive ? "Hide full archive map" : "Show full archive map"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MoriColors.botanicalInk)

                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: MoriV2Layout.minimumHitTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(MoriV2PressButtonStyle())
                    .accessibilityLabel(MoriL10n.display(showsFullArchive ? "Hide full archive map" : "Show full archive map"))

                    if showsFullArchive {
                        VStack(alignment: .leading, spacing: 14) {
                            MoriSectionTitle(
                                title: "Full archive map",
                                subtitle: "A quiet reference for older weeks."
                            )

                            GeometryReader { proxy in
                                let availableWidth = max(proxy.size.width, 260)
                                let dotSize = max(3.8, min(7, (availableWidth - CGFloat(51) * spacing) / 52))

                                WeekArchiveWeeksCanvas(
                                    archiveSpanYears: settings.archiveSpanYears,
                                    archiveWeeksElapsed: settings.archiveWeeksElapsed,
                                    currentWeekIndex: settings.currentWeekIndex,
                                    recordedWeekIndexes: recordedWeekIndexes,
                                    dotSize: dotSize,
                                    spacing: spacing,
                                    onWeekSelected: onWeekSelected
                                )
                                .frame(width: proxy.size.width, height: CGFloat(settings.archiveSpanYears) * dotSize + CGFloat(max(0, settings.archiveSpanYears - 1)) * spacing)
                            }
                            .frame(height: CGFloat(settings.archiveSpanYears) * 7.0 + CGFloat(max(0, settings.archiveSpanYears - 1)) * spacing)

                            WeekArchiveWeekLegend()
                        }
                        .transition(.opacity)
                    }
                }
                .transition(.opacity)
            }
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsYearMap)
        .moriReduceMotionAnimation(MoriV2Motion.disclosure, value: showsFullArchive)
    }
}

private struct WeekArchiveFocusedYearSummary: View {
    let archiveYear: Int
    let currentWeekOfYear: Int
    let recordedWeeks: Int

    var body: some View {
        HStack(spacing: 16) {
            summaryMetric(title: "Archive year", value: "\(archiveYear + 1)")
            summaryMetric(title: "Current week", value: "\(currentWeekOfYear + 1)")
            summaryMetric(title: "Recorded", value: "\(recordedWeeks)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(MoriL10n.display(title))
                .font(MoriTypography.micro)
                .foregroundColor(MoriColors.botanicalMuted)

            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.botanicalInk)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WeekArchiveFocusedYearCanvas: View {
    let archiveYear: Int
    let archiveWeeksElapsed: Int
    let currentWeekIndex: Int
    let recordedWeekIndexes: Set<Int>
    let dotSize: CGFloat
    let spacing: CGFloat
    let onWeekSelected: (WeekCoordinate) -> Void

    private let columns = 13
    private let weeksPerYear = 52

    var body: some View {
        Canvas { context, _ in
            for week in 0..<weeksPerYear {
                let weekIndex = archiveYear * weeksPerYear + week
                let rect = dotRect(week: week)
                let path = Path(roundedRect: rect, cornerRadius: max(3, dotSize * 0.24))

                context.fill(path, with: .color(fillColor(for: weekIndex)))

                if shouldStrokeQuietWeek(weekIndex) {
                    context.stroke(
                        path,
                        with: .color(MoriColors.botanicalInk.opacity(0.075)),
                        lineWidth: 0.65
                    )
                }

                if weekIndex == currentWeekIndex {
                    let lineWidth: CGFloat = 1.6
                    let ringRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
                    let ring = Path(roundedRect: ringRect, cornerRadius: max(3, dotSize * 0.24))
                    context.stroke(ring, with: .color(MoriColors.botanicalInk), lineWidth: lineWidth)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            SpatialTapGesture(coordinateSpace: .local)
                .onEnded { value in
                    guard let coordinate = weekCoordinate(at: value.location) else { return }
                    guard coordinate.linearIndex <= currentWeekIndex else { return }
                    onWeekSelected(coordinate)
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MoriL10n.display("Current archive year"))
        .accessibilityHint(MoriL10n.display("Tap a week to review its records"))
    }

    private func dotRect(week: Int) -> CGRect {
        let row = week / columns
        let column = week % columns

        return CGRect(
            x: CGFloat(column) * (dotSize + spacing),
            y: CGFloat(row) * (dotSize + spacing),
            width: dotSize,
            height: dotSize
        )
    }

    private func weekCoordinate(at location: CGPoint) -> WeekCoordinate? {
        guard location.x >= 0, location.y >= 0 else { return nil }

        let stride = dotSize + spacing
        let column = Int(location.x / stride)
        let row = Int(location.y / stride)
        guard column >= 0, column < columns, row >= 0, row < 4 else { return nil }

        let week = row * columns + column
        guard week >= 0, week < weeksPerYear else { return nil }

        let hitRect = CGRect(
            x: CGFloat(column) * stride - spacing,
            y: CGFloat(row) * stride - spacing,
            width: dotSize + spacing * 2,
            height: dotSize + spacing * 2
        )
        guard hitRect.contains(location) else { return nil }

        return WeekCoordinate(year: archiveYear, week: week)
    }

    private func fillColor(for weekIndex: Int) -> Color {
        if recordedWeekIndexes.contains(weekIndex) {
            return MoriColors.botanicalMoss.opacity(0.78)
        }

        if weekIndex < archiveWeeksElapsed {
            return MoriColors.botanicalInk.opacity(0.10)
        }

        return MoriColors.botanicalInk.opacity(0.035)
    }

    private func shouldStrokeQuietWeek(_ weekIndex: Int) -> Bool {
        !recordedWeekIndexes.contains(weekIndex) && weekIndex < archiveWeeksElapsed
    }
}

private struct WeekArchiveFocusedYearLegend: View {
    var body: some View {
        FlowLayout(spacing: 10) {
            WeekArchiveLegendPill(title: "Recorded", color: MoriColors.botanicalMoss.opacity(0.78))
            WeekArchiveOutlineLegendPill(title: "Current week is outlined")
            WeekArchiveLegendPill(title: "Quiet week", color: MoriColors.botanicalInk.opacity(0.10))
        }
    }
}

private struct WeekArchiveWeeksCanvas: View {
    let archiveSpanYears: Int
    let archiveWeeksElapsed: Int
    let currentWeekIndex: Int
    let recordedWeekIndexes: Set<Int>
    let dotSize: CGFloat
    let spacing: CGFloat
    let onWeekSelected: (WeekCoordinate) -> Void

    var body: some View {
        Canvas { context, _ in
            for year in 0..<archiveSpanYears {
                for week in 0..<52 {
                    let weekIndex = year * 52 + week
                    let rect = dotRect(year: year, week: week)
                    let path = Path(roundedRect: rect, cornerRadius: max(1.5, dotSize * 0.28))

                    context.fill(path, with: .color(fillColor(for: weekIndex)))

                    if shouldStrokeQuietWeek(weekIndex) {
                        context.stroke(
                            path,
                            with: .color(MoriColors.botanicalInk.opacity(0.055)),
                            lineWidth: 0.45
                        )
                    }

                    if weekIndex == currentWeekIndex {
                        let lineWidth: CGFloat = 1.5
                        let ringRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
                        let ring = Path(roundedRect: ringRect, cornerRadius: max(1.5, dotSize * 0.28))
                        context.stroke(ring, with: .color(MoriColors.botanicalInk), lineWidth: lineWidth)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            SpatialTapGesture(coordinateSpace: .local)
                .onEnded { value in
                    guard let coordinate = weekCoordinate(at: value.location) else { return }
                    let linearIndex = coordinate.linearIndex
                    guard linearIndex <= currentWeekIndex else { return }
                    onWeekSelected(coordinate)
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MoriL10n.display("Weeks archive"))
        .accessibilityHint(MoriL10n.display("Tap an archived week to review its records"))
    }

    private func dotRect(year: Int, week: Int) -> CGRect {
        CGRect(
            x: CGFloat(week) * (dotSize + spacing),
            y: CGFloat(year) * (dotSize + spacing),
            width: dotSize,
            height: dotSize
        )
    }

    private func weekCoordinate(at location: CGPoint) -> WeekCoordinate? {
        guard location.x >= 0, location.y >= 0 else { return nil }

        let stride = dotSize + spacing
        let week = Int(location.x / stride)
        let year = Int(location.y / stride)
        guard year >= 0, year < archiveSpanYears, week >= 0, week < 52 else { return nil }

        let hitRect = CGRect(
            x: CGFloat(week) * stride - spacing,
            y: CGFloat(year) * stride - spacing,
            width: dotSize + spacing * 2,
            height: dotSize + spacing * 2
        )
        guard hitRect.contains(location) else { return nil }
        return WeekCoordinate(year: year, week: week)
    }

    private func fillColor(for weekIndex: Int) -> Color {
        if recordedWeekIndexes.contains(weekIndex) {
            return MoriColors.botanicalMoss.opacity(0.78)
        }

        if weekIndex < archiveWeeksElapsed {
            return MoriColors.botanicalInk.opacity(0.10)
        }

        return MoriColors.botanicalInk.opacity(0.03)
    }

    private func shouldStrokeQuietWeek(_ weekIndex: Int) -> Bool {
        !recordedWeekIndexes.contains(weekIndex) && weekIndex < archiveWeeksElapsed
    }
}

private struct WeekArchiveWeekLegend: View {
    var body: some View {
        FlowLayout(spacing: 10) {
            WeekArchiveLegendPill(title: "Future", color: MoriColors.botanicalInk.opacity(0.03))
            WeekArchiveLegendPill(title: "Quiet week", color: MoriColors.botanicalInk.opacity(0.10))
            WeekArchiveLegendPill(title: "Recorded", color: MoriColors.botanicalMoss.opacity(0.78))
            WeekArchiveOutlineLegendPill(title: "Current week is outlined")
        }
    }
}

struct WeekArchiveLegendPill: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(MoriL10n.display(title))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MoriColors.botanicalMuted)
        }
    }
}

private struct WeekArchiveOutlineLegendPill: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(MoriColors.botanicalInk, lineWidth: 1.3)
                .frame(width: 12, height: 12)

            Text(MoriL10n.display(title))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MoriColors.botanicalMuted)
        }
    }
}
