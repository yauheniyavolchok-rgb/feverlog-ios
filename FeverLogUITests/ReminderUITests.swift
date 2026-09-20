import XCTest

final class ReminderUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openReminders(in app: XCUIApplication) {
        app.tabBars.buttons["Settings"].tap()
        app.buttons["settings.reminders"].tap()
    }

    @MainActor
    func testScheduleReminder() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        handleNotificationPermissionPromptIfPresent()
        app.createChild(named: "Ava", fromEmptyState: true)

        openReminders(in: app)
        XCTAssertTrue(app.staticTexts["No reminders yet"].waitForExistence(timeout: 5))

        app.buttons["reminders.addButton"].tap()
        let saveButton = app.buttons["reminderForm.save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        app.tap() // wake any pending interruption monitor for the system permission alert

        XCTAssertTrue(app.staticTexts["Medication"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEditReminder() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        handleNotificationPermissionPromptIfPresent()
        app.createChild(named: "Ava", fromEmptyState: true)

        openReminders(in: app)
        app.buttons["reminders.addButton"].tap()
        app.buttons["reminderForm.save"].waitForExistence(timeout: 5)
        app.buttons["reminderForm.save"].tap()
        app.tap()

        let row = app.staticTexts["Medication"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let typePicker = app.segmentedControls["reminderForm.type"]
        XCTAssertTrue(typePicker.waitForExistence(timeout: 5))
        typePicker.buttons["Hydration"].tap()
        app.buttons["reminderForm.save"].tap()
        app.tap()

        XCTAssertTrue(app.staticTexts["Hydration"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Medication"].exists)
    }

    @MainActor
    func testCancelReminder() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        handleNotificationPermissionPromptIfPresent()
        app.createChild(named: "Ava", fromEmptyState: true)

        openReminders(in: app)
        app.buttons["reminders.addButton"].tap()
        app.buttons["reminderForm.save"].waitForExistence(timeout: 5)
        app.buttons["reminderForm.save"].tap()
        app.tap()

        let row = app.staticTexts["Medication"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        XCTAssertTrue(app.staticTexts["No reminders yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeniedNotificationPermissionShowsGracefulState() throws {
        let app = XCUIApplication().launchFreshPastOnboarding(extraArguments: ["--uitest-notifications-denied"])
        app.createChild(named: "Ava", fromEmptyState: true)

        openReminders(in: app)

        XCTAssertTrue(app.staticTexts["Notifications are off"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reminders.openSettings"].exists)
        XCTAssertFalse(app.buttons["reminders.addButton"].exists)
    }
}
