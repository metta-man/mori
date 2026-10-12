import XCTest

final class MoriRecoveryUITests: XCTestCase {
    func testDeepSessionContinuesInBackgroundAndManualPauseStaysPaused() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest",
            "-MoriSkipCloudBackupForUITest", "-MoriDisableAIPulse",
            "-MoriOpenDeepSessionForUITest", "-MoriAutoStartDeepSessionForUITest",
            "-mori_settle_pomodoro_focus_breathing", "none",
            "-mori_timer_dark_room_enabled", "NO",
            "-AppleLanguages", "(en)", "-mori_locale_preference", "en"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        let timer = app.descendants(matching: .any).matching(
            NSPredicate(format: "label MATCHES %@", ".*, [0-9]+:[0-9]{2} remaining")
        ).firstMatch
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        func remaining() -> Int {
            let value = timer.label.components(separatedBy: ", ").last ?? ""
            let parts = value.replacingOccurrences(of: " remaining", with: "").split(separator: ":")
            guard parts.count == 2, let minutes = Int(parts[0]), let seconds = Int(parts[1]) else {
                XCTFail("Missing timer value: \(value)"); return -1
            }
            return minutes * 60 + seconds
        }
        let before = remaining()
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 8)
        app.activate()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(remaining(), before - 8)
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 3))
        let paused = remaining()
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 5)
        app.activate()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
        XCTAssertEqual(remaining(), paused)
        attachScreenshot(named: "deep-session-background-paused")
    }

    func testDeepSessionKeepScreenSettingIsAvailableDuringSession() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest",
            "-MoriDisableAIPulse", "-MoriOpenDeepSessionForUITest",
            "-MoriAutoStartDeepSessionForUITest", "-mori_timer_dark_room_enabled", "NO",
            "-AppleLanguages", "(en)", "-mori_locale_preference", "en"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["Show session options"].waitForExistence(timeout: 8))
        app.buttons["Show session options"].tap()
        let toggle = app.switches["deep-session-keep-screen-on"]
        for _ in 0..<4 where !toggle.isHittable { app.swipeUp() }
        XCTAssertTrue(toggle.exists)
        let old = toggle.value as? String
        toggle.tap()
        XCTAssertNotEqual(toggle.value as? String, old)
        attachScreenshot(named: "deep-session-screen-options")
        let saved = toggle.value as? String
        app.terminate()
        app.launchArguments.removeAll { $0 == "-MoriAutoStartDeepSessionForUITest" }
        app.launch()
        let options = app.buttons["Show session options"]
        XCTAssertTrue(options.waitForExistence(timeout: 8))
        for _ in 0..<4 where !options.isHittable { app.swipeUp() }
        options.tap()
        for _ in 0..<6 where !toggle.isHittable { app.swipeUp() }
        XCTAssertTrue(toggle.exists)
        XCTAssertEqual(toggle.value as? String, saved)
        attachScreenshot(named: "deep-session-setup-screen-options")
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, old)
    }

    func testDeepSessionKeepScreenSettingInDarkRoom() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest",
            "-MoriDisableAIPulse", "-MoriOpenDeepSessionForUITest",
            "-MoriAutoStartDeepSessionForUITest", "-mori_timer_dark_room_enabled", "YES",
            "-AppleLanguages", "(en)", "-mori_locale_preference", "en"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Tap to wake"].waitForExistence(timeout: 8))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        let toggle = app.switches["deep-session-keep-screen-on"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
        attachScreenshot(named: "deep-session-dark-screen-options")
    }

    func testDeepSessionCountsDownAndRespectsPauseWithBreathing() {
        verifyDeepSessionCountdown(breathing: "box")
    }

    func testDeepSessionCountsDownAndRespectsPauseWithoutBreathing() {
        verifyDeepSessionCountdown(breathing: "none")
    }

    private func verifyDeepSessionCountdown(breathing: String) {
        let app = XCUIApplication()
        app.launchArguments = [
            "-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest",
            "-MoriSkipCloudBackupForUITest", "-MoriDisableAIPulse",
            "-MoriOpenDeepSessionForUITest", "-MoriAutoStartDeepSessionForUITest",
            "-mori_settle_pomodoro_focus_breathing", breathing,
            "-mori_settle_sound_enabled", "NO",
            "-mori_timer_dark_room_enabled", "NO",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        let timer = app.descendants(matching: .any).matching(
            NSPredicate(format: "label MATCHES %@", ".*, [0-9]+:[0-9]{2} remaining")
        ).firstMatch
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        func remaining() -> String {
            timer.label.components(separatedBy: ", ").last ?? ""
        }
        let initial = remaining()
        let advances = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in remaining() != initial }, object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [advances], timeout: 6), .completed,
                       "Deep Session must count down while breathing refreshes the view")
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 3))
        let paused = remaining()
        let staysPaused = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in remaining() != paused }, object: nil
        )
        staysPaused.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [staysPaused], timeout: 3), .completed)
        app.buttons["Resume"].tap()
        let resumes = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in remaining() != paused }, object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [resumes], timeout: 6), .completed)
    }

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

    func testBeforeFeedStartsWithThreeBreathsBeforeIntentChoices() {
        let app = launchBeforeFeed()

        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Long Exhale (4-6) · 3 cycles · about 30 seconds"].exists)
        XCTAssertTrue(app.staticTexts["3 breaths remaining"].exists)
        XCTAssertFalse(app.staticTexts["Breathe in for 4. Breathe out for 6."].exists)
        XCTAssertFalse(app.staticTexts["Why now?"].exists)
        attachScreenshot(named: "before-feed-breath-key")
    }

    func testBeforeFeedRemainingBreathsPauseAndFinishBeforeIntent() {
        let app = launchBeforeFeed()
        XCTAssertTrue(app.staticTexts["3 breaths remaining"].waitForExistence(timeout: 5))
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 3))
        let changesWhilePaused = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in !app.staticTexts["3 breaths remaining"].exists }, object: nil
        )
        changesWhilePaused.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [changesWhilePaused], timeout: 11), .completed)
        app.buttons["Resume"].tap()
        XCTAssertTrue(app.staticTexts["2 breaths remaining"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["1 breath remaining"].waitForExistence(timeout: 12))
        XCTAssertFalse(app.staticTexts["Why now?"].exists)
        XCTAssertTrue(app.staticTexts["Why now?"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.buttons["Keep feed closed"].exists)
    }

    func testBeforeFeedConfiguredGuidedFixtureShowsRemainingBreathsWithoutCountdown() {
        let app = launchBeforeFeed(extraArguments: [
            "-MoriUseConfiguredGuidedBeforeFeedPauseForUITest",
            "-MoriFreezeBeforeFeedTimerForUITest"
        ])

        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Coherent Breathing (5-5) · 3 cycles · about 30 seconds"].exists)
        XCTAssertTrue(app.staticTexts["3 breaths remaining"].exists)
        XCTAssertFalse(app.staticTexts["00:30"].exists)
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

    func testBeforeFeedTraditionalChineseSettingsLocalizeTechniqueSummary() {
        let app = launchBeforeFeedSettings(extraArguments: [
            "-MoriShowBeforeFeedConfiguredGuidedSettingsForUITest", "-mori_locale_preference", "zh-Hant"
        ])
        let picker = app.descendants(matching: .any)["before-feed-technique-picker"]
        XCTAssertTrue(scrollUntilExists(picker, in: app))
        XCTAssertTrue(app.staticTexts["共振呼吸（5-5） · 3 次 · 約 30 秒"].exists)
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Coherent Breathing")).count, 0)
        attachScreenshot(named: "Mori Before Feed localized TC settings")
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

        let expectedHeading = "How do you feel?"
        XCTAssertTrue(app.staticTexts[expectedHeading].waitForExistence(timeout: 8))
        tapGuidedControl("journal-other-feelings", app)
        tapGuidedControl("journal-feeling-group-difficult", app)
        XCTAssertTrue(app.buttons["Anxious"].exists)
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        XCTAssertEqual(app.textViews.count, 0)
        attachScreenshot(named: "guided-log-step-1")

        tapGuidedControl("journal-guided-emotion-anxious", app)
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
        XCTAssertFalse(restoredApp.staticTexts[expectedHeading].exists)
        attachScreenshot(named: "guided-log-restored")

        tapGuidedControl("journal-guided-summary-0", restoredApp)
        XCTAssertTrue(restoredApp.staticTexts[expectedHeading].waitForExistence(timeout: 3))
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
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-mori_locale_preference", "en",
            "-MoriOpenSettingsForUITest",
            "-MoriDisableAIPulse"
        ]
        relaunchedApp.launch()

        let appLimitsButton = relaunchedApp.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "App Limits,")
        ).firstMatch
        XCTAssertTrue(appLimitsButton.waitForExistence(timeout: 8))
        XCTAssertEqual(relaunchedApp.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "App Limits,")).count, 1)
        appLimitsButton.tap()
        XCTAssertTrue(relaunchedApp.staticTexts["App Limits"].waitForExistence(timeout: 5))
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
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-mori_locale_preference", "en",
            "-MoriOpenSettingsForUITest",
            "-MoriDisableAIPulse"
        ] + extraArguments
        app.launch()

        let appLimitsButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "App Limits,")
        ).firstMatch
        XCTAssertTrue(appLimitsButton.waitForExistence(timeout: 8))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "App Limits,")).count, 1)
        appLimitsButton.tap()
        XCTAssertTrue(app.staticTexts["App Limits"].waitForExistence(timeout: 5))

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
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-mori_locale_preference", "en",
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
        app.launchArguments = [
            "-MoriSkipOnboardingForUITest",
            "-AppleLanguages", "(en)", "-mori_locale_preference", "en",
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
        app.launchArguments = [
            "-MoriSkipOnboardingForUITest",
            "-AppleLanguages", "(en)", "-mori_locale_preference", "en",
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

    private func tapGuidedControl(_ id: String, _ app: XCUIApplication) {
        let target = app.descendants(matching: .any).matching(identifier: id).firstMatch
        for _ in 0..<6 where !target.isHittable {
            if target.exists && target.frame.midY < app.frame.midY { app.swipeDown() }
            else { app.swipeUp() }
        }
        attachScreenshot(named: "guided-control-" + id)
        XCTAssertTrue(target.waitForExistence(timeout: 5), id)
        XCTAssertTrue(target.isHittable, id)
        target.tap()
    }


    private func launchGuidedLog(fresh: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-mori_locale_preference", "en",
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
