import XCTest
@testable import Mori

final class MoriRoutingTests: XCTestCase {
    func testRecoveryDeepLinkOpensRecovery() {
        let request = MoriAppRouteRequest(url: URL(string: "mori://recovery")!)
        guard case .todayLaunch(.recovery) = request.route else {
            return XCTFail("Recovery link did not open Recovery")
        }
    }

    func testReleasePulseBoundary() {
        #if !DEBUG
        guard case .todayLaunch(.recovery) = MoriAppRoute.pulseSheet else {
            return XCTFail("Pulse must be hidden in release builds")
        }
        #endif
    }

    func testBeforeFeedTerminalCueSchedulesDuringEarlierCycle() {
        XCTAssertTrue(
            MoriBreathingTerminalCuePolicy.shouldScheduleNextPhaseCue(
                sessionRemaining: 16,
                phaseRemaining: 6
            )
        )
    }

    func testBeforeFeedTerminalCueSuppressesExactFinalBoundary() {
        XCTAssertFalse(
            MoriBreathingTerminalCuePolicy.shouldScheduleNextPhaseCue(
                sessionRemaining: 6,
                phaseRemaining: 6
            )
        )
    }

    func testBeforeFeedTerminalCueSuppressesWithinTimingEpsilon() {
        XCTAssertFalse(
            MoriBreathingTerminalCuePolicy.shouldScheduleNextPhaseCue(
                sessionRemaining: 6 + (MoriBreathingTerminalCuePolicy.timingEpsilon / 2),
                phaseRemaining: 6
            )
        )
    }

    func testBeforeFeedTerminalCueSchedulesWhenResumeHasAnotherPhase() {
        XCTAssertTrue(
            MoriBreathingTerminalCuePolicy.shouldScheduleNextPhaseCue(
                sessionRemaining: 6 + MoriBreathingTerminalCuePolicy.timingEpsilon + 0.001,
                phaseRemaining: 6
            )
        )
    }

    func testBeforeFeedTerminalCueFailsClosedForInvalidTiming() {
        XCTAssertFalse(
            MoriBreathingTerminalCuePolicy.shouldScheduleNextPhaseCue(
                sessionRemaining: .infinity,
                phaseRemaining: 6
            )
        )
        XCTAssertFalse(
            MoriBreathingTerminalCuePolicy.shouldScheduleNextPhaseCue(
                sessionRemaining: 16,
                phaseRemaining: .nan
            )
        )
        XCTAssertFalse(
            MoriBreathingTerminalCuePolicy.shouldScheduleNextPhaseCue(
                sessionRemaining: 16,
                phaseRemaining: 0
            )
        )
    }

    func testAttentionResetCompletionTonesKeepBeforeFeedDistinct() {
        let beforeFeedTone = MoriAttentionResetCuePolicy.completionTone(for: .beforeFeed)

        XCTAssertEqual(beforeFeedTone, .defaultChime)
        XCTAssertNotEqual(beforeFeedTone.fileName, SettleBreathingCue.exhale.fileName)
        XCTAssertEqual(
            MoriAttentionResetCuePolicy.completionTone(for: .morningGate),
            .singingBowlA
        )
        XCTAssertEqual(
            MoriBreathingSessionFeedbackCoordinator.defaultCompletionTone,
            .singingBowlA
        )
    }

    func testBeforeFeedFlowCannotOpenUntilPauseCompletes() {
        var state = MoriBeforeFeedFlowState()

        XCTAssertFalse(state.canOpenFeed)
        XCTAssertNil(state.confirmedOpenWindowSeconds)
        XCTAssertFalse(state.proceedToPlan())

        state.selectReason(.relax)
        XCTAssertTrue(state.proceedToPlan())
        XCTAssertFalse(state.selectEnoughChoice(.oneReply))
        XCTAssertFalse(state.beginPause())
        XCTAssertTrue(state.selectEnoughChoice(.twoMinutes))
        XCTAssertTrue(state.beginPause())
        XCTAssertFalse(state.canOpenFeed)
        XCTAssertNil(state.confirmedOpenWindowSeconds)

        XCTAssertTrue(state.completePause())
        XCTAssertTrue(state.canOpenFeed)
        XCTAssertEqual(state.confirmedOpenWindowSeconds, 2 * 60)
    }

