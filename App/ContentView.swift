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
            let contentHeight = mainTabBarHidden
                ? proxy.size.height
                : max(0, proxy.size.height - MoriMainTabBarMetrics.overlayHeight)

            ZStack(alignment: .bottom) {
                selectedTabContent
                    .frame(width: proxy.size.width, height: contentHeight)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipped()
                    .allowsHitTesting(presentation.activeSheet == nil)
                    .disabled(presentation.activeSheet != nil)
                    .accessibilityHidden(presentation.activeSheet != nil)

                if !mainTabBarHidden {
                    MoriBottomTabBarOverlay(
                        selectedTab: presentation.selectedTab,
                        onSelectTab: { tab in
                            open(.tab(tab), source: .userInteraction)
                        }
                    )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .allowsHitTesting(presentation.activeSheet == nil)
                        .disabled(presentation.activeSheet != nil)
                        .accessibilityHidden(presentation.activeSheet != nil)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
        .onPreferenceChange(MoriMainTabBarHiddenPreferenceKey.self) { hidden in
            mainTabBarHidden = hidden
        }
        .background {
            MoriPaperBackground(variant: presentation.selectedTab.backgroundVariant) {
                Color.clear
            }
        }
        .animation(MoriAnimation.standard, value: mainTabBarHidden)
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
        switch presentation.selectedTab {
        case .today:
            TodayView(
                launchRequest: presentation.todayLaunchRequest
            )
        case .practice:
            SettleView(
                launchRequest: presentation.practiceLaunchRequest
            )
        case .journal:
            GratitudeJournalScreen()
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
        if arguments.contains("-MoriOpenBeforeFeedForUITest") {
            open(.beforeFeedReset, source: .screenTimeGate)
        } else if arguments.contains("-MoriOpenWeekArchiveForUITest") {
            open(.weekArchiveDetail, source: .deepLink)
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

    private func open(_ request: MoriAppRouteRequest) {
        open(request.route, source: request.source)
    }

    private func open(_ route: MoriAppRoute, source: MoriAppRouteSource = .userInteraction) {
        let sourceTab = presentation.selectedTab.analyticsName
        let sourceSheet = presentation.activeSheet?.analyticsName
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
