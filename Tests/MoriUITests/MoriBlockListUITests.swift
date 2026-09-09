import XCTest

final class MoriBlockListUITests: XCTestCase {
    func testSettingsBlockListCreateRenameCancelDeleteAndRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest", "-MoriSkipCloudBackupForUITest", "-MoriDisableAIPulse", "-MoriOpenSettingsForUITest", "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-mori_locale_preference", "en"]
        app.launch()
        let entry = app.buttons["settings-block-lists"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        capture("Settings block lists entry")
        entry.tap()
        XCTAssertTrue(app.buttons["block-lists-add"].waitForExistence(timeout: 5))
        capture("Block lists overview")
        app.buttons["block-lists-add"].tap()
        XCTAssertTrue(app.textFields["block-list-name"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["block-list-save"].isEnabled)
        let name = "Work \(UUID().uuidString.prefix(6))"
        app.textFields["block-list-name"].tap()
        app.textFields["block-list-name"].typeText(name)
        capture("New block list editor")
        app.buttons["block-list-save"].tap()
        let row = app.buttons["block-list-\(name)"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        capture("Saved work list")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["settings-block-lists"].waitForExistence(timeout: 10))
        app.buttons["settings-block-lists"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        let field = app.textFields["block-list-name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(" draft")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(" study")
        app.buttons["block-list-save"].tap()
        let renamed = app.buttons["block-list-\(name) study"]
        XCTAssertTrue(renamed.waitForExistence(timeout: 5))
        renamed.tap()
        let delete = app.buttons["Delete Block List"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        capture("Delete block list confirmation")
        app.alerts.buttons["Cancel"].tap()
        delete.tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertTrue(app.buttons["block-lists-add"].waitForExistence(timeout: 5))
        XCTAssertFalse(renamed.exists)
    }

    func testTraditionalChineseListsAndLargeText() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest",
            "-MoriSkipCloudBackupForUITest", "-MoriDisableAIPulse", "-MoriOpenSettingsForUITest",
            "-AppleLanguages", "(zh-Hant)", "-AppleLocale", "zh_HK",
            "-mori_locale_preference", "zh-Hant",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["settings-block-lists"].waitForExistence(timeout: 10))
        if !app.buttons["settings-block-lists"].isHittable { app.swipeUp() }
        app.buttons["settings-block-lists"].tap()
        XCTAssertTrue(app.staticTexts["封鎖清單"].waitForExistence(timeout: 5))
        capture("Traditional Chinese block lists large text")
        app.buttons["block-lists-add"].tap()
        XCTAssertTrue(app.textFields["block-list-name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "選擇 App")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts["Choose Apps"].exists)
        XCTAssertFalse(app.staticTexts["No apps selected"].exists)
        capture("Traditional Chinese editor large text")
        app.buttons["取消"].tap()
        XCTAssertTrue(app.buttons["block-lists-add"].waitForExistence(timeout: 5))
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
