import SwiftUI

struct TodayView: View {
    var onOpenSettle: () -> Void = {}

    @EnvironmentObject var settings: UserSettings
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var settleStore = SettleSessionStore.shared
    @StateObject private var dailySparkStore = DailySparkStore.shared
    @State private var pulse: MoriDailyPulse = .mock()
    @State private var isLoadingPulse = false
    @State private var activePracticeSheet: MoriPracticeSheet?

    private var metrics: MoriClarityMetrics {
        clarityStore.metrics(settings: settings)
    }

    var body: some View {
        NavigationStack {
            MoriForestBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        MoriPageHeader(
                            eyebrow: "Today",
                            title: "Mori",
                            subtitle: "Reclaim attention from the internet and grow the life you actually want."
                        )

                        TodayClarityHero(metrics: metrics)

                        TodaySettleRecommendation(
                            recommendedMinutes: settleStore.recommendedDurationMinutes(),
                            summary: settleStore.weeklySummary(),
                            onOpenSettle: onOpenSettle
                        )

                        TodayPulsePreview(
                            pulse: pulse,
                            isLoading: isLoadingPulse,
                            onOpenSettle: onOpenSettle,
                            onRefresh: {
                                Task { await loadPulse(force: true) }
                            }
                        )

                        TodaySeedLauncher(
                            suggestedPractice: clarityStore.suggestedPracticeForToday(),
                            onOpenPracticePicker: {
                                activePracticeSheet = .selection
                            }
                        )

                        TodayLifeGridBridge(
                            metrics: metrics,
                            domainScores: clarityStore.nourishedDomains(),
                            suggestedPractice: clarityStore.suggestedPracticeForToday(),
                            onOpenPracticePicker: {
                                activePracticeSheet = .selection
                            }
                        )

                        TodayPracticeGarden(
                            onOpenSettle: onOpenSettle,
                            onComplete: completePractice
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .task {
                await loadPulse(force: false)
            }
            .sheet(item: $activePracticeSheet) { sheet in
                switch sheet {
                case .selection:
                    MoriPracticeSelectionSheet(
                        title: "Ways to Plant Seeds",
                        subtitle: "Choose one small practice. Each Seed nourishes part of your Life Grid.",
                        practices: MoriPractice.plantSeedChoices,
                        onComplete: completePractice
                    )
                case .completion(let practice):
                    MoriPracticeCompletionSheet(practice: practice)
                }
            }
        }
    }

    private func loadPulse(force: Bool) async {
        if !force,
           let latest = clarityStore.latestPulse,
           latest.dateKey == MoriDateKey.value() {
            pulse = latest
            return
        }

        isLoadingPulse = true
        let generated = await MoriPulseService.shared.generateDailyPulse(
            userContext: clarityStore.userContext(settings: settings),
            topics: clarityStore.selectedTopicLabels,
            recentInputs: summarizedRecentInputs
        )
        clarityStore.savePulse(generated)
        pulse = generated
        isLoadingPulse = false
    }

    private var summarizedRecentInputs: [String] {
        var inputs: [String] = []

        if dailySparkStore.todayEntry != nil {
            inputs.append("Daily focus has been set.")
        }

        if settings.hasCompletedWeeklyIntention {
            inputs.append("The weekly Life Grid proof is complete.")
        }

        if metrics.quietMinutesToday > 0 {
            inputs.append("\(metrics.quietMinutesToday) quiet minutes logged today.")
        }

        return inputs
    }

    private func completePractice(_ practice: MoriPractice) {
        clarityStore.recordPractice(practice)
        activePracticeSheet = .completion(practice)
    }
}

enum MoriPracticeSheet: Identifiable {
    case selection
    case completion(MoriPractice)

    var id: String {
        switch self {
        case .selection:
            return "selection"
        case .completion(let practice):
            return "completion-\(practice.id)"
        }
    }
}

private struct TodayClarityHero: View {
    let metrics: MoriClarityMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Clarity Score")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.forestMuted)

