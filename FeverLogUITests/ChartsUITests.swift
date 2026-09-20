import XCTest

final class ChartsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testEmptyStateBeforeAnyLogging() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.tabBars.buttons["Charts"].tap()

        XCTAssertTrue(app.staticTexts["No temperature readings in this range."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No medications logged in this range."].exists)
        XCTAssertTrue(app.staticTexts["No symptoms logged in this range."].exists)
    }

    @MainActor
    func testSwitchChartRanges() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.tabBars.buttons["Charts"].tap()
        let rangePicker = app.segmentedControls["charts.rangeMode"]
        XCTAssertTrue(rangePicker.waitForExistence(timeout: 5))

        for label in ["3d", "7d", "14d", "24h"] {
            let button = rangePicker.buttons[label]
            XCTAssertTrue(button.exists, "missing range option \(label)")
            button.tap()
        }
    }

    @MainActor
    func testTemperatureChartShowsDataAfterLogging() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.buttons["home.quickAdd"].tap()
        app.buttons["quickAdd.temperature"].tap()
        app.buttons["temperatureEntry.save"].tap()

        app.tabBars.buttons["Charts"].tap()

        XCTAssertTrue(app.staticTexts["Temperature"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["No temperature readings in this range."].exists)
    }

    @MainActor
    func testChartsRenderInLandscape() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.tabBars.buttons["Charts"].tap()
        let rangePicker = app.segmentedControls["charts.rangeMode"]
        XCTAssertTrue(rangePicker.waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(rangePicker.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Temperature"].waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .portrait
    }
}
