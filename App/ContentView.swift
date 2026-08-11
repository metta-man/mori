import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject private var routeStore = MoriAppRouteStore.shared
    @StateObject private var clarityStore = MoriClarityStore.shared
    @AppStorage(
        MoriScreenTimeShared.beforeFeedDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedDurationSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedDurationSeconds
    @AppStorage(
        MoriScreenTimeShared.morningGateDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var morningGateDurationSeconds: Int = MoriScreenTimeShared.defaultMorningGateDurationSeconds
    @State private var presentation = MoriAppPresentationState()
    @State private var rootNavigationPath = NavigationPath()
    @State private var mainTabBarHidden = false
    @State private var handledUITestLaunchRoute = false
    @State private var didOpenInitialRoutes = false
    
    var body: some View {
        Group {
            if !settings.hasCompletedOnboarding {
                MoriOnboardingView()
            } else {
                mainTabView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mainTabView: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                NavigationStack(path: $rootNavigationPath) {
                    ZStack {
                        MoriRootShellBackground()
                            .ignoresSafeArea()

                        selectedTabContent
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .allowsHitTesting(presentation.activeSheet == nil)
                    .disabled(presentation.activeSheet != nil)
                    .accessibilityHidden(presentation.activeSheet != nil)
                    .navigationTitle("")
                    .toolbar(.hidden, for: .navigationBar)
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .navigationDestination(for: TodayNavigationRoute.self) { route in
                        todayDestination(route)
                    }
                    .navigationDestination(for: SettleNavigationRoute.self) { route in
                        settleDestination(route)
                    }
                    .navigationDestination(for: GratitudeJournalRoute.self) { route in
                        gratitudeJournalDestination(route)
                    }
                }
                .background(Color.clear)
                .environment(\.moriOpenTodayRoute, TodayRouteAction { route in
                    rootNavigationPath.append(route)
                })
                .environment(\.moriOpenSettleRoute, MoriSettleRouteAction { route in
                    rootNavigationPath.append(route)
                })
                .environment(\.moriOpenGratitudeJournalRoute, GratitudeJournalRouteAction { route in
                    rootNavigationPath.append(route)
                })

                MoriBottomTabBarOverlay(
                    selectedTab: presentation.selectedTab,
                    onSelectTab: { tab in
                        selectTab(tab)
                    }
                )
                    .opacity(mainTabBarHidden ? 0 : 1)
                    .allowsHitTesting(!mainTabBarHidden && presentation.activeSheet == nil)
                    .disabled(presentation.activeSheet != nil)
                    .accessibilityHidden(mainTabBarHidden || presentation.activeSheet != nil)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
        .onPreferenceChange(MoriMainTabBarHiddenPreferenceKey.self) { hidden in
            mainTabBarHidden = hidden
        }
        .moriReduceMotionAnimation(MoriAnimation.standard, value: mainTabBarHidden)
        .tint(MoriColors.botanicalInk)
        .onOpenURL { url in
            open(MoriAppRouteRequest(url: url, fallbackSource: .deepLink))
        }
        .onAppear {
            openInitialRoutesAfterLayout()
        }
        .onReceive(routeStore.$requestID.dropFirst()) { _ in
            openPendingRoutesAfterLayout()
        }
        .environment(\.moriOpenRoute, MoriAppRouteAction { route, source in
            open(route, source: source)
        })
        .moriAppSheet(
            item: $presentation.activeSheet,
            routeSource: presentation.activeSheetSource,
            selectionTitle: "Reset before the feed",
            selectionSubtitle: "Choose one grounded action, then leave the app.",
            beforeFeedDurationSeconds: beforeFeedDurationSeconds,
            morningGateDurationSeconds: morningGateDurationSeconds,
            onStartPractice: startGlobalPractice,
            onCompletePractice: completeGlobalPractice,
            pulseShowsDismissButton: true
        )
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        if presentation.selectedTab == .today {
            TodayView(launchRequest: presentation.todayLaunchRequest)
        }

        if presentation.selectedTab == .practice {
            SettleView(
                launchRequest: presentation.practiceLaunchRequest
            )
        }

        if presentation.selectedTab == .journal {
            GratitudeJournalScreen(usesAppShellNavigation: true)
        }
    }

    @ViewBuilder
    private func todayDestination(_ route: TodayNavigationRoute) -> some View {
        switch route {
        case .weekArchiveDetail:
            WeekArchiveDetailView()
        }
    }

    @ViewBuilder
    private func settleDestination(_ route: SettleNavigationRoute) -> some View {
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
        case .quietMode:
            QuietModeView()
                .moriHidesMainTabBar()
        case .essentialMode:
            EssentialModeView()
                .moriHidesMainTabBar()
        case .mindfulnessBellSettings:
            MindfulnessBellSettingsView()
                .moriHidesMainTabBar()
        }
    }

    @ViewBuilder
    private func gratitudeJournalDestination(_ route: GratitudeJournalRoute) -> some View {
        switch route {
        case .history:
            GratitudeHistoryView()
        case .weekArchiveDetail:
            WeekArchiveDetailView()
                .moriHidesMainTabBar()
        }
    }

    private func openPendingRoutesIfNeeded() {
        for request in routeStore.consumePendingResetRouteRequests() {
            open(request.route, source: request.source)
        }

        if let request = MoriNotificationRouter.consumePendingRouteRequest() {
            open(request.route, source: request.source)
        }

        for request in routeStore.consumeQueuedRouteRequests() {
            open(request.route, source: request.source)
        }
    }

    private func openInitialRoutesAfterLayout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard !didOpenInitialRoutes else { return }
            openPendingRoutesIfNeeded()
            openUITestLaunchRouteIfNeeded()
            didOpenInitialRoutes = true
        }
    }

    private func openPendingRoutesAfterLayout() {
        guard didOpenInitialRoutes else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            openPendingRoutesIfNeeded()
        }
    }

    private func openUITestLaunchRouteIfNeeded() {
        guard !handledUITestLaunchRoute else { return }
        handledUITestLaunchRoute = true

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-MoriOpenFocusForUITest") {
            open(.practiceTab, source: .deepLink)
        } else if arguments.contains("-MoriOpenBeforeFeedForUITest") {
            open(.beforeFeedReset, source: .screenTimeGate)
        } else if arguments.contains("-MoriOpenDeepSessionForUITest") {
            open(.practiceLaunch(.deepSession), source: .deepLink)
        } else if arguments.contains("-MoriOpenWeekArchiveForUITest") {
            open(.weekArchiveDetail, source: .deepLink)
        } else if arguments.contains("-MoriOpenQuietModeForUITest") {
            open(.practiceLaunch(.quietMode), source: .deepLink)
        } else if arguments.contains("-MoriOpenPracticeVerificationForUITest") {
            open(.practiceLaunch(.essentialMode), source: .deepLink)
        } else if arguments.contains("-MoriOpenEssentialModeForUITest") {
            open(.practiceLaunch(.essentialMode), source: .deepLink)
        } else if arguments.contains("-MoriOpenSettingsForUITest") {
            open(.settings, source: .deepLink)
        }
    }

    private func startGlobalPractice(_ practice: MoriPractice) {
        if practice.route == .journal {
            open(.journalTab)
        } else {
            openPracticeSheet(MoriPracticeSheet.destination(for: practice))
        }
    }

    private func completeGlobalPractice(_ practice: MoriPractice) {
        let action = clarityStore.recordPractice(practice)
        openPracticeSheet(.completion(practice, action.seeds))
    }

    private func openPracticeSheet(_ sheet: MoriPracticeSheet) {
        open(.practiceSheet(sheet), source: .userInteraction)
    }

    private func selectTab(_ tab: AppTab) {
        guard tab != presentation.selectedTab else { return }
        open(.tab(tab), source: .userInteraction)
    }

    private func open(_ request: MoriAppRouteRequest) {
        open(request.route, source: request.source)
    }

    private func open(_ route: MoriAppRoute, source: MoriAppRouteSource = .userInteraction) {
        let sourceTab = presentation.selectedTab.analyticsName
        let sourceSheet = presentation.activeSheet?.analyticsName
        let previousTab = presentation.selectedTab
        let shouldResetRootNavigation: Bool
        switch route {
        case .tab, .todayLaunch, .practiceLaunch:
            shouldResetRootNavigation = true
        case .sheet(_, let destinationTab):
            shouldResetRootNavigation = destinationTab != previousTab
        case .practiceSheet, .settings, .appLimits, .appLimitSetup:
            shouldResetRootNavigation = false
        }

        if shouldResetRootNavigation {
            rootNavigationPath = NavigationPath()
        }
        presentation.open(route, source: source)
        trackRouteOpened(
            route,
            source: source,
            sourceTab: sourceTab,
            sourceSheet: sourceSheet
        )
    }

    private func trackRouteOpened(
        _ route: MoriAppRoute,
        source: MoriAppRouteSource,
        sourceTab: String,
        sourceSheet: String?
    ) {
        var properties = route.analyticsProperties
        properties[AnalyticsProperties.routeSource] = source.analyticsName
        properties[AnalyticsProperties.sourceTab] = sourceTab
        properties[AnalyticsProperties.destinationTab] = presentation.selectedTab.analyticsName

        if let sourceSheet {
            properties[AnalyticsProperties.sourceSheet] = sourceSheet
        }

        if let destinationSheet = presentation.activeSheet?.analyticsName {
            properties[AnalyticsProperties.destinationSheet] = destinationSheet
        }

        AnalyticsManager.shared.trackAppRouteOpened(
            routeName: route.analyticsName,
            properties: properties
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSettings())
}
