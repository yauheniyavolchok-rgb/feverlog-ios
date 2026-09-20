import XCTest

final class TemperatureUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func recordTemperature(in app: XCUIApplication) {
        app.buttons["home.quickAdd"].tap()
        app.buttons["quickAdd.temperature"].tap()
        // Wheel picker defaults to a valid value (37.0°C); no adjustment needed to save.
        app.buttons["temperatureEntry.save"].tap()
    }

    @MainActor
    func testRecordTemperatureAppearsInTodayAndTimeline() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        recordTemperature(in: app)

        XCTAssertTrue(app.staticTexts["37.0°C"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Timeline"].tap()
        XCTAssertTrue(app.staticTexts["37.0°C"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Today"].exists)
    }

    @MainActor
    func testEditTemperatureEntry() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)
        recordTemperature(in: app)

        app.tabBars.buttons["Timeline"].tap()
        let row = app.staticTexts["37.0°C"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()

        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let picker = app.pickerWheels.element
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.adjust(toPickerWheelValue: "38.5°C")
        app.buttons["temperatureEntry.save"].tap()

        XCTAssertTrue(app.staticTexts["38.5°C"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDuplicateTemperatureEntry() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)
        recordTemperature(in: app)

        app.tabBars.buttons["Timeline"].tap()
        let row = app.staticTexts["37.0°C"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()

        let duplicateButton = app.buttons["Duplicate"]
        XCTAssertTrue(duplicateButton.waitForExistence(timeout: 5))
        duplicateButton.tap()

        let matches = app.staticTexts.matching(identifier: "37.0°C")
        XCTAssertTrue(matches.element(boundBy: 1).waitForExistence(timeout: 5))
        XCTAssertEqual(matches.count, 2)
    }

    @MainActor
    func testDeleteTemperatureEntry() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)
        recordTemperature(in: app)

        app.tabBars.buttons["Timeline"].tap()
        let row = app.staticTexts["37.0°C"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        XCTAssertTrue(app.staticTexts["No entries yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTimelineIsScopedPerChild() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)
        recordTemperature(in: app)

        app.createChild(named: "Leo", fromEmptyState: false)
        app.tabBars.buttons["Timeline"].tap()

        // Leo has no entries yet, even though Ava does.
        XCTAssertTrue(app.staticTexts["No entries yet"].waitForExistence(timeout: 5))
    }
}
