import SwiftUI

private enum PulseSheet: Identifiable {
    case card(UUID)

    var id: String {
        switch self {
        case .card(let id):
            return "card-\(id.uuidString)"
        }
    }
}

private enum PulseRoute: Hashable {
    case recoverySignals
}

struct ClarityPulseView: View {
    var showsDismissButton = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.moriOpenRoute) private var openRoute
    @EnvironmentObject var settings: UserSettings
    @StateObject private var clarityStore = MoriClarityStore.shared
    @StateObject private var recoveryStore = MoriRecoveryStore.shared
    @StateObject private var appLimitManager = AppLimitManager.shared
    @State private var pulse: MoriDailyPulse = .mock()
    @State private var isLoading = false
    @State private var customTopic = ""
    @State private var selectedCustomTopicIcon: MoriCustomPulseTopicIcon = .leaf
    @State private var navigationPath: [PulseRoute] = []
    @State private var activeSheet: PulseSheet?
    @State private var answeringCardIDs: Set<UUID> = []
    @State private var followUpErrors: [UUID: String] = [:]
    @State private var pulseErrorMessage: String?
    @State private var showsTopicControls = false
    @AppStorage(MoriRecoveryStore.llmInsightOptInKey) private var recoveryInsightOptIn = false

    private var metrics: MoriClarityMetrics {
        clarityStore.metrics(settings: settings)
    }

    private var shouldShowPulseContent: Bool {
        !(pulse.isMock && pulseErrorMessage != nil)
    }

    private var isCoreLoopReady: Bool {
        appLimitManager.settingsSnapshot.isAppLimitReady(for: .beforeFeed)
    }

    private var shouldOpenRecoveryDetailsForUITest: Bool {
        ProcessInfo.processInfo.arguments.contains("-MoriOpenRecoveryDetailsForUITest")
    }

    private var shouldUseMockPulseForUITest: Bool {
        ProcessInfo.processInfo.arguments.contains("-MoriUseMockPulseForUITest")
    }

    private var activeTopicSet: Set<String> {
        Set(clarityStore.activeTopicLabels.map { $0.lowercased() })
    }

    private var sharedPulseCards: [MoriPulseCard] {
        pulse.displaySharedCards.filter { card in
            card.kind == .resetAction || card.kind == .reclaimedTime
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MoriRootScrollScreen(
                title: MoriL10n.display("Pulse"),
                subtitle: nil,
                spacing: 18,
                backgroundVariant: .today
            ) {
                if isCoreLoopReady {
                    ClarityPulseStatsHeader(
                        generatedAt: pulse.generatedAt,
                        metrics: metrics,
                        isLoading: isLoading,
                        onRefresh: refreshPulse
                    )

                    MoriRecoveryPulseCard(
                        snapshot: recoveryStore.snapshot,
                        isLoading: recoveryStore.isLoading,
                        errorMessage: recoveryStore.errorMessage,
                        title: MoriL10n.display("Recovery Pulse"),
                        subtitle: MoriL10n.display("HealthKit readiness signals before the attention scan."),
                        onOpenDetails: openRecoveryDetails,
                        onRefresh: refreshRecovery,
                        onStartPractice: startPractice,
                        onQuickComplete: completePractice
                    )

                    if recoveryStore.snapshot.status != .needsPermission {
                        MoriRecoveryInsightOptInCard(isEnabled: $recoveryInsightOptIn)
                    }

                    if let pulseErrorMessage {
                        PulseErrorBanner(message: pulseErrorMessage)
                    }

                    PulseTopicControlsSummary(
                        activeTopicLabels: clarityStore.activeTopicLabels,
                        activeCount: clarityStore.activeTopicLabels.count,
                        maxActiveCount: clarityStore.maxActiveTopicCount,
                        selectedCount: clarityStore.selectedTopicLabels.count,
                        queuedCount: clarityStore.queuedTopicLabels.count,
                        isExpanded: showsTopicControls,
                        onToggle: {
                            withAnimation(.snappy(duration: 0.22)) {
                                showsTopicControls.toggle()
                            }
                        }
                    )

                    if showsTopicControls {
                        PulseTopicPickerCard(
                            clarityStore: clarityStore,
                            customTopic: $customTopic,
                            selectedCustomTopicIcon: $selectedCustomTopicIcon
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if shouldShowPulseContent {
                        ForEach(pulse.displayTopicPulses) { topicPulse in
                            TopicPulseSection(
                                topicPulse: topicPulse,
                                topicIcon: clarityStore.icon(forTopicLabel: topicPulse.topic),
                                onAction: handle,
                                onOpenDetails: { card in
                                    presentCardDetail(card.id)
                                }
                            )
                        }

                        SharedPulseSection(
                            cards: sharedPulseCards,
                            onAction: handle,
                            onOpenDetails: { card in
                                presentCardDetail(card.id)
                            }
                        )
                    }

                    PulsePracticeCTA {
                        presentPracticeSheet(.selection)
                    }

                    PulsePrivacyNote()
                } else {
                    PulseCoreLoopGateCard(
                        onOpenAppLimitSetup: openAppLimitSetup,
                        onStartReset: openBeforeFeedReset
                    )
                }
            }
            .overlay(alignment: .topLeading) {
                if showsDismissButton {
                    PulseDismissButton {
                        dismiss()
                    }
                        .padding(.leading, 20)
                        .padding(.top, 52)
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: PulseRoute.self) { route in
                switch route {
                case .recoverySignals:
                    MoriRecoveryDetailView(
                        snapshot: recoveryStore.snapshot,
                        onStartPractice: startPractice,
                        onQuickComplete: completePractice
                    )
                }
            }
            .task(id: isCoreLoopReady) {
                guard isCoreLoopReady else { return }
                await recoveryStore.refresh()
                openRecoveryDetailsForUITestIfNeeded()
                await loadPulse(force: false)
            }
            .sheet(item: $activeSheet) { sheet in
                activeSheetContent(sheet)
            }
            .moriKeyboardDoneToolbar()
        }
    }

    @ViewBuilder
    private func activeSheetContent(_ sheet: PulseSheet) -> some View {
        switch sheet {
        case .card(let cardID):
            if let cardBinding = bindingForCard(cardID) {
                PulseCardDetailSheet(
                    card: cardBinding,
                    isAnswering: answeringCardIDs.contains(cardID),
                    errorMessage: followUpErrors[cardID],
                    onAsk: { question in
                        await askFollowUp(cardID: cardID, question: question, appendUserMessage: true)
                    },
                    onRetry: {
                        await retryFollowUp(cardID: cardID)
                    },
                    onOpenPractices: {
                        presentPracticeSheet(.selection)
                    }
                )
            }
        }
    }

    private func loadPulse(force: Bool) async {
        if shouldUseMockPulseForUITest {
            var mockPulse = MoriDailyPulse.mock(topics: clarityStore.activeTopicLabels)
            mockPulse.screenTimeAttemptsAtGeneration = metrics.screenTimeAttemptsToday
            mockPulse.screenTimeSavedMinutesAtGeneration = metrics.screenTimeSavedMinutesToday
            pulse = mockPulse
            pulseErrorMessage = nil
            return
        }

        if !force,
           let latest = clarityStore.latestPulse,
           canUseCachedPulse(latest) {
            pulse = latest
            pulseErrorMessage = nil
            return
        }

        isLoading = true
        pulseErrorMessage = nil
        defer { isLoading = false }

        do {
            var generated = try await MoriPulseService.shared.generateDailyPulse(
                userContext: clarityStore.userContext(settings: settings),
                topics: clarityStore.activeTopicLabels,
                recentInputs: recentInputs
            )
            generated.screenTimeAttemptsAtGeneration = metrics.screenTimeAttemptsToday
            generated.screenTimeSavedMinutesAtGeneration = metrics.screenTimeSavedMinutesToday
            clarityStore.savePulse(generated)
            pulse = generated
        } catch {
            pulseErrorMessage = "Could not load today's Pulse."
        }
    }

    private func canUseCachedPulse(_ cachedPulse: MoriDailyPulse) -> Bool {
        guard cachedPulse.dateKey == MoriDateKey.value(),
              cachedPulse.isUsableForCurrentLocale,
              !cachedPulse.topicPulses.isEmpty else {
            return false
        }

        let cachedTopics = Set(cachedPulse.topicPulses.map { $0.topic.lowercased() })
        return activeTopicSet.isSubset(of: cachedTopics)
    }

    private var recentInputs: [String] {
        var inputs = [
            "Seeds today: \(metrics.seedsToday)",
            "Quiet minutes today: \(metrics.quietMinutesToday)",
            "Reclaimed minutes today: \(metrics.reclaimedMinutesToday)",
            "Screen Time attempts today: \(metrics.screenTimeAttemptsToday), estimated saved \(metrics.screenTimeSavedMinutesToday) minutes"
        ]

        if recoveryInsightOptIn {
            inputs.append("Recovery summary is user opt-in and contains coarse labels only.")
            inputs.append(contentsOf: recoveryStore.snapshot.llmInsightLines.map { "Recovery: \($0)" })
        }

        return inputs
    }

    private func refreshRecovery() {
        Task {
            if recoveryStore.snapshot.status == .needsPermission {
                await recoveryStore.requestAuthorizationAndRefresh()
            } else {
                await recoveryStore.refresh()
            }
        }
    }

    private func refreshPulse() {
        Task { await loadPulse(force: true) }
    }

    private func openAppLimitSetup() {
        openRoute(.appLimitSetup)
    }

    private func openBeforeFeedReset() {
        openRoute(.beforeFeedReset)
    }

    private func startPractice(_ practice: MoriPractice) {
        if practice.route == .journal {
            openJournalPractice()
        } else {
            presentPracticeSheet(MoriPracticeSheet.destination(for: practice))
        }
    }

    private func openJournalPractice() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if !openRoute(.journalTab) {
                presentPracticeSheet(.journal)
            }
        }
    }

    private func bindingForCard(_ id: UUID) -> Binding<MoriPulseCard>? {
        guard let current = pulse.card(with: id) else { return nil }

        return Binding(
            get: {
                pulse.card(with: id) ?? current
            },
            set: { updatedCard in
                pulse.replaceCard(updatedCard)
                clarityStore.savePulse(pulse)
            }
        )
    }

    @MainActor
    private func askFollowUp(cardID: UUID, question: String, appendUserMessage: Bool) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              var requestCard = pulse.card(with: cardID) else { return }

        if appendUserMessage {
            requestCard.followUpMessages.append(
                MoriPulseFollowUpMessage(role: .user, content: trimmed)
            )
            pulse.replaceCard(requestCard)
        }

        followUpErrors[cardID] = nil
        answeringCardIDs.insert(cardID)
        defer { answeringCardIDs.remove(cardID) }
        clarityStore.savePulse(pulse)

        let requestTopics = pulse.topic(for: cardID).map { [$0] } ?? pulse.topics
        do {
            let result = try await MoriPulseService.shared.answerFollowUp(
                card: requestCard,
                question: trimmed,
                topics: requestTopics,
                userContext: clarityStore.userContext(settings: settings),
                recentInputs: recentInputs
            )
            guard var answerCard = pulse.card(with: cardID) else { return }
            answerCard.followUpMessages.append(result.message)
            if !result.followUpPrompts.isEmpty {
                answerCard.followUpPrompts = result.followUpPrompts
            }
            mergeSources(result.message.sources, into: &answerCard)
            pulse.replaceCard(answerCard)
            clarityStore.savePulse(pulse)
        } catch {
            followUpErrors[cardID] = MoriL10n.string(
                "pulse.follow_up.error_saved",
                defaultValue: "Live answer unavailable. Your question is saved."
            )
        }
    }

    @MainActor
    private func retryFollowUp(cardID: UUID) async {
        guard let card = pulse.card(with: cardID),
              let lastQuestion = card.followUpMessages.last(where: { $0.role == .user })?.content else { return }

        await askFollowUp(cardID: cardID, question: lastQuestion, appendUserMessage: false)
    }

    private func mergeSources(_ sources: [MoriPulseSource], into card: inout MoriPulseCard) {
        guard !sources.isEmpty else { return }

        var seen = Set(card.sources.map(\.id))
        for source in sources where !seen.contains(source.id) {
            card.sources.append(source)
            seen.insert(source.id)
        }
    }

    private func handle(_ card: MoriPulseCard) {
        switch card.kind {
        case .worthKnowing:
            clarityStore.record(kind: .pulseRead, title: MoriL10n.string("pulse.record.read_useful_signal", defaultValue: "Read useful signal"), seeds: 1, minutes: pulse.reclaimedMinutes)
        case .worthIgnoring:
            clarityStore.record(kind: .pulseRead, title: MoriL10n.string("pulse.record.skipped_noisy_loop", defaultValue: "Skipped noisy loop"), seeds: 2, minutes: 5)
        case .attentionTrap:
            clarityStore.record(kind: .urgeCheckIn, title: MoriL10n.string("pulse.record.named_attention_trap", defaultValue: "Named an attention trap"), seeds: 2, minutes: 3)
        case .resetAction:
            presentPracticeSheet(.selection)
        case .reclaimedTime:
            clarityStore.record(kind: .pulseRead, title: MoriL10n.string("pulse.record.accepted_reclaimed_time", defaultValue: "Accepted reclaimed time"), seeds: 1, minutes: card.minutes ?? pulse.reclaimedMinutes)
        }
    }

    private func completePractice(_ practice: MoriPractice) {
        let action = clarityStore.recordPractice(practice)
        presentPracticeSheet(.completion(practice, action.seeds))
    }

    private func presentPracticeSheet(_ sheet: MoriPracticeSheet) {
        if activeSheet != nil {
            activeSheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                openRoute(.practiceSheet(sheet))
            }
        } else {
            openRoute(.practiceSheet(sheet))
        }
    }

    private func presentCardDetail(_ id: UUID) {
        activeSheet = .card(id)
    }

    private func openRecoveryDetails() {
        navigationPath.append(.recoverySignals)
    }

    private func openRecoveryDetailsForUITestIfNeeded() {
        guard shouldOpenRecoveryDetailsForUITest,
              recoveryStore.snapshot.status == .ready,
              !navigationPath.contains(.recoverySignals) else {
            return
        }

        navigationPath.append(.recoverySignals)
    }
}

#Preview {
    ClarityPulseView()
        .environmentObject(UserSettings())
}
