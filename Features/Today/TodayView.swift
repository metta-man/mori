import SwiftUI
import FamilyControls
import UIKit

struct TodayView: View {
    @Environment(\.moriOpenRoute) private var openRoute
    @EnvironmentObject private var settings: UserSettings

    let launchRequest: MoriTodayLaunchRequest?
    let screenSafeAreaTopInset: CGFloat

    @StateObject private var appLimitManager = AppLimitManager.shared
    @StateObject private var clarityStore = MoriClarityStore.shared
    @AppStorage(
        MoriScreenTimeShared.beforeFeedDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedDurationSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedDurationSeconds
    @AppStorage(
        MoriScreenTimeShared.morningGateDurationSecondsKey,
        store: MoriAppGroup.defaults
    ) private var morningGateDurationSeconds: Int = MoriScreenTimeShared.defaultMorningGateDurationSeconds
    @AppStorage(
        MoriScreenTimeShared.beforeFeedGraceWindowSecondsKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedGraceWindowSeconds: Int = MoriScreenTimeShared.defaultBeforeFeedGraceWindowSeconds
    @AppStorage(
        MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedBreathingTechniqueID: String = MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
    @State private var todayFocus = TodayFocusDraftStore.live.load(for: Date())
    @State private var navigationPath: [TodayNavigationRoute] = []
    @State private var handledLaunchRequestID: UUID?
    @State private var todayIntentCount = BeforeFeedGateStore().todayIntentCount()

    private var appLimitPresentation: TodayAppLimitPresentation {
        TodayAppLimitPresentation(
            snapshot: appLimitManager.settingsSnapshot,
            effectiveSelection: effectiveBeforeFeedSelection,
            durationSeconds: beforeFeedDurationSeconds,
            graceWindowSeconds: beforeFeedGraceWindowSeconds,
            breathingTechniqueID: beforeFeedBreathingTechniqueID
        )
    }

    private var effectiveBeforeFeedSelection: FamilyActivitySelection {
        let summary = appLimitManager.settingsSnapshot.profileSummary(for: .beforeFeed)
        let target: AttentionShieldSelectionTarget = summary.usesDefaultSelection
            ? .defaultList
            : .feature(.beforeFeed)

        return appLimitManager.selectionDraft(for: target).selection
    }

    private var quietMinutesToday: Int {
        clarityStore.metrics(settings: settings).quietMinutesToday
    }

    private var longestQuietToday: Int {
        clarityStore.actions(for: Date())
            .filter { action in
                switch action.kind {
                case .quietTimer, .replacementAction, .urgeCheckIn, .breathingSession, .pomodoroSession:
                    return true
                default:
                    return false
                }
            }
            .map(\.minutes)
            .max() ?? 0
    }

    private var resolvedScreenSafeAreaTopInset: CGFloat {
        guard screenSafeAreaTopInset <= 0 else {
            return screenSafeAreaTopInset
        }

        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? 0
    }

    init(
        launchRequest: MoriTodayLaunchRequest? = nil,
        screenSafeAreaTopInset: CGFloat = 0
    ) {
        self.launchRequest = launchRequest
        self.screenSafeAreaTopInset = screenSafeAreaTopInset
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                TodayRootBackdrop()
                    .ignoresSafeArea()

                NavigationStack(path: $navigationPath) {
                    TodayRootScrollScreen(
                        title: "Today",
                        subtitle: "One mindful choice at a time.",
                        screenHeight: proxy.size.height,
                        topSafeAreaInset: resolvedScreenSafeAreaTopInset,
                        onOpenSettings: openSettings
                    ) {
                        TodayPrimaryResetCard(
                            appLimitPresentation: appLimitPresentation,
                            intentCount: todayIntentCount,
                            onStartReset: openBeforeFeedReset,
                            onOpenAppLimits: openAppLimits
                        )

                        TodayQuietMetricsCard(
                            quietMinutes: quietMinutesToday,
                            longestQuietMinutes: longestQuietToday
                        )
                        .padding(.top, 18)

                        TodaySecondaryContextCard(
                            focus: $todayFocus,
                            morningDurationText: MorningGate.formattedDuration(morningGateDurationSeconds),
                            onOpenMorningReset: openMorningReset,
                            onOpenWeekArchive: openWeekArchive
                        )
                        .padding(.top, 13)
                    }
                    .toolbar(.hidden, for: .navigationBar)
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .moriKeyboardDoneToolbar()
                    .navigationDestination(for: TodayNavigationRoute.self) { route in
                        switch route {
                        case .weekArchiveDetail:
                            WeekArchiveDetailView()
                        }
                    }
                }
                .background(Color.clear)
            }
        }
        .environment(\.moriOpenTodayRoute, TodayRouteAction { route in
            navigationPath.append(route)
        })
        .onAppear {
            todayFocus = TodayFocusDraftStore.live.load(for: Date())
            refreshIntentCount()
            AnalyticsManager.shared.trackTodayViewed()
            handleLaunchRequestIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .moriBeforeFeedIntentDidRecord)) { _ in
            refreshIntentCount()
        }
        .moriOnChange(of: todayFocus) { newValue in
            TodayFocusDraftStore.live.save(newValue, for: Date())
        }
        .moriOnChange(of: launchRequest?.id) { _ in
            handleLaunchRequestIfNeeded()
        }
    }

    private func openSettings() {
        openRoute(.settings)
    }

    private func refreshIntentCount() {
        todayIntentCount = BeforeFeedGateStore().todayIntentCount()
    }

    private func openAppLimits() {
        openRoute(.appLimits)
    }

    private func openBeforeFeedReset() {
        openRoute(.beforeFeedReset)
    }

    private func openMorningReset() {
        openRoute(.morningGateReset)
    }

    private func openWeekArchive() {
        navigationPath.append(.weekArchiveDetail)
    }

    private func handleLaunchRequestIfNeeded() {
        guard let launchRequest, handledLaunchRequestID != launchRequest.id else { return }
        handledLaunchRequestID = launchRequest.id

        switch launchRequest.kind {
        case .weekArchiveDetail:
            navigationPath = [.weekArchiveDetail]
        }
    }

}
