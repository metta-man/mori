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

    func testFollowOwnBreathAudioPolicyUsesOneOpeningBowlAndNoCompletionSound() {
        XCTAssertEqual(
            SettleBreathingCue.exhale.fileName,
            SettleBellTone.singingBowlA.fileName,
            "Follow-your-own mode should use the long Singing Bowl A recording."
        )
        XCTAssertTrue(
            MoriBeforeFeedOwnBreathAudioPolicy.shouldHandleOpeningCue(
                style: .quietPause,
                hasHandledOpeningCue: false
            )
        )
        XCTAssertFalse(
            MoriBeforeFeedOwnBreathAudioPolicy.shouldHandleOpeningCue(
                style: .quietPause,
                hasHandledOpeningCue: true
            ),
            "Resume and late sound enable must not replay the opening bowl."
        )
        XCTAssertFalse(
            MoriBeforeFeedOwnBreathAudioPolicy.shouldHandleOpeningCue(
                style: .guidedBreathing,
                hasHandledOpeningCue: false
            )
        )
        XCTAssertFalse(
            MoriBeforeFeedOwnBreathAudioPolicy.shouldPlayCompletionSound(style: .quietPause)
        )
        XCTAssertTrue(
            MoriBeforeFeedOwnBreathAudioPolicy.shouldPlayCompletionSound(style: .guidedBreathing)
        )
    }

    func testBeforeFeedFlowCannotOpenUntilBreathAndIntentAreComplete() {
        var state = MoriBeforeFeedFlowState()

        XCTAssertEqual(state.stage, .breathKey)
        XCTAssertFalse(state.hasCompletedBreath)
        XCTAssertFalse(state.canOpenFeed)
        XCTAssertNil(state.confirmedOpenWindowSeconds)

        state.selectReason(.relax)
        XCTAssertNil(state.reason, "Intent choices must stay locked before the breath key completes")
        XCTAssertFalse(state.selectEnoughChoice(.twoMinutes))

        XCTAssertTrue(state.completeBreath())
        XCTAssertEqual(state.stage, .intent)
        XCTAssertTrue(state.hasCompletedBreath)
        XCTAssertFalse(state.canOpenFeed)

        state.selectReason(.relax)
        XCTAssertFalse(state.selectEnoughChoice(.oneReply))
        XCTAssertTrue(state.selectEnoughChoice(.twoMinutes))
        XCTAssertTrue(state.canOpenFeed)
        XCTAssertEqual(state.confirmedOpenWindowSeconds, 2 * 60)
        XCTAssertNil(state.returnAnchor, "The return anchor remains optional")
        XCTAssertFalse(state.completeBreath(), "The breath transition is idempotent")
    }

    func testBeforeFeedBreathKeyIsExactlyOneLongExhale() {
        XCTAssertEqual(MoriBeforeFeedBreathKey.pattern.inhale, 4, accuracy: 0.000_001)
        XCTAssertNil(MoriBeforeFeedBreathKey.pattern.inhaleHold)
        XCTAssertEqual(MoriBeforeFeedBreathKey.pattern.exhale, 6, accuracy: 0.000_001)
        XCTAssertNil(MoriBeforeFeedBreathKey.pattern.exhaleHold)
        XCTAssertEqual(MoriBeforeFeedBreathKey.duration, 10, accuracy: 0.000_001)
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

    func testBeforeFeedReturnAnchorPromptShowsForEveryReason() {
        for reason in MoriBeforeFeedIntentReason.allCases {
            XCTAssertTrue(
                MoriBeforeFeedReturnAnchorPolicy.shouldShow(for: reason),
                "Expected the post-feed return question for \(reason.rawValue)."
            )
        }
    }

    func testFreshBeforeFeedPauseMigrationDefaultsToOneLongExhaleCycle() {
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
            XCTAssertEqual(preferences.guidedCycleCount(), 1)
            XCTAssertEqual(preferences.resolvedDuration(), 10, accuracy: 0.000_001)
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

    func testBeforeFeedPauseSessionSnapshotIsImmutableAndRoundsOnlyItsDisplay() {
        withDefaults { defaults, legacyDefaults in
            let preferences = MoriBeforeFeedPausePreferences(
                defaults: defaults,
                legacyDefaults: legacyDefaults
            )
            preferences.savePauseStyle(.guidedBreathing)
            preferences.saveTechniqueID(MoriBreathingTechniqueID.custom.rawValue)
            preferences.saveGuidedCycleCount(3)

            let snapshot = MoriBeforeFeedPauseSessionSnapshot(
                preferences: preferences,
                customInhaleSeconds: 4.5,
                customHoldSeconds: 1.5,
                customExhaleSeconds: 6.5,
                customUsesHold: true
            )

            XCTAssertEqual(snapshot.style, .guidedBreathing)
            XCTAssertEqual(snapshot.guidedCycleCount, 3)
            XCTAssertEqual(snapshot.pattern?.totalCycleDuration ?? 0, 12.5, accuracy: 0.000_001)
            XCTAssertEqual(snapshot.targetDuration, 37.5, accuracy: 0.000_001)
            XCTAssertEqual(snapshot.displayedDurationSeconds, 38)

            preferences.savePauseStyle(.quietPause)
            preferences.saveQuietDurationSeconds(10 * 60)
            preferences.saveTechniqueID(MoriBreathingTechniqueID.longExhale.rawValue)
            preferences.saveGuidedCycleCount(10)

            XCTAssertEqual(snapshot.style, .guidedBreathing)
            XCTAssertEqual(snapshot.guidedCycleCount, 3)
            XCTAssertEqual(snapshot.pattern?.totalCycleDuration ?? 0, 12.5, accuracy: 0.000_001)
            XCTAssertEqual(snapshot.targetDuration, 37.5, accuracy: 0.000_001)
            XCTAssertEqual(snapshot.displayedDurationSeconds, 38)
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

    func testFollowOwnBreathDurationOptionsCoverFullBoundedRange() {
        let options = MoriBeforeFeedPauseSettingsPresentation.ownBreathDurationOptions(current: 47)

        XCTAssertEqual(options.first, 10)
        XCTAssertEqual(options.last, 10 * 60)
        XCTAssertTrue(options.contains(47))
        XCTAssertTrue(options.allSatisfy { (10...(10 * 60)).contains($0) })
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
            XCTAssertEqual(legacyEvent?.reason, .learn)
            XCTAssertNil(legacyEvent?.enoughChoiceID)
            XCTAssertNil(legacyEvent?.openWindowSeconds)
            XCTAssertNil(legacyEvent?.returnAnchorID)
            XCTAssertEqual(legacyEvent?.resolvedOutcome, .openWindowRequested)

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
            XCTAssertEqual(recorded.resolvedOutcome, .openWindowRequested)
        }
    }

    func testBeforeFeedKeptClosedIsTruthfulIdempotentAndSeparateFromOpenIntent() {
        withDefaults { defaults, legacyDefaults in
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let now = Date(timeIntervalSince1970: 1_777_809_600)
            let keptClosedID = UUID()
            let store = BeforeFeedGateStore(defaults: defaults, legacyDefaults: legacyDefaults)

            let first = store.recordKeptClosed(
                routeSource: "screen_time_gate",
                eventID: keptClosedID,
                now: now
            )
            let duplicate = store.recordKeptClosed(
                routeSource: "shortcut",
                eventID: keptClosedID,
                now: now.addingTimeInterval(10)
            )
            _ = store.recordIntent(
                reason: .learn,
                routeSource: "screen_time_gate",
                enoughChoiceID: MoriBeforeFeedEnoughChoice.fiveMinutes.id,
                openWindowSeconds: MoriBeforeFeedEnoughChoice.fiveMinutes.openWindowSeconds,
                now: now.addingTimeInterval(20)
            )
            _ = store.recordKeptClosed(
                routeSource: nil,
                now: now.addingTimeInterval(-86_400)
            )

            XCTAssertEqual(first, duplicate)
            XCTAssertNil(first.reason)
            XCTAssertEqual(first.resolvedOutcome, .keptClosed)
            XCTAssertEqual(store.todayKeptClosedCount(now: now, calendar: calendar), 1)
            XCTAssertEqual(store.todayIntentCount(now: now, calendar: calendar), 1)
            XCTAssertNil(store.graceUntil(now: now))

            store.clearIntentHistory()
            XCTAssertEqual(store.todayKeptClosedCount(now: now, calendar: calendar), 0)
            XCTAssertEqual(store.todayIntentCount(now: now, calendar: calendar), 0)
        }
    }

    func testGuidedJournalAdvancesWithoutTypingAndAllowsJustRecordIt() {
        var state = JournalGuidedCheckInState()

        XCTAssertEqual(state.currentStep, .emotion)
        XCTAssertNil(state.emotion)
        XCTAssertFalse(state.canSave)

        state.selectEmotion(.calm)
        XCTAssertEqual(state.currentStep, .context)
        XCTAssertEqual(state.selectedTone, .positive)

        state.selectContext(.relationships)
        XCTAssertEqual(state.currentStep, .response)
        XCTAssertEqual(
            state.availableResponses,
            [.keepThisMoment, .thankSomeone, .continueThisDirection, .justRecordIt]
        )

        XCTAssertTrue(state.selectResponse(.justRecordIt))
        XCTAssertEqual(state.currentStep, .details)
        XCTAssertTrue(state.canSave)
    }

    func testGuidedJournalChangingToneInvalidatesUnavailableResponse() {
        var state = JournalGuidedCheckInState()
        state.selectEmotion(.anxious)
        state.selectContext(.workOrStudy)
        XCTAssertTrue(state.selectResponse(.separateFactsFromGuesses))

        state.edit(.emotion)
        state.selectEmotion(.hopeful)

        XCTAssertEqual(state.currentStep, .context)
        XCTAssertEqual(state.context, .workOrStudy)
        XCTAssertNil(state.response)
        XCTAssertFalse(state.canSave)
        XCTAssertFalse(state.availableResponses.contains(.separateFactsFromGuesses))
    }

    func testGuidedJournalRestoresCanonicalSelectionIntoDetails() {
        let entry = HabitEntry(
            date: Date(timeIntervalSince1970: 1_000),
            tone: .negative,
            createdAt: Date(timeIntervalSince1970: 1_001),
            note: "One sentence",
            trigger: JournalGuidedContext.money.title,
            feeling: JournalGuidedEmotion.hurt.title,
            responsePlan: JournalGuidedResponse.speakToMyselfLikeAFriend.title,
            journalEmotionID: JournalGuidedEmotion.hurt.id,
            journalContextID: JournalGuidedContext.money.id,
            journalResponseID: JournalGuidedResponse.speakToMyselfLikeAFriend.id
        )

        let state = JournalGuidedCheckInState(restoring: entry)

        XCTAssertEqual(state.currentStep, .details)
        XCTAssertEqual(state.emotion, .hurt)
        XCTAssertEqual(state.context, .money)
        XCTAssertEqual(state.response, .speakToMyselfLikeAFriend)
        XCTAssertTrue(state.canSave)
    }

    func testGuidedJournalDoesNotRestoreCanonicalSelectionWithMismatchedTone() {
        let entry = HabitEntry(
            date: Date(timeIntervalSince1970: 1_100),
            tone: .positive,
            createdAt: Date(timeIntervalSince1970: 1_101),
            journalEmotionID: JournalGuidedEmotion.anxious.id,
            journalContextID: JournalGuidedContext.workOrStudy.id,
            journalResponseID: JournalGuidedResponse.separateFactsFromGuesses.id
        )

        let state = JournalGuidedCheckInState(restoring: entry)

        XCTAssertEqual(state.currentStep, .emotion)
        XCTAssertNil(state.emotion)
        XCTAssertNil(state.context)
        XCTAssertNil(state.response)
        XCTAssertFalse(state.canSave)
    }

    func testHabitEntryGuidedFieldsDecodeBackwardCompatiblyAndRoundTrip() throws {
        let legacyEntry = HabitEntry(
            date: Date(timeIntervalSince1970: 2_000),
            tone: .neutral,
            createdAt: Date(timeIntervalSince1970: 2_001),
            note: "Legacy note"
        )
        let encoder = JSONEncoder()
        var legacyObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoder.encode(legacyEntry)) as? [String: Any]
        )
        legacyObject.removeValue(forKey: "journalEmotionID")
        legacyObject.removeValue(forKey: "journalContextID")
        legacyObject.removeValue(forKey: "journalResponseID")

        let decodedLegacy = try JSONDecoder().decode(
            HabitEntry.self,
            from: JSONSerialization.data(withJSONObject: legacyObject)
        )
        XCTAssertEqual(decodedLegacy.note, "Legacy note")
        XCTAssertNil(decodedLegacy.journalEmotionID)
        XCTAssertNil(decodedLegacy.journalContextID)
        XCTAssertNil(decodedLegacy.journalResponseID)

        let guidedEntry = HabitEntry(
            date: Date(timeIntervalSince1970: 3_000),
            tone: .neutral,
            createdAt: Date(timeIntervalSince1970: 3_001),
            journalEmotionID: JournalGuidedEmotion.unclear.id,
            journalContextID: JournalGuidedContext.notSure.id,
            journalResponseID: JournalGuidedResponse.justRecordIt.id
        )
        let roundTripped = try JSONDecoder().decode(
            HabitEntry.self,
            from: encoder.encode(guidedEntry)
        )
        XCTAssertEqual(roundTripped.journalEmotionID, "unclear")
        XCTAssertEqual(roundTripped.journalContextID, "not-sure")
        XCTAssertEqual(roundTripped.journalResponseID, "just-record-it")
    }

    func testPatternEditPreservesCompatibleGuidedIDsAndClearsThemAfterRetone() {
        withDefaults { defaults, _ in
            let manager = HabitDataManager(
                store: HabitEntryStore(
                    defaults: defaults,
                    notificationCenter: NotificationCenter()
                )
            )

            _ = manager.saveEntry(
                tone: .negative,
                note: "Kept note",
                trigger: JournalGuidedContext.workOrStudy.title,
                feeling: JournalGuidedEmotion.anxious.title,
                responsePlan: JournalGuidedResponse.takeOneSmallStep.title,
                journalEmotionID: JournalGuidedEmotion.anxious.id,
                journalContextID: JournalGuidedContext.workOrStudy.id,
                journalResponseID: JournalGuidedResponse.takeOneSmallStep.id
            )

            let patternEdited = manager.saveEntry(
                tone: .negative,
                note: "Kept note",
                trigger: "A changed trigger",
                thought: "A closer look",
                feeling: "Anxious",
                responsePlan: "Take one small step"
            )
            XCTAssertEqual(patternEdited.journalEmotionID, "anxious")
            XCTAssertEqual(patternEdited.journalContextID, "work-or-study")
            XCTAssertEqual(patternEdited.journalResponseID, "take-one-small-step")
            XCTAssertEqual(manager.getEntries(from: .distantPast, to: .distantFuture).count, 1)

            let retoned = manager.saveEntry(
                tone: .positive,
                note: "Kept note",
                trigger: "A changed trigger",
                thought: "A closer look",
                feeling: "Hopeful",
                responsePlan: "Continue this direction"
            )
            XCTAssertNil(retoned.journalEmotionID)
            XCTAssertNil(retoned.journalContextID)
            XCTAssertNil(retoned.journalResponseID)
        }
    }

    func testGuidedResavePreservesPatternDetailsUntilItsSelectionChanges() throws {
        try withDefaults { defaults, _ in
            let manager = HabitDataManager(
                store: HabitEntryStore(
                    defaults: defaults,
                    notificationCenter: NotificationCenter()
                )
            )
            _ = manager.saveEntry(
                tone: .negative,
                note: "Original note",
                trigger: JournalGuidedContext.workOrStudy.title,
                feeling: JournalGuidedEmotion.anxious.title,
                responsePlan: JournalGuidedResponse.separateFactsFromGuesses.title,
                journalEmotionID: JournalGuidedEmotion.anxious.id,
                journalContextID: JournalGuidedContext.workOrStudy.id,
                journalResponseID: JournalGuidedResponse.separateFactsFromGuesses.id
            )
            let patternEditedEntry = manager.saveEntry(
                tone: .negative,
                note: "Original note",
                trigger: "A specific meeting",
                thought: "They may reject the proposal",
                feeling: "Tight chest",
                responsePlan: "Ask one clarifying question"
            )

            var state = JournalGuidedCheckInState(restoring: patternEditedEntry)
            let unchanged = try XCTUnwrap(state.legacyFields(preserving: patternEditedEntry))
            let resavedEntry = manager.saveEntry(
                tone: try XCTUnwrap(state.selectedTone),
                note: "Updated note",
                trigger: unchanged.trigger,
                thought: unchanged.thought,
                feeling: unchanged.feeling,
                responsePlan: unchanged.responsePlan,
                journalEmotionID: state.emotion?.id,
                journalContextID: state.context?.id,
                journalResponseID: state.response?.id
            )
            XCTAssertEqual(resavedEntry.note, "Updated note")
            XCTAssertEqual(resavedEntry.trigger, "A specific meeting")
            XCTAssertEqual(resavedEntry.thought, "They may reject the proposal")
            XCTAssertEqual(resavedEntry.feeling, "Tight chest")
            XCTAssertEqual(resavedEntry.responsePlan, "Ask one clarifying question")

            state.edit(.emotion)
            state.selectEmotion(.hopeful)
            state.selectContext(.workOrStudy)
            XCTAssertTrue(state.selectResponse(.continueThisDirection))
            let changed = try XCTUnwrap(state.legacyFields(preserving: resavedEntry))
            XCTAssertEqual(changed.trigger, "A specific meeting")
            XCTAssertEqual(changed.thought, "They may reject the proposal")
            XCTAssertEqual(changed.feeling, JournalGuidedEmotion.hopeful.title)
            XCTAssertEqual(changed.responsePlan, JournalGuidedResponse.continueThisDirection.title)
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
