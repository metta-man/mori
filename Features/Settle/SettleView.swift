import SwiftUI

struct SettleView: View {
    let launchRequest: MoriPracticeLaunchRequest?

    @Environment(\.moriOpenRoute) private var openRoute
    @StateObject private var clarityStore = MoriClarityStore.shared
    @AppStorage(
        MoriScreenTimeShared.beforeFeedDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedDurationSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedDurationSeconds
    @AppStorage(MindfulnessBellDefaults.isActiveKey) private var mindfulnessBellEnabled = false
    @AppStorage(MindfulnessBellDefaults.nextFireKey) private var mindfulnessBellNextFireTimestamp: Double = 0
    @State private var navigationPath: [SettleNavigationRoute] = []
    @State private var mindfulnessBellAuthorizationDenied = false
    @State private var handledLaunchRequestID: UUID?
    @State private var showsMorePractices = false

    init(
        launchRequest: MoriPracticeLaunchRequest? = nil
    ) {
        self.launchRequest = launchRequest
    }

    private var recommendedPractice: MoriPractice {
        clarityStore.suggestedPracticeForToday()
    }

    private var mindfulnessBellCard: some View {
        MindfulnessBellSettleCard(
            isActive: mindfulnessBellEnabled,
            nextFireTimestamp: mindfulnessBellNextFireTimestamp,
            authorizationDenied: mindfulnessBellAuthorizationDenied,
            onEnableRecommended: enableRecommendedMindfulnessBell
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MoriRootScrollScreen(
                title: "Reset",
                subtitle: "One action. One limit. Then leave.",
                spacing: 16,
                backgroundVariant: .practice
            ) {
                primarySeedSection(
                    practice: recommendedPractice
                )

                attentionAnchorSection

                morePracticeSection

                mindfulnessBellCard

                SettlePrivacyNote()
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettleNavigationRoute.self) { route in
                switch route {
                case .appLimits:
                    LockedScreenTimeSettingsView()
                        .moriHidesMainTabBar()
                case .breathingLibrary:
                    MoriBreathingLibraryView()
                case .breathingSession(let techniqueID, let durationMinutes, let autoStart):
                    MoriBreathingSessionView(
                        techniqueID: techniqueID,
                        durationMinutes: durationMinutes,
                        autoStart: autoStart
                    )
                case .settleTimer:
                    SettleTimerDetailView()
                case .focusCycle:
                    PomodoroPracticeDetailView()
                case .mindfulnessBellSettings:
                    MindfulnessBellSettingsView()
                        .moriHidesMainTabBar()
                }
            }
            .environment(\.moriOpenSettleRoute, MoriSettleRouteAction { route in
                navigationPath.append(route)
            })
            .settleLaunchRequestLifecycle(
                launchRequestID: launchRequest?.id,
                onHandleLaunchRequest: handleLaunchRequestIfNeeded
            )
        }
    }

    private func primarySeedSection(practice: MoriPractice) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(
                title: "Do this next",
                subtitle: "One reset. Then leave."
            )

            seedRoute(for: practice, style: .hero)
        }
    }

    private func practiceNeedSection(_ need: MoriPracticeNeed) -> some View {
        let practices = MoriPractice.practiceGarden.filter { $0.primaryNeed == need }

        return VStack(alignment: .leading, spacing: 14) {
            MoriSectionTitle(title: need.title, subtitle: need.subtitle)

            ForEach(practices) { practice in
                seedRoute(for: practice)
            }
        }
    }

    private var attentionAnchorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoriSectionTitle(
                title: "Limit the next feed",
                subtitle: "Screen Time is the multiplier. Use it before willpower is needed."
            )

            attentionTools
        }
    }

    private var attentionTools: some View {
        VStack(spacing: 10) {
            Button {
                openPracticeSheet(.beforeFeed)
            } label: {
                PracticeUtilityRow(
                    title: "Before Feed Reset",
                    subtitle: "Pause \(BeforeFeedGate.formattedDuration(beforeFeedDurationSeconds)) before opening selected apps.",
                    icon: .timer,
                    productSymbol: .beforeFeedReset
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: SettleNavigationRoute.appLimits) {
                PracticeUtilityRow(
                    title: "App Limits",
                    subtitle: "Choose one app or website to slow down before the next feed opens.",
                    icon: .lockShield,
                    productSymbol: .appLimit
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var morePracticeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.24)) {
                    showsMorePractices.toggle()
                }
            } label: {
                PracticeUtilityRow(
                    title: showsMorePractices ? "Hide reset menu" : "More reset options",
                    subtitle: showsMorePractices
                        ? "Keep the screen small again."
                        : "Open the full reset menu only when the first action is wrong.",
                    icon: showsMorePractices ? .minus : .plus
                )
            }
            .buttonStyle(.plain)

            if showsMorePractices {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(MoriPracticeNeed.allCases) { need in
                        practiceNeedSection(need)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private func seedRoute(for practice: MoriPractice, style: PracticeActionStyle = .row) -> some View {
        switch practice.route {
        case .quickComplete:
            Button {
                openPracticeSheet(.verification(practice))
            } label: {
                practiceActionCard(for: practice, style: style)
            }
            .buttonStyle(.plain)
        case .breathing:
            NavigationLink(value: SettleNavigationRoute.breathingLibrary) {
                practiceActionCard(for: practice, style: style)
            }
            .buttonStyle(.plain)
        case .settle:
            NavigationLink(value: SettleNavigationRoute.settleTimer) {
                practiceActionCard(for: practice, style: style)
            }
            .buttonStyle(.plain)
        case .focusCycle:
            NavigationLink(value: SettleNavigationRoute.focusCycle) {
                practiceActionCard(for: practice, style: style)
            }
            .buttonStyle(.plain)
        case .quietMode:
            Button {
                openPracticeSheet(.quietMode)
            } label: {
                practiceActionCard(for: practice, style: style)
            }
            .buttonStyle(.plain)
        case .journal:
            Button {
                openRoute(.journalTab)
            } label: {
                practiceActionCard(for: practice, style: style)
            }
            .buttonStyle(.plain)
        case .dailyCheckIn:
            Button {
                openPracticeSheet(.dailyCheckIn)
            } label: {
                practiceActionCard(for: practice, style: style)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func practiceActionCard(for practice: MoriPractice, style: PracticeActionStyle) -> some View {
        switch style {
        case .hero:
            PracticeHeroActionCard(
                practice: practice,
                reason: "Chosen from today's signal and recent reset history."
            )
        case .row:
            MoriPracticeCard(practice: practice)
        }
    }

    private func openPracticeSheet(_ sheet: MoriPracticeSheet) {
        openRoute(.practiceSheet(sheet))
    }

    private func handleLaunchRequestIfNeeded() {
        guard let launchRequest,
              handledLaunchRequestID != launchRequest.id else {
            return
        }

        handledLaunchRequestID = launchRequest.id

        switch launchRequest.kind {
        case .mindfulnessBellBreathing:
            openMindfulnessBellBreathing()
        }
    }

    private func openMindfulnessBellBreathing() {
        let techniqueID = MindfulnessBellDefaults.selectedBreathingTechniqueID()
        let durationMinutes = MindfulnessBellDefaults.selectedBreathingDurationMinutes()

        DispatchQueue.main.async {
            navigationPath = [
                .breathingSession(
                    techniqueID: techniqueID,
                    durationMinutes: durationMinutes,
                    autoStart: true
                )
            ]
        }
    }

    private func enableRecommendedMindfulnessBell() {
        mindfulnessBellAuthorizationDenied = false
        MindfulnessBellScheduler.shared.applyRecommendedDefaults()
        MindfulnessBellScheduler.shared.requestAuthorization { granted in
            if granted {
                mindfulnessBellEnabled = true
                MindfulnessBellScheduler.shared.scheduleUpcomingBells()
            } else {
                mindfulnessBellEnabled = false
                mindfulnessBellAuthorizationDenied = true
            }
        }
    }

}

#Preview {
    SettleView()
        .environmentObject(UserSettings())
}
