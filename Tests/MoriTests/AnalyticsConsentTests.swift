import XCTest
import PostHog
@testable import Mori

final class AnalyticsConsentTests: XCTestCase {
    func testConsentDefaultsToUndecidedAndPersists() {
        let suite = "AnalyticsConsentTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AnalyticsStateStore(defaults: defaults)

        XCTAssertEqual(store.consentState(), .undecided)
        store.saveConsentState(.optedIn)
        XCTAssertEqual(store.consentState(), .optedIn)
    }

    func testStableIDUsesFullUUID() {
        let suite = "AnalyticsIdentityTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let id = AnalyticsStateStore(defaults: defaults).stableUserID()
        XCTAssertTrue(id.hasPrefix("user_"))
        XCTAssertNotNil(UUID(uuidString: String(id.dropFirst(5))))
    }

    func testRemoteDeletionFailureStillDisablesAnalyticsAndPreservesRetryID() async {
        let suite = "AnalyticsDeletionFailureTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AnalyticsStateStore(defaults: defaults)
        store.saveConsentState(.optedIn)
        let userID = store.stableUserID()
        let order = AnalyticsDeletionOrderRecorder()
        let remoteDeletion = AnalyticsRemoteDeletionStub(
            error: AnalyticsDeletionStubError.unavailable,
            order: order
        )
        let localCleaner = AnalyticsLocalDataCleanerSpy(order: order)
        let manager = AnalyticsManager(
            stateStore: store,
            remoteDeletionClient: remoteDeletion,
            localDataCleaner: localCleaner,
            uploadDrainBarrier: AnalyticsUploadDrainBarrierStub(order: order)
        )

        do {
            try await manager.deleteAnalyticsData()
            XCTFail("Expected remote deletion to fail")
        } catch let error as AnalyticsDeletionError {
            guard case .remoteDeletionFailed = error else {
                return XCTFail("Expected a retryable remote deletion error")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(store.consentState(), .optedOut)
        XCTAssertNil(store.existingUserID())
        XCTAssertEqual(store.pendingDeletionUserIDs(), [userID])
        XCTAssertFalse(store.isLocalPurgePending())
        XCTAssertEqual(remoteDeletion.requestedUserIDs, [userID])
        XCTAssertEqual(localCleaner.clearCount, 1)
        XCTAssertEqual(order.events, ["cleanup", "drain", "remote"])
    }

    func testDeletionRetryUsesPendingIDAndClearsItAfterAcceptedResponse() async throws {
        let suite = "AnalyticsDeletionRetryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AnalyticsStateStore(defaults: defaults)
        store.saveConsentState(.optedIn)
        let userID = store.stableUserID()

        let failedRemoteDeletion = AnalyticsRemoteDeletionStub(error: AnalyticsDeletionStubError.unavailable)
        let firstManager = AnalyticsManager(
            stateStore: store,
            remoteDeletionClient: failedRemoteDeletion,
            localDataCleaner: AnalyticsLocalDataCleanerSpy(),
            uploadDrainBarrier: AnalyticsUploadDrainBarrierStub()
        )
        do {
            try await firstManager.deleteAnalyticsData()
            XCTFail("Expected first remote deletion to fail")
        } catch {}

        let order = AnalyticsDeletionOrderRecorder()
        let successfulRemoteDeletion = AnalyticsRemoteDeletionStub(
            order: order,
            onRequest: { requestedUserID in
                XCTAssertEqual(requestedUserID, userID)
                XCTAssertEqual(store.pendingDeletionUserIDs(), [userID])
            }
        )
        let retryManager = AnalyticsManager(
            stateStore: store,
            remoteDeletionClient: successfulRemoteDeletion,
            localDataCleaner: AnalyticsLocalDataCleanerSpy(order: order),
            uploadDrainBarrier: AnalyticsUploadDrainBarrierStub(order: order)
        )
        try await retryManager.deleteAnalyticsData()

        XCTAssertEqual(successfulRemoteDeletion.requestedUserIDs, [userID])
        XCTAssertTrue(store.pendingDeletionUserIDs().isEmpty)
        XCTAssertEqual(store.consentState(), .optedOut)
        XCTAssertNil(store.existingUserID())
        XCTAssertEqual(order.events, ["cleanup", "drain", "remote"])
    }

    func testCancelledDrainKeepsPendingIDAndNeverStartsRemoteDeletion() async {
        let suite = "AnalyticsDeletionCancellationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AnalyticsStateStore(defaults: defaults)
        store.saveConsentState(.optedIn)
        let userID = store.stableUserID()
        let order = AnalyticsDeletionOrderRecorder()
        let remoteDeletion = AnalyticsRemoteDeletionStub(order: order)
        let manager = AnalyticsManager(
            stateStore: store,
            remoteDeletionClient: remoteDeletion,
            localDataCleaner: AnalyticsLocalDataCleanerSpy(order: order),
            uploadDrainBarrier: AnalyticsUploadDrainBarrierStub(
                error: CancellationError(),
                order: order
            )
        )

        do {
            try await manager.deleteAnalyticsData()
            XCTFail("Expected the drain barrier to be cancelled")
        } catch is CancellationError {
            // Expected: cancellation must never consume the durable retry ID.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(order.events, ["cleanup", "drain"])
        XCTAssertTrue(remoteDeletion.requestedUserIDs.isEmpty)
        XCTAssertEqual(store.pendingDeletionUserIDs(), [userID])
        XCTAssertEqual(store.consentState(), .optedOut)
        XCTAssertNil(store.existingUserID())
    }

    func testPostHogCleanerPurgesPinnedSDKEventAndReplayStorageOnly() throws {
        let fileManager = FileManager.default
        let storageDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("PostHogLocalDataCleanerTests.\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: storageDirectory) }

        let postHogStorageNames = [
            "posthog.distinctId",
            "posthog.anonymousId",
            "posthog.queueFolder",
            "posthog.queue.plist",
            "posthog.replayFolder",
            "posthog.enabledFeatureFlags",
            "posthog.enabledFeatureFlagPayloads",
            "posthog.groups",
            "posthog.registerProperties",
            "posthog.optOut",
            "posthog.sessionReplay"
        ]
        for name in postHogStorageNames {
            let url = storageDirectory.appendingPathComponent(name)
            if name.hasSuffix("Folder") {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                try Data("queued".utf8).write(to: url.appendingPathComponent("event"))
            } else {
                try Data("stored".utf8).write(to: url)
            }
        }
        let unrelatedURL = storageDirectory.appendingPathComponent("mori.private-data")
        try Data("keep".utf8).write(to: unrelatedURL)

        let cleaner = PostHogLocalDataCleaner(
            fileManager: fileManager,
            storageDirectory: { storageDirectory }
        )
        try cleaner.clear(postHog: nil)

        for name in postHogStorageNames {
            XCTAssertFalse(fileManager.fileExists(atPath: storageDirectory.appendingPathComponent(name).path))
        }
        XCTAssertTrue(fileManager.fileExists(atPath: unrelatedURL.path))
    }
}

final class MoriDataDeletionTests: XCTestCase {
    func testLocalLogDeletionPreventsKVSRestoreWithoutDeletingMirror() throws {
        let suite = "MoriLogDeletionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let mirror = GratitudeUbiquitousStoreStub()
        let mirroredEntries = [
            GratitudeEntry(date: Date(), content: "Keep the mirror, not the local copy")
        ]
        let mirrorData = try JSONEncoder().encode(mirroredEntries)
        mirror.set(mirrorData, forKey: "icloud_mori_gratitude_entries")

        let store = GratitudeEntryStore(
            defaults: defaults,
            ubiquitousStore: mirror,
            notificationCenter: NotificationCenter()
        )

        XCTAssertEqual(store.loadEntries().count, 1)
        store.deleteLocalEntries()

        XCTAssertTrue(store.loadEntries().isEmpty)
        XCTAssertEqual(
            mirror.data(forKey: "icloud_mori_gratitude_entries"),
            mirrorData,
            "Granular local deletion must not silently delete the separate iCloud mirror"
        )
    }

    func testFullDefaultsDeletionClearsOwnedAndLegacyDataButPreservesLocale() {
        let standardSuite = "MoriFullDeletion.Standard.\(UUID().uuidString)"
        let sharedSuite = "MoriFullDeletion.Shared.\(UUID().uuidString)"
        let standard = UserDefaults(suiteName: standardSuite)!
        let shared = UserDefaults(suiteName: sharedSuite)!
        defer {
            standard.removePersistentDomain(forName: standardSuite)
            shared.removePersistentDomain(forName: sharedSuite)
        }

        let standardOwnedKeys = [
            "archiveStartDate", "birthDate", "archiveSpanYears", "lifeExpectancy",
            "weeklyIntentions", "weeklyIntention", "hasCompletedOnboarding",
            "habit_entries", "mori_daily_spark_entries", "weekArchiveUserID",
            "mori_clarity_actions", "mori_pulse_selected_topics",
            "mori_recovery_daily_indicators_v1", "mori_factor_tag_overrides_v1",
            "mori_recovery_health_authorization_requested", "mori_recovery_llm_insight_opt_in",
            "mori_settle_sessions", "mori_settle_pomodoro_cycles",
            "clockReminderEnabled", "dailySparkReminderEnabled",
            "mori_before_feed_duration_minutes", "mori_pending_deep_link_target"
        ]
        standardOwnedKeys.forEach { standard.set("seed", forKey: $0) }
        TodayFocusDraftStore(defaults: standard).save("A seeded focus", for: Date())

        let sharedOwnedKeys = [
            "archiveStartDate", "birthDate", "archiveSpanYears", "lifeExpectancy",
            "weeklyIntentions", "weeklyIntention", "hasCompletedOnboarding",
            MoriWidgetContextSnapshot.defaultsKey,
            MoriScreenTimeShared.signalsKey,
            MoriScreenTimeShared.defaultSelectionKey,
            MoriScreenTimeShared.featureSelectionKeyPrefix + MoriScreenTimeFeature.beforeFeed.rawValue,
            MoriScreenTimeShared.beforeFeedDurationSecondsKey,
            MoriScreenTimeShared.beforeFeedPauseStyleKey,
            MoriScreenTimeShared.beforeFeedGuidedCycleCountKey,
            MoriScreenTimeShared.beforeFeedPausePreferencesMigrationKey,
            MoriScreenTimeShared.morningGateEnabledKey,
            "journalReminderEnabled"
        ]
        sharedOwnedKeys.forEach { shared.set("seed", forKey: $0) }

        standard.set(MoriLocalePreference.traditionalChinese.rawValue, forKey: MoriLocalePreference.defaultsKey)
        shared.set(MoriLocalePreference.traditionalChinese.rawValue, forKey: MoriLocalePreference.defaultsKey)
        standard.set("keep", forKey: "unrelated_standard_key")
        shared.set("keep", forKey: "unrelated_shared_key")

        MoriPersistedDataDeletion(
            standardDefaults: standard,
            sharedDefaults: shared
        ).deleteAllDefaults()

        standardOwnedKeys.forEach { XCTAssertNil(standard.object(forKey: $0), "Expected \($0) to be deleted") }
        sharedOwnedKeys.forEach { XCTAssertNil(shared.object(forKey: $0), "Expected \($0) to be deleted") }
        XCTAssertEqual(TodayFocusDraftStore(defaults: standard).load(for: Date()), "")
        XCTAssertEqual(standard.string(forKey: MoriLocalePreference.defaultsKey), MoriLocalePreference.traditionalChinese.rawValue)
        XCTAssertEqual(shared.string(forKey: MoriLocalePreference.defaultsKey), MoriLocalePreference.traditionalChinese.rawValue)
        XCTAssertEqual(standard.string(forKey: "unrelated_standard_key"), "keep")
        XCTAssertEqual(shared.string(forKey: "unrelated_shared_key"), "keep")
    }

    @MainActor
    func testScreenTimeLockDeletionClearsKeychainAndRetryState() throws {
        let suite = "MoriScreenTimeLockDeletion.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let keychain = ScreenTimeSettingsLockKeychainStub()
        let store = ScreenTimeSettingsLockStore(
            defaults: defaults,
            keychain: keychain
        )
        defer {
            try? store.clearForDataDeletion()
            defaults.removePersistentDomain(forName: suite)
        }

        try store.createSelfPIN("123456", confirmation: "123456")
        XCTAssertNotNil(keychain.data)
        for _ in 0..<5 {
            XCTAssertThrowsError(try store.verify("654321"))
        }
        XCTAssertTrue(store.isConfigured)
        XCTAssertGreaterThan(store.cooldownRemainingSeconds(), 0)

        try store.clearForDataDeletion()

        XCTAssertFalse(store.isConfigured)
        XCTAssertNil(store.mode)
        XCTAssertNil(keychain.data)
        XCTAssertEqual(store.cooldownRemainingSeconds(), 0)
        XCTAssertNil(defaults.object(forKey: "mori_screen_time_settings_lock_failed_attempts"))
        XCTAssertNil(defaults.object(forKey: "mori_screen_time_settings_lock_cooldown_until"))
    }

    func testWeekArchiveIdentityDeletionDoesNotResurrectLegacyUser() throws {
        let suite = "MoriWeekArchiveIdentityDeletion.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let persistence = PersistenceController(inMemory: true)
        let legacyID = UUID()
        let user = UserEntity(context: persistence.viewContext)
        user.id = legacyID
        user.createdAt = Date()
        user.updatedAt = Date()

        let habit = HabitEntryEntity(context: persistence.viewContext)
        habit.id = UUID()
        habit.date = Date()
        habit.createdAt = Date()
        habit.updatedAt = Date()
        habit.user = user

        let gratitude = GratitudeEntryEntity(context: persistence.viewContext)
        gratitude.id = UUID()
        gratitude.date = Date()
        gratitude.content = "Legacy gratitude"
        gratitude.createdAt = Date()
        gratitude.updatedAt = Date()
        gratitude.user = user

        let lifeWeek = LifeWeekEntity(context: persistence.viewContext)
        lifeWeek.id = UUID()
        lifeWeek.userID = legacyID
        lifeWeek.createdAt = Date()
        lifeWeek.updatedAt = Date()
        lifeWeek.user = user
        try persistence.viewContext.save()

        let store = WeekArchiveIdentityStore(
            defaults: defaults,
            persistenceController: persistence
        )
        XCTAssertEqual(store.userID, legacyID)

        try store.deleteAllIdentityData()
        let replacementID = store.userID

        XCTAssertNotEqual(replacementID, legacyID)
        XCTAssertEqual(try persistence.viewContext.count(for: HabitEntryEntity.fetchRequest()), 0)
        XCTAssertEqual(try persistence.viewContext.count(for: GratitudeEntryEntity.fetchRequest()), 0)
        XCTAssertEqual(try persistence.viewContext.count(for: LifeWeekEntity.fetchRequest()), 0)
        XCTAssertEqual(try persistence.viewContext.count(for: UserEntity.fetchRequest()), 0)
    }
}

private final class ScreenTimeSettingsLockKeychainStub: ScreenTimeSettingsLockKeychainStoring {
    var data: Data?

    func loadData() -> Data? {
        data
    }

    func saveData(_ data: Data) throws {
        self.data = data
    }

    func deleteData() throws {
        data = nil
    }
}

private enum AnalyticsDeletionStubError: Error {
    case unavailable
}

private final class AnalyticsDeletionOrderRecorder {
    private(set) var events: [String] = []

    func record(_ event: String) {
        events.append(event)
    }
}

private final class AnalyticsRemoteDeletionStub: AnalyticsRemoteDeleting {
    private(set) var requestedUserIDs: [String] = []
    var error: Error?
    private let order: AnalyticsDeletionOrderRecorder?
    private let onRequest: ((String) -> Void)?

    init(
        error: Error? = nil,
        order: AnalyticsDeletionOrderRecorder? = nil,
        onRequest: ((String) -> Void)? = nil
    ) {
        self.error = error
        self.order = order
        self.onRequest = onRequest
    }

    func deleteAnalyticsData(for userID: String) async throws {
        order?.record("remote")
        requestedUserIDs.append(userID)
        onRequest?(userID)
        if let error { throw error }
    }
}

private final class AnalyticsLocalDataCleanerSpy: AnalyticsLocalDataClearing {
    private(set) var clearCount = 0
    private let order: AnalyticsDeletionOrderRecorder?

    init(order: AnalyticsDeletionOrderRecorder? = nil) {
        self.order = order
    }

    func clear(postHog: PostHogSDK?) throws {
        order?.record("cleanup")
        clearCount += 1
    }
}

private struct AnalyticsUploadDrainBarrierStub: AnalyticsUploadDraining {
    let error: Error?
    let order: AnalyticsDeletionOrderRecorder?

    init(
        error: Error? = nil,
        order: AnalyticsDeletionOrderRecorder? = nil
    ) {
        self.error = error
        self.order = order
    }

    func waitForInFlightUploads() async throws {
        order?.record("drain")
        if let error { throw error }
    }
}

private final class GratitudeUbiquitousStoreStub: GratitudeUbiquitousKeyValueStoring {
    private var storage: [String: Any] = [:]

    func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }

    func synchronize() -> Bool { true }
}
