import XCTest

final class FeverLogLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFreshLaunchShowsOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()

        XCTAssertTrue(app.buttons["onboarding.skip"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAppLaunchesIntoTabShellAfterOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()
        app.buttons["onboarding.skip"].tap()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Timeline"].exists)
        XCTAssertTrue(app.tabBars.buttons["Charts"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
        XCTAssertTrue(app.staticTexts["No child yet"].waitForExistence(timeout: 5))
    }
}