                    Text("\(metrics.clarityScore)")
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                        .monospacedDigit()

                    Text("Daily attention and calm")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(MoriColors.forestLine.opacity(0.7), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(max(0, min(100, metrics.clarityScore))) / 100)
                        .stroke(MoriColors.forestMoss, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(MoriColors.forestMoss)
                }
                .frame(width: 92, height: 92)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MoriMetricTile(
                    title: "Seeds",
                    value: "\(metrics.seedsToday)",
                    detail: "mindful actions",
                    symbolName: "circle.hexagongrid.fill",
                    tint: MoriColors.forestSeed
                )

                MoriMetricTile(
                    title: "Bloom",
                    value: metrics.bloomPercentText,
                    detail: "growth today",
                    symbolName: "camera.macro",
                    tint: MoriColors.forestFern
                )
            }
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }
}

private struct TodayPulsePreview: View {
    let pulse: MoriDailyPulse
    let isLoading: Bool
    let onOpenSettle: () -> Void
    let onRefresh: () -> Void

    private var previewCard: MoriPulseCard? {
        pulse.cards.first { $0.kind == .worthKnowing } ?? pulse.cards.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                MoriSectionTitle(
                    title: "Mori Pulse",
                    subtitle: "A brief signal check before the internet gets loud."
                )

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: isLoading ? "hourglass" : "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                        .frame(width: 34, height: 34)
                        .background(MoriColors.forestCanopy.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh Mori Pulse")
            }

            if let previewCard {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: previewCard.kind.symbolName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(MoriColors.forestMoss)
                        .frame(width: 36, height: 36)
                        .background(MoriColors.forestMoss.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(previewCard.kind.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MoriColors.forestMoss)

                        Text(previewCard.headline)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.forestCanopy)

                        Text(previewCard.body)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(MoriColors.forestMuted)
                            .lineLimit(3)
                    }
                }
            }

            HStack(spacing: 10) {
                MoriPill(title: "\(pulse.reclaimedMinutes) min reclaimed", symbolName: "clock", tint: MoriColors.forestMist)

                if pulse.isMock {
                    MoriPill(title: "mock fallback", symbolName: "wand.and.stars", tint: MoriColors.forestClay)
                }

                Spacer()
            }

            NavigationLink(destination: ClarityPulseView(onOpenSettle: onOpenSettle)) {
                Label("Open full Pulse", systemImage: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCard)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(MoriColors.forestCanopy)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct TodaySettleRecommendation: View {
    let recommendedMinutes: Int
    let summary: SettleWeeklySummary
    let onOpenSettle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MoriColors.forestMoss)
                    .frame(width: 38, height: 38)
                    .background(MoriColors.forestMoss.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Settle Practice")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.forestMoss)

                    Text("\(recommendedMinutes) minutes before the feed")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(copy)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                MoriPill(
                    title: "\(summary.completedSessions) this week",
                    symbolName: "chart.bar.fill",
                    tint: MoriColors.forestRoot
                )

                MoriPill(
                    title: "\(summary.totalMinutes)m settled",
                    symbolName: "timer",
                    tint: MoriColors.forestMist
                )

                Spacer(minLength: 0)
            }

            Button(action: onOpenSettle) {
                Label("Open Settle", systemImage: "leaf.arrow.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCard)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(MoriColors.forestCanopy)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var copy: String {
        if summary.completedSessions == 0 {
            return "Start small. Let one quiet sit become the first Seed of the day."
        }

        if summary.consistencyDays >= 4 {
            return "Your Roots are taking. Keep the practice spacious and steady."
        }

        return "A short sit can turn the next scroll into a choice."
    }
}

private struct TodaySeedLauncher: View {
    let suggestedPractice: MoriPractice
    let onOpenPracticePicker: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Plant a Seed",
                subtitle: "Start with a real practice. Seeds grow through breath, focus, rest, reflection, and check-ins."
            )

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: suggestedPractice.symbolName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MoriColors.forestMoss)
                    .frame(width: 36, height: 36)
                    .background(MoriColors.forestMoss.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Suggested Seed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.forestMoss)

                    Text(suggestedPractice.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text("\(suggestedPractice.description) - nourishes \(suggestedPractice.domainText)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(suggestedPractice.seedText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.forestRoot)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(MoriColors.forestSeed.opacity(0.20))
                    .clipShape(Capsule())
            }
            .padding(12)
            .background(MoriColors.forestPaperDeep.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: onOpenPracticePicker) {
                Label("Choose a practice", systemImage: "leaf.arrow.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCard)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(MoriColors.forestCanopy)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct TodayLifeGridBridge: View {
    let metrics: MoriClarityMetrics
    let domainScores: [LifeDomain: Int]
    let suggestedPractice: MoriPractice
    let onOpenPracticePicker: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Life Grid is the center",
                subtitle: "Every Seed nourishes one part of your life."
            )

            MoriLifeGridNodePreview(domainScores: domainScores)

            VStack(alignment: .leading, spacing: 8) {
                Text("Today, \(suggestedPractice.domains.first?.title ?? "Rest") needs care.")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.forestCanopy)

                Text("\(suggestedPractice.title) would nourish \(suggestedPractice.domainText).")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(MoriColors.forestMoss.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            MoriForestProgressBar(value: metrics.bloomProgress, tint: MoriColors.forestFern)

            FlowLayout(spacing: 10) {
                MoriPill(title: "Bloom \(metrics.bloomPercentText)", symbolName: "camera.macro", tint: MoriColors.forestFern)
                MoriPill(title: "\(metrics.rootsStreak) day roots", symbolName: "chart.bar.fill", tint: MoriColors.forestRoot)
                MoriPill(title: "Settle \(metrics.settleMinutesToday)m", symbolName: "figure.mind.and.body", tint: MoriColors.forestMoss)
            }

            Button(action: onOpenPracticePicker) {
                Label("Plant suggested Seed", systemImage: "leaf.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCard)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(MoriColors.forestCanopy)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            NavigationLink(destination: LifeGridView()) {
                Label("View Life Grid", systemImage: "square.grid.3x3.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(MoriColors.forestCanopy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct MoriLifeGridNodePreview: View {
    let domainScores: [LifeDomain: Int]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(LifeDomain.allCases) { domain in
                let score = domainScores[domain, default: 0]
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(score > 0 ? moriDomainTint(domain).opacity(0.18) : MoriColors.forestLine.opacity(0.42))
                            .frame(width: 42, height: 42)

                        Image(systemName: domain.symbolName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(score > 0 ? moriDomainTint(domain) : MoriColors.forestMuted)
                    }

                    Text(domain.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(score > 0 ? MoriColors.forestCanopy : MoriColors.forestMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(score > 0 ? moriDomainTint(domain).opacity(0.08) : MoriColors.forestPaperDeep.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}

private struct TodayPracticeGarden: View {
    let onOpenSettle: () -> Void
    let onComplete: (MoriPractice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Practice Garden", subtitle: "Ways to Plant Seeds across Mori.")

            ForEach(MoriPractice.practiceGarden) { practice in
                practiceRow(for: practice)
            }

            NavigationLink(destination: ClockView()) {
                PracticeLinkRow(
                    symbolName: "clock",
                    title: "Clock",
                    subtitle: "Time awareness without hurry"
                )
            }
            .buttonStyle(.plain)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    @ViewBuilder
    private func practiceRow(for practice: MoriPractice) -> some View {
        switch practice.route {
        case .quickComplete:
            Button {
                onComplete(practice)
            } label: {
                PracticeGardenRow(practice: practice)
            }
            .buttonStyle(.plain)
        case .settle, .focusCycle:
            Button(action: onOpenSettle) {
                PracticeGardenRow(practice: practice)
            }
            .buttonStyle(.plain)
        case .quietMode:
            NavigationLink(destination: QuietModeView(onOpenSettle: onOpenSettle)) {
                PracticeGardenRow(practice: practice)
            }
            .buttonStyle(.plain)
        case .journal:
            NavigationLink(destination: GratitudeJournalScreen()) {
                PracticeGardenRow(practice: practice)
            }
            .buttonStyle(.plain)
        case .dailyCheckIn:
            NavigationLink(destination: HabitTrackerView()) {
                PracticeGardenRow(practice: practice)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct PracticeGardenRow: View {
    let practice: MoriPractice

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: practice.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(MoriColors.forestMoss)
                .frame(width: 34, height: 34)
                .background(MoriColors.forestMoss.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(practice.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text(practice.durationText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MoriColors.forestMuted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(MoriColors.forestCanopy.opacity(0.07))
                        .clipShape(Capsule())
                }

                Text(practice.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)

                FlowLayout(spacing: 6) {
                    MoriPill(title: practice.seedText, symbolName: "circle.hexagongrid.fill", tint: MoriColors.forestSeed)
                    MoriPill(title: practice.domainText, symbolName: "square.grid.3x3.fill", tint: MoriColors.forestMoss)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoriColors.forestMuted.opacity(0.7))
                .padding(.top, 10)
        }
        .padding(12)
        .background(MoriColors.forestPaperDeep.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct MoriPracticeSelectionSheet: View {
    let title: String
    let subtitle: String
    let practices: [MoriPractice]
    let onComplete: (MoriPractice) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            MoriForestBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        MoriPageHeader(
                            eyebrow: "Seeds",
                            title: title,
                            subtitle: subtitle
                        )

                        ForEach(practices) { practice in
                            Button {
                                onComplete(practice)
                            } label: {
                                PracticeGardenRow(practice: practice)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Plant Seed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)
                }
            }
        }
    }
}

struct MoriPracticeCompletionSheet: View {
    let practice: MoriPractice

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            MoriForestBackground {
                VStack(alignment: .leading, spacing: 20) {
                    Spacer(minLength: 18)

                    ZStack {
                        Circle()
                            .fill(MoriColors.forestSeed.opacity(0.22))
                            .frame(width: 86, height: 86)

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(MoriColors.forestMoss)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Seed planted.")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.forestCanopy)

                        Text("This nourished \(practice.domainText).")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.forestMoss)

                        Text("Your Life Grid grew a little.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(MoriColors.forestMuted)
                    }

                    FlowLayout(spacing: 8) {
                        MoriPill(title: practice.seedText, symbolName: "circle.hexagongrid.fill", tint: MoriColors.forestSeed)
                        MoriPill(title: practice.durationText, symbolName: "timer", tint: MoriColors.forestMist)
                        MoriPill(title: practice.domainText, symbolName: "square.grid.3x3.fill", tint: MoriColors.forestMoss)
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 10) {
                        NavigationLink(destination: LifeGridView()) {
                            Label("View Life Grid", systemImage: "square.grid.3x3.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MoriColors.forestCard)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(MoriColors.forestCanopy)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            Text("Return to Today")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MoriColors.forestCanopy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(MoriColors.forestCanopy.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .navigationTitle("Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }
}

private func moriDomainTint(_ domain: LifeDomain) -> Color {
    switch domain {
    case .body:
        return MoriColors.forestFern
    case .mind:
        return MoriColors.forestMist
    case .love:
        return MoriColors.forestClay
    case .craft:
        return MoriColors.forestSeed
    case .courage:
        return MoriColors.forestRoot
    case .service:
        return MoriColors.forestSage
    case .wonder:
        return MoriColors.morningGold
    case .rest:
        return MoriColors.forestMuted
    }
}

struct PracticeLinkRow: View {
    let symbolName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(MoriColors.forestMoss)
                .frame(width: 32, height: 32)
                .background(MoriColors.forestMoss.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MoriColors.forestMuted.opacity(0.7))
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    TodayView()
        .environmentObject(UserSettings())
}
