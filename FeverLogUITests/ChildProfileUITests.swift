import XCTest

final class ChildProfileUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreateChild() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        XCTAssertTrue(app.staticTexts["Ava"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEditChild() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.staticTexts["Ava"].tap()
        XCTAssertTrue(app.buttons["childProfile.edit"].waitForExistence(timeout: 5))
        app.buttons["childProfile.edit"].tap()

        let nameField = app.textFields["childForm.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.clearAndTypeText("Ava Marie")
        app.buttons["childForm.save"].tap()

        XCTAssertTrue(app.navigationBars["Ava Marie"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddWeightHistory() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.staticTexts["Ava"].tap()
        XCTAssertTrue(app.buttons["childProfile.addWeight"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Not recorded yet"].exists)

        app.buttons["childProfile.addWeight"].tap()
        let valueField = app.textFields["weightForm.value"]
        XCTAssertTrue(valueField.waitForExistence(timeout: 5))
        valueField.tap()
        valueField.clearAndTypeText("10.5")
        app.buttons["weightForm.save"].tap()

        XCTAssertTrue(app.staticTexts["Not recorded yet"].waitForExistence(timeout: 5) == false)
    }

    @MainActor
    func testSwitchBetweenTwoChildren() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)
        app.createChild(named: "Leo", fromEmptyState: false)

        let selector = app.navigationBars.buttons["home.childSelector"]
        XCTAssertTrue(selector.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Leo"].waitForExistence(timeout: 5))

        selector.tap()
        app.buttons["Ava"].tap()
        XCTAssertTrue(app.staticTexts["Ava"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSoftDeleteChildExcludesItFromSelector() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.staticTexts["Ava"].tap()
        XCTAssertTrue(app.buttons["childProfile.delete"].waitForExistence(timeout: 5))
        app.buttons["childProfile.delete"].tap()

        let confirmButton = app.buttons["Delete"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        // Back on Home with no active children — the empty state returns.
        XCTAssertTrue(app.staticTexts["No child yet"].waitForExistence(timeout: 5))
    }
}
