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
        XCTAssertTrue(app.staticTexts["Recovery"].waitForExistence(timeout: 8))
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
}
