import XCTest

final class AppearanceUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOpenSettingsAndSwitchAppearance() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        let calmNightOption = app.buttons["settings.appearance.option.calmNight"]
        XCTAssertTrue(calmNightOption.waitForExistence(timeout: 5))
        calmNightOption.tap()

        // The tapped row should now show as selected (checkmark visible via accessibility trait).
        XCTAssertTrue(calmNightOption.isSelected)
    }

    @MainActor
    func testAppearanceSelectionPersistsAcrossRelaunch() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()

        app.tabBars.buttons["Settings"].tap()
        let calmNightOption = app.buttons["settings.appearance.option.calmNight"]
        XCTAssertTrue(calmNightOption.waitForExistence(timeout: 5))
        calmNightOption.tap()
        XCTAssertTrue(calmNightOption.isSelected)

        // No reset flag this time — appearance and onboarding completion
        // should both survive the relaunch.
        app.terminate()
        app.launchArguments = []
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        let calmNightOptionAfterRelaunch = app.buttons["settings.appearance.option.calmNight"]
        XCTAssertTrue(calmNightOptionAfterRelaunch.waitForExistence(timeout: 5))
        XCTAssertTrue(calmNightOptionAfterRelaunch.isSelected)
    }
}
