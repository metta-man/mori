import SwiftUI

struct RootsGrowthView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var settleStore = SettleSessionStore.shared
    @State private var reflection = MoriWeeklyReflection(
        title: "Your roots are forming",
        body: "Small choices become visible when you return to them each day.",
        nextSeed: "Choose one quiet action before your first feed check."
    )

    private var metrics: MoriClarityMetrics {
        clarityStore.metrics(settings: settings)
    }

    private var settleSummary: SettleWeeklySummary {
        settleStore.weeklySummary()
    }

    var body: some View {
        NavigationStack {
            MoriForestBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        MoriPageHeader(
                            eyebrow: "Roots",
                            title: "Growth",
                            subtitle: "Seeds become Bloom when they repeat. Roots are the practice history that keeps you steady."
                        )

                        bloomCard

                        rootsSummary

                        settleRoots

                        reflectionCard

                        recentSeeds

                        practiceArchive
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Roots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .task {
                reflection = await MoriPulseService.shared.generateWeeklyReflection(
                    clarityStore.weeklyStats(settings: settings)
                )
            }
        }
    }

    private var bloomCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bloom Progress")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.forestMuted)

                    Text(metrics.bloomPercentText)
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                }

                Spacer()

                Image(systemName: "camera.macro")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(MoriColors.forestFern)
                    .frame(width: 72, height: 72)
                    .background(MoriColors.forestFern.opacity(0.12))
                    .clipShape(Circle())
            }

            MoriForestProgressBar(value: metrics.bloomProgress, tint: MoriColors.forestFern)

            Text("Bloom grows from Seeds, quiet minutes, daily check-ins, and completed Life Grid proofs.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var rootsSummary: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MoriMetricTile(
                title: "Roots",
                value: "\(metrics.rootsStreak)",
                detail: "day practice streak",
                symbolName: "chart.bar.fill",
                tint: MoriColors.forestRoot
            )

            MoriMetricTile(
                title: "Seeds",
                value: "\(metrics.seedsToday)",
                detail: "planted today",
                symbolName: "circle.hexagongrid.fill",
                tint: MoriColors.forestSeed
            )

            MoriMetricTile(
                title: "Quiet",
                value: "\(metrics.quietMinutesToday)m",
                detail: "attention recovery",
                symbolName: "moon.stars",
                tint: MoriColors.forestMist
            )

            MoriMetricTile(
                title: "Clarity",
                value: "\(metrics.clarityScore)",
                detail: "daily calm score",
                symbolName: "leaf",
                tint: MoriColors.forestMoss
            )
        }
    }

    private var settleRoots: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Settle Roots",
                subtitle: "Weekly meditation sessions, minutes, consistency, and Bloom progress."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                RootsInlineStat(
                    title: "Sessions",
                    value: "\(settleSummary.completedSessions)",
                    symbolName: "figure.mind.and.body",
                    tint: MoriColors.forestMoss
                )

                RootsInlineStat(
                    title: "Minutes",
                    value: "\(settleSummary.totalMinutes)m",
                    symbolName: "timer",
                    tint: MoriColors.forestMist
                )

                RootsInlineStat(
                    title: "Consistency",
                    value: "\(settleSummary.consistencyDays)d",
                    symbolName: "chart.bar.fill",
                    tint: MoriColors.forestRoot
                )

                RootsInlineStat(
                    title: "Bloom",
                    value: settleSummary.bloomPercentText,
                    symbolName: "camera.macro",
                    tint: MoriColors.forestFern
                )
            }

            MoriForestProgressBar(value: settleSummary.bloomProgress, tint: MoriColors.forestFern)

            NavigationLink(destination: SettleView()) {
                Label("Open Settle", systemImage: "leaf.arrow.circlepath")
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

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: reflection.title, subtitle: "Weekly reflection")

            Text(reflection.body)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "leaf.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MoriColors.forestMoss)

                Text(reflection.nextSeed)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(MoriColors.forestMoss.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var recentSeeds: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(title: "Recent Seeds", subtitle: "Small actions that shaped your week.")

            let recentActions = Array(clarityStore.actions.prefix(8))
            if recentActions.isEmpty {
                Text("No Seeds yet today. A breath, walk, journal note, or quiet timer will appear here.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(recentActions) { action in
                    RecentSeedRow(action: action)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var practiceArchive: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(title: "Practice Archive", subtitle: "Existing Mori tools remain part of the forest.")

            NavigationLink(destination: GratitudeJournalScreen()) {
                PracticeLinkRow(symbolName: "heart.text.square", title: "Journal", subtitle: "Private memories and daily sparks")
            }
            .buttonStyle(.plain)

            NavigationLink(destination: HabitTrackerView()) {
                PracticeLinkRow(symbolName: "plus.forwardslash.minus", title: "Daily Check-In", subtitle: "Tone and pattern history")
            }
            .buttonStyle(.plain)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct RecentSeedRow: View {
    let action: MoriMindfulAction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(MoriColors.forestMoss)
                .frame(width: 32, height: 32)
                .background(MoriColors.forestMoss.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(action.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)

                Text(action.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(MoriColors.forestMuted)
            }

            Spacer()

            Text("+\(action.seeds)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(MoriColors.forestRoot)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(MoriColors.forestSeed.opacity(0.20))
                .clipShape(Capsule())
        }
    }

    private var symbolName: String {
        switch action.kind {
        case .pulseRead: return "sparkles"
        case .resetAction: return "leaf.arrow.circlepath"
        case .quietTimer: return "moon.stars"
        case .settleSession: return "figure.mind.and.body"
        case .breathingSession: return "wind"
        case .pomodoroSession: return "timer"
        case .urgeCheckIn: return "hand.raised"
        case .replacementAction: return "arrow.triangle.turn.up.right.circle"
        case .dailyFocus: return "target"
        case .lifeGridProof: return "square.grid.3x3"
        case .journal: return "book.closed"
        }
    }
}

private struct RootsInlineStat: View {
    let title: String
    let value: String
    let symbolName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(MoriColors.forestCanopy)
                    .minimumScaleFactor(0.75)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MoriColors.forestMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    RootsGrowthView()
        .environmentObject(UserSettings())
}
