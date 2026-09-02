import XCTest

final class MoriRecoveryUITests: XCTestCase {
    func testRecoveryCanOpenFromToday() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-MoriOpenRecoveryForUITest",
            "-MoriUseMockRecoveryReadyForUITest",
            "-MoriDisableAIPulse"
        ]
        app.launch()
        XCTAssertTrue(
            app.staticTexts["Recovery Signals"].waitForExistence(timeout: 8),
            "Expected the ready-state Recovery detail header to appear."
        )
    }

    func testAppAndDataShowsGranularDeletionControls() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-MoriOpenSettingsForUITest",
            "-MoriOpenAppAndDataForUITest",
            "-MoriDisableAIPulse"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Delete Data"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Delete All Mori Data"].exists)

        let logsAndPhotosButton = app.buttons["Logs & Photos"]
        XCTAssertTrue(logsAndPhotosButton.exists)
        logsAndPhotosButton.tap()

        let deletionAlert = app.alerts["Delete this data?"]
        XCTAssertTrue(
            deletionAlert.waitForExistence(timeout: 3),
            "Granular deletion should use one standard alert instead of an anchored popover."
        )
        XCTAssertEqual(app.alerts.count, 1)
        XCTAssertTrue(deletionAlert.buttons["Cancel"].exists)
        XCTAssertTrue(deletionAlert.buttons["Delete"].exists)
        attachScreenshot(named: "app-and-data-delete-confirmation")

        deletionAlert.buttons["Cancel"].tap()
        XCTAssertFalse(deletionAlert.waitForExistence(timeout: 1))
    }

    func testBeforeFeedStartsWithOneBreathBeforeIntentChoices() {
        let app = launchBeforeFeed()

        XCTAssertTrue(app.staticTexts["Begin with the breath"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Breathe in for 4. Breathe out for 6."].exists)
        XCTAssertFalse(app.staticTexts["Why now?"].exists)
        attachScreenshot(named: "before-feed-breath-key")
    }

    func testBeforeFeedConfiguredGuidedFixtureShowsTechniqueCyclesAndExactTimer() {
        let app = launchBeforeFeed(extraArguments: [
            "-MoriUseConfiguredGuidedBeforeFeedPauseForUITest",
            "-MoriFreezeBeforeFeedTimerForUITest"
        ])

        XCTAssertTrue(app.staticTexts["Begin with the breath"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Coherent Breathing (5-5) · 3 cycles · about 30 seconds"].exists)
        XCTAssertTrue(app.staticTexts["Cycle 1 of 3"].exists)
        XCTAssertTrue(app.staticTexts["00:30"].exists)
        attachScreenshot(named: "before-feed-configured-guided")
    }

    func testBeforeFeedFollowOwnFixtureShowsStaticTimerAndOpeningBowlPromise() {
        let app = launchBeforeFeed(extraArguments: [
            "-MoriUseFollowOwnBeforeFeedPauseForUITest",
            "-MoriFreezeBeforeFeedTimerForUITest"
        ])

        XCTAssertTrue(app.staticTexts["Begin with the breath"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Follow your own breath · 20 seconds"].exists)
        XCTAssertTrue(
            app.staticTexts["One long singing bowl marks the start. Breathe naturally until the timer ends."].exists
        )
        XCTAssertTrue(app.staticTexts["00:20"].exists)
        XCTAssertFalse(app.staticTexts["Cycle 1 of 1"].exists)
        attachScreenshot(named: "before-feed-follow-own")
    }

    func testBeforeFeedConfiguredGuidedSettingsExposeTechniqueAndCycleControls() {
        let app = launchBeforeFeedSettings(extraArguments: [
            "-MoriShowBeforeFeedConfiguredGuidedSettingsForUITest"
        ])
        let techniquePicker = app.descendants(matching: .any)["before-feed-technique-picker"]
        let cycleStepper = app.descendants(matching: .any)["before-feed-cycle-stepper"]

        XCTAssertTrue(scrollUntilExists(techniquePicker, in: app))
        XCTAssertTrue(cycleStepper.exists)
        XCTAssertTrue(app.staticTexts["Coherent Breathing (5-5) · 3 cycles · about 30 seconds"].exists)
        attachScreenshot(named: "before-feed-configured-guided-settings")
    }

    func testBeforeFeedFollowOwnSettingsExposeBoundedDurationAndSoundContract() {
        let app = launchBeforeFeedSettings(extraArguments: [
            "-MoriShowBeforeFeedOwnBreathSettingsForUITest"
        ])
        let durationPicker = app.descendants(matching: .any)["before-feed-own-duration-picker"]

        XCTAssertTrue(scrollUntilExists(durationPicker, in: app))
        XCTAssertTrue(
            app.staticTexts["One long singing bowl marks the start. There is no completion sound."].exists
        )
        XCTAssertTrue(app.staticTexts["Follow your own breath · 20 seconds"].exists)
        attachScreenshot(named: "before-feed-follow-own-settings")
    }

    func testBeforeFeedIntentRevealsPlanOnOneSurface() {
        let app = launchBeforeFeed(extraArguments: [
            "-MoriShowBeforeFeedIntentForUITest"
        ])

        XCTAssertTrue(app.staticTexts["Why now?"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Keep feed closed"].exists)
        XCTAssertFalse(app.buttons["Choose a time to open"].exists)
        XCTAssertFalse(app.staticTexts["What would be enough?"].exists)
        attachScreenshot(named: "before-feed-intent-entry")
        app.buttons["Just checking"].tap()

        XCTAssertTrue(app.staticTexts["What would be enough?"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["15 minutes"].waitForExistence(timeout: 3))
        app.buttons["15 minutes"].tap()

        XCTAssertTrue(app.staticTexts["After this?"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Open for 15 minutes"].exists)
        let workButton = app.buttons["Work"]
        XCTAssertTrue(workButton.exists)
        attachScreenshot(named: "before-feed-intent-surface")

        workButton.tap()
        XCTAssertEqual(workButton.value as? String, "Selected")
        attachScreenshot(named: "before-feed-intent-return-selected")
    }

    func testBeforeFeedKeepClosedRecordsOneTruthfulChoice() {
        let app = launchBeforeFeed(extraArguments: [
            "-MoriShowBeforeFeedIntentForUITest",
            "-MoriClearBeforeFeedHistoryForUITest"
        ])

        let keepClosedButton = app.buttons["Keep feed closed"]
        XCTAssertTrue(keepClosedButton.waitForExistence(timeout: 8))
        keepClosedButton.tap()

        XCTAssertTrue(app.staticTexts["Kept closed once today"].waitForExistence(timeout: 5))
    }

    func testGuidedLogSavesWithoutTypingAndRestores() {
        let app = launchGuidedLog(fresh: true)

        XCTAssertTrue(app.staticTexts["How are you right now?"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Anxious"].exists)
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        XCTAssertEqual(app.textViews.count, 0)
        attachScreenshot(named: "guided-log-step-1")

        app.buttons["Anxious"].tap()
        XCTAssertTrue(app.staticTexts["What is this connected to?"].waitForExistence(timeout: 3))
        attachScreenshot(named: "guided-log-step-2")

        app.buttons["Work or study"].tap()
        XCTAssertTrue(app.staticTexts["What would help next?"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Separate facts from guesses"].exists)
        attachScreenshot(named: "guided-log-step-3")

        app.buttons["Separate facts from guesses"].tap()
        let saveButton = app.buttons["Save check-in"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        XCTAssertTrue(saveButton.isEnabled)
        XCTAssertTrue(app.buttons["Add a sentence"].exists)
        XCTAssertEqual(app.textViews.count, 0)
        attachScreenshot(named: "guided-log-ready-to-save")

        if !saveButton.isHittable {
            app.swipeUp()
        }
        saveButton.tap()
        XCTAssertFalse(app.staticTexts["Pattern Log"].waitForExistence(timeout: 1))

        app.terminate()
        let restoredApp = launchGuidedLog(fresh: false)
        XCTAssertTrue(restoredApp.buttons["Save check-in"].waitForExistence(timeout: 8))
        XCTAssertTrue(restoredApp.buttons["Add a sentence"].exists)
        XCTAssertFalse(restoredApp.staticTexts["How are you right now?"].exists)
        attachScreenshot(named: "guided-log-restored")

        restoredApp.buttons["journal-guided-summary-0"].tap()
        XCTAssertTrue(restoredApp.staticTexts["How are you right now?"].waitForExistence(timeout: 3))
        attachScreenshot(named: "guided-log-edit-selection")
    }

    func testAccountabilityPINShareCancellationDoesNotLock() {
        let app = launchAccountabilityPINConfirmation()
        let confirmation = app.descendants(matching: .any)["screen_time_accountability_pin_confirmation"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 3))

        let shareButton = app.buttons["screen_time_accountability_pin_share"]
        XCTAssertTrue(shareButton.exists)
        XCTAssertFalse(app.switches["screen_time_accountability_pin_received_acknowledgement"].exists)
        XCTAssertFalse(app.buttons["screen_time_accountability_pin_confirm_lock"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[0-9]{6}")).firstMatch.exists)
        attachScreenshot(named: "accountability-pin-confirmation-before-share")

        shareButton.tap()
        let closeShareSheet = app.buttons["Close"]
        XCTAssertTrue(closeShareSheet.waitForExistence(timeout: 5))
        closeShareSheet.tap()

        XCTAssertTrue(confirmation.waitForExistence(timeout: 3))
        XCTAssertFalse(app.switches["screen_time_accountability_pin_received_acknowledgement"].exists)
        XCTAssertFalse(app.buttons["screen_time_accountability_pin_confirm_lock"].exists)

        app.buttons["screen_time_accountability_pin_cancel"].tap()

        XCTAssertTrue(app.buttons["Generate and Share PIN"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["App Limits are locked"].exists)
    }

    func testAccountabilityPINRequiresShareAndReceiptBeforeLock() {
        let app = launchAccountabilityPINConfirmation(extraArguments: [
            "-MoriCompletePINShareForUITest"
        ])

        XCTAssertFalse(app.switches["screen_time_accountability_pin_received_acknowledgement"].exists)
        XCTAssertFalse(app.buttons["screen_time_accountability_pin_confirm_lock"].exists)

        app.buttons["screen_time_accountability_pin_share"].tap()

        let acknowledgement = app.switches["screen_time_accountability_pin_received_acknowledgement"]
        let confirmButton = app.buttons["screen_time_accountability_pin_confirm_lock"]
        XCTAssertTrue(acknowledgement.waitForExistence(timeout: 3))
        XCTAssertTrue(acknowledgement.isEnabled)
        XCTAssertTrue(confirmButton.exists)
        XCTAssertFalse(confirmButton.isEnabled)
        attachScreenshot(named: "accountability-pin-confirmation-after-share")

        acknowledgement.coordinate(
            withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)
        ).tap()
        XCTAssertEqual(acknowledgement.value as? String, "1")
        let enabledConfirmation = app.buttons["screen_time_accountability_pin_confirm_lock"]
        let enabledExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"),
            object: enabledConfirmation
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [enabledExpectation], timeout: 3),
            .completed
        )
        attachScreenshot(named: "accountability-pin-confirmation-ready-to-lock")

        app.buttons["screen_time_accountability_pin_cancel"].tap()
        XCTAssertTrue(app.buttons["Generate and Share PIN"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["App Limits are locked"].exists)
    }

    func testAccountabilityPINCommitsOnlyAfterBothConfirmations() {
        let app = launchAccountabilityPINConfirmation(extraArguments: [
            "-MoriCompletePINShareForUITest"
        ])

        app.buttons["screen_time_accountability_pin_share"].tap()

        let acknowledgement = app.switches["screen_time_accountability_pin_received_acknowledgement"]
        XCTAssertTrue(acknowledgement.waitForExistence(timeout: 3))
        acknowledgement.coordinate(
            withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)
        ).tap()
        XCTAssertEqual(acknowledgement.value as? String, "1")

        let confirmButton = app.buttons["screen_time_accountability_pin_confirm_lock"]
        let enabledExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"),
            object: confirmButton
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [enabledExpectation], timeout: 3),
            .completed
        )
        confirmButton.tap()
        XCTAssertFalse(
            app.descendants(matching: .any)["screen_time_accountability_pin_confirmation"]
                .waitForExistence(timeout: 1)
        )

        app.terminate()
        let relaunchedApp = XCUIApplication()
        relaunchedApp.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-MoriOpenSettingsForUITest",
            "-MoriDisableAIPulse"
        ]
        relaunchedApp.launch()

        let appLimitsButton = relaunchedApp.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Open App Limits")
        ).firstMatch
        XCTAssertTrue(appLimitsButton.waitForExistence(timeout: 8))
        appLimitsButton.tap()
        XCTAssertTrue(
            relaunchedApp.staticTexts["App Limits are locked"].waitForExistence(timeout: 5)
        )

        relaunchedApp.terminate()
        clearAppLimitsAndPINData()
    }

    private func launchAccountabilityPINConfirmation(
        extraArguments: [String] = []
    ) -> XCUIApplication {
        clearAppLimitsAndPINData()

        let app = XCUIApplication()
        app.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-MoriOpenSettingsForUITest",
            "-MoriDisableAIPulse"
        ] + extraArguments
        app.launch()

        let appLimitsButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Open App Limits")
        ).firstMatch
        XCTAssertTrue(appLimitsButton.waitForExistence(timeout: 8))
        appLimitsButton.tap()

        let preventChangesButton = app.buttons["Prevent Changes"]
        if preventChangesButton.waitForExistence(timeout: 3) {
            if !preventChangesButton.isHittable {
                app.swipeUp()
            }
            preventChangesButton.tap()
        } else {
            let advancedButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS %@", "Advanced")
            ).firstMatch
            XCTAssertTrue(advancedButton.waitForExistence(timeout: 3))
            advancedButton.tap()
            let lockButton = app.buttons["Lock App Limits"]
            XCTAssertTrue(lockButton.waitForExistence(timeout: 3))
            lockButton.tap()
        }

        let accountabilityMode = app.segmentedControls.buttons["Accountability PIN"]
        XCTAssertTrue(accountabilityMode.waitForExistence(timeout: 5))
        accountabilityMode.tap()

        let generateButton = app.buttons["Generate and Share PIN"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 3))
        generateButton.tap()
        return app
    }

    private func clearAppLimitsAndPINData() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-MoriOpenSettingsForUITest",
            "-MoriOpenAppAndDataForUITest",
            "-MoriDisableAIPulse"
        ]
        app.launch()

        let deleteButton = app.buttons["App Limits, Focus & Reminders"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 8))
        deleteButton.tap()

        let confirmation = app.alerts["Delete this data?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 3))
        confirmation.buttons["Delete"].tap()

        let result = app.alerts["Data Deletion"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.buttons["OK"].tap()
        app.terminate()
    }

    private func launchBeforeFeed(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        let pauseFixtureArguments = extraArguments.contains(where: {
            $0 == "-MoriUseConfiguredGuidedBeforeFeedPauseForUITest" ||
                $0 == "-MoriUseFollowOwnBeforeFeedPauseForUITest" ||
                $0 == "-MoriShowBeforeFeedQuietPauseForUITest"
        }) ? [] : ["-MoriUseDefaultBeforeFeedPauseForUITest"]
        app.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-MoriOpenBeforeFeedForUITest",
            "-MoriDisableAIPulse"
        ] + pauseFixtureArguments + extraArguments
        app.launch()

        if app.buttons["Not Now"].waitForExistence(timeout: 2) {
            app.buttons["Not Now"].tap()
        }
        return app
    }

    private func launchBeforeFeedSettings(extraArguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-MoriOpenBeforeFeedSettingsForUITest",
            "-MoriDisableAIPulse"
        ] + extraArguments
        app.launch()
        return app
    }

    private func scrollUntilExists(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<6 {
            if element.exists { return true }
            app.swipeUp()
        }
        return element.waitForExistence(timeout: 1)
    }

    private func launchGuidedLog(fresh: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-MoriSkipAnalyticsConsentForUITest",
            "-MoriSkipCloudBackupForUITest",
            "-MoriOpenLogForUITest",
            "-MoriDisableAIPulse"
        ]
        if fresh {
            app.launchArguments.append("-MoriStartFreshLogForUITest")
        }
        app.launch()
        return app
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
