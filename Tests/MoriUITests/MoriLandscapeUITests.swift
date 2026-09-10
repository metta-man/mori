import XCTest
import UIKit

final class MoriLandscapeUITests: XCTestCase {
    private func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest",
            "-MoriSkipCloudBackupForUITest", "-MoriDisableAIPulse",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-mori_locale_preference", "en",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"
        ] + arguments
        app.launch()
        return app
    }

    func testQuietCountdownSurfacesKeepStartAndPauseReachable() {
        for (route, name) in [
            ("-MoriOpenQuietModeForUITest", "Quiet timer"),
            ("-MoriOpenSettleTimerForUITest", "Settle timer"),
            ("-MoriOpenMorningTimerForUITest", "Morning timer"),
            ("-MoriOpenManualTimerForUITest", "Manual practice timer")
        ] {
            let app = launch([route, "-mori_timer_dark_room_enabled", "NO"])
            let start = app.buttons["Start"].firstMatch
            // Quiet/Settle legitimately restore an unfinished timer on relaunch.
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                start.exists || app.buttons["Resume"].firstMatch.exists || app.buttons["Pause"].firstMatch.exists
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 8), .completed, name)
            if !app.buttons["Pause"].firstMatch.exists {
                let action = app.buttons["Resume"].firstMatch.exists ? app.buttons["Resume"].firstMatch : start
                if !action.isHittable { app.swipeUp() }
                action.tap()
            }
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let denyNotifications = springboard.buttons["Don’t Allow"].firstMatch
            let denyNotificationsASCII = springboard.buttons["Don't Allow"].firstMatch
            if denyNotifications.waitForExistence(timeout: 1) { denyNotifications.tap() }
            else if denyNotificationsASCII.exists { denyNotificationsASCII.tap() }
            let pause = app.buttons["Pause"].firstMatch
            XCTAssertTrue(pause.waitForExistence(timeout: 5), name)
            capture(name)
            pause.tap()
            XCTAssertFalse(pause.exists, name)
            app.terminate()
        }
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

    func testSetupDurationUpdatesTimerAndStartsChosenLength() {
        let app = launch([
            "-MoriOpenDeepSessionForUITest",
            "-mori_settle_pomodoro_focus_breathing", "none",
            "-mori_timer_dark_room_enabled", "NO"
        ])
        let duration = app.steppers.firstMatch
        XCTAssertTrue(duration.waitForExistence(timeout: 10))
        // Do not seed this editable preference via a launch argument: the
        // UserDefaults argument domain overrides subsequent preference writes.
        let initialMinutes = Int((duration.value as? String ?? "").split(separator: ":").first ?? "")
        guard let initialMinutes else { return XCTFail("Missing duration value") }
        let chosenMinutes = initialMinutes >= 90 ? initialMinutes - 5 : initialMinutes + 5
        duration.buttons[initialMinutes >= 90 ? "Decrement" : "Increment"].tap()
        let chosenDuration = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", String(format: "%02d:00", chosenMinutes)), object: duration
        )
        XCTAssertEqual(XCTWaiter.wait(for: [chosenDuration], timeout: 5), .completed)
        capture("Chosen duration setup")
        let start = app.buttons["Start Deep Session"]
        for _ in 0..<4 where !start.isHittable { app.swipeUp() }
        start.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        let timer = app.descendants(matching: .any).matching(
            NSPredicate(format: "label MATCHES %@", String(format: ".*, (%02d:00|%02d:[0-9]{2}) remaining", chosenMinutes, chosenMinutes - 1))
        ).firstMatch
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        capture("Chosen duration running")
    }

    func testLargeChineseCoreScreensRemainScrollable() {
        verifyChineseCoreScreens(category: "UICTContentSizeCategoryAccessibilityXL", prefix: "Large zh")
    }

    func testCompactChineseCoreScreensRemainScrollable() {
        verifyChineseCoreScreens(category: "UICTContentSizeCategoryL", prefix: "Compact zh")
    }

    func testRootScrollClearanceChinese() {
        let roots: Set<String> = ["Today", "Focus", "Log"]
        verifyChineseCoreScreens(category: "UICTContentSizeCategoryL", prefix: "Compact zh", screens: roots)
        verifyChineseCoreScreens(category: "UICTContentSizeCategoryAccessibilityXL", prefix: "Large zh", screens: roots)
    }

    private func verifyChineseCoreScreens(category: String, prefix: String, screens: Set<String>? = nil) {
        for (route, name) in [
            ("", "Today"), ("-MoriOpenFocusForUITest", "Focus"),
            ("-MoriOpenLogForUITest", "Log"), ("-MoriOpenSettingsForUITest", "Settings"),
            ("-MoriOpenDeepSessionForUITest", "Setup"),
            ("-MoriOpenDeepSessionForUITest", "Active"),
            ("-MoriOpenWeekArchiveForUITest", "Life Grid")
        ] {
            if let screens, !screens.contains(name) { continue }
            let app = XCUIApplication()
            app.launchArguments = [
                "-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest",
                "-MoriSkipCloudBackupForUITest", "-MoriDisableAIPulse",
                "-AppleLanguages", "(zh-Hant)", "-AppleLocale", "zh_HK",
                "-mori_locale_preference", "zh-Hant",
                "-UIPreferredContentSizeCategoryName", category
            ] + (route.isEmpty ? [] : [route])
              + (name == "Active" ? ["-MoriAutoStartDeepSessionForUITest", "-mori_timer_dark_room_enabled", "NO"] : [])
              + (name == "Log" ? ["-MoriStartFreshLogForUITest"] : [])
            app.launch()
            let destination: XCUIElement
            switch name {
            case "Today": destination = app.staticTexts["資訊流前重置"]
            case "Focus": destination = app.buttons["專心做一件事"]
            case "Log": destination = app.staticTexts["你現在感覺如何？"]
            case "Settings": destination = app.buttons["完成"]
            case "Setup": destination = app.steppers.firstMatch
            case "Active": destination = app.buttons["暫停"]
            default: destination = app.buttons["月"]
            }
            XCTAssertTrue(destination.waitForExistence(timeout: 30), name)
            XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 30), name)
            capture("\(prefix) \(name) top")
            app.swipeUp()
            app.swipeUp()
            capture("\(prefix) \(name) scrolled")
            if name == "Focus" {
                let support = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "專注工具")).firstMatch
                XCTAssertTrue(support.isHittable)
            }
            if name == "Settings" { XCTAssertTrue(app.buttons["完成"].exists) }
            app.terminate()
        }
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
