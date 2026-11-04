import XCTest
@testable import Mori

@MainActor
final class MoriJournalMoodTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)
    private func mood() -> MoriJournalMood {
        .editing(nil, valence: .unpleasant, emotionID: "anxious", contextID: "money", now: now)
    }
    func testEditingKeepsIdentityTimestampAndAdvancesOnlyMoodRevision() throws {
        let first = mood()
        XCTAssertEqual(MoriJournalMood.editing(first, valence: first.valence,
            emotionID: first.emotionID, contextID: first.contextID, now: now.addingTimeInterval(60)), first)
        let edited = MoriJournalMood.editing(first, valence: .neutral,
            emotionID: first.emotionID, contextID: first.contextID, now: now.addingTimeInterval(60))
        XCTAssertEqual(edited.id, first.id)
        XCTAssertEqual(edited.recordedAt, first.recordedAt)
        XCTAssertEqual(edited.version, 2)
        XCTAssertEqual(edited.syncIdentifier, first.syncIdentifier)
        XCTAssertEqual(try JSONDecoder().decode(MoriJournalMood.self, from: JSONEncoder().encode(edited)), edited)
    }
    func testNoProseOrAmbiguousLabelsAreInHealthInput() throws {
        for feeling in ["tired", "hurt", "unsure", "unclear"] {
            let observation = MoriJournalMood.editing(nil, valence: .neutral,
                emotionID: feeling, contextID: "relationships", now: now)
            XCTAssertNil(observation.healthLabelID)
            XCTAssertNil(observation.healthAssociationID)
        }
        let keys = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(mood())) as? [String: Any])
        XCTAssertNil(keys["note"])
        XCTAssertNil(keys["thought"])
        XCTAssertNil(keys["photos"])
    }
    func testLocalSaveLegacyDecodeEditsReceiptAndDeleteDoNotBackfill() throws {
        let suite = "mori.mood.tests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let manager = HabitDataManager(store: HabitEntryStore(defaults: defaults))
        let old = manager.saveEntry(tone: .neutral, note: "private")
        XCTAssertNil(old.journalMood)
        let first = manager.saveEntry(tone: .neutral, note: "private", journalEmotionID: "tired",
            moodEdit: .select(.neutral))
        let observed = try XCTUnwrap(first.journalMood)
        let textEdit = manager.saveEntry(tone: .neutral, note: "changed private text")
        XCTAssertEqual(textEdit.journalMood, observed)
        let newer = manager.saveEntry(tone: .neutral, moodEdit: .select(.pleasant))
        manager.markMoodShared(observed) // obsolete completion must not mark new version
        XCTAssertNil(manager.getTodayEntry()?.journalMood?.sharedVersion)
        manager.markMoodShared(try XCTUnwrap(newer.journalMood))
        XCTAssertFalse(try XCTUnwrap(manager.getTodayEntry()?.journalMood).needsSharing)
        let restored = HabitDataManager(store: HabitEntryStore(defaults: defaults))
        XCTAssertEqual(restored.getTodayEntry()?.journalMood?.id, observed.id)
        restored.clearAllEntries()
        manager.markMoodShared(observed) // deletion must not resurrect the journal
        XCTAssertNil(manager.getTodayEntry())
        let legacyData = try JSONEncoder().encode(old)
        XCTAssertNil(try JSONDecoder().decode(HabitEntry.self, from: legacyData).journalMood)
    }
    func testActualGuidedSaveActionFirstSelectionEditClearAndDisclosedPayload() throws {
        let suite = "mori.mood.action.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let manager = HabitDataManager(store: HabitEntryStore(defaults: defaults))
        let checkIn = JournalGuidedCheckInState(emotion: .calm, context: .money,
            response: .keepThisMoment, currentStep: .details)
        let firstAction = try XCTUnwrap(MoriJournalGuidedSaveAction(checkIn: checkIn,
            existingEntry: nil, note: "private", valence: .pleasant, recordedAt: now))
        let first = firstAction.save(using: manager)
        let mood = try XCTUnwrap(first.journalMood)
        XCTAssertEqual(mood.valence, .pleasant)
        XCTAssertEqual(mood.recordedAt, now)
        let preview = MoriJournalMood.editing(mood, valence: .veryPleasant,
            emotionID: "calm", contextID: "money", now: now.addingTimeInterval(60)).healthPayload
        let edit = try XCTUnwrap(MoriJournalGuidedSaveAction(checkIn: checkIn,
            existingEntry: first, note: "edited", valence: .veryPleasant,
            recordedAt: now.addingTimeInterval(60))).save(using: manager)
        XCTAssertEqual(edit.journalMood?.healthPayload, preview)
        XCTAssertEqual(edit.journalMood?.id, mood.id)
        XCTAssertEqual(edit.journalMood?.version, 2)
        let clear = try XCTUnwrap(MoriJournalGuidedSaveAction(checkIn: checkIn,
            existingEntry: edit, note: "still private", valence: nil)).save(using: manager)
        XCTAssertNil(clear.journalMood)
        XCTAssertEqual(clear.note, "still private")
    }

    func testBalancedChoicesKeepLegacyIDsAndSelectedHistoricalFeelingVisible() {
        let legacyIDs = ["calm", "hopeful", "anxious", "tired", "hurt", "frustrated", "unsure", "unclear"]
        let choices = MoriJournalFeelingGroup.primary + MoriJournalFeelingGroup.allCases.flatMap(\.choices)
        XCTAssertEqual(choices.count, Set(choices.map(\.id)).count)
        XCTAssertEqual(Set(choices), Set(JournalGuidedEmotion.allCases))
        XCTAssertEqual(MoriJournalFeelingGroup.primary.count, 4)
        XCTAssertEqual(MoriJournalFeelingGroup.primary.filter { $0.tone == .positive }.count, 2)
        XCTAssertEqual(MoriJournalFeelingGroup.primary.filter { $0.tone == .neutral }.count, 1)
        XCTAssertEqual(MoriJournalFeelingGroup.primary.filter { $0.tone == .negative }.count, 1)
        for id in legacyIDs {
            let emotion = JournalGuidedEmotion(rawValue: id)!
            let entry = HabitEntry(date: now, tone: emotion.tone, createdAt: now,
                journalEmotionID: id, journalContextID: "money",
                journalResponseID: JournalGuidedResponse.options(for: emotion.tone)[0].id)
            XCTAssertEqual(JournalGuidedCheckInState(restoring: entry).emotion?.id, id)
            XCTAssertTrue(MoriJournalFeelingGroup.visiblePrimary(selected: emotion).contains(emotion))
            let expanded = MoriJournalFeelingGroup.visiblePrimary(selected: emotion)
                + MoriJournalFeelingGroup.allCases.flatMap {
                    MoriJournalFeelingGroup.additionalChoices(in: $0, selected: emotion)
                }
            XCTAssertEqual(expanded.count, Set(expanded.map(\.id)).count)

        }
        XCTAssertNil(MoriJournalMood.editing(nil, valence: .neutral,
            emotionID: "okay", contextID: nil, now: now).healthLabelID)
    }

    func testFeelingCanBeSkippedAndRestoredWithoutInventingALabelOrValence() throws {
        var state = JournalGuidedCheckInState()
        state.skipEmotion()
        state.selectContext(.notSure)
        XCTAssertTrue(state.selectResponse(.justRecordIt))
        XCTAssertTrue(state.canSave)
        let suite = "mori.mood.skip.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let manager = HabitDataManager(store: HabitEntryStore(defaults: defaults))
        let action = try XCTUnwrap(MoriJournalGuidedSaveAction(checkIn: state,
            existingEntry: nil, note: "private", valence: .pleasant, recordedAt: now))
        let entry = action.save(using: manager)
        XCTAssertTrue(entry.journalEmotionWasSkipped)
        XCTAssertNil(entry.journalEmotionID)
        XCTAssertNil(entry.feeling)
        XCTAssertEqual(entry.journalMood?.valence, .pleasant)
        XCTAssertNil(entry.journalMood?.healthPayload.labelID)
        let restored = JournalGuidedCheckInState(restoring: entry)
        XCTAssertTrue(restored.canSave)
        XCTAssertTrue(restored.emotionWasSkipped)
        XCTAssertNil(restored.emotion)
    }

    func testCachedReceiptStillChecksRevokedPermission() async throws {
        let writer = MoodWriter()
        let service = MoriJournalMoodHealth(writer: writer)
        var observation = mood()
        observation.sharedVersion = observation.version
        let cachedResult = try await service.share(observation)
        XCTAssertEqual(cachedResult, .previouslyShared)
        XCTAssertEqual(writer.authorizationCalls, 1)
        XCTAssertEqual(writer.calls, 0)
        writer.fail = true
        do { try await service.share(observation); XCTFail("revoked permission accepted") }
        catch MoriJournalMoodHealthError.denied {}
        XCTAssertEqual(writer.authorizationCalls, 2)
        XCTAssertEqual(writer.calls, 0)
    }

    func testSuspendedShareThenEditOrDeleteCannotPublishStaleStatus() async throws {
        for deletes in [false, true] {
            let writer = MoodWriter()
            writer.suspends = true
            let service = MoriJournalMoodHealth(writer: writer)
            let original = mood()
            var presentation = MoriJournalMoodSharePresentation()
            presentation.begin(original)
            let job = Task { try await service.share(original) }
            while writer.continuation == nil { await Task.yield() }
            let edited = MoriJournalMood.editing(original, valence: .pleasant,
                emotionID: original.emotionID, contextID: original.contextID, now: now)
            let persisted = deletes ? nil : edited
            let draft = MoriJournalMoodDraft(valence: deletes ? nil : .pleasant,
                emotionID: original.emotionID, contextID: original.contextID)
            presentation.clearIfChanged(draft: draft, persisted: persisted)
            writer.continuation?.resume()
            _ = try await job.value
            presentation.complete(original, outcome: .written, draft: draft, persisted: persisted)
            XCTAssertNil(presentation.outcome)
            XCTAssertNil(presentation.mood)
        }
    }

    func testUIFixtureFactoryNeverConstructsLiveHealthWriter() async throws {
        #if DEBUG
        var liveConstructions = 0
        let service = MoriJournalMoodHealth.configured(arguments: ["-MoriSkipOnboardingForUITest"]) {
            liveConstructions += 1
            return MoodWriter()
        }
        let fixtureResult = try await service.share(mood())
        XCTAssertEqual(fixtureResult, .written)
        XCTAssertEqual(liveConstructions, 0)
        let denied = MoriJournalMoodHealth.configured(arguments: ["-MoriMoodHealthDeniedForUITest"]) {
            liveConstructions += 1
            return MoodWriter()
        }
        do { try await denied.share(mood()); XCTFail("fixture denial missing") }
        catch MoriJournalMoodHealthError.denied {}
        XCTAssertEqual(liveConstructions, 0)
        #endif
    }

    func testDenialRetryAndDuplicateReceipt() async throws {
        let writer = MoodWriter()
        let service = MoriJournalMoodHealth(writer: writer)
        let observation = mood()
        writer.fail = true
        do { try await service.share(observation); XCTFail("denial must fail") } catch {}
        XCTAssertTrue(observation.needsSharing)
        writer.fail = false
        try await service.share(observation)
        try await service.share(observation) // same sync ID/version, one logical Health sample
        XCTAssertEqual(writer.samples.count, 1)
        var acknowledged = observation
        acknowledged.sharedVersion = acknowledged.version
        let calls = writer.calls
        try await service.share(acknowledged)
        XCTAssertEqual(writer.calls, calls)
    }
}

@MainActor
private final class MoodWriter: MoriJournalMoodHealthWriting {
    var fail = false
    var calls = 0
    var authorizationCalls = 0
    var suspends = false
    var continuation: CheckedContinuation<Void, Never>?
    var samples: [String: MoriJournalMood] = [:]
    func authorize() async throws {
        authorizationCalls += 1
        if fail { throw MoriJournalMoodHealthError.denied }
    }
    func write(_ mood: MoriJournalMood) async throws {
        if suspends { await withCheckedContinuation { continuation = $0 } }
        calls += 1
        if fail { throw MoriJournalMoodHealthError.denied }
        if (samples[mood.syncIdentifier]?.version ?? 0) < mood.version {
            samples[mood.syncIdentifier] = mood
        }
    }
}
