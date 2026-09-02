import XCTest
@testable import Mori

final class MoriCallContinuityTests: XCTestCase {
    func testExistingDedicatedBeforeFeedSelectionWinsOnceOverBroadDefaultSelection() {
        XCTAssertTrue(
            BeforeFeedDedicatedSelectionMigrationPolicy.shouldPreferDedicatedSelection(
                usesDefaultSelection: true,
                dedicatedSelectedCount: 2,
                hiddenAppLockEnabled: true,
                migrationCompleted: false
            )
        )
        XCTAssertFalse(
            BeforeFeedDedicatedSelectionMigrationPolicy.shouldPreferDedicatedSelection(
                usesDefaultSelection: true,
                dedicatedSelectedCount: 0,
                hiddenAppLockEnabled: true,
                migrationCompleted: false
            )
        )
        XCTAssertFalse(
            BeforeFeedDedicatedSelectionMigrationPolicy.shouldPreferDedicatedSelection(
                usesDefaultSelection: true,
                dedicatedSelectedCount: 2,
                hiddenAppLockEnabled: true,
                migrationCompleted: true
            )
        )
        XCTAssertFalse(
            BeforeFeedDedicatedSelectionMigrationPolicy.shouldPreferDedicatedSelection(
                usesDefaultSelection: true,
                dedicatedSelectedCount: 2,
                hiddenAppLockEnabled: false,
                migrationCompleted: false
            )
        )
    }

    func testForegroundReconcilePreservesMatchingPassiveShieldWithoutReapply() {
        XCTAssertFalse(
            AttentionShieldForegroundReconcilePolicy.shouldRefresh(
                action: .apply([.beforeFeed]),
                desiredStateMatches: true
            )
        )
        XCTAssertTrue(
            AttentionShieldForegroundReconcilePolicy.shouldRefresh(
                action: .apply([.beforeFeed]),
                desiredStateMatches: false
            )
        )
        XCTAssertFalse(
            AttentionShieldForegroundReconcilePolicy.shouldRefresh(
                action: .clear,
                desiredStateMatches: true
            )
        )
        XCTAssertTrue(
            AttentionShieldForegroundReconcilePolicy.shouldRefresh(
                action: .clear,
                desiredStateMatches: false
            )
        )
    }

    func testMatchingActiveShieldSkipsManagedSettingsApply() {
        var applyCount = 0

        AttentionShieldStateReconcilePolicy.applyIfNeeded(desiredStateMatches: true) {
            applyCount += 1
        }
        XCTAssertEqual(applyCount, 0)

        AttentionShieldStateReconcilePolicy.applyIfNeeded(desiredStateMatches: false) {
            applyCount += 1
        }
        XCTAssertEqual(applyCount, 1)
    }

    func testDedicatedBeforeFeedMigrationPersistsOnceAndPreservesEnabledState() {
        let suiteName = "MoriCallContinuityMigrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let persistence = ScreenTimeSelectionPersistence(defaults: defaults)
        persistence.saveProfiles([
            MoriScreenTimeFeature.beforeFeed.rawValue: MoriScreenTimeFeatureProfile(
                isEnabled: true,
                usesDefaultSelection: true
            )
        ])

        let migratedStore = ScreenTimeSelectionStore(
            persistence: persistence,
            beforeFeedMigrationInputs: BeforeFeedDedicatedSelectionMigrationInputs(
                dedicatedSelectedCount: 2,
                hiddenAppLockEnabled: true
            )
        )

        XCTAssertTrue(migratedStore.profile(for: .beforeFeed).isEnabled)
        XCTAssertFalse(migratedStore.profile(for: .beforeFeed).usesDefaultSelection)
        XCTAssertTrue(persistence.hasCompletedBeforeFeedDedicatedSelectionMigration())

        var explicitlyRestoredProfile = migratedStore.profile(for: .beforeFeed)
        explicitlyRestoredProfile.usesDefaultSelection = true
        migratedStore.saveProfile(explicitlyRestoredProfile, for: .beforeFeed)
        let secondStore = ScreenTimeSelectionStore(
            persistence: persistence,
            beforeFeedMigrationInputs: BeforeFeedDedicatedSelectionMigrationInputs(
                dedicatedSelectedCount: 2,
                hiddenAppLockEnabled: true
            )
        )
        XCTAssertTrue(secondStore.profile(for: .beforeFeed).usesDefaultSelection)
    }

