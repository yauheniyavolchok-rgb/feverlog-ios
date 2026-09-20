import XCTest

/// This build has no Supabase configuration (no `Config/Secrets.xcconfig`),
/// so `AuthService.isConfigured` is always `false` here. These tests verify
/// the app still surfaces the right, honest UI state in that case — guest
/// mode with Supabase disabled must never look broken or block anything.
final class AccountUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAccountScreenShowsNotBackedUpStateWhenUnconfigured() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()

        app.tabBars.buttons["Settings"].tap()
        app.buttons["settings.account"].tap()

        XCTAssertTrue(app.staticTexts["Not backed up"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["account.continueWithApple"].exists)
        XCTAssertTrue(app.buttons["account.continueWithGoogle"].exists)
        XCTAssertTrue(app.buttons["account.continueWithEmail"].exists)
        XCTAssertTrue(app.buttons["account.signOut"].exists)
    }

    @MainActor
    func testEmailLinkSheetOpensAndCancels() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()

        app.tabBars.buttons["Settings"].tap()
        app.buttons["settings.account"].tap()
        app.buttons["account.continueWithEmail"].tap()

        let emailField = app.textFields["emailLink.email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["emailLink.send"].exists)

        app.buttons["Cancel"].tap()
        XCTAssertFalse(emailField.exists)
    }

    @MainActor
    func testSyncStatusScreenShowsNotConfiguredMessage() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()

        app.tabBars.buttons["Settings"].tap()
        app.buttons["settings.syncStatus"].tap()

        let notConfiguredMessage = "Cloud sync isn't configured for this build. Your data stays fully available on this device."
        XCTAssertTrue(app.staticTexts[notConfiguredMessage].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Everything is synced."].exists)

        let syncNowButton = app.buttons["syncStatus.syncNow"]
        XCTAssertTrue(syncNowButton.exists)
        XCTAssertFalse(syncNowButton.isEnabled)
    }
}
