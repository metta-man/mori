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
            ZStack(alignment: .bottom) {
                ZStack {
                    selectedTabContent(
                        safeAreaTopInset: proxy.safeAreaInsets.top
                    )
                        .id(presentation.selectedTab)
                        .transition(.opacity)
                }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .moriReduceMotionAnimation(
                        MoriAnimation.screenTransition,
                        value: presentation.selectedTab
                    )
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
                        .transition(.opacity)
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
            if presentation.selectedTab == .today {
                MoriPaperBackground(variant: .today) {
                    LinearGradient(
                        stops: [
                            .init(color: MoriV2Palette.raisedPaper.opacity(0.70), location: 0),
                            .init(color: MoriV2Palette.raisedPaper.opacity(0.70), location: 0.065),
                            .init(color: MoriV2Palette.raisedPaper.opacity(0), location: 0.15),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                        .ignoresSafeArea()
                }
            } else if presentation.selectedTab == .practice {
                MoriV2PaperScene(variant: .focus) {
                    Color.clear
                }
            } else {
                MoriPaperBackground(variant: presentation.selectedTab.backgroundVariant) {
                    Color.clear
                }
            }
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
    private func selectedTabContent(safeAreaTopInset: CGFloat) -> some View {
        switch presentation.selectedTab {
        case .today:
            TodayView(
                launchRequest: presentation.todayLaunchRequest,
                screenSafeAreaTopInset: safeAreaTopInset
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
        } else if arguments.contains("-MoriOpenDeepSessionForUITest") {
            open(.practiceSheet(.focusCycle), source: .deepLink)
        } else if arguments.contains("-MoriOpenWeekArchiveForUITest") {
            open(.weekArchiveDetail, source: .deepLink)
        } else if arguments.contains("-MoriOpenQuietModeForUITest") {
            open(.practiceSheet(.quietMode), source: .deepLink)
        } else if arguments.contains("-MoriOpenPracticeVerificationForUITest") {
            open(.practiceSheet(.verification(.walkReset)), source: .deepLink)
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
