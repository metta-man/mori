import SwiftUI
import CoreData
import UIKit

struct LifeGridView: View {
    @EnvironmentObject var settings: UserSettings
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
    @State private var selectedMonthDay: MonthDaySelection?
    
    private let weekColumns = 52
    private let ageLabelWidth: CGFloat = 28
    private let weekGap: CGFloat = 1.6
    
    var body: some View {
        NavigationStack {
            ZStack {
                MoriColors.moriDark.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        LifeGridHeader(
                            weeksLived: settings.weeksLived,
                            totalWeeks: settings.totalWeeks,
                            weeksRemaining: settings.weeksRemaining
                        )

                        WeeklyIntentionCard(
                            intentions: settings.activeWeeklyIntentions,
                            selectedDomain: $draftDomain,
                            actionText: $draftAction,
                            onSave: {
                                settings.setWeeklyIntention(domain: draftDomain, action: draftAction)
                            },
                            onComplete: { intention in
                                settings.completeWeeklyIntention(intention)
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
                        .tint(MoriColors.moriGold)

                        gridContent

                        HabitToneLegend()

                        Text(selectedView.helperText)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(MoriColors.moriCreamMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Mori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(MoriColors.moriDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(MoriColors.moriGold.opacity(0.8))
                    }
                }
            }
            .sheet(isPresented: $showWeekDetail) {
                if let week = selectedWeek {
                    WeekDetailSheet(
                        week: week,
                        settings: settings,
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

                    LifeWeeksGrid(
                        lifeExpectancy: settings.lifeExpectancy,
                        weeksLived: settings.weeksLived,
                        currentWeekIndex: settings.currentWeekIndex,
                        currentWeekDomain: settings.activeWeeklyIntentionDomain,
                        isCurrentWeekMeaningful: settings.hasCompletedWeeklyIntention,
                        weekTones: weekToneMap,
                        dotSize: dotSize,
                        spacing: weekGap,
                        onWeekTap: handleWeekTap
                    )
                }
                .padding(16)
                .background(MoriColors.moriDarkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(MoriColors.moriHairline, lineWidth: 1)
                )
                .cornerRadius(18)
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

    private var weekToneMap: [Int: HabitDayTone] {
        var tones: [Int: [HabitDayTone]] = [:]

        for entry in habitEntries {
            guard let weekIndex = visualWeekIndex(for: entry.date) else { continue }
            tones[weekIndex, default: []].append(entry.tone)
        }

        return tones.compactMapValues { majorityTone(in: $0) }
    }

    private func gridHeight(for lifeExpectancy: Int) -> CGFloat {
        let estimatedDotSize: CGFloat = 4.5
        let chrome: CGFloat = 32
        return CGFloat(lifeExpectancy) * (estimatedDotSize + weekGap) + chrome
    }
    
    private func handleWeekTap(year: Int, week: Int) {
        let weekIndex = year * 52 + week
        
        // Don't allow tapping future weeks
        if weekIndex >= settings.weeksLived {
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
    }

    private func loadJournalEntries() {
        journalEntries = GratitudeEntry.loadAllStored()
    }

    private func visualWeekIndex(for date: Date) -> Int? {
        let calendar = Calendar.current
        let birthDay = calendar.startOfDay(for: settings.birthDate)
        let entryDay = calendar.startOfDay(for: date)
        guard entryDay >= birthDay else { return nil }

        let ageAtEntry = calendar.dateComponents([.year], from: birthDay, to: entryDay).year ?? 0
        guard ageAtEntry < settings.lifeExpectancy else { return nil }

        let ageStart = calendar.date(byAdding: .year, value: ageAtEntry, to: birthDay) ?? birthDay
        let daysIntoAgeYear = calendar.dateComponents([.day], from: ageStart, to: entryDay).day ?? 0
        let weekIntoAgeYear = max(0, min(51, daysIntoAgeYear / 7))

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
            return "Each dot is one week. Colored lived weeks use the majority tone from daily check-ins."
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
                        .foregroundColor(MoriColors.moriCreamMuted)
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
                .foregroundColor(MoriColors.moriCream)

            Text("\(weeksRemaining.formatted()) weeks remaining")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(MoriColors.moriGold)

            ProgressView(value: Double(weeksLived), total: Double(max(totalWeeks, 1)))
                .tint(MoriColors.moriGold)
                .background(MoriColors.moriCream.opacity(0.12))
                .clipShape(Capsule())
        }
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
                        .foregroundColor(MoriColors.moriCream)

                    Text(intentions.isEmpty ? "Choose one small proof that this square was lived." : "\(intentions.filter(\.isCompleted).count)/\(intentions.count) actions for every day done")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.moriCreamMuted)
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
                            .foregroundColor(intention.isCompleted ? MoriColors.moriDark : MoriColors.moriGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(intention.isCompleted ? MoriColors.moriGold : MoriColors.moriDarkElevated)
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
                                .foregroundColor(selectedDomain == domain ? MoriColors.moriDark : MoriColors.moriCreamMuted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedDomain == domain ? domain.moriColor : MoriColors.moriDarkElevated)
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
                            .foregroundColor(MoriColors.moriCream)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MoriColors.moriCreamMuted)
                    }
                    .padding(14)
                    .background(MoriColors.moriDarkElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(action: onSave) {
                    Label(intentions.isEmpty ? "Set weekly proof" : "Add weekly proof", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.moriDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(trimmedAction.isEmpty ? MoriColors.moriCreamMuted.opacity(0.45) : MoriColors.moriGold)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(trimmedAction.isEmpty)
            }
        }
        .padding(18)
        .background(MoriColors.moriDarkSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(MoriColors.moriHairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct LifeWeeksGrid: View {
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
        VStack(spacing: spacing) {
            ForEach(0..<lifeExpectancy, id: \.self) { year in
                HStack(spacing: spacing) {
                    ForEach(0..<52, id: \.self) { week in
                        let weekIndex = year * 52 + week
                        WeekSquare(
                            year: year,
                            week: week,
                            size: dotSize,
                            isPast: weekIndex < weeksLived,
                            isCurrent: weekIndex == currentWeekIndex,
                            currentWeekDomain: currentWeekDomain,
                            tone: weekTones[weekIndex],
                            isMeaningful: weekIndex == currentWeekIndex && isCurrentWeekMeaningful
                        )
                        .onTapGesture {
                            onWeekTap(year, week)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Week Square
struct WeekSquare: View {
    let year: Int
    let week: Int
    let size: CGFloat
    let isPast: Bool
    let isCurrent: Bool
    let currentWeekDomain: LifeDomain?
    let tone: HabitDayTone?
    let isMeaningful: Bool
    
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            Circle()
                .fill(squareColor)
                .frame(width: size, height: size)
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .frame(width: size, height: size)
        .overlay {
            if isCurrent {
                Circle()
                    .stroke((currentWeekDomain?.moriColor ?? MoriColors.moriGold).opacity(0.95), lineWidth: isMeaningful ? 2 : 1.5)
                    .frame(width: size + (isMeaningful ? 5 : 3), height: size + (isMeaningful ? 5 : 3))
                    .opacity(reduceMotion ? 1 : 0.85)
                    .animation(
                        reduceMotion ? .none :
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isCurrent
                    )
                    .allowsHitTesting(false)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to add memory")
    }
    
    private var squareColor: Color {
        if let tone {
            return tone.color
        } else if isCurrent {
            return currentWeekDomain?.moriColor ?? MoriColors.moriGold
        } else if isPast {
            return MoriColors.moriCream.opacity(0.74)
        } else {
            return MoriColors.moriCream.opacity(0.13)
        }
    }
    
    private var accessibilityLabel: String {
        if isCurrent {
            return "Current week, week \(week + 1) of age \(year)"
        } else if isPast {
            return "Lived week \(week + 1) of age \(year)"
        } else {
            return "Future week \(week + 1) of age \(year)"
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
                        .foregroundColor(MoriColors.moriCreamMuted)
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
                                .foregroundColor(MoriColors.moriCreamMuted)

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
                        .background(MoriColors.moriDarkSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MoriColors.moriHairline, lineWidth: 1)
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
    private let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols

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
                            .foregroundColor(MoriColors.moriCreamMuted)
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
                            .disabled(journalEntry == nil && habitEntry?.hasPatternLog != true)
                        } else {
                            Color.clear
                                .frame(height: 34)
                        }
                    }
                }
            }
            .padding(16)
            .background(MoriColors.moriDarkSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MoriColors.moriHairline, lineWidth: 1)
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
            .fill(tone?.color ?? MoriColors.moriCream.opacity(0.12))
            .frame(height: size)
            .overlay(
                RoundedRectangle(cornerRadius: min(7, size * 0.22), style: .continuous)
                    .stroke(isToday ? MoriColors.moriGold : Color.clear, lineWidth: 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if hasJournal {
                    Circle()
                        .fill(MoriColors.moriCream)
                        .frame(width: max(4, size * 0.18), height: max(4, size * 0.18))
                        .padding(max(2, size * 0.08))
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if hasPatternLog {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(MoriColors.moriGold)
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
                    .fill(MoriColors.moriCream)
                    .frame(width: 7, height: 7)

                Text("Journal")
            }

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(MoriColors.moriGold)
                    .frame(width: 12, height: 4)

                Text("Pattern Log")
            }

            Spacer(minLength: 0)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(MoriColors.moriCreamMuted)
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
                            .foregroundColor(MoriColors.moriCream)
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

                    if let journalEntry = selection.journalEntry {
                        JournalSummaryCard(entry: journalEntry)
                    }
                }
                .padding(24)
            }
            .background(MoriColors.moriDark.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(MoriColors.moriDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MoriColors.moriGold)
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
                .foregroundColor(MoriColors.moriGold)

            PatternLogRow(title: "Trigger", value: entry.trigger)
            PatternLogRow(title: "Thought", value: entry.thought)
            PatternLogRow(title: "Feeling", value: entry.feeling)
            PatternLogRow(title: "Next response", value: entry.responsePlan)
        }
        .padding(16)
        .background(MoriColors.moriDarkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.moriHairline, lineWidth: 1)
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
                    .foregroundColor(MoriColors.moriCreamMuted)

                Text(value)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(MoriColors.moriCream)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct JournalSummaryCard: View {
    let entry: GratitudeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(entry.sourceLabel, systemImage: entry.sourceSymbolName)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.moriCream)

            Text(entry.displayContent)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.moriCream)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(MoriColors.moriDarkSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MoriColors.moriHairline, lineWidth: 1)
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
    case .dailySpark: return 1
    case .weeklyIntention: return 2
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
            .foregroundColor(MoriColors.moriGold)

            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.moriCream)
                .frame(maxWidth: .infinity)

            Button(action: nextAction) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundColor(MoriColors.moriGold)
        }
    }
}

private extension LifeDomain {
    var moriColor: Color {
        switch self {
        case .body: return MoriColors.sageGreen
        case .mind: return MoriColors.mistBlue
        case .love: return MoriColors.warmClay
        case .craft: return MoriColors.moriGold
        case .courage: return MoriColors.emberOrange
        case .service: return MoriColors.softSage
        case .wonder: return MoriColors.morningGold
        case .rest: return MoriColors.softTaupe
        }
    }
}

// MARK: - Week Coordinate
struct WeekCoordinate: Equatable {
    let year: Int
    let week: Int
}

// MARK: - Week Detail Sheet
struct WeekDetailSheet: View {
    let week: WeekCoordinate
    let settings: UserSettings
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
        let calendar = Calendar.current
        let birthDate = settings.birthDate
        let daysOffset = (week.year * 52 + week.week) * 7
        return calendar.date(byAdding: .day, value: daysOffset, to: birthDate) ?? birthDate
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
                            .foregroundColor(MoriColors.moriCream)
                        
                        Text(dateRangeText)
                            .font(.subheadline)
                            .foregroundColor(MoriColors.moriCreamMuted)
                    }
                    .padding(.top)
                    
                    // Memory section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(MoriColors.moriGold)
                            Text("Memory from this week")
                                .font(.headline)
                                .foregroundColor(MoriColors.moriCream)
                            Spacer()
                            if existingNote != nil && !isEditing {
                                Button("Edit") {
                                    isEditing = true
                                }
                                .font(.subheadline)
                                .foregroundColor(MoriColors.moriGold)
                            }
                        }
                        
                        if isEditing || existingNote == nil {
                            TextEditor(text: $memoryText)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(MoriColors.moriDarkSurface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(MoriColors.moriHairline, lineWidth: 1)
                                )
                                .foregroundColor(MoriColors.moriCream)
                                .scrollContentBackground(.hidden)
                            
                            Button(action: saveMemory) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Memory")
                                }
                                .font(.headline)
                                .foregroundColor(MoriColors.moriDark)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(memoryText.isEmpty ? MoriColors.moriCreamMuted.opacity(0.45) : MoriColors.moriGold)
                                .cornerRadius(12)
                            }
                            .disabled(memoryText.isEmpty)
                        } else {
                            Text(existingNote ?? "")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundColor(MoriColors.moriCream)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(MoriColors.moriDarkSurface)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Reflection prompts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reflection prompts")
                            .font(.headline)
                            .foregroundColor(MoriColors.moriCreamMuted)
                            .padding(.horizontal)
                        
                        ForEach(reflectionPrompts, id: \.self) { prompt in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(MoriColors.morningGold)
                                    .font(.system(size: 16))
                                Text(prompt)
                                    .font(.subheadline)
                                    .foregroundColor(MoriColors.moriCreamMuted)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(MoriColors.moriDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(MoriColors.moriDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(MoriColors.moriGold)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        dismissKeyboard()
                    }
                    .foregroundColor(MoriColors.moriGold)
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
            let birthDate = settings.birthDate
            let startDate = calendar.date(byAdding: .day, value: week.week * 7, to: birthDate) ?? birthDate
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
}

#Preview {
    LifeGridView()
        .environmentObject(UserSettings())
}
