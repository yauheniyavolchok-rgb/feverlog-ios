import XCTest

final class LanguageUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSwitchingLanguageUpdatesVisibleStrings() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()

        app.tabBars.buttons["Settings"].tap()
        app.scrollToAndTap("settings.language")
        XCTAssertTrue(app.navigationBars["Language"].waitForExistence(timeout: 5))

        let ukrainianOption = app.buttons["languageSettings.option.uk"]
        XCTAssertTrue(ukrainianOption.waitForExistence(timeout: 5))
        ukrainianOption.tap()

        // Selecting a language forces a full view-tree rebuild, so the
        // navigation title itself should now read in the selected language.
        XCTAssertTrue(app.navigationBars["Мова"].waitForExistence(timeout: 5))
        XCTAssertTrue(ukrainianOption.isSelected)
    }

    @MainActor
    func testLanguageSelectionPersistsAcrossRelaunch() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()

        app.tabBars.buttons["Settings"].tap()
        app.scrollToAndTap("settings.language")
        let ukrainianOption = app.buttons["languageSettings.option.uk"]
        XCTAssertTrue(ukrainianOption.waitForExistence(timeout: 5))
        ukrainianOption.tap()
        XCTAssertTrue(app.navigationBars["Мова"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = []
        app.launch()

        app.tabBars.buttons["Налаштування"].tap()
        app.scrollToAndTap("settings.language")
        let ukrainianOptionAfterRelaunch = app.buttons["languageSettings.option.uk"]
        XCTAssertTrue(ukrainianOptionAfterRelaunch.waitForExistence(timeout: 5))
        XCTAssertTrue(ukrainianOptionAfterRelaunch.isSelected)
    }
}
