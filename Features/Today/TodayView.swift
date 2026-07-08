import SwiftUI

struct TodayView: View {
    @Environment(\.moriOpenRoute) private var openRoute

    let launchRequest: MoriTodayLaunchRequest?

    @StateObject private var appLimitManager = AppLimitManager.shared
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

    private var appLimitPresentation: TodayAppLimitPresentation {
        TodayAppLimitPresentation(
            snapshot: appLimitManager.settingsSnapshot,
            durationSeconds: beforeFeedDurationSeconds,
            graceWindowSeconds: beforeFeedGraceWindowSeconds,
            breathingTechniqueID: beforeFeedBreathingTechniqueID
        )
    }

    init(
        launchRequest: MoriTodayLaunchRequest? = nil
    ) {
        self.launchRequest = launchRequest
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MoriRootScrollScreen(
                title: "Today",
                subtitle: "Limit one app. Do one reset. Leave.",
                spacing: 14,
                backgroundVariant: .today
            ) {
                Button(action: openSettings) {
                    MoriBitmapIconImage(icon: .settings, size: 23, opacity: 0.94)
                        .frame(width: 48, height: 48)
                        .background(MoriColors.sanctuarySurface.opacity(0.70))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(MoriL10n.display("Settings"))
            } content: {
                TodayAppLimitCard(
                    presentation: appLimitPresentation,
                    onOpenAppLimits: openAppLimits
                )

                TodayPrimaryResetCard(
                    durationText: BeforeFeedGate.formattedDuration(beforeFeedDurationSeconds),
                    onStartReset: openBeforeFeedReset
                )

                TodayFocusCard(focus: $todayFocus)

                TodayQuickActionsCard(
                    morningDurationText: MorningGate.formattedDuration(morningGateDurationSeconds),
                    onOpenMorningReset: openMorningReset,
                    onOpenAppLimits: openAppLimits
                )
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .moriKeyboardDoneToolbar()
            .navigationDestination(for: TodayNavigationRoute.self) { route in
                switch route {
                case .weekArchiveDetail:
                    WeekArchiveDetailView()
                }
            }
        }
        .environment(\.moriOpenTodayRoute, TodayRouteAction { route in
            navigationPath.append(route)
        })
        .onAppear {
            todayFocus = TodayFocusDraftStore.live.load(for: Date())
            AnalyticsManager.shared.trackTodayViewed()
            handleLaunchRequestIfNeeded()
        }
        .onChange(of: todayFocus) { newValue in
            TodayFocusDraftStore.live.save(newValue, for: Date())
        }
        .onChange(of: launchRequest?.id) { _ in
            handleLaunchRequestIfNeeded()
        }
    }

    private func openSettings() {
        openRoute(.settings)
    }

    private func openAppLimits() {
        openRoute(.appLimitSetup)
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