    func testSecondaryMoriAudioYieldsToExistingPrimaryAudio() {
        XCTAssertFalse(
            SettleBellAudioInterruptionPolicy.shouldPlaySecondaryAudio(
                secondaryAudioShouldBeSilenced: true,
                isOtherAudioPlaying: false
            )
        )
        XCTAssertFalse(
            SettleBellAudioInterruptionPolicy.shouldPlaySecondaryAudio(
                secondaryAudioShouldBeSilenced: false,
                isOtherAudioPlaying: true
            )
        )
        XCTAssertTrue(
            SettleBellAudioInterruptionPolicy.shouldPlaySecondaryAudio(
                secondaryAudioShouldBeSilenced: false,
                isOtherAudioPlaying: false
            )
        )
    }

    func testSuppressedCueNeverActivatesMoriAudioSession() {
        let audioSession = FakeSettleBellAudioSessionManager(isOtherAudioPlaying: true)
        let service = SettleBellService(audioSessionManager: audioSession)
        let observationFinished = expectation(description: "audio suppression observed")

        service.playIntervalBell()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            observationFinished.fulfill()
        }

        wait(for: [observationFinished], timeout: 1)
        XCTAssertEqual(audioSession.configureCount, 0)
        XCTAssertEqual(audioSession.activateCount, 0)
        XCTAssertEqual(audioSession.deactivateCount, 0)
    }

    func testOwnedAudioSessionDeactivatesAfterStop() {
        let audioSession = FakeSettleBellAudioSessionManager()
        let activated = expectation(description: "Mori audio session activated")
        let deactivated = expectation(description: "Mori audio session deactivated")
        audioSession.onActivate = { activated.fulfill() }
        audioSession.onDeactivate = { deactivated.fulfill() }
        let service = SettleBellService(audioSessionManager: audioSession)

        service.playIntervalBell()
        wait(for: [activated], timeout: 2)
        service.stop()
        wait(for: [deactivated], timeout: 2)

        XCTAssertEqual(audioSession.configureCount, 1)
        XCTAssertEqual(audioSession.activateCount, 1)
        XCTAssertEqual(audioSession.deactivateCount, 1)
    }

    func testManagedSettingsMismatchCannotBeSkippedAsMatching() {
        XCTAssertTrue(
            AttentionShieldClearedStateMatchPolicy.matches(
                currentFeature: nil,
                hasBlockedApplications: false,
                hasShieldApplications: false,
                hasShieldApplicationCategories: false,
                hasShieldWebDomains: false
            )
        )

        let mismatches: [(MoriScreenTimeFeature?, Bool, Bool, Bool, Bool)] = [
            (.beforeFeed, false, false, false, false),
            (nil, true, false, false, false),
            (nil, false, true, false, false),
            (nil, false, false, true, false),
            (nil, false, false, false, true)
        ]
        for mismatch in mismatches {
            XCTAssertFalse(
                AttentionShieldClearedStateMatchPolicy.matches(
                    currentFeature: mismatch.0,
                    hasBlockedApplications: mismatch.1,
                    hasShieldApplications: mismatch.2,
                    hasShieldApplicationCategories: mismatch.3,
                    hasShieldWebDomains: mismatch.4
                )
            )
        }
    }
}

private final class FakeSettleBellAudioSessionManager: SettleBellAudioSessionManaging {
    let secondaryAudioShouldBeSilencedHint: Bool
    let isOtherAudioPlaying: Bool
    var onActivate: (() -> Void)?
    var onDeactivate: (() -> Void)?

    private let lock = NSLock()
    private var storedConfigureCount = 0
    private var storedActivateCount = 0
    private var storedDeactivateCount = 0

    init(
        secondaryAudioShouldBeSilencedHint: Bool = false,
        isOtherAudioPlaying: Bool = false
    ) {
        self.secondaryAudioShouldBeSilencedHint = secondaryAudioShouldBeSilencedHint
        self.isOtherAudioPlaying = isOtherAudioPlaying
    }

    var configureCount: Int { locked { storedConfigureCount } }
    var activateCount: Int { locked { storedActivateCount } }
    var deactivateCount: Int { locked { storedDeactivateCount } }

    func configureForMixedPlayback() throws {
        lock.lock()
        storedConfigureCount += 1
        lock.unlock()
    }

    func activateForPlayback() throws {
        lock.lock()
        storedActivateCount += 1
        let callback = onActivate
        lock.unlock()
        callback?()
    }

    func deactivateAfterPlayback() throws {
        lock.lock()
        storedDeactivateCount += 1
        let callback = onDeactivate
        lock.unlock()
        callback?()
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
