import SwiftUI

struct ClarityPulseView: View {
    var onOpenSettle: (() -> Void)? = nil

    @EnvironmentObject var settings: UserSettings
    @StateObject private var clarityStore = MoriClarityStore.shared
    @State private var pulse: MoriDailyPulse = .mock()
    @State private var isLoading = false
    @State private var customTopic = ""
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
                            eyebrow: "Pulse",
                            title: "Clarity Pulse",
                            subtitle: "Useful signal, noisy loops, attention traps, and one reset action."
                        )

                        topicPicker

                        pulseHeader

                        ForEach(MoriPulseCardKind.allCases) { kind in
                            if let card = pulse.cards.first(where: { $0.kind == kind }) {
                                PulseCardView(
                                    card: card,
                                    onAction: {
                                        handle(card)
                                    }
                                )
                            }
                        }

                        PulsePracticeCTA {
                            activePracticeSheet = .selection
                        }

                        privacyNote
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Pulse")
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
                        title: "Reset with a Practice",
                        subtitle: "Close the Pulse with one grounded action instead of another scan.",
                        practices: MoriPractice.plantSeedChoices,
                        onComplete: completePractice
                    )
                case .completion(let practice):
                    MoriPracticeCompletionSheet(practice: practice)
                }
            }
        }
    }

    private var topicPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Topics",
                subtitle: "Choose what Mori should gently watch for you. Custom topics stay as labels until a provider is configured."
            )

            FlowLayout(spacing: 8) {
                ForEach(PulseTopic.allCases) { topic in
                    Button {
                        clarityStore.toggleTopic(topic)
                    } label: {
                        MoriPill(
                            title: topic.title,
                            symbolName: topic.symbolName,
                            isSelected: clarityStore.selectedTopics.contains(topic),
                            tint: topic == .custom ? MoriColors.forestClay : MoriColors.forestMoss
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                TextField("Add custom topic", text: $customTopic)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(MoriColors.forestCanopy)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(MoriColors.forestPaperDeep.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    clarityStore.addCustomTopic(customTopic)
                    customTopic = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MoriColors.forestCard)
                        .frame(width: 40, height: 40)
                        .background(MoriColors.forestCanopy)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(customTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !clarityStore.customTopics.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(clarityStore.customTopics, id: \.self) { topic in
                        Button {
                            clarityStore.removeCustomTopic(topic)
                        } label: {
                            MoriPill(title: topic, symbolName: "xmark", isSelected: true, tint: MoriColors.forestClay)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(topic)")
                    }
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var pulseHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Today's briefing")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)

                    Text(pulse.generatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MoriColors.forestMuted)
                }

                Spacer()

                Button {
                    Task { await loadPulse(force: true) }
                } label: {
                    Label(isLoading ? "Updating" : "Refresh", systemImage: isLoading ? "hourglass" : "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MoriColors.forestCanopy)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(MoriColors.forestCanopy.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }

            HStack(spacing: 10) {
                MoriPill(title: "\(pulse.reclaimedMinutes) min saved", symbolName: "clock", tint: MoriColors.forestMist)
                MoriPill(title: "\(metrics.clarityScore) clarity", symbolName: "leaf", tint: MoriColors.forestMoss)
                if pulse.isMock {
                    MoriPill(title: "mock fallback", symbolName: "wand.and.stars", tint: MoriColors.forestClay)
                }
            }
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundColor(MoriColors.forestMoss)

            Text("Mori sends only topic labels and aggregate clarity stats to configured providers. Raw journal, habit, and screen-time details stay local whenever possible.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }

    private func loadPulse(force: Bool) async {
        if !force,
           let latest = clarityStore.latestPulse,
           latest.dateKey == MoriDateKey.value() {
            pulse = latest
            return
        }

        isLoading = true
        let generated = await MoriPulseService.shared.generateDailyPulse(
            userContext: clarityStore.userContext(settings: settings),
            topics: clarityStore.selectedTopicLabels,
            recentInputs: recentInputs
        )
        clarityStore.savePulse(generated)
        pulse = generated
        isLoading = false
    }

    private var recentInputs: [String] {
        [
            "Seeds today: \(metrics.seedsToday)",
            "Quiet minutes today: \(metrics.quietMinutesToday)",
            "Reclaimed minutes today: \(metrics.reclaimedMinutesToday)"
        ]
    }

    private func handle(_ card: MoriPulseCard) {
        switch card.kind {
        case .worthKnowing:
            clarityStore.record(kind: .pulseRead, title: "Read useful signal", seeds: 1, minutes: pulse.reclaimedMinutes)
        case .worthIgnoring:
            clarityStore.record(kind: .pulseRead, title: "Skipped noisy loop", seeds: 2, minutes: 5)
        case .attentionTrap:
            clarityStore.record(kind: .urgeCheckIn, title: "Named an attention trap", seeds: 2, minutes: 3)
        case .resetAction:
            activePracticeSheet = .selection
        case .reclaimedTime:
            clarityStore.record(kind: .pulseRead, title: "Accepted reclaimed time", seeds: 1, minutes: card.minutes ?? pulse.reclaimedMinutes)
        }
    }

    private func completePractice(_ practice: MoriPractice) {
        clarityStore.recordPractice(practice)
        activePracticeSheet = .completion(practice)
    }
}

private struct PulsePracticeCTA: View {
    let onOpenPractices: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Close the loop",
                subtitle: "End with a practice so Pulse stays an attention filter, not a feed."
            )

            Button(action: onOpenPractices) {
                HStack(spacing: 12) {
                    Image(systemName: "leaf.arrow.circlepath")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MoriColors.forestMoss)
                        .frame(width: 38, height: 38)
                        .background(MoriColors.forestMoss.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose a reset practice")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(MoriColors.forestCanopy)

                        Text("Breathe, Settle, Journal, Focus, Quiet Mode, or walk offline.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(MoriColors.forestMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MoriColors.forestMuted.opacity(0.7))
                }
                .padding(12)
                .background(MoriColors.forestPaperDeep.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

private struct PulseCardView: View {
    let card: MoriPulseCard
    let onAction: () -> Void

    private var tint: Color {
        switch card.kind {
        case .worthKnowing: return MoriColors.forestMoss
        case .worthIgnoring: return MoriColors.forestMist
        case .attentionTrap: return MoriColors.forestClay
        case .resetAction: return MoriColors.forestFern
        case .reclaimedTime: return MoriColors.forestSeed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: card.kind.symbolName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.13))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(card.kind.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(tint)

                    Text(card.headline)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(MoriColors.forestCanopy)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(card.body)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(MoriColors.forestMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if let minutes = card.minutes {
                MoriForestProgressBar(value: Double(min(minutes, 45)) / 45.0, tint: tint)
            }

            Button(action: onAction) {
                Label(card.actionLabel ?? "Mark useful", systemImage: "checkmark.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MoriColors.forestCanopy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .moriSanctuaryCard(cornerRadius: 22, padding: 18)
    }
}

#Preview {
    ClarityPulseView()
        .environmentObject(UserSettings())
}
