import SwiftUI
import CoreData
import UIKit

struct LifeGridView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject private var clarityStore = MoriClarityStore.shared
    @State private var selectedWeek: WeekCoordinate?
    @State private var showWeekDetail = false
    @State private var showSettings = false
    @State private var draftDomain: LifeDomain = .love
    @State private var draftAction = LifeDomain.love.suggestedActions[0]
    @State private var selectedView: LifeGridZoom = .life
    @State private var focusedMonth = Date()
    @State private var focusedYear = Date()
    @State private var habitEntries: [HabitEntry] = []
    @State private var journalEntries: [GratitudeEntry] = []
    @State private var weekTones: [Int: HabitDayTone] = [:]
    @State private var selectedMonthDay: MonthDaySelection?
    
    private let weekColumns = 52
    private let ageLabelWidth: CGFloat = 28
    private let weekGap: CGFloat = 1.6
    
    var body: some View {
        NavigationStack {
            ZStack {
                MoriColors.forestPaper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        LifeGridHeader(
                            weeksLived: settings.weeksLived,
                            totalWeeks: settings.totalWeeks,
                            weeksRemaining: settings.weeksRemaining
                        )

                        LifeGridGrowthCard(metrics: clarityStore.metrics(settings: settings))

                        WeeklyIntentionCard(
                            intentions: settings.activeWeeklyIntentions,
                            selectedDomain: $draftDomain,
                            actionText: $draftAction,
                            onSave: {
                                settings.setWeeklyIntention(domain: draftDomain, action: draftAction)
                            },
                            onComplete: { intention in
                                settings.completeWeeklyIntention(intention)
                                clarityStore.record(
                                    kind: .lifeGridProof,
                                    title: "Completed weekly proof",
                                    seeds: 4,
                                    minutes: 0,
                                    note: intention.action
                                )
                            },
                            onReopen: { intention in
                                settings.reopenWeeklyIntention(intention)
                            }
                        )

                        Picker("Life grid view", selection: $selectedView) {
                            ForEach(LifeGridZoom.allCases) { view in
                                Text(view.title).tag(view)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(MoriColors.forestCanopy)

                        gridContent

                        HabitToneLegend()

                        Text(selectedView.helperText)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(MoriColors.forestMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Life Grid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(MoriColors.forestCanopy.opacity(0.82))
                    }
                }
            }
            .sheet(isPresented: $showWeekDetail) {
                if let week = selectedWeek {
                    WeekDetailSheet(
                        week: week,
                        settings: settings,
                        habitEntries: entries(for: week, in: habitEntries),
                        journalEntries: entries(for: week, in: journalEntries),
                        isPresented: $showWeekDetail
                    )
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
            .sheet(item: $selectedMonthDay) { selection in
                MonthDayDetailSheet(selection: selection)
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackLifeGridViewed()
            loadHabitEntries()
            loadJournalEntries()
            if let intention = settings.activeWeeklyIntention {
                draftDomain = intention.domain
                draftAction = intention.action
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .habitDataDidChange)) { _ in
            loadHabitEntries()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gratitudeDataDidChange)) { _ in
            loadJournalEntries()
        }
    }

    @ViewBuilder
    private var gridContent: some View {
        switch selectedView {
        case .life:
            GeometryReader { proxy in
                let availableWidth = max(proxy.size.width - ageLabelWidth - 44, 220)
                let dotSize = max(3, min(5.5, (availableWidth - CGFloat(weekColumns - 1) * weekGap) / CGFloat(weekColumns)))

                HStack(alignment: .top, spacing: 12) {
                    AgeLabelsColumn(
                        lifeExpectancy: settings.lifeExpectancy,
                        rowHeight: dotSize,
                        rowSpacing: weekGap
                    )
                    .frame(width: ageLabelWidth)

                    LifeWeeksCanvasGrid(
                        lifeExpectancy: settings.lifeExpectancy,
                        weeksLived: displayCurrentWeekIndex,
                        currentWeekIndex: displayCurrentWeekIndex,
                        currentWeekDomain: settings.activeWeeklyIntentionDomain,
                        isCurrentWeekMeaningful: settings.hasCompletedWeeklyIntention,
                        weekTones: weekTones,
                        dotSize: dotSize,
                        spacing: weekGap,
                        onWeekTap: handleWeekTap
                    )
                }
                .padding(16)
                .background(MoriColors.forestCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(MoriColors.forestHairline, lineWidth: 1)
                )
                .cornerRadius(18)
                .shadow(color: MoriColors.forestShadow.opacity(0.45), radius: 18, x: 0, y: 10)
            }
            .frame(height: gridHeight(for: settings.lifeExpectancy))
        case .year:
            YearToneGrid(
                focusedYear: $focusedYear,
                entries: habitEntries,
                journalEntries: journalEntries,
                onMonthSelected: { month in
                    focusedMonth = month
                    selectedView = .month
                }
            )
        case .month:
            MonthToneGrid(
                focusedMonth: $focusedMonth,
                entries: habitEntries,
                journalEntries: journalEntries,
                onDaySelected: { selectedMonthDay = $0 }
            )
        }
    }

    private func makeWeekToneMap(from entries: [HabitEntry]) -> [Int: HabitDayTone] {
        var tones: [Int: [HabitDayTone]] = [:]

        for entry in entries {
            guard let weekIndex = visualWeekIndex(for: entry.date) else { continue }
            tones[weekIndex, default: []].append(entry.tone)
        }

        return tones.compactMapValues { majorityTone(in: $0) }
    }

    private var displayCurrentWeekIndex: Int {
        visualWeekIndex(for: Date()) ?? settings.currentWeekIndex
    }

    private func gridHeight(for lifeExpectancy: Int) -> CGFloat {
        let estimatedDotSize: CGFloat = 4.5
        let chrome: CGFloat = 32
        return CGFloat(lifeExpectancy) * (estimatedDotSize + weekGap) + chrome
    }
    
    private func handleWeekTap(year: Int, week: Int) {
        let weekIndex = year * 52 + week
        
        // Don't allow tapping future weeks
        if weekIndex > displayCurrentWeekIndex {
            return
        }
        
        selectedWeek = WeekCoordinate(year: year, week: week)
        showWeekDetail = true
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func loadHabitEntries() {
        habitEntries = HabitDataManager.shared.getEntries(from: settings.birthDate, to: Date())
        weekTones = makeWeekToneMap(from: habitEntries)
    }

    private func loadJournalEntries() {
        journalEntries = GratitudeEntry.loadAllStored()
    }

    private func entries(for week: WeekCoordinate, in entries: [HabitEntry]) -> [HabitEntry] {
        entries
            .filter { visualWeekIndex(for: $0.date) == week.linearIndex }
            .sorted { $0.date < $1.date }
    }

    private func entries(for week: WeekCoordinate, in entries: [GratitudeEntry]) -> [GratitudeEntry] {
        entries
            .filter { visualWeekIndex(for: $0.date) == week.linearIndex }
            .sorted { $0.date < $1.date }
    }

    private func visualWeekIndex(for date: Date) -> Int? {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        let birthDay = calendar.startOfDay(for: settings.birthDate)
        let entryDay = calendar.startOfDay(for: date)
        guard entryDay >= birthDay else { return nil }

        let ageAtEntry = calendar.dateComponents([.year], from: birthDay, to: entryDay).year ?? 0
        guard ageAtEntry < settings.lifeExpectancy else { return nil }

        let ageStart = calendar.date(byAdding: .year, value: ageAtEntry, to: birthDay) ?? birthDay
        let ageWeekStart = moriMondayWeekStart(for: ageStart)
        let entryWeekStart = moriMondayWeekStart(for: entryDay)
        let weeksIntoAgeYear = calendar.dateComponents([.weekOfYear], from: ageWeekStart, to: entryWeekStart).weekOfYear ?? 0
        let weekIntoAgeYear = max(0, min(51, weeksIntoAgeYear))

        return ageAtEntry * 52 + weekIntoAgeYear
    }

    private func majorityTone(in tones: [HabitDayTone]) -> HabitDayTone? {
        guard !tones.isEmpty else { return nil }
        let positive = tones.filter { $0 == .positive }.count
        let neutral = tones.filter { $0 == .neutral }.count
        let negative = tones.filter { $0 == .negative }.count

        if positive > neutral && positive > negative {
            return .positive
        } else if negative > positive && negative > neutral {
            return .negative
        } else {
            return .neutral
        }
    }
}

private func moriMondayWeekStart(for date: Date) -> Date {
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    let day = calendar.startOfDay(for: date)
    let weekday = calendar.component(.weekday, from: day)
    let daysFromMonday = (weekday - calendar.firstWeekday + 7) % 7
    return calendar.date(byAdding: .day, value: -daysFromMonday, to: day) ?? day
}

private func moriMondayWeekStart(for week: WeekCoordinate, birthDate: Date) -> Date {
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    let birthDay = calendar.startOfDay(for: birthDate)
    let ageStart = calendar.date(byAdding: .year, value: week.year, to: birthDay) ?? birthDay
    let ageWeekStart = moriMondayWeekStart(for: ageStart)
    return calendar.date(byAdding: .weekOfYear, value: week.week, to: ageWeekStart) ?? ageWeekStart
}

private enum LifeGridZoom: String, CaseIterable, Identifiable {
    case life
    case year
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .life: return "Life"
        case .year: return "Year"
        case .month: return "Month"
        }
    }

    var helperText: String {
        switch self {
        case .life:
            return "Each dot is one week. Colored lived weeks reflect the majority tone from daily check-ins."
        case .year:
            return "Each square is one day in the selected year."
        case .month:
            return "Each square is one day in the selected month. A gold bar marks a Pattern Log."
        }
    }
}

// MARK: - Age Labels Column
struct AgeLabelsColumn: View {
    let lifeExpectancy: Int
    let rowHeight: CGFloat
    let rowSpacing: CGFloat
    
    var body: some View {
        VStack(alignment: .trailing, spacing: rowSpacing) {
            ForEach(0..<lifeExpectancy, id: \.self) { age in
                if age.isMultiple(of: 5) || age == lifeExpectancy - 1 {
                    Text("\(age)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(MoriColors.forestMuted)
                        .frame(height: rowHeight, alignment: .trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Color.clear
                        .frame(height: rowHeight)
                }
            }
        }
    }
}

private struct LifeGridHeader: View {
    let weeksLived: Int
    let totalWeeks: Int
    let weeksRemaining: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Life Grid")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)

            Text("\(weeksRemaining.formatted()) weeks remaining")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(MoriColors.forestMoss)

            ProgressView(value: Double(weeksLived), total: Double(max(totalWeeks, 1)))
                .tint(MoriColors.forestMoss)
                .background(MoriColors.forestLine.opacity(0.6))
                .clipShape(Capsule())
        }
    }
}

private struct LifeGridGrowthCard: View {
    let metrics: MoriClarityMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "This week is alive",
                subtitle: "Seeds from Settle, Quiet, Pulse, check-ins, and weekly proofs feed today's Bloom."
            )

            HStack(spacing: 12) {
                GrowthStatPill(
                    title: "Seeds",
                    value: "\(metrics.seedsToday)",
                    symbolName: "circle.hexagongrid.fill",
                    tint: MoriColors.forestSeed
                )

                GrowthStatPill(
                    title: "Clarity",
                    value: "\(metrics.clarityScore)",
                    symbolName: "leaf.fill",
                    tint: MoriColors.forestMoss
                )

                GrowthStatPill(
                    title: "Bloom",
                    value: metrics.bloomPercentText,
                    symbolName: "camera.macro",
                    tint: MoriColors.forestFern
                )
            }

            MoriForestProgressBar(value: metrics.bloomProgress, tint: MoriColors.forestFern)

            HStack(spacing: 10) {
                MoriPill(
                    title: "Settle \(metrics.settleMinutesToday)m",
                    symbolName: "figure.mind.and.body",
                    tint: MoriColors.forestMoss
                )

                MoriPill(
                    title: "\(metrics.settleSessionsToday) sessions",
                    symbolName: "leaf.fill",
                    tint: MoriColors.forestSeed
                )
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct GrowthStatPill: View {
    let title: String
    let value: String
    let symbolName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)

            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(MoriColors.forestMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct WeeklyIntentionCard: View {
    let intentions: [WeeklyIntention]
    @Binding var selectedDomain: LifeDomain
    @Binding var actionText: String
    let onSave: () -> Void
    let onComplete: (WeeklyIntention) -> Void
    let onReopen: (WeeklyIntention) -> Void

    private var trimmedAction: String {
        actionText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var primaryDomain: LifeDomain {
        intentions.first?.domain ?? selectedDomain
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: primaryDomain.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primaryDomain.moriColor)
                    .frame(width: 34, height: 34)
                    .background(primaryDomain.moriColor.opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(intentions.isEmpty ? "This Week Must Matter" : "This week is being written")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text(intentions.isEmpty ? "Choose one small proof that this square was lived." : "\(intentions.filter(\.isCompleted).count)/\(intentions.count) actions for every day done")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if !intentions.isEmpty {
                VStack(spacing: 10) {
                    ForEach(intentions) { intention in
                        HStack(spacing: 10) {
                            Label(intention.action, systemImage: intention.domain.symbolName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(intention.domain.moriColor)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                intention.isCompleted ? onReopen(intention) : onComplete(intention)
                            } label: {
                                Label(
                                    intention.isCompleted ? "Done" : "Mark done",
                                    systemImage: intention.isCompleted ? "checkmark.circle.fill" : "circle"
                                )
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(intention.isCompleted ? MoriColors.forestCard : MoriColors.forestCanopy)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(intention.isCompleted ? MoriColors.forestCanopy : MoriColors.forestCanopy.opacity(0.08))
                            .clipShape(Capsule())
                            .accessibilityLabel(intention.isCompleted ? "Weekly intention completed" : "Mark weekly intention done")
                        }
                        .padding(12)
                        .background(intention.domain.moriColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                FlowLayout(spacing: 8) {
                    ForEach(LifeDomain.allCases) { domain in
                        Button {
                            selectedDomain = domain
                            actionText = domain.suggestedActions[0]
                        } label: {
                            Label(domain.title, systemImage: domain.symbolName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(selectedDomain == domain ? MoriColors.forestCard : MoriColors.forestMuted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedDomain == domain ? domain.moriColor : MoriColors.forestCanopy.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Menu {
                    ForEach(selectedDomain.suggestedActions, id: \.self) { action in
                        Button(action) {
                            actionText = action
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(trimmedAction.isEmpty ? "Pick a tiny action" : actionText)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(MoriColors.forestCanopy)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MoriColors.forestMuted)
                    }
                    .padding(14)
                    .background(MoriColors.forestPaperDeep.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(action: onSave) {
                    Label(intentions.isEmpty ? "Set weekly proof" : "Add weekly proof", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(trimmedAction.isEmpty ? MoriColors.forestMuted.opacity(0.35) : MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(trimmedAction.isEmpty)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct LifeWeeksCanvasGrid: View {
    let lifeExpectancy: Int
    let weeksLived: Int
    let currentWeekIndex: Int
    let currentWeekDomain: LifeDomain?
    let isCurrentWeekMeaningful: Bool
    let weekTones: [Int: HabitDayTone]
    let dotSize: CGFloat
    let spacing: CGFloat
    let onWeekTap: (Int, Int) -> Void

    var body: some View {
        Canvas { context, _ in
            for year in 0..<lifeExpectancy {
                for week in 0..<52 {
                    let weekIndex = year * 52 + week
                    let rect = dotRect(year: year, week: week)
                    let dotPath = Path(ellipseIn: rect)

                    context.fill(dotPath, with: .color(dotColor(for: weekIndex)))

                    if weekIndex == currentWeekIndex {
                        let ringInset = isCurrentWeekMeaningful ? -2.5 : -1.5
                        let ringRect = rect.insetBy(dx: ringInset, dy: ringInset)
                        let ringPath = Path(ellipseIn: ringRect)
                        let ringColor = (currentWeekDomain?.moriColor ?? MoriColors.forestMoss).opacity(0.95)
                        context.stroke(
                            ringPath,
                            with: .color(ringColor),
                            lineWidth: isCurrentWeekMeaningful ? 2 : 1.5
                        )
                    }
                }
            }
        }
        .frame(width: gridWidth, height: gridHeight)
        .contentShape(Rectangle())
        .gesture(
            SpatialTapGesture(coordinateSpace: .local)
                .onEnded { value in
                    guard let coordinate = weekCoordinate(at: value.location) else { return }
                    onWeekTap(coordinate.year, coordinate.week)
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Life grid")
        .accessibilityValue("\(min(weeksLived, lifeExpectancy * 52)) lived weeks out of \(lifeExpectancy * 52)")
        .accessibilityHint("Tap a lived week to add or view a memory")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            let accessibleWeekIndex = min(max(currentWeekIndex, 0), max(lifeExpectancy * 52 - 1, 0))
            onWeekTap(accessibleWeekIndex / 52, accessibleWeekIndex % 52)
        }
    }

    private var gridWidth: CGFloat {
        CGFloat(52) * dotSize + CGFloat(51) * spacing
    }

    private var gridHeight: CGFloat {
        CGFloat(lifeExpectancy) * dotSize + CGFloat(max(0, lifeExpectancy - 1)) * spacing
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
        guard year >= 0, year < lifeExpectancy, week >= 0, week < 52 else { return nil }

        let dotOriginX = CGFloat(week) * stride
        let dotOriginY = CGFloat(year) * stride
        let hitSlop = max(2, spacing)
        let hitRect = CGRect(
            x: dotOriginX - hitSlop,
            y: dotOriginY - hitSlop,
            width: dotSize + hitSlop * 2,
            height: dotSize + hitSlop * 2
        )
        guard hitRect.contains(location) else { return nil }

        return WeekCoordinate(year: year, week: week)
    }

    private func dotColor(for weekIndex: Int) -> Color {
        if let tone = weekTones[weekIndex] {
            return tone.color
        } else if weekIndex == currentWeekIndex {
            return MoriColors.forestCanopy.opacity(0.78)
        } else if weekIndex < weeksLived {
            return MoriColors.forestCanopy.opacity(0.52)
        } else {
            return MoriColors.forestLine.opacity(0.60)
        }
    }
}

private struct HabitToneLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(HabitDayTone.allCases) { tone in
                HStack(spacing: 6) {
                    Circle()
                        .fill(tone.color)
                        .frame(width: 9, height: 9)

                    Text(tone.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MoriColors.forestMuted)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
    }
}

private struct YearToneGrid: View {
    @Binding var focusedYear: Date
    let entries: [HabitEntry]
    let journalEntries: [GratitudeEntry]
    let onMonthSelected: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PeriodNavigator(
                title: yearFormatter.string(from: focusedYear),
                previousAction: { moveYear(by: -1) },
                nextAction: { moveYear(by: 1) }
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 14)], spacing: 14) {
                ForEach(monthsInFocusedYear, id: \.self) { month in
                    Button {
                        onMonthSelected(month)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(monthFormatter.string(from: month))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(MoriColors.forestMuted)

                            LazyVGrid(columns: columns, spacing: 5) {
                                ForEach(Array(monthCells(for: month).enumerated()), id: \.offset) { _, day in
                                    if let day {
                                        DayToneSquare(
                                            date: day,
                                            tone: tone(for: day),
                                            size: 10,
                                            hasJournal: journalEntry(for: day) != nil
                                        )
                                    } else {
                                        Color.clear
                                            .frame(height: 10)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
                        .background(MoriColors.forestCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MoriColors.forestHairline, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var monthsInFocusedYear: [Date] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: focusedYear)
        return (1...12).compactMap { month in
            calendar.date(from: DateComponents(year: year, month: month, day: 1))
        }
    }

    private func monthCells(for month: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let range = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        let days = range.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: interval.start)
        }
        let cells = Array(repeating: nil, count: leadingBlanks) + days.map(Optional.some)
        return cells + Array(repeating: nil, count: max(0, 42 - cells.count))
    }

    private func tone(for date: Date) -> HabitDayTone? {
        let calendar = Calendar.current
        return entries.first { calendar.isDate($0.date, inSameDayAs: date) }?.tone
    }

    private func journalEntry(for date: Date) -> GratitudeEntry? {
        let calendar = Calendar.current
        return preferredJournalEntry(on: date, in: journalEntries, calendar: calendar)
    }

    private func moveYear(by value: Int) {
        focusedYear = Calendar.current.date(byAdding: .year, value: value, to: focusedYear) ?? focusedYear
    }
}

private struct MonthToneGrid: View {
    @Binding var focusedMonth: Date
    let entries: [HabitEntry]
    let journalEntries: [GratitudeEntry]
    let onDaySelected: (MonthDaySelection) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = max(0, min(symbols.count - 1, calendar.firstWeekday - 1))
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PeriodNavigator(
                title: monthFormatter.string(from: focusedMonth),
                previousAction: { moveMonth(by: -1) },
                nextAction: { moveMonth(by: 1) }
            )

            VStack(spacing: 10) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(String(symbol.prefix(1)))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(MoriColors.forestMuted)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                        if let date {
                            let journalEntry = journalEntry(for: date)
                            let habitEntry = habitEntry(for: date)
                            Button {
                                onDaySelected(
                                    MonthDaySelection(
                                        date: date,
                                        habitEntry: habitEntry,
                                        journalEntry: journalEntry
                                    )
                                )
                            } label: {
                                DayToneSquare(
                                    date: date,
                                    tone: habitEntry?.tone,
                                    size: 34,
                                    hasJournal: journalEntry != nil,
                                    hasPatternLog: habitEntry?.hasPatternLog == true
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(journalEntry == nil && habitEntry == nil)
                        } else {
                            Color.clear
                                .frame(height: 34)
                        }
                    }
                }
            }
            .padding(16)
            .background(MoriColors.forestCard)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MoriColors.forestHairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            MonthGridLegend()
        }
    }

    private var monthCells: [Date?] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: focusedMonth),
              let dayRange = calendar.range(of: .day, in: .month, for: focusedMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        let days = dayRange.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: interval.start)
        }

        return Array(repeating: nil, count: leadingBlanks) + days.map(Optional.some)
    }

    private func habitEntry(for date: Date) -> HabitEntry? {
        let calendar = Calendar.current
        return entries.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func journalEntry(for date: Date) -> GratitudeEntry? {
        let calendar = Calendar.current
        return preferredJournalEntry(on: date, in: journalEntries, calendar: calendar)
    }

    private func moveMonth(by value: Int) {
        focusedMonth = Calendar.current.date(byAdding: .month, value: value, to: focusedMonth) ?? focusedMonth
    }
}

private struct DayToneSquare: View {
    let date: Date
    let tone: HabitDayTone?
    let size: CGFloat
    var hasJournal: Bool = false
    var hasPatternLog: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: min(7, size * 0.22), style: .continuous)
            .fill(tone?.color ?? MoriColors.forestLine.opacity(0.58))
            .frame(height: size)
            .overlay(
                RoundedRectangle(cornerRadius: min(7, size * 0.22), style: .continuous)
                    .stroke(isToday ? MoriColors.forestMoss : Color.clear, lineWidth: 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if hasJournal {
                    Circle()
                        .fill(MoriColors.forestCanopy)
                        .frame(width: max(4, size * 0.18), height: max(4, size * 0.18))
                        .padding(max(2, size * 0.08))
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if hasPatternLog {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(MoriColors.forestSeed)
                        .frame(width: max(8, size * 0.28), height: max(3, size * 0.1))
                        .padding(max(2, size * 0.08))
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(accessibilityLabel)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let toneText = tone?.title ?? "No check-in"
        let journalText = hasJournal ? ", journal entry available" : ""
        let patternText = hasPatternLog ? ", pattern log available" : ""
        return "\(formatter.string(from: date)), \(toneText)\(journalText)\(patternText)"
    }
}

private struct MonthGridLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                Circle()
                    .fill(MoriColors.forestCanopy)
                    .frame(width: 7, height: 7)

                Text("Journal")
            }

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(MoriColors.forestSeed)
                    .frame(width: 12, height: 4)

                Text("Pattern Log")
            }

            Spacer(minLength: 0)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(MoriColors.forestMuted)
        .padding(.horizontal, 2)
    }
}

private struct MonthDaySelection: Identifiable {
    let id: String
    let date: Date
    let habitEntry: HabitEntry?
    let journalEntry: GratitudeEntry?

    init(date: Date, habitEntry: HabitEntry?, journalEntry: GratitudeEntry?) {
        self.date = date
        self.habitEntry = habitEntry
        self.journalEntry = journalEntry
        self.id = Self.id(for: date)
    }

    private static func id(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}

private struct MonthDayDetailSheet: View {
    let selection: MonthDaySelection
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dateFormatter.string(from: selection.date))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.forestCanopy)
                            .fixedSize(horizontal: false, vertical: true)

                        if let tone = selection.habitEntry?.tone {
                            Label("\(tone.title) day", systemImage: tone.symbolName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(tone.color)
                        }
                    }

                    if let habitEntry = selection.habitEntry, habitEntry.hasPatternLog {
                        PatternLogSummaryCard(entry: habitEntry)
                    }

                    if let habitEntry = selection.habitEntry,
                       let note = habitEntry.note?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !note.isEmpty {
                        HabitNoteSummaryCard(note: note)
                    }

                    if let journalEntry = selection.journalEntry {
                        JournalSummaryCard(entry: journalEntry)
                    }
                }
                .padding(24)
            }
            .background(MoriColors.forestPaper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MoriColors.forestCanopy)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private extension HabitDayTone {
    var symbolName: String {
        switch self {
        case .positive: return "plus.circle.fill"
        case .neutral: return "equal.circle.fill"
        case .negative: return "minus.circle.fill"
        }
    }
}

private struct PatternLogSummaryCard: View {
    let entry: HabitEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Pattern Log", systemImage: "arrow.triangle.2.circlepath")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestMoss)

            PatternLogRow(title: "Trigger", value: entry.trigger)
            PatternLogRow(title: "Thought", value: entry.thought)
            PatternLogRow(title: "Feeling", value: entry.feeling)
            PatternLogRow(title: "Next response", value: entry.responsePlan)
        }
        .padding(16)
        .background(MoriColors.forestCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.forestHairline, lineWidth: 1)
        )
    }
}

private struct PatternLogRow: View {
    let title: String
    let value: String?

    var body: some View {
        if let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MoriColors.forestMuted)

                Text(value)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.forestCanopy)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HabitNoteSummaryCard: View {
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Day Note", systemImage: "note.text")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)

            Text(note)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.forestCanopy)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(MoriColors.forestCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.forestHairline, lineWidth: 1)
        )
    }
}

private struct JournalSummaryCard: View {
    let entry: GratitudeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(entry.sourceLabel, systemImage: entry.sourceSymbolName)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)

            Text(entry.displayContent)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.forestCanopy)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(MoriColors.forestCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.forestHairline, lineWidth: 1)
        )
    }
}

private func preferredJournalEntry(
    on date: Date,
    in entries: [GratitudeEntry],
    calendar: Calendar
) -> GratitudeEntry? {
    entries
        .filter { calendar.isDate($0.date, inSameDayAs: date) }
        .sorted { lhs, rhs in
            let lhsPriority = journalEntryPriority(lhs)
            let rhsPriority = journalEntryPriority(rhs)

            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }

            return lhs.updatedAt > rhs.updatedAt
        }
        .first
}

private func journalEntryPriority(_ entry: GratitudeEntry) -> Int {
    switch entry.sourceKind {
    case .journal: return 0
    case .dayLog: return 1
    case .dailySpark: return 2
    case .weeklyIntention: return 3
    }
}

private struct PeriodNavigator: View {
    let title: String
    let previousAction: () -> Void
    let nextAction: () -> Void

    var body: some View {
        HStack {
            Button(action: previousAction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundColor(MoriColors.forestCanopy)

            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestCanopy)
                .frame(maxWidth: .infinity)

            Button(action: nextAction) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundColor(MoriColors.forestCanopy)
        }
    }
}

private extension LifeDomain {
    var moriColor: Color {
        switch self {
        case .body: return MoriColors.forestFern
        case .mind: return MoriColors.forestMist
        case .love: return MoriColors.forestClay
        case .craft: return MoriColors.forestSeed
        case .courage: return MoriColors.forestRoot
        case .service: return MoriColors.forestSage
        case .wonder: return MoriColors.morningGold
        case .rest: return MoriColors.forestMuted
        }
    }
}

// MARK: - Week Coordinate
struct WeekCoordinate: Equatable {
    let year: Int
    let week: Int

    var linearIndex: Int {
        year * 52 + week
    }
}

// MARK: - Week Detail Sheet
struct WeekDetailSheet: View {
    let week: WeekCoordinate
    let settings: UserSettings
    let habitEntries: [HabitEntry]
    let journalEntries: [GratitudeEntry]
    @Binding var isPresented: Bool
    
    @State private var memoryText: String = ""
    @State private var isEditing: Bool = false
    @State private var existingNote: String?
    @State private var weekID: UUID?
    @State private var showSaveSuccess: Bool = false
    
    private let store = LifeWeekStore.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
    
    private var weekDate: Date {
        moriMondayWeekStart(for: week, birthDate: settings.birthDate)
    }
    
    private var dateRangeText: String {
        let start = weekDate
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekDate) ?? weekDate
        return "\(dateFormatter.string(from: start))-\(dateFormatter.string(from: end)), age \(week.year)"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Week info
                    VStack(spacing: 8) {
                        Text("Week \(week.week + 1), Age \(week.year)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(MoriColors.forestCanopy)

                        Text(dateRangeText)
                            .font(.subheadline)
                            .foregroundColor(MoriColors.forestMuted)
                    }
                    .padding(.top)

                    if hasWeekActivity {
                        WeekActivitySection(
                            habitEntries: habitEntries,
                            journalEntries: journalEntries
                        )
                        .padding(.horizontal)
                    }
                    
                    // Memory section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(MoriColors.forestMoss)
                            Text("Memory from this week")
                                .font(.headline)
                                .foregroundColor(MoriColors.forestCanopy)
                            Spacer()
                            if existingNote != nil && !isEditing {
                                Button("Edit") {
                                    isEditing = true
                                }
                                .font(.subheadline)
                                .foregroundColor(MoriColors.forestCanopy)
                            }
                        }
                        
                        if isEditing || existingNote == nil {
                            TextEditor(text: $memoryText)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(MoriColors.forestCard)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(MoriColors.forestHairline, lineWidth: 1)
                                )
                                .foregroundColor(MoriColors.forestCanopy)
                                .scrollContentBackground(.hidden)
                            
                            Button(action: saveMemory) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Memory")
                                }
                                .font(.headline)
                                .foregroundColor(MoriColors.forestCard)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(memoryText.isEmpty ? MoriColors.forestMuted.opacity(0.35) : MoriColors.forestCanopy)
                                .cornerRadius(12)
                            }
                            .disabled(memoryText.isEmpty)
                        } else {
                            Text(existingNote ?? "")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(MoriColors.forestCanopy)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(MoriColors.forestCard)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Reflection prompts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reflection prompts")
                            .font(.headline)
                            .foregroundColor(MoriColors.forestMuted)
                            .padding(.horizontal)
                        
                        ForEach(reflectionPrompts, id: \.self) { prompt in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(MoriColors.forestSeed)
                                    .font(.system(size: 16))
                                Text(prompt)
                                    .font(.subheadline)
                                    .foregroundColor(MoriColors.forestMuted)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(MoriColors.forestPaper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(MoriColors.forestCanopy)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        dismissKeyboard()
                    }
                    .foregroundColor(MoriColors.forestCanopy)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear(perform: loadExistingNote)
    }
    
    private var reflectionPrompts: [String] {
        if week.year + settings.age < 10 {
            return [
                "What surprised you this week?",
                "What did you learn for the first time?",
                "What made you feel light?"
            ]
        } else if week.year < 30 {
            return [
                "What did this week teach you?",
                "What was hard, and how did you meet it?",
                "What do you want next week to remember?"
            ]
        } else {
            return [
                "What are you most grateful for this week?",
                "Which moment deserves to be kept?",
                "What would you like to leave behind?"
            ]
        }
    }
    
    private func loadExistingNote() {
        guard let userID = UserManager.shared.currentUser?.id else { return }
        if let lifeWeek = store.fetchWeek(userID: userID, yearIndex: week.year, weekIndex: week.week) {
            existingNote = lifeWeek.note
            memoryText = lifeWeek.note ?? ""
            weekID = lifeWeek.id
        }
    }
    
    private func saveMemory() {
        dismissKeyboard()

        guard let userID = UserManager.shared.currentUser?.id else { return }
        
        let trimmed = memoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let id = weekID {
            store.updateNote(weekID: id, note: trimmed)
        } else {
            // Create a new LifeWeek with the note
            let calendar = Calendar.current
            let startDate = moriMondayWeekStart(for: week, birthDate: settings.birthDate)
            let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
            
            let newWeek = LifeWeek(
                weekIndex: week.week,
                yearIndex: week.year,
                weekOfYear: week.week + 1,
                startDate: startDate,
                endDate: endDate,
                isLived: week.year * 52 + week.week < settings.weeksLived,
                note: trimmed
            )
            store.saveWeek(newWeek, userID: userID)
        }
        
        existingNote = trimmed
        isEditing = false
        showSaveSuccess = true
        
        // Auto-dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private var hasWeekActivity: Bool {
        !habitEntries.isEmpty || !journalEntries.isEmpty
    }
}

private struct WeekActivitySection: View {
    let habitEntries: [HabitEntry]
    let journalEntries: [GratitudeEntry]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Already captured this week", systemImage: "sparkles")
                .font(.headline)
                .foregroundColor(MoriColors.forestMoss)

            ForEach(journalEntries.prefix(4)) { entry in
                WeekActivityRow(
                    symbolName: entry.sourceSymbolName,
                    tint: entry.photoAttachments.isEmpty ? MoriColors.forestCanopy : MoriColors.forestMist,
                    title: entry.sourceLabel,
                    subtitle: dateFormatter.string(from: entry.date),
                    bodyText: entry.displayContent
                )
            }

            ForEach(habitEntries.filter(\.hasPatternLog).prefix(3)) { entry in
                WeekActivityRow(
                    symbolName: "arrow.triangle.2.circlepath",
                    tint: MoriColors.forestSeed,
                    title: "Pattern Log",
                    subtitle: "\(dateFormatter.string(from: entry.date)) · \(entry.tone.title)",
                    bodyText: patternSummary(for: entry)
                )
            }

            let noteEntries = habitEntries.filter { entry in
                entry.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && !entry.hasPatternLog
            }

            ForEach(noteEntries.prefix(3)) { entry in
                WeekActivityRow(
                    symbolName: "note.text",
                    tint: entry.tone.color,
                    title: "\(entry.tone.title) day",
                    subtitle: dateFormatter.string(from: entry.date),
                    bodyText: entry.note ?? ""
                )
            }
        }
        .padding(16)
        .background(MoriColors.forestCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.forestHairline, lineWidth: 1)
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

private struct WeekActivityRow: View {
    let symbolName: String
    let tint: Color
    let title: String
    let subtitle: String
    let bodyText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MoriColors.forestMuted)
                }

                Text(bodyText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    LifeGridView()
        .environmentObject(UserSettings())
}
