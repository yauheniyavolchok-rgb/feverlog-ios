import XCTest

final class OnboardingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()
        return app
    }

    @MainActor
    func testSkipCompletesOnboardingAndEntersGuestModeHome() throws {
        let app = launchFreshApp()

        let skipButton = app.buttons["onboarding.skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))
        skipButton.tap()

        // Guest mode: lands directly on the tab shell, no sign-in, no network.
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No child yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testGetStartedCompletesOnboardingAfterPagingThroughAllPages() throws {
        let app = launchFreshApp()

        let nextButton = app.buttons["onboarding.next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        nextButton.tap()
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        nextButton.tap()

        let getStartedButton = app.buttons["onboarding.getStarted"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5))
        getStartedButton.tap()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOnboardingCompletionPersistsAcrossRelaunch() throws {
        let app = launchFreshApp()

        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = []
        app.launch()

        // No --uitest-reset-state this time: onboarding should already be complete.
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboarding.skip"].exists)
    }
}
