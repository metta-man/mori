import Foundation
import WatchConnectivity
#if canImport(WidgetKit)
import WidgetKit
#endif

final class MoriWatchSettingsSync: NSObject {
    static let shared = MoriWatchSettingsSync()

    private var pendingContext: [String: Any]?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        session.delegate = self

        if session.activationState == .notActivated {
            session.activate()
        }
    }

    func send(
        archiveStartDate: Date,
        archiveSpanYears: Int,
        localePreference: String
    ) {
        guard WCSession.isSupported() else { return }

        enqueue([
            "archiveStartDate": archiveStartDate,
            "archiveSpanYears": archiveSpanYears,
            MoriLocalePreference.defaultsKey: localePreference
        ])
    }

    func sendWidgetContext(_ snapshot: MoriWidgetContextSnapshot) {
        guard let data = snapshot.encodedData else { return }

        enqueue([
            MoriWidgetContextSnapshot.watchApplicationContextKey: data
        ])
    }

    private func enqueue(_ values: [String: Any]) {
        guard WCSession.isSupported() else { return }

        var context = WCSession.default.applicationContext
        if let pendingContext {
            context.merge(pendingContext) { _, pending in pending }
        }
        context.merge(values) { _, new in new }
        pendingContext = context
        activate()
        flushPendingContext()
    }

    private func flushPendingContext() {
        guard
            let context = pendingContext,
            WCSession.default.activationState == .activated,
            WCSession.default.isWatchAppInstalled
        else { return }

        do {
            try WCSession.default.updateApplicationContext(context)
            pendingContext = nil
        } catch {
            pendingContext = context
        }
    }
}

extension MoriWatchSettingsSync: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        flushPendingContext()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}

@MainActor
enum MoriWidgetContextPublisher {
    static func publish(
        settings: UserSettings? = nil,
        clarityStore: MoriClarityStore? = nil,
        now: Date = Date(),
        reloadTimelines: Bool = true
    ) {
        let clarityStore = clarityStore ?? .shared
        let snapshot = makeSnapshot(
            settings: settings,
            clarityStore: clarityStore,
            now: now
        )

        snapshot.save()
        MoriWatchSettingsSync.shared.sendWidgetContext(snapshot)

        guard reloadTimelines else { return }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "MoriWidgets")
        WidgetCenter.shared.reloadTimelines(ofKind: "MoriPulseWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "MoriJournalQuickStartWidget")
        #endif
    }

    private static func makeSnapshot(
        settings: UserSettings?,
        clarityStore: MoriClarityStore,
        now: Date
    ) -> MoriWidgetContextSnapshot {
        let existingSnapshot = MoriWidgetContextSnapshot.load()
        let metricSummary = metricsSummary(
            settings: settings,
            clarityStore: clarityStore
        )
        let suggestedPractice = clarityStore.suggestedPracticeForToday(date: now)
        let pulseSummary = pulseSummary(
            from: clarityStore.latestPulse,
            now: now
        )

        return MoriWidgetContextSnapshot(
            pulseHeadline: pulseSummary.headline,
            pulseTopic: pulseSummary.topic,
            pulseGeneratedAt: pulseSummary.generatedAt,
            isPulseFreshToday: pulseSummary.isFreshToday,
            clarityScore: metricSummary.clarityScore,
            seedsToday: metricSummary.seedsToday,
            bloomProgress: metricSummary.bloomProgress,
            reclaimedMinutesToday: metricSummary.reclaimedMinutesToday,
            suggestedPracticeTitle: suggestedPractice.title,
            suggestedPracticeIcon: suggestedPractice.icon,
            recoveryScore: existingSnapshot.recoveryScore,
            recoveryStateTitle: existingSnapshot.recoveryStateTitle,
            recoveryStateDetail: existingSnapshot.recoveryStateDetail,
            recoverySuggestedPracticeTitle: existingSnapshot.recoverySuggestedPracticeTitle,
            recoverySuggestedPracticeIcon: existingSnapshot.recoverySuggestedPracticeIcon,
            recoveryUpdatedAt: existingSnapshot.recoveryUpdatedAt,
            updatedAt: now
        )
    }

    private static func metricsSummary(
        settings: UserSettings?,
        clarityStore: MoriClarityStore
    ) -> MoriWidgetMetricSummary {
        if let settings {
            let metrics = clarityStore.metrics(settings: settings)
            return MoriWidgetMetricSummary(
                clarityScore: metrics.clarityScore,
                seedsToday: metrics.seedsToday,
                bloomProgress: metrics.bloomProgress,
                reclaimedMinutesToday: metrics.reclaimedMinutesToday
            )
        }

        let todayActions = clarityStore.actions()
        let seeds = todayActions.reduce(0) { $0 + $1.seeds }
        let quietMinutes = todayActions
            .filter {
                $0.kind == .quietTimer ||
                    $0.kind == .replacementAction ||
                    $0.kind == .urgeCheckIn ||
                    $0.kind == .breathingSession ||
                    $0.kind == .pomodoroSession
            }
            .reduce(0) { $0 + $1.minutes }
        let pulseMinutes: Int
        if let latestPulse = clarityStore.latestPulse,
           latestPulse.dateKey == MoriDateKey.value() {
            pulseMinutes = latestPulse.reclaimedMinutes
        } else {
            pulseMinutes = 0
        }
        let reclaimedMinutes = todayActions
            .filter { $0.kind == .pulseRead || $0.kind == .resetAction }
            .reduce(pulseMinutes) { $0 + $1.minutes }
        let clarityScore = max(0, min(100, 46 + seeds * 4 + min(16, quietMinutes / 2) + min(12, reclaimedMinutes / 5)))

        return MoriWidgetMetricSummary(
            clarityScore: clarityScore,
            seedsToday: seeds,
            bloomProgress: min(1, Double(seeds) / 24.0),
            reclaimedMinutesToday: reclaimedMinutes
        )
    }

    private static func pulseSummary(
        from pulse: MoriDailyPulse?,
        now: Date
    ) -> MoriWidgetPulseSummary {
        guard let pulse,
              pulse.dateKey == MoriDateKey.value(for: now) else {
            return MoriWidgetPulseSummary()
        }

        let topicPulse = pulse.displayTopicPulses.first
        let topicCard = topicPulse?.cards.first { $0.kind == .worthKnowing } ?? topicPulse?.cards.first
        let sharedCard = pulse.displaySharedCards.first { $0.kind == .resetAction } ?? pulse.displaySharedCards.first
        let card = topicCard ?? sharedCard
        let headline = card?.headline
        let topic = topicPulse?.topic ?? pulse.topics.first

        return MoriWidgetPulseSummary(
            headline: headline,
            topic: topic,
            generatedAt: pulse.generatedAt,
            isFreshToday: headline?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        )
    }
}

private struct MoriWidgetMetricSummary {
    let clarityScore: Int
    let seedsToday: Int
    let bloomProgress: Double
    let reclaimedMinutesToday: Int
}

private struct MoriWidgetPulseSummary {
    let headline: String?
    let topic: String?
    let generatedAt: Date?
    let isFreshToday: Bool

    init(
        headline: String? = nil,
        topic: String? = nil,
        generatedAt: Date? = nil,
        isFreshToday: Bool = false
    ) {
        self.headline = headline
        self.topic = topic
        self.generatedAt = generatedAt
        self.isFreshToday = isFreshToday
    }
}
