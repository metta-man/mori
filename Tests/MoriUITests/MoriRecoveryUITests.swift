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
    }

    func testHabitReasonLeadsToPlanWithoutContinueNowBypass() {
        let app = launchBeforeFeed()

        XCTAssertTrue(app.buttons["Habit"].waitForExistence(timeout: 8))
        app.buttons["Habit"].tap()
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["What would be enough?"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Continue now"].exists)
    }

    func testOtherReasonAlsoAsksWhatComesAfterTheFeed() {
        let app = launchBeforeFeed()

        XCTAssertTrue(app.buttons["Other"].waitForExistence(timeout: 8))
        app.buttons["Other"].tap()
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.buttons["15 minutes"].waitForExistence(timeout: 3))
        app.buttons["15 minutes"].tap()

        XCTAssertTrue(app.staticTexts["After this?"].waitForExistence(timeout: 3))
        let workButton = app.buttons["Work"]
        XCTAssertTrue(workButton.exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Before Feed - Other return question"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        workButton.tap()
        XCTAssertEqual(workButton.value as? String, "Selected")

        let selectedScreenshot = XCTAttachment(screenshot: app.screenshot())
        selectedScreenshot.name = "Before Feed - Other return question selected"
        selectedScreenshot.lifetime = .keepAlways
        add(selectedScreenshot)
    }

    func testForcedCompletionOffersLeaveClosedAndSpecificWindow() {
        let app = launchBeforeFeed(extraArguments: [
            "-MoriShowBeforeFeedCompletionForUITest"
        ])

        let returnButton = app.buttons["Return to work now"]
        let openButton = app.buttons["Open a 5-minute window"]
        XCTAssertTrue(returnButton.waitForExistence(timeout: 8))
        XCTAssertTrue(openButton.exists)
        XCTAssertLessThan(
            returnButton.frame.minY,
            openButton.frame.minY,
            "Selecting a real-world return anchor should keep the feed-closed action primary, even for a non-Habit reason."
        )
    }

    private func launchBeforeFeed(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-MoriSkipOnboardingForUITest",
            "-MoriOpenBeforeFeedForUITest",
            "-MoriDisableAIPulse"
        ] + extraArguments
        app.launch()

        if app.buttons["Not Now"].waitForExistence(timeout: 2) {
            app.buttons["Not Now"].tap()
        }
        return app
    }
}
