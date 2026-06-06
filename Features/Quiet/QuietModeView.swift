import SwiftUI

struct QuietModeView: View {
    var onOpenSettle: (() -> Void)? = nil

    @EnvironmentObject var settings: UserSettings
    @StateObject private var clarityStore = MoriClarityStore.shared
    @State private var selectedMinutes = 10
    @State private var secondsRemaining = 10 * 60
    @State private var isRunning = false
    @State private var urgeReason = ""
    @State private var selectedReplacement: QuietReplacementAction?
    @State private var didCompleteTimer = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let minuteOptions = [5, 10, 20, 30]

    private var metrics: MoriClarityMetrics {
        clarityStore.metrics(settings: settings)
    }

    var body: some View {
        NavigationStack {
            MoriForestBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        MoriPageHeader(
                            eyebrow: "Quiet",
                            title: "Social Detox",
                            subtitle: "Pause before scrolling. Let the urge become information instead of instruction."
                        )

                        settleSuggestion

                        timerCard

                        urgeCheckIn

                        replacementActions

                        dailySummary
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Quiet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MoriColors.forestPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .onReceive(ticker) { _ in
                tick()
            }
            .onChange(of: selectedMinutes) { newValue in
                guard !isRunning else { return }
                secondsRemaining = newValue * 60
                didCompleteTimer = false
            }
        }
    }