    func testBeforeFeedEnoughChoicesMapToBoundedWindows() {
        XCTAssertEqual(MoriBeforeFeedEnoughChoice.oneReply.openWindowSeconds, 5 * 60)
        XCTAssertEqual(MoriBeforeFeedEnoughChoice.twoMinutes.openWindowSeconds, 2 * 60)
        XCTAssertEqual(MoriBeforeFeedEnoughChoice.fiveMinutes.openWindowSeconds, 5 * 60)
        XCTAssertEqual(MoriBeforeFeedEnoughChoice.tenMinutes.openWindowSeconds, 10 * 60)
        XCTAssertEqual(MoriBeforeFeedEnoughChoice.fifteenMinutes.openWindowSeconds, 15 * 60)
        XCTAssertTrue(MoriBeforeFeedEnoughChoice.oneReply.isAvailable(for: .replyToSomeone))
        XCTAssertFalse(MoriBeforeFeedEnoughChoice.oneReply.isAvailable(for: .learn))
        XCTAssertTrue(
            MoriBeforeFeedEnoughChoice.choices(for: .replyToSomeone).contains(.oneReply)
        )
        XCTAssertFalse(MoriBeforeFeedEnoughChoice.choices(for: .habit).contains(.oneReply))
    }

    func testBeforeFeedAdaptiveReturnAnchorPolicyUsesHabitOrRecentIntent() {
        let now = Date(timeIntervalSince1970: 10_000)
        let recentEvent = MoriBeforeFeedIntentEvent(
            id: UUID(),
            reason: .learn,
            confirmedAt: now.addingTimeInterval(-(10 * 60) + 1),
            routeSource: nil
        )
        let staleEvent = MoriBeforeFeedIntentEvent(
            id: UUID(),
            reason: .relax,
            confirmedAt: now.addingTimeInterval(-(10 * 60) - 1),
            routeSource: nil
        )

        XCTAssertTrue(
            MoriBeforeFeedAdaptivePolicy.shouldShowReturnAnchors(
                reason: .habit,
                recentIntentEvents: [],
                now: now
            )
        )
        XCTAssertTrue(
            MoriBeforeFeedAdaptivePolicy.shouldShowReturnAnchors(
                reason: .learn,
                recentIntentEvents: [recentEvent],
                now: now
            )
        )
        XCTAssertFalse(
            MoriBeforeFeedAdaptivePolicy.shouldShowReturnAnchors(
                reason: .learn,
                recentIntentEvents: [staleEvent],
                now: now
            )
        )
    }

    func testFreshBeforeFeedPauseMigrationDefaultsToThreeLongExhaleCycles() {
        withDefaults { defaults, legacyDefaults in
            let preferences = MoriBeforeFeedPausePreferences(
                defaults: defaults,
                legacyDefaults: legacyDefaults
            )

            preferences.migrateLegacyPausePreferencesIfNeeded()

            XCTAssertEqual(preferences.pauseStyle(), .guidedBreathing)
            XCTAssertEqual(
                preferences.techniqueID(),
                MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
            )
            XCTAssertEqual(preferences.guidedCycleCount(), 3)
            XCTAssertEqual(preferences.resolvedDuration(), 30, accuracy: 0.000_001)
            XCTAssertTrue(
                defaults.bool(forKey: MoriScreenTimeShared.beforeFeedPausePreferencesMigrationKey)
            )
        }
    }

    func testLegacyNoneMigratesToQuietPauseAndPreservesSeconds() {
        withDefaults { defaults, legacyDefaults in
            defaults.set(
                MoriScreenTimeShared.beforeFeedBreathingNoneID,
                forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey
            )
            defaults.set(8 * 60, forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey)
            let preferences = MoriBeforeFeedPausePreferences(
                defaults: defaults,
                legacyDefaults: legacyDefaults
            )

            preferences.migrateLegacyPausePreferencesIfNeeded()

            XCTAssertEqual(preferences.pauseStyle(), .quietPause)
            XCTAssertEqual(preferences.quietDurationSeconds(), 8 * 60)
            XCTAssertEqual(preferences.resolvedDuration(), 8 * 60, accuracy: 0.000_001)
        }
    }

