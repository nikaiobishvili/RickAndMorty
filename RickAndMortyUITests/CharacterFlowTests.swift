import XCTest

@MainActor
final class CharacterFlowTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(language: String = "en", largeText: Bool = false, resetSettings: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(\(language))", "-AppleLocale", language == "ka" ? "ka_GE" : "en_US"]
        if resetSettings { app.launchArguments.append("--reset-settings") }
        if largeText { app.launchArguments += ["--dark-mode", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }

    func testCharacterEpisodeParticipantAndBackNavigation() throws {
        let app = launch()
        let rick = app.buttons["character-1"]
        XCTAssertTrue(rick.waitForExistence(timeout: 10))
        rick.tap()
        let episode = app.buttons["episode-1"]
        XCTAssertTrue(episode.waitForExistence(timeout: 10))
        try app.performAccessibilityAudit()
        app.swipeUp()
        episode.tap()
        let morty = app.buttons["participant-2"]
        XCTAssertTrue(morty.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["participant-1"].exists)
        morty.tap()
        XCTAssertTrue(app.staticTexts["Morty Smith"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Rick Sanchez"].waitForExistence(timeout: 10))
        attachScreenshot("Character details and episode participants")
    }

    func testGeorgianDarkLandscapeAndLargeText() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launch(language: "ka", largeText: true)
        XCTAssertTrue(app.navigationBars["პერსონაჟები"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["character-1"].exists)
        app.buttons["character-1"].tap()
        XCTAssertTrue(app.navigationBars["პერსონაჟის დეტალები"].waitForExistence(timeout: 10))
        attachScreenshot("Georgian details with accessibility text")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["character-filters"].tap()
        XCTAssertTrue(app.navigationBars["ფილტრები"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["გამოყენება"].exists)
        attachScreenshot("Georgian adaptive filters")
    }

    func testLastParticipantIsReachable() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["character-1"].waitForExistence(timeout: 10))
        app.buttons["character-1"].tap()
        XCTAssertTrue(app.buttons["episode-1"].waitForExistence(timeout: 10))
        app.swipeUp()
        app.buttons["episode-1"].tap()
        let participants = app.scrollViews["participants-1"]
        XCTAssertTrue(participants.waitForExistence(timeout: 10))
        let last = app.buttons["participant-22"]
        for _ in 0..<16 {
            if last.exists && last.isHittable { break }
            participants.swipeLeft()
        }
        XCTAssertTrue(last.isHittable)
        last.tap()
        XCTAssertTrue(app.staticTexts["Character 22"].waitForExistence(timeout: 10))
    }

    func testCharacterListAccessibilityAudit() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["character-1"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit()
    }

    func testInAppLanguageChangesImmediatelyAndSurvivesRelaunch() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["character-1"].waitForExistence(timeout: 10))
        app.buttons["app-settings"].tap()
        XCTAssertTrue(app.buttons["open-background-settings"].exists)
        app.buttons["open-language-settings"].tap()
        app.buttons["language-ka"].tap()
        XCTAssertTrue(app.navigationBars["აპლიკაციის ენა"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit()
        attachScreenshot("In-app Georgian language selection")
        dismissSettings(in: app)
        XCTAssertTrue(app.navigationBars["პერსონაჟები"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["character-1"].label.contains("ცოცხალი"))
        app.terminate()

        let relaunched = launch(resetSettings: false)
        XCTAssertTrue(relaunched.navigationBars["პერსონაჟები"].waitForExistence(timeout: 10))
        relaunched.buttons["app-settings"].tap()
        relaunched.buttons["open-language-settings"].tap()
        relaunched.buttons["language-en"].tap()
        XCTAssertTrue(relaunched.navigationBars["App language"].waitForExistence(timeout: 5))
        dismissSettings(in: relaunched)
        XCTAssertTrue(relaunched.navigationBars["Characters"].waitForExistence(timeout: 5))
        relaunched.buttons["app-settings"].tap()
        relaunched.buttons["open-language-settings"].tap()
        relaunched.buttons["language-system"].tap()
        dismissSettings(in: relaunched)
        XCTAssertTrue(relaunched.navigationBars["Characters"].waitForExistence(timeout: 5))
    }

    func testLightAndDarkAreSelectedInsideTheAppAndRestored() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["character-1"].waitForExistence(timeout: 10))
        app.buttons["app-settings"].tap()
        XCTAssertTrue(app.buttons["open-language-settings"].exists)
        app.buttons["open-background-settings"].tap()
        app.buttons["theme-dark"].tap()
        XCTAssertTrue(app.buttons["theme-dark"].isSelected)
        XCTAssertFalse(app.buttons["theme-system"].exists)
        XCTAssertFalse(app.buttons["background-mint"].exists)
        try app.performAccessibilityAudit()
        dismissSettings(in: app)
        attachScreenshot("In-app Dark character list")
        app.terminate()

        let relaunched = launch(resetSettings: false)
        XCTAssertTrue(relaunched.buttons["app-settings"].waitForExistence(timeout: 10))
        relaunched.buttons["app-settings"].tap()
        relaunched.buttons["open-background-settings"].tap()
        XCTAssertTrue(relaunched.buttons["theme-dark"].isSelected)
        relaunched.buttons["theme-light"].tap()
        XCTAssertTrue(relaunched.buttons["theme-light"].isSelected)
        attachScreenshot("In-app Light background settings")
        dismissSettings(in: relaunched)
    }

    private func dismissSettings(in app: XCUIApplication) {
        XCTAssertFalse(app.buttons["settings-done"].exists)
        let start = app.navigationBars.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
