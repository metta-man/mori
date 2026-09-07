import XCTest
import UIKit

final class MoriLandscapeUITests: XCTestCase {
    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest",
            "-MoriSkipCloudBackupForUITest", "-MoriDisableAIPulse",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ] + arguments
        app.launch()
        return app
    }

    func testThreeTabsKeepCoreEntrypointsReachable() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["Before Feed Reset"].waitForExistence(timeout: 10))
        capture("Today")
        app.buttons["Focus"].tap()
        XCTAssertTrue(app.buttons["Focus on one thing"].waitForExistence(timeout: 5))
        capture("Focus")
        // Mode cards and disclosures expose semantic buttons, not separate title text.
        let support = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Focus support")).firstMatch
        for _ in 0..<4 where !support.isHittable { app.swipeUp() }
        XCTAssertTrue(support.waitForExistence(timeout: 3))
        support.tap()
        XCTAssertTrue(app.staticTexts["Breathing"].waitForExistence(timeout: 3))
        app.buttons["Log"].tap()
        XCTAssertTrue(app.staticTexts["Log"].waitForExistence(timeout: 5))
        capture("Log")
        app.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["Before Feed Reset"].waitForExistence(timeout: 5))
    }

    func testImmersiveFocusCanPauseResumeAndEnd() {
        let app = launch(["-MoriOpenDeepSessionForUITest", "-MoriAutoStartDeepSessionForUITest"])
        let pause = app.buttons["Pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        if !pause.isHittable { app.swipeUp() }
        capture("Deep Session running")
        pause.tap()
        let resume = app.buttons["Resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 3))
        capture("Deep Session paused")
        resume.tap()
        XCTAssertTrue(pause.waitForExistence(timeout: 3))
        pause.tap()
        let end = app.buttons["End quietly"]
        if !end.isHittable { app.swipeUp() }
        XCTAssertTrue(end.waitForExistence(timeout: 3))
        end.tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        capture("Deep Session complete")
    }

    func testTodayKeepsStatusSettingsAndQuietDetailsReachable() {
        let app = launch()
        let status = app.buttons["today-app-limits-status"]
        XCTAssertTrue(status.waitForExistence(timeout: 8))
        status.tap()
        XCTAssertTrue(app.staticTexts["App Limits"].waitForExistence(timeout: 5))
        app.swipeDown()
        app.terminate()
        let home = launch()
        let minutes = home.buttons["today-quiet-minutes"]
        if !minutes.isHittable { home.swipeUp() }
        minutes.tap()
        XCTAssertTrue(home.staticTexts["Longest quiet"].waitForExistence(timeout: 3))
        capture("Today quiet details")
        minutes.tap()
        XCTAssertFalse(home.staticTexts["Longest quiet"].exists)
    }

    func testAdditionalFeelingSavesAndRemainsEditable() {
        let app = launch(["-MoriOpenLogForUITest", "-MoriStartFreshLogForUITest"])
        XCTAssertTrue(app.buttons["journal-other-feelings"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["Hopeful"].exists)
        app.buttons["journal-other-feelings"].tap()
        XCTAssertTrue(app.buttons["Hopeful"].waitForExistence(timeout: 3))
        capture("Log other feelings")
        app.buttons["Hopeful"].tap()
        app.buttons["Work or study"].tap()
        let record = app.buttons["Just record it"]
        if !record.isHittable { app.swipeUp() }
        record.tap()
        let save = app.buttons["Save check-in"]
        if !save.isHittable { app.swipeUp() }
        save.tap()
        app.terminate()
        let restored = launch(["-MoriOpenLogForUITest"])
        XCTAssertTrue(restored.buttons["Save check-in"].waitForExistence(timeout: 8))
        restored.buttons["journal-guided-summary-0"].tap()
        XCTAssertTrue(restored.buttons["Hopeful"].waitForExistence(timeout: 3))
        capture("Saved additional feeling remains visible")
    }

    func testSystemReduceMotionKeepsLandscapeStill() {
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.activate()
        let reduce = settings.switches["Reduce Motion"].firstMatch
        if !reduce.exists {
            let motion = settings.staticTexts["Motion"].firstMatch
            if !motion.exists {
                let accessibility = settings.staticTexts["Accessibility"].firstMatch
                for _ in 0..<8 where !accessibility.isHittable { settings.swipeUp() }
                XCTAssertTrue(accessibility.waitForExistence(timeout: 5))
                accessibility.tap()
            }
            XCTAssertTrue(motion.waitForExistence(timeout: 5))
            motion.tap()
        }
        XCTAssertTrue(reduce.waitForExistence(timeout: 5))
        let wasEnabled = (reduce.value as? String) == "1"
        if !wasEnabled {
            reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        guard (reduce.value as? String) == "1" else {
            XCTFail("The system Reduce Motion switch did not turn on")
            return
        }
        defer {
            settings.activate()
            if !wasEnabled && (reduce.value as? String) == "1" {
                reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
            }
        }
        let app = launch()
        XCTAssertTrue(app.buttons["Begin quiet pause"].waitForExistence(timeout: 10))
        // Compare pixels in the landscape only, excluding system chrome and text.
        Thread.sleep(forTimeInterval: 2)
        let firstCapture = XCUIScreen.main.screenshot()
        let first = firstCapture.image.cgImage!
        Thread.sleep(forTimeInterval: 3)
        let secondCapture = XCUIScreen.main.screenshot()
        let second = secondCapture.image.cgImage!
        for (name, screenshot) in [("Reduced motion first", firstCapture), ("Reduced motion second", secondCapture)] {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        let region = CGRect(x: 0, y: Double(first.height) * 0.20,
                            width: Double(first.width), height: Double(first.height) * 0.24)
        let a = UIImage(cgImage: first.cropping(to: region)!).pngData()!
        let b = UIImage(cgImage: second.cropping(to: region)!).pngData()!
        XCTAssertTrue(a == b, "The landscape must stop under the system Reduce Motion setting")
        capture("System Reduce Motion")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