    func testLegacyNoneMinutesMigrateBeforeExistingDurationMigration() {
        withDefaults { defaults, legacyDefaults in
            defaults.set(
                MoriScreenTimeShared.beforeFeedBreathingNoneID,
                forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey
            )
            legacyDefaults.set(5, forKey: MoriScreenTimeShared.beforeFeedDurationMinutesKey)
            let preferences = MoriBeforeFeedPausePreferences(
                defaults: defaults,
                legacyDefaults: legacyDefaults
            )
            let gateStore = BeforeFeedGateStore(
                defaults: defaults,
                legacyDefaults: legacyDefaults
            )

            preferences.migrateLegacyPausePreferencesIfNeeded()
            XCTAssertNil(defaults.object(forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey))
            gateStore.migrateLegacyDurationIfNeeded()

            XCTAssertEqual(preferences.pauseStyle(), .quietPause)
            XCTAssertEqual(preferences.quietDurationSeconds(), 5 * 60)
        }
    }

    func testLegacyGuidedDurationMigratesToNearestCompleteCycleAndIsIdempotent() {
        withDefaults { defaults, legacyDefaults in
            defaults.set(
                MoriBreathingTechniqueID.longExhale.rawValue,
                forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey
            )
            defaults.set(64, forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey)
            let preferences = MoriBeforeFeedPausePreferences(
                defaults: defaults,
                legacyDefaults: legacyDefaults
            )

            preferences.migrateLegacyPausePreferencesIfNeeded()
            XCTAssertEqual(preferences.guidedCycleCount(), 6)

            defaults.set(5 * 60, forKey: MoriScreenTimeShared.beforeFeedDurationSecondsKey)
            preferences.migrateLegacyPausePreferencesIfNeeded()

            XCTAssertEqual(preferences.guidedCycleCount(), 6)
            XCTAssertEqual(preferences.resolvedDuration(), 60, accuracy: 0.000_001)
        }
    }

    func testBeforeFeedPauseDurationUsesExactCycleLengthIncludingHalfSeconds() {
        withDefaults { defaults, legacyDefaults in
            let preferences = MoriBeforeFeedPausePreferences(
                defaults: defaults,
                legacyDefaults: legacyDefaults
            )
            preferences.savePauseStyle(.guidedBreathing)
            preferences.saveTechniqueID(MoriBreathingTechniqueID.custom.rawValue)
            preferences.saveGuidedCycleCount(3)

            let pattern = preferences.resolvedPattern(
                customInhaleSeconds: 4.5,
                customHoldSeconds: 1.5,
                customExhaleSeconds: 6.5,
                customUsesHold: true
            )

            XCTAssertNotNil(pattern)
            XCTAssertEqual(pattern!.totalCycleDuration, 12.5, accuracy: 0.000_001)
            XCTAssertEqual(
                preferences.resolvedDuration(
                    customInhaleSeconds: 4.5,
                    customHoldSeconds: 1.5,
                    customExhaleSeconds: 6.5,
                    customUsesHold: true
                ),
                37.5,
                accuracy: 0.000_001
            )
        }
    }

    func testBeforeFeedPausePreferencesNormalizeCorruptedValues() {
        withDefaults { defaults, legacyDefaults in
            defaults.set("unexpected", forKey: MoriScreenTimeShared.beforeFeedPauseStyleKey)
            defaults.set(99, forKey: MoriScreenTimeShared.beforeFeedGuidedCycleCountKey)
            defaults.set("missing-technique", forKey: MoriScreenTimeShared.beforeFeedBreathingTechniqueIDKey)
            let preferences = MoriBeforeFeedPausePreferences(
                defaults: defaults,
                legacyDefaults: legacyDefaults
            )

            XCTAssertEqual(preferences.pauseStyle(), .guidedBreathing)
            XCTAssertEqual(preferences.guidedCycleCount(), 10)
            XCTAssertEqual(
                preferences.techniqueID(),
                MoriScreenTimeShared.defaultBeforeFeedBreathingTechniqueID
            )

            preferences.saveTechniqueID(MoriBreathingTechniqueID.custom.rawValue)
            let pattern = preferences.resolvedPattern(
                customInhaleSeconds: -20,
                customHoldSeconds: .infinity,
                customExhaleSeconds: 40,
                customUsesHold: true
            )
            XCTAssertNotNil(pattern)
            XCTAssertEqual(pattern!.inhale, 1)
            XCTAssertEqual(pattern!.inhaleHold, 1)
            XCTAssertEqual(pattern!.exhale, 20)
        }
    }

