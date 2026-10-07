import XCTest

final class MoriJournalMoodUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testWhitespaceNoteShareSuccess() {
        let app = launch()
        prepareDetails(app, note: " note \n")
        tap("journal-mood-share-health", app)
        assertNormalizedNote(app)
        XCTAssertTrue(app.staticTexts["journal-mood-share-status"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journal-mood-share-status"].label, "Shared with Apple Health")
        capture("Journal mood share success", app)
    }

    func testWhitespaceNoteShareDenied() {
        let app = launch(extra: ["-MoriMoodHealthDeniedForUITest"])
        prepareDetails(app, note: " note \n")
        tap("journal-mood-share-health", app)
        assertNormalizedNote(app)
        XCTAssertTrue(app.staticTexts["journal-mood-share-status"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journal-mood-share-status"].label,
            "Saved in Mori. This share did not complete. Check Health access and try again.")
        capture("Journal mood share denied", app)
    }

    func testWhitespaceNoteDeferredShareCompletesAfterNormalization() {
        let app = launch(extra: ["-MoriMoodHealthDeferredForUITest"])
        prepareDetails(app, note: " note \n")
        tap("journal-mood-share-health", app)
        assertNormalizedNote(app)
        XCTAssertFalse(app.staticTexts["journal-mood-share-status"].exists)
        tap("journal-mood-finish-fixture", app)
        XCTAssertTrue(app.staticTexts["journal-mood-share-status"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journal-mood-share-status"].label, "Shared with Apple Health")
        capture("Journal mood deferred completion", app)
    }

    func testCompactChoicesEnglish() {
        let app = launch()
        assertPrimaryChoices(app)
        capture("Journal feeling choices English", app)
        prepareDetails(app)
        capture("Journal Health disclosure English", app)
    }

    func testCompactChoicesTraditionalChinese() {
        let app = launch(language: "zh-Hant")
        assertPrimaryChoices(app)
        capture("Journal feeling choices Traditional Chinese", app)
        prepareDetails(app)
        capture("Journal Health disclosure Traditional Chinese", app)
    }

    func testLargeTextTraditionalChinese() {
        let app = launch(language: "zh-Hant", extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        assertPrimaryChoices(app)
        capture("Journal feeling choices Traditional Chinese large text", app)
        prepareDetails(app)
        capture("Journal Health disclosure Traditional Chinese large text", app)
    }

    func testHistoricalFeelingAppearsOnceAfterExpandingGroup() {
        var app = launch()
        tap("journal-other-feelings", app)
        tap("journal-feeling-group-pleasant", app)
        tap("journal-guided-emotion-hopeful", app)
        tap("journal-guided-context-money", app)
        tap("journal-guided-response-keep-this-moment", app)
        tap("journal-guided-save", app)
        app.terminate()
        app = launch(fresh: false)
        tap("journal-guided-summary-0", app)
        XCTAssertEqual(app.buttons.matching(identifier: "journal-guided-emotion-hopeful").count, 1)
        tap("journal-other-feelings", app)
        tap("journal-feeling-group-pleasant", app)
        XCTAssertEqual(app.buttons.matching(identifier: "journal-guided-emotion-hopeful").count, 1)
        capture("Journal restored feeling without duplicate", app)
    }

    func testExpandedChoicesAndScaleBothLanguages() {
        for language in ["en", "zh-Hant"] {
            let app = launch(language: language)
            tap("journal-mood-valence-disclosure", app)
            capture("Expanded pleasantness " + language + " upper", app)
            tap("journal-mood-veryPleasant", app)
            capture("Expanded pleasantness " + language + " selected lower", app)
            tap("journal-mood-valence-disclosure", app)
            tap("journal-other-feelings", app)
            for group in ["pleasant", "neutral", "difficult"] {
                tap("journal-feeling-group-" + group, app)
                capture("Additional feelings " + language + " " + group + " upper", app)
                let last = group == "pleasant" ? "relieved" : (group == "neutral" ? "unclear" : "frustrated")
                reveal("journal-guided-emotion-" + last, app)
                capture("Additional feelings " + language + " " + group + " lower", app)
                tap("journal-feeling-group-" + group, app)
            }
            app.terminate()
        }
    }

    func testAccessiblePhotoFooterAndSummary() {
        for language in ["en", "zh-Hant"] {
            let app = launch(language: language, extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
            prepareDetails(app)
            reveal("journal-guided-summary-0", app)
            for _ in 0..<4 where app.buttons["journal-guided-summary-0"].frame.minY < app.frame.minY + 80 {
                app.swipeDown()
            }
            for index in 0..<8 {
                capture("Large review " + language + " upper summary " + String(index), app)
                let lastSummary = app.buttons["journal-guided-summary-2"]
                if lastSummary.isHittable && lastSummary.frame.maxY < app.frame.maxY - 100 { break }
                let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
                let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
                start.press(forDuration: 0.1, thenDragTo: end)
            }
            reveal("journal-mood-share-health", app)
            capture("Large review " + language + " share action", app)
            for index in 0..<10 {
                capture("Large review " + language + " payload scroll " + String(index), app)
                if app.buttons["journal-mood-sharing-details"].isHittable { break }
                let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
                let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
                start.press(forDuration: 0.1, thenDragTo: end)
            }
            tap("journal-mood-sharing-details", app)
            capture("Large review " + language + " sharing details", app)
            for index in 0..<10 {
                capture("Large review " + language + " scroll " + String(index), app)
                let save = app.buttons["journal-guided-save"]
                if save.isHittable && save.frame.maxY < app.frame.maxY - 100 { break }
                let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
                let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
                start.press(forDuration: 0.1, thenDragTo: end)
            }
            capture("Large review " + language + " privacy and local save", app)
            XCTAssertTrue(app.buttons["journal-guided-save"].isHittable)
            XCTAssertLessThan(app.buttons["journal-guided-save"].frame.maxY, app.frame.maxY - 100)
            XCTAssertTrue(app.buttons["journal-guided-add-photo"].isHittable)
            capture("Large photo and complete local save footer " + language, app)
            if language == "en" {
                tap("journal-mood-share-health", app)
                XCTAssertTrue(app.staticTexts["journal-mood-share-status"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["journal-mood-share-status"].label, "Shared with Apple Health")
                reveal("journal-mood-share-health", app)
                capture("Large English share outcome upper", app)
                reveal("journal-mood-share-status", app)
                for _ in 0..<4 where app.staticTexts["journal-mood-share-status"].frame.maxY > app.frame.maxY - 100 {
                    app.swipeUp()
                }
                capture("Large English complete share outcome", app)
            }
            app.terminate()
        }
    }

    func testTraditionalChineseShareOutcomes() {
        for denied in [false, true] {
            let app = launch(language: "zh-Hant", extra: denied ? ["-MoriMoodHealthDeniedForUITest"] : [])
            prepareDetails(app)
            tap("journal-mood-share-health", app)
            XCTAssertTrue(app.staticTexts["journal-mood-share-status"].waitForExistence(timeout: 5))
            reveal("journal-mood-share-health", app)
            capture(denied ? "Chinese share incomplete" : "Chinese share completed", app)
            reveal("journal-guided-save", app)
            capture(denied ? "Chinese share incomplete local save" : "Chinese share completed local save", app)
            app.terminate()
        }
    }

    private func reveal(_ id: String, _ app: XCUIApplication) {
        let target = element(id, app)
        if !target.exists {
            for _ in 0..<4 where !target.exists { app.swipeDown() }
            for _ in 0..<10 where !target.exists { app.swipeUp() }
        }
        XCTAssertTrue(target.waitForExistence(timeout: 5), id)
        for _ in 0..<10 where !target.isHittable {
            if target.frame.midY < app.frame.midY { app.swipeDown() }
            else { app.swipeUp() }
        }
        XCTAssertTrue(target.isHittable, id)
    }

    private func launch(language: String = "en", fresh: Bool = true, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-MoriSkipOnboardingForUITest", "-MoriSkipAnalyticsConsentForUITest",
            "-MoriSkipCloudBackupForUITest", "-MoriDisableAIPulse", "-MoriOpenLogForUITest",
            "-MoriJournalMoodFixtureForUITest", "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "en" ? "en_US" : "zh_TW", "-mori_locale_preference", language]
            + (fresh ? ["-MoriStartFreshLogForUITest"] : []) + extra
        app.launch()
        let initialID = fresh ? "journal-guided-emotion-calm" : "journal-guided-summary-0"
        if !app.buttons[initialID].waitForExistence(timeout: 5) {
            reveal(initialID, app)
        }
        XCTAssertTrue(app.buttons[initialID].exists)
        return app
    }

    private func assertPrimaryChoices(_ app: XCUIApplication) {
        for id in ["happy", "calm", "okay", "sad"] {
            let choice = app.buttons["journal-guided-emotion-" + id]
            for _ in 0..<8 where !choice.exists { app.swipeUp() }
            XCTAssertTrue(choice.exists)
        }
        XCTAssertFalse(app.buttons["journal-guided-emotion-anxious"].exists)
        XCTAssertTrue(app.buttons["journal-guided-skip-feeling"].exists)
    }

    private func prepareDetails(_ app: XCUIApplication, note: String? = nil) {
        tap("journal-guided-emotion-calm", app)
        tap("journal-guided-context-money", app)
        tap("journal-guided-response-keep-this-moment", app)
        tap("journal-mood-valence-disclosure", app)
        tap("journal-mood-pleasant", app)
        tap("journal-mood-valence-disclosure", app)
        if let note {
            tap("journal-guided-add-sentence", app)
            let editor = app.textViews["journal-guided-note"]
            XCTAssertTrue(editor.waitForExistence(timeout: 3))
            editor.tap(); editor.typeText(note)
            let done = app.buttons["Dismiss keyboard"].firstMatch
            if done.exists { done.tap() }
        }
        let share = element("journal-mood-share-health", app)
        for _ in 0..<8 where !share.isHittable { app.swipeUp() }
        XCTAssertTrue(share.isHittable)
    }

    private func assertNormalizedNote(_ app: XCUIApplication) {
        let editor = app.textViews["journal-guided-note"]
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "note"), object: editor)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    private func element(_ id: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func tap(_ id: String, _ app: XCUIApplication) {
        let target = element(id, app)
        if !target.exists {
            for _ in 0..<4 where !target.exists { app.swipeDown() }
            for _ in 0..<8 where !target.exists { app.swipeUp() }
        }
        XCTAssertTrue(target.waitForExistence(timeout: 5), id)
        for _ in 0..<8 where !target.isHittable {
            if target.frame.midY < app.frame.midY { app.swipeDown() }
            else { app.swipeUp() }
        }
        XCTAssertTrue(target.isHittable, id)
        target.tap()
    }

    private func capture(_ name: String, _ app: XCUIApplication) {
        Thread.sleep(forTimeInterval: 0.5) // Let disclosure transitions settle before preserving original pixels.
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
