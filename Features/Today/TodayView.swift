import SwiftUI
import FamilyControls
import UIKit

struct TodayView: View {
    @Environment(\.moriOpenRoute) private var openRoute
    @Environment(\.moriOpenTodayRoute) private var openTodayRoute
    @EnvironmentObject private var settings: UserSettings

    let launchRequest: MoriTodayLaunchRequest?

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
        MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedBreathingTechniqueID: String = MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
    @AppStorage(
        MoriScreenTimeShared.beforeFeedPauseStyleKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedPauseStyleRaw: String = MoriBeforeFeedPauseStyle.guidedBreathing.rawValue
    @AppStorage(
        MoriScreenTimeShared.beforeFeedGuidedCycleCountKey,
        store: MoriAppGroup.defaults
    ) private var beforeFeedGuidedCycleCount: Int = MoriBeforeFeedPausePreferences.defaultGuidedCycleCount
    @State private var todayFocus = TodayFocusDraftStore.live.load(for: Date())
    @State private var handledLaunchRequestID: UUID?
    @State private var todayKeptClosedCount = BeforeFeedGateStore().todayKeptClosedCount()

    private var appLimitPresentation: TodayAppLimitPresentation {
        TodayAppLimitPresentation(
            snapshot: appLimitManager.settingsSnapshot,
            effectiveSelection: effectiveBeforeFeedSelection,
            pauseStyle: MoriBeforeFeedPauseStyle(rawValue: beforeFeedPauseStyleRaw) ?? .guidedBreathing,
            guidedCycleCount: beforeFeedGuidedCycleCount,
            quietDurationSeconds: beforeFeedDurationSeconds,
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

    init(launchRequest: MoriTodayLaunchRequest? = nil) {
        self.launchRequest = launchRequest
    }

    var body: some View {
        TodayRootScrollScreen(
            title: "Today",
            subtitle: "One mindful choice at a time.",
            onOpenSettings: openSettings
        ) {
            TodayPrimaryResetCard(
                appLimitPresentation: appLimitPresentation,
                keptClosedCount: todayKeptClosedCount,
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
                onOpenWeekArchive: openWeekArchive,
                onOpenRecovery: openRecovery
            )
            .padding(.top, 13)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .moriKeyboardDoneToolbar()
        .onAppear {
            todayFocus = TodayFocusDraftStore.live.load(for: Date())
            refreshKeptClosedCount()
            AnalyticsManager.shared.trackTodayViewed()
            handleLaunchRequestIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .moriBeforeFeedDecisionDidRecord)) { _ in
            refreshKeptClosedCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshKeptClosedCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshKeptClosedCount()
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

    private func refreshKeptClosedCount() {
        todayKeptClosedCount = BeforeFeedGateStore().todayKeptClosedCount()
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
        openTodayRoute(.weekArchiveDetail)
    }

    private func openRecovery() {
        openTodayRoute(.recovery)
    }

    private func handleLaunchRequestIfNeeded() {
        guard let launchRequest, handledLaunchRequestID != launchRequest.id else { return }
        handledLaunchRequestID = launchRequest.id

        switch launchRequest.kind {
        case .weekArchiveDetail:
            openTodayRoute(.weekArchiveDetail)
        case .recovery:
            openTodayRoute(.recovery)
        }
    }

}