    func testQuietPauseAcceptsTenSecondsAndPreservesLegacyMaximum() {
        withDefaults { defaults, legacyDefaults in
            let preferences = MoriBeforeFeedPausePreferences(
                defaults: defaults,
                legacyDefaults: legacyDefaults
            )
            preferences.savePauseStyle(.quietPause)

            preferences.saveQuietDurationSeconds(10)
            XCTAssertEqual(preferences.quietDurationSeconds(), 10)
            XCTAssertEqual(preferences.resolvedDuration(), 10, accuracy: 0.000_001)

            preferences.saveQuietDurationSeconds(10 * 60)
            XCTAssertEqual(preferences.quietDurationSeconds(), 10 * 60)
        }
    }

    func testPerSessionBeforeFeedWindowClampsWithoutMutatingSavedDefault() {
        withDefaults { defaults, legacyDefaults in
            let store = BeforeFeedGateStore(defaults: defaults, legacyDefaults: legacyDefaults)
            store.saveGraceWindowSeconds(10 * 60)

            XCTAssertEqual(store.resolvedGraceWindowSeconds(override: nil), 10 * 60)
            XCTAssertEqual(store.resolvedGraceWindowSeconds(override: 0), 60)
            XCTAssertEqual(store.resolvedGraceWindowSeconds(override: 5 * 60), 5 * 60)
            XCTAssertEqual(store.resolvedGraceWindowSeconds(override: 60 * 60), 15 * 60)
            XCTAssertEqual(store.graceWindowSeconds(), 10 * 60)
        }
    }

    func testBeforeFeedIntentEventDecodesLegacyPayloadAndRecordsOptionalPlan() throws {
        withDefaults { defaults, legacyDefaults in
            let eventID = UUID()
            let confirmedAt = Date(timeIntervalSince1970: 1_000)
            let legacyPayload: [[String: Any]] = [[
                "id": eventID.uuidString,
                "reason": MoriBeforeFeedIntentReason.learn.rawValue,
                "confirmedAt": confirmedAt.timeIntervalSinceReferenceDate,
                "routeSource": "shortcut"
            ]]
            let data = try! JSONSerialization.data(withJSONObject: legacyPayload)
            defaults.set(data, forKey: "mori_before_feed_intent_events_v1")
            let store = BeforeFeedGateStore(defaults: defaults, legacyDefaults: legacyDefaults)

            let legacyEvent = store.intentEvents().first
            XCTAssertEqual(legacyEvent?.id, eventID)
            XCTAssertNil(legacyEvent?.enoughChoiceID)
            XCTAssertNil(legacyEvent?.openWindowSeconds)
            XCTAssertNil(legacyEvent?.returnAnchorID)

            let recorded = store.recordIntent(
                reason: .replyToSomeone,
                routeSource: "screen_time_gate",
                enoughChoiceID: MoriBeforeFeedEnoughChoice.oneReply.id,
                openWindowSeconds: MoriBeforeFeedEnoughChoice.oneReply.openWindowSeconds,
                returnAnchorID: MoriBeforeFeedReturnAnchor.someone.id,
                now: confirmedAt.addingTimeInterval(1)
            )
            XCTAssertEqual(recorded.enoughChoiceID, MoriBeforeFeedEnoughChoice.oneReply.id)
            XCTAssertEqual(recorded.openWindowSeconds, 5 * 60)
            XCTAssertEqual(recorded.returnAnchorID, MoriBeforeFeedReturnAnchor.someone.id)
        }
    }

    private func withDefaults(
        _ body: (UserDefaults, UserDefaults) throws -> Void
    ) rethrows {
        let defaultsSuite = "MoriRoutingTests.Defaults.\(UUID().uuidString)"
        let legacySuite = "MoriRoutingTests.Legacy.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: defaultsSuite)!
        let legacyDefaults = UserDefaults(suiteName: legacySuite)!
        defer {
            defaults.removePersistentDomain(forName: defaultsSuite)
            legacyDefaults.removePersistentDomain(forName: legacySuite)
        }
        try body(defaults, legacyDefaults)
    }
}