    private var settleSuggestion: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "leaf.arrow.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MoriColors.forestMoss)
                    .frame(width: 38, height: 38)
                    .background(MoriColors.forestMoss.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Settle first")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text("Before opening a feed, try a short Settle practice and let the urge soften.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let onOpenSettle {
                Button(action: onOpenSettle) {
                    settleSuggestionLabel
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(destination: SettleView()) {
                    settleSuggestionLabel
                }
                .buttonStyle(.plain)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var settleSuggestionLabel: some View {
        Label("Open Settle", systemImage: "figure.mind.and.body")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(MoriColors.forestCard)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(MoriColors.forestCanopy)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            MoriSectionTitle(
                title: "Detox Timer",
                subtitle: "Give your attention a small clearing before opening another feed."
            )

            HStack(spacing: 8) {
                ForEach(minuteOptions, id: \.self) { minutes in
                    Button {
                        selectedMinutes = minutes
                    } label: {
                        Text("\(minutes)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedMinutes == minutes ? MoriColors.forestCard : MoriColors.forestCanopy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedMinutes == minutes ? MoriColors.forestCanopy : MoriColors.forestCanopy.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(minutes) minute quiet timer")
                }
            }

            ZStack {
                Circle()
                    .stroke(MoriColors.forestLine.opacity(0.62), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(MoriColors.forestMoss, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: timerProgress)

                VStack(spacing: 4) {
                    Text(timeText)
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                        .monospacedDigit()

                    Text(isRunning ? "quiet in progress" : didCompleteTimer ? "seed planted" : "ready when you are")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.forestMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 210)

            HStack(spacing: 12) {
                Button {
                    isRunning.toggle()
                    if isRunning {
                        didCompleteTimer = false
                    }
                } label: {
                    Label(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(MoriColors.forestCanopy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    isRunning = false
                    secondsRemaining = selectedMinutes * 60
                    didCompleteTimer = false
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(MoriColors.forestCanopy)
                        .frame(width: 48, height: 48)
                        .background(MoriColors.forestCanopy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset timer")
            }
        }
        .moriSanctuaryCard(cornerRadius: 24, padding: 18)
    }

    private var urgeCheckIn: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Urge Check-In",
                subtitle: "Why do you want to open this now?"
            )

            TextField("Bored, anxious, avoiding something, seeking news...", text: $urgeReason, axis: .vertical)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.forestCanopy)
                .lineLimit(2...4)
                .padding(14)
                .background(MoriColors.forestPaperDeep.opacity(0.62))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                let trimmed = urgeReason.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                clarityStore.record(
                    kind: .urgeCheckIn,
                    title: "Named the urge",
                    seeds: 2,
                    minutes: 2,
                    note: trimmed
                )
                urgeReason = ""
            } label: {
                Label("Plant this pause", systemImage: "leaf")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MoriColors.forestCard)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(urgeReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MoriColors.forestMuted.opacity(0.35) : MoriColors.forestMoss)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(urgeReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var replacementActions: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Replacement Actions",
                subtitle: "Choose a different path for the same need."
            )

            ForEach(QuietReplacementAction.allCases) { action in
                Button {
                    selectedReplacement = action
                    clarityStore.record(
                        kind: .replacementAction,
                        title: action.title,
                        seeds: action.seeds,
                        minutes: action.minutes,
                        note: action.note
                    )
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: action.symbolName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(action.tint)
                            .frame(width: 36, height: 36)
                            .background(action.tint.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(action.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(MoriColors.forestCanopy)

                            Text(action.note)
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
                    .padding(12)
                    .background(selectedReplacement == action ? action.tint.opacity(0.12) : MoriColors.forestPaperDeep.opacity(0.52))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var dailySummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Daily Attention Summary",
                subtitle: "A local view of the attention you reclaimed today."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MoriMetricTile(
                    title: "Quiet",
                    value: "\(metrics.quietMinutesToday)m",
                    detail: "detox minutes",
                    symbolName: "moon.stars",
                    tint: MoriColors.forestMist
                )

                MoriMetricTile(
                    title: "Seeds",
                    value: "\(metrics.seedsToday)",
                    detail: "earned today",
                    symbolName: "circle.hexagongrid",
                    tint: MoriColors.forestSeed
                )

                MoriMetricTile(
                    title: "Clarity",
                    value: "\(metrics.clarityScore)",
                    detail: "calm score",
                    symbolName: "leaf",
                    tint: MoriColors.forestMoss
                )

                MoriMetricTile(
                    title: "Reclaimed",
                    value: "\(metrics.reclaimedMinutesToday)m",
                    detail: "feed time saved",
                    symbolName: "clock",
                    tint: MoriColors.forestClay
                )
            }
        }
    }

    private var timerProgress: CGFloat {
        let total = max(1, selectedMinutes * 60)
        return CGFloat(total - secondsRemaining) / CGFloat(total)
    }

    private var timeText: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func tick() {
        guard isRunning else { return }

        if secondsRemaining > 0 {
            secondsRemaining -= 1
            return
        }

        isRunning = false
        guard !didCompleteTimer else { return }
        didCompleteTimer = true
        clarityStore.record(
            kind: .quietTimer,
            title: "\(selectedMinutes) minute quiet timer",
            seeds: max(2, selectedMinutes / 5),
            minutes: selectedMinutes,
            note: "Completed a social detox timer"
        )
    }
}

private enum QuietReplacementAction: String, CaseIterable, Identifiable {
    case breathe
    case journal
    case stretch
    case walk
    case reflect

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breathe: return "Breathe"
        case .journal: return "Journal"
        case .stretch: return "Stretch"
        case .walk: return "Walk"
        case .reflect: return "Reflect"
        }
    }

    var symbolName: String {
        switch self {
        case .breathe: return "wind"
        case .journal: return "book.closed"
        case .stretch: return "figure.cooldown"
        case .walk: return "figure.walk"
        case .reflect: return "sparkle.magnifyingglass"
        }
    }

    var note: String {
        switch self {
        case .breathe: return "Two minutes of longer exhales"
        case .journal: return "Write the thought instead of feeding it"
        case .stretch: return "Move the body out of the loop"
        case .walk: return "Let the screen lose its grip"
        case .reflect: return "Ask what the urge is protecting"
        }
    }

    var seeds: Int {
        switch self {
        case .breathe, .journal, .stretch: return 2
        case .walk, .reflect: return 3
        }
    }

    var minutes: Int {
        switch self {
        case .breathe: return 2
        case .journal: return 5
        case .stretch: return 4
        case .walk: return 8
        case .reflect: return 6
        }
    }

    var tint: Color {
        switch self {
        case .breathe: return MoriColors.forestMist
        case .journal: return MoriColors.forestMoss
        case .stretch: return MoriColors.forestFern
        case .walk: return MoriColors.forestClay
        case .reflect: return MoriColors.forestSeed
        }
    }
}

#Preview {
    QuietModeView()
        .environmentObject(UserSettings())
}
