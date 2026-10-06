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

    func testBreathingPhasePauseResumeAndBackgroundContinuity() {
        let app = launch(["-MoriOpenBreathingTimerForUITest", "-mori_timer_dark_room_enabled", "NO",
                          "-mori_settle_breathing_sound_enabled", "NO", "-mori_settle_breathing_haptics_enabled", "NO"])
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 15))
        let active = XCTAttachment(screenshot: app.screenshot())
        active.name = "breathing-active-pass-1"
        active.lifetime = .keepAlways
        add(active)
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 3))
        let paused = XCTAttachment(screenshot: app.screenshot())
        paused.name = "breathing-paused-pass-2"
        paused.lifetime = .keepAlways
        add(paused)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
        app.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        let resumed = XCTAttachment(screenshot: app.screenshot())
        resumed.name = "breathing-resumed"
        resumed.lifetime = .keepAlways
        add(resumed)
    }

    private var beforeFeedCircleFlags: [String] {
        ["-MoriOpenBeforeFeedForUITest", "-MoriClearBeforeFeedHistoryForUITest",
         "-mori_before_feed_grace_until", "0",
         "-mori_before_feed_pause_style_v1", "guided_breathing",
         "-mori_before_feed_breathing_technique_id", "Coherent (5.5s in - 5.5s out)",
         "-mori_before_feed_guided_cycle_count", "3"]
    }

    func testBeforeFeedSantiCirclePhasePauseResumeAndCompletion() {
        let app = launch(beforeFeedCircleFlags)
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 12))
        let visual = app.descendants(matching: .any)["before-feed.breath-visual"].firstMatch
        XCTAssertTrue(visual.waitForExistence(timeout: 3))
        capture("Mori Santi circle active pass 1")
        let exhale = NSPredicate(format: "label CONTAINS[c] %@", "Exhale")
        expectation(for: exhale, evaluatedWith: visual)
        waitForExpectations(timeout: 12)
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 3))
        let pausedLabel = visual.label
        capture("Mori Santi circle paused pass 2")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
        XCTAssertEqual(visual.label, pausedLabel)
        app.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Why now?"].waitForExistence(timeout: 40))
        XCTAssertFalse(visual.exists)
    }

    func testBeforeFeedConciseTraditionalChineseHasNoVisibleTechniqueOrSeconds() {
        let app = launch(beforeFeedCircleFlags + ["-mori_locale_preference", "zh-Hant", "-MoriFreezeBeforeFeedTimerForUITest"])
        XCTAssertTrue(app.buttons["暫停"].waitForExistence(timeout: 12))
        let visual = app.descendants(matching: .any)["before-feed.breath-visual"].firstMatch
        XCTAssertTrue(visual.exists)
        XCTAssertTrue(visual.label.contains("3") && visual.label.contains("呼吸"))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "秒")).count, 0)
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Coherent")).count, 0)
        XCTAssertFalse(app.staticTexts["呼吸鑰匙"].exists)
        XCTAssertFalse(app.staticTexts["從呼吸開始"].exists)
        capture("Mori concise Before Feed TC pass 1")
        app.buttons["暫停"].tap()
        XCTAssertTrue(app.buttons["繼續"].waitForExistence(timeout: 3))
    }

    func testBeforeFeedConciseTraditionalChineseLargeTextKeepsControlsReachable() {
        let app = launch(beforeFeedCircleFlags + ["-mori_locale_preference", "zh-Hant", "-MoriFreezeBeforeFeedTimerForUITest",
                          "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let pause = app.buttons["暫停"]
        XCTAssertTrue(pause.waitForExistence(timeout: 12))
        if !pause.isHittable { app.swipeUp() }
        XCTAssertTrue(pause.isHittable)
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "秒")).count, 0)
        capture("Mori concise Before Feed TC large text pass 2")
    }

    func testBeforeFeedSantiCircleTraditionalChineseAtAccessibilityTextSize() {
        let app = launch(beforeFeedCircleFlags + ["-mori_locale_preference", "zh-Hant",
                          "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let pause = app.buttons["暫停"]
        XCTAssertTrue(pause.waitForExistence(timeout: 12))
        if !pause.isHittable { app.swipeUp() }
        XCTAssertTrue(pause.isHittable)
        capture("Mori Santi circle Traditional Chinese large text")
        pause.tap()
        XCTAssertTrue(app.buttons["繼續"].waitForExistence(timeout: 3))
    }

    func testGentleReentryPreservesAllowanceThroughCancelReturnAndBackground() {
        let flags = ["-MoriOpenBeforeFeedForUITest", "-MoriSeedRecentAllowanceForUITest", "-MoriInspectAllowanceForUITest"]
        let app = launch(flags + ["-MoriClearBeforeFeedHistoryForUITest"])
        let title = app.staticTexts["before-feed.reentry-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 12))
        let before = app.otherElements["before-feed.test-allowance"].value as? String
        XCTAssertNotNil(before)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "gentle-reentry-library-pass-1"; screenshot.lifetime = .keepAlways; add(screenshot)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(app.otherElements["before-feed.test-allowance"].value as? String, before)
        app.buttons["Close"].tap()
        app.terminate()
        app.launchArguments.removeAll { $0 == "-MoriClearBeforeFeedHistoryForUITest" }
        app.launch()
        XCTAssertTrue(title.waitForExistence(timeout: 12))
        XCTAssertEqual(app.otherElements["before-feed.test-allowance"].value as? String, before)
        app.buttons["before-feed.reentry-reuse"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(title.waitForExistence(timeout: 12))
        XCTAssertEqual(app.otherElements["before-feed.test-allowance"].value as? String, before)
        app.buttons["before-feed.reentry-return"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(title.waitForExistence(timeout: 12))
        XCTAssertEqual(app.otherElements["before-feed.test-allowance"].value as? String, before)
    }

    func testActiveAllowanceOffersOnlyReuseOrReturnAcrossRelaunch() {
        let app = launch(["-MoriOpenBeforeFeedForUITest", "-MoriSeedRecentAllowanceForUITest", "-MoriInspectAllowanceForUITest", "-MoriClearBeforeFeedHistoryForUITest"])
        XCTAssertTrue(app.staticTexts["before-feed.reentry-title"].waitForExistence(timeout: 12))
        let before = app.otherElements["before-feed.test-allowance"].value as? String
        XCTAssertFalse(app.buttons["before-feed.reentry-choose"].exists)
        XCTAssertFalse(app.buttons["2 minutes"].exists)
        XCTAssertTrue(app.buttons["before-feed.reentry-reuse"].exists)
        XCTAssertTrue(app.buttons["before-feed.reentry-return"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "active-allowance-no-renewal-pass-1"; shot.lifetime = .keepAlways; add(shot)
        app.terminate(); app.launchArguments.removeAll { $0 == "-MoriClearBeforeFeedHistoryForUITest" }; app.launch()
        XCTAssertTrue(app.staticTexts["before-feed.reentry-title"].waitForExistence(timeout: 12))
        XCTAssertEqual(app.otherElements["before-feed.test-allowance"].value as? String, before)
        XCTAssertFalse(app.buttons["before-feed.reentry-choose"].exists)
    }

    func testGentleReentryTraditionalChineseAtAccessibilityTextSize() {
        let app = launch(["-MoriOpenBeforeFeedForUITest", "-MoriSeedRecentAllowanceForUITest",
                          "-MoriClearBeforeFeedHistoryForUITest", "-mori_locale_preference", "zh-Hant",
                          "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(app.staticTexts["before-feed.reentry-title"].waitForExistence(timeout: 12))
        XCTAssertEqual(app.staticTexts["before-feed.reentry-title"].label, "呢刻想點？")
        let choose = app.buttons["before-feed.reentry-reuse"]
        if !choose.isHittable { app.swipeUp() }
        XCTAssertTrue(choose.isHittable)
        let returned = app.buttons["before-feed.reentry-return"]
        if !returned.isHittable { app.swipeUp() }
        XCTAssertTrue(returned.isHittable)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "gentle-reentry-zh-Hant-large-text"; screenshot.lifetime = .keepAlways; add(screenshot)
    }

    func testActiveAllowanceAtOneAndThreeMinutesPreservesDeadlineAfterCancelAndReuse() {
        for age in ["60", "180"] {
            let app = launch(["-MoriOpenBeforeFeedForUITest", "-MoriSeedRecentAllowanceForUITest",
                              "-MoriInspectAllowanceForUITest", "-MoriClearBeforeFeedHistoryForUITest",
                              "-MoriAllowanceAgeForUITest", age])
            XCTAssertTrue(app.staticTexts["before-feed.reentry-title"].waitForExistence(timeout: 12))
            let before = app.otherElements["before-feed.test-allowance"].value as? String
            XCTAssertFalse(app.buttons["before-feed.reentry-choose"].exists)
            XCTAssertFalse(app.buttons["2 minutes"].exists)
            app.buttons["Close"].tap()
            app.terminate()
            app.launchArguments.removeAll { $0 == "-MoriClearBeforeFeedHistoryForUITest" }
            app.launch()
            XCTAssertTrue(app.staticTexts["before-feed.reentry-title"].waitForExistence(timeout: 12))
            XCTAssertEqual(app.otherElements["before-feed.test-allowance"].value as? String, before)
            app.buttons["before-feed.reentry-reuse"].tap()
            app.terminate(); app.launch()
            XCTAssertTrue(app.staticTexts["before-feed.reentry-title"].waitForExistence(timeout: 12))
            XCTAssertEqual(app.otherElements["before-feed.test-allowance"].value as? String, before)
            app.terminate()
        }
    }

    func testAllowanceExpiringWhilePromptOpenCannotRenewOnReuse() {
        let app = launch(["-MoriOpenBeforeFeedForUITest", "-MoriSeedRecentAllowanceForUITest",
                          "-MoriInspectAllowanceForUITest", "-MoriClearBeforeFeedHistoryForUITest",
                          "-MoriExpireAllowanceForUITest",
                          "-mori_before_feed_pause_style_v1", "guided_breathing",
                          "-mori_before_feed_breathing_technique_id", "Coherent (5.5s in - 5.5s out)",
                          "-mori_before_feed_guided_cycle_count", "3"])
        XCTAssertTrue(app.staticTexts["before-feed.reentry-title"].waitForExistence(timeout: 12))
        let expired = NSPredicate(format: "label == %@", "Your planned window has ended.")
        expectation(for: expired, evaluatedWith: app.staticTexts["before-feed.reentry-remaining"])
        waitForExpectations(timeout: 15)
        app.buttons["before-feed.reentry-reuse"].tap()
        app.terminate()
        app.launchArguments.removeAll { $0 == "-MoriClearBeforeFeedHistoryForUITest" || $0 == "-MoriExpireAllowanceForUITest" }
        app.launch()
        XCTAssertFalse(app.staticTexts["before-feed.reentry-title"].waitForExistence(timeout: 3))
        XCTAssertTrue((app.otherElements["before-feed.test-allowance"].value as? String)?.hasSuffix("|1") == true)
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["before-feed.breath-visual"].firstMatch.exists)
        XCTAssertFalse(app.buttons["2 minutes"].exists)
        capture("expiry-fresh-Santi-pause-pass-2")
        XCTAssertTrue(app.staticTexts["Why now?"].waitForExistence(timeout: 40))
        app.buttons["Learn"].tap()
        app.buttons["2 minutes"].tap()
        let confirm = app.buttons["Open for 2 minutes"]
        if !confirm.isHittable { app.swipeUp() }
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["before-feed.reentry-title"].waitForExistence(timeout: 12))
        XCTAssertTrue((app.otherElements["before-feed.test-allowance"].value as? String)?.hasSuffix("|2") == true)
        XCTAssertFalse(app.buttons["before-feed.reentry-choose"].exists)

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

    func testBeforeFeedCircleSystemReducedMotionPixelsV4() throws {
        let revision = XCTAttachment(string: "MoriCircleSystemReduced-20261002-v4")
        revision.name = "Mori reduced circle revision"; revision.lifetime = .keepAlways; add(revision)
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.activate()
        let reduce = settings.switches["Reduce Motion"].firstMatch
        if !reduce.exists {
            let motion = settings.staticTexts["Motion"].firstMatch
            if !motion.exists {
                let accessibility = settings.staticTexts["Accessibility"].firstMatch
                for _ in 0..<8 where !accessibility.isHittable { settings.swipeUp() }
                XCTAssertTrue(accessibility.waitForExistence(timeout: 5)); accessibility.tap()
            }
            XCTAssertTrue(motion.waitForExistence(timeout: 5)); motion.tap()
        }
        XCTAssertTrue(reduce.waitForExistence(timeout: 5))
        guard (reduce.value as? String) == "1" else {
            throw XCTSkip("This read-only system-reduced check requires Reduce Motion already enabled")
        }
        let breathing = launch(beforeFeedCircleFlags)
        XCTAssertTrue(breathing.buttons["Pause"].waitForExistence(timeout: 12))
        let visual = breathing.descendants(matching: .any)["before-feed.breath-visual"].firstMatch
        XCTAssertTrue(visual.waitForExistence(timeout: 3))
        let frame = visual.frame
        let first = XCUIScreen.main.screenshot()
        Thread.sleep(forTimeInterval: 3)
        let second = XCUIScreen.main.screenshot()
        let scale = CGFloat(first.image.cgImage!.width) / breathing.frame.width
        let region = CGRect(x: (frame.midX - 106) * scale, y: (frame.midY - 26) * scale,
                            width: 22 * scale, height: 52 * scale)
        let a = UIImage(cgImage: first.image.cgImage!.cropping(to: region)!).pngData()!
        let b = UIImage(cgImage: second.image.cgImage!.cropping(to: region)!).pngData()!
        XCTAssertEqual(a, b, "The live circle must stay still under the actual system setting")
        for (name, screenshot) in [("System reduced circle V4 first", first), ("System reduced circle V4 second", second)] {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        let proof = XCTAttachment(string: "revision=MoriCircleSystemReduced-20261002-v4\nsystemReduceMotion=1\nedgePixelsIdentical=\(a == b)\nregion=\(region)\nsettingsMutated=false")
        proof.name = "Mori live reduced circle proof"; proof.lifetime = .keepAlways; add(proof)
    }

    func testBeforeFeedCircleMotionPixelsV3() throws {
        let revision = XCTAttachment(string: "MoriSantiCirclePixels-20261002-v3")
        revision.name = "Mori circle pixel test revision"; revision.lifetime = .keepAlways; add(revision)
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
        func setReduceMotion(_ enabled: Bool) -> Bool {
            settings.activate()
            let target = enabled ? "1" : "0"
            if (reduce.value as? String) != target {
                // iOS 26.5 exposes the whole settings row as this switch. Its
                // native tap hits the label; drag between the inspected thumb
                // centers instead, and still require the actual value to change.
                let onThumb = reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
                let offThumb = reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.5))
                if enabled { offThumb.press(forDuration: 0.15, thenDragTo: onThumb) }
                else { onThumb.press(forDuration: 0.15, thenDragTo: offThumb) }
            }
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", target), object: reduce)
            return XCTWaiter.wait(for: [changed], timeout: 5) == .completed
        }
        guard setReduceMotion(true) else {
            XCTFail("The system Reduce Motion switch did not turn on"); return
        }
        defer { XCTAssertTrue(setReduceMotion(wasEnabled), "Restore the original simulator motion setting") }
        let breathing = launch(beforeFeedCircleFlags)
        XCTAssertTrue(breathing.buttons["Pause"].waitForExistence(timeout: 12))
        // Compare the circle edge only; the phase label inside remains meaningful.
        let visual = breathing.descendants(matching: .any)["before-feed.breath-visual"].firstMatch
        XCTAssertTrue(visual.waitForExistence(timeout: 3))
        let visualFrame = visual.frame
        let aCapture = XCUIScreen.main.screenshot()
        Thread.sleep(forTimeInterval: 3)
        let bCapture = XCUIScreen.main.screenshot()
        let pixelScale = CGFloat(aCapture.image.cgImage!.width) / breathing.frame.width
        let edgeRegion = CGRect(x: (visualFrame.midX - 106) * pixelScale,
                                y: (visualFrame.midY - 26) * pixelScale,
                                width: 22 * pixelScale, height: 52 * pixelScale)
        func circleEdge(_ screenshot: XCUIScreenshot) -> Data {
            UIImage(cgImage: screenshot.image.cgImage!.cropping(to: edgeRegion)!).pngData()!
        }
        func filledCirclePixels(_ screenshot: XCUIScreenshot, region: CGRect) -> Int {
            guard let image = screenshot.image.cgImage?.cropping(to: region) else {
                XCTFail("The inspected circle edge must be inside the screenshot"); return 0
            }
            let width = image.width, height = image.height
            var rgba = [UInt8](repeating: 0, count: width * height * 4)
            rgba.withUnsafeMutableBytes { bytes in
                guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                    bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else {
                    XCTFail("Unable to inspect the circle pixels"); return
                }
                context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            }
            // This screenshot's inspected opaque circle fill is RGB (247,247,240).
            // Counting its area excludes incidental motion in the cream background.
            var filled = 0
            for offset in stride(from: 0, to: rgba.count, by: 4) {
                let red = Int(rgba[offset])
                let green = Int(rgba[offset + 1])
                let blue = Int(rgba[offset + 2])
                if abs(red - 247) <= 2 && abs(green - 247) <= 2 && abs(blue - 240) <= 2 {
                    filled += 1
                }
            }
            return filled
        }
        let reducedFillA = filledCirclePixels(aCapture, region: edgeRegion)
        let reducedFillB = filledCirclePixels(bCapture, region: edgeRegion)
        XCTAssertGreaterThan(reducedFillA, 0, "The comparison must include the actual circle edge")
        XCTAssertEqual(reducedFillA, reducedFillB)
        XCTAssertEqual(circleEdge(aCapture), circleEdge(bCapture), "Reduce Motion must keep the circle edge still while phase labels update")
        for (name, screenshot) in [("Before Feed reduced circle first", aCapture), ("Before Feed reduced circle second", bCapture)] {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        guard setReduceMotion(false) else {
            throw XCTSkip("The iOS 26.5 simulator Settings switch remains ON after the verified thumb gesture. Reduced-motion pixels were checked; normal phase rendering is verified independently by the native ImageRenderer test.")
        }
        breathing.terminate()
        let moving = launch(beforeFeedCircleFlags)
        XCTAssertTrue(moving.buttons["Pause"].waitForExistence(timeout: 12))
        let movingVisual = moving.descendants(matching: .any)["before-feed.breath-visual"].firstMatch
        XCTAssertTrue(movingVisual.waitForExistence(timeout: 3))
        let movingFrame = movingVisual.frame
        let firstMoving = XCUIScreen.main.screenshot()
        Thread.sleep(forTimeInterval: 3)
        let secondMoving = XCUIScreen.main.screenshot()
        let movingRegion = CGRect(x: (movingFrame.midX - 106) * pixelScale,
                                  y: (movingFrame.midY - 26) * pixelScale,
                                  width: 22 * pixelScale, height: 52 * pixelScale)
        let firstEdge = UIImage(cgImage: firstMoving.image.cgImage!.cropping(to: movingRegion)!).pngData()!
        let secondEdge = UIImage(cgImage: secondMoving.image.cgImage!.cropping(to: movingRegion)!).pngData()!
        let movingFillA = filledCirclePixels(firstMoving, region: movingRegion)
        let movingFillB = filledCirclePixels(secondMoving, region: movingRegion)
        XCTAssertNotEqual(movingFillA, movingFillB, "The circle's filled area must change, independent of background motion")
        XCTAssertNotEqual(firstEdge, secondEdge, "With motion allowed, the selected breath must change the circle's edge")
        for (name, screenshot) in [("Before Feed moving circle first", firstMoving), ("Before Feed moving circle second", secondMoving)] {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        let proof = XCTAttachment(string: "revision=MoriSantiCirclePixels-20261002-v3\nreducedEdgeEqual=\(circleEdge(aCapture) == circleEdge(bCapture))\nnormalEdgeChanged=\(firstEdge != secondEdge)\nreducedFilledPixels=\(reducedFillA),\(reducedFillB)\nnormalFilledPixels=\(movingFillA),\(movingFillB)\nreducedEdgeRegion=\(edgeRegion)\nnormalEdgeRegion=\(movingRegion)")
        proof.name = "Mori circle pixel proof"; proof.lifetime = .keepAlways; add(proof)
        // Verify normal-path restoration as well as retaining the defer safety net.
        XCTAssertTrue(setReduceMotion(wasEnabled), "Restore the exact original simulator setting")
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
