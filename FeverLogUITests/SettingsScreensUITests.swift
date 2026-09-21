import XCTest

final class SettingsScreensUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAllSettingsRowsNavigate() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.tabBars.buttons["Settings"].tap()

        let rows = [
            "settings.household", "settings.children", "settings.medicationLibrary", "settings.units",
            "settings.language", "settings.reminders", "settings.account", "settings.syncStatus",
            "settings.about", "settings.privacy"
        ]
        for identifier in rows {
            app.scrollToAndTap(identifier)
            XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5), "\(identifier) did not push a screen")
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    @MainActor
    func testChildrenSettingsAddEditDelete() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Nora", fromEmptyState: true)

        app.tabBars.buttons["Settings"].tap()
        app.scrollToAndTap("settings.children")
        XCTAssertTrue(app.staticTexts["Nora"].waitForExistence(timeout: 5))

        app.staticTexts["Nora"].tap()
        let nameField = app.textFields["childForm.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.replaceText(with: "Nora Rose")
        app.buttons["childForm.save"].tap()
        XCTAssertTrue(app.staticTexts["Nora Rose"].waitForExistence(timeout: 5))

        app.staticTexts["Nora Rose"].swipeLeft()
        app.buttons["Delete Child"].tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["No children yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testUnitsSettingsSelectionPersistsAcrossRelaunch() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.tabBars.buttons["Settings"].tap()
        app.scrollToAndTap("settings.units")

        let poundsOption = app.buttons["unitsSettings.weightUnit.pounds"]
        XCTAssertTrue(poundsOption.waitForExistence(timeout: 5))
        poundsOption.tap()
        XCTAssertTrue(poundsOption.isSelected)

        app.terminate()
        app.launchArguments = []
        app.launch()

        app.tabBars.buttons["Settings"].tap()
        app.scrollToAndTap("settings.units")
        let poundsOptionAfterRelaunch = app.buttons["unitsSettings.weightUnit.pounds"]
        XCTAssertTrue(poundsOptionAfterRelaunch.waitForExistence(timeout: 5))
        XCTAssertTrue(poundsOptionAfterRelaunch.isSelected)
    }

    @MainActor
    func testHouseholdSettingsRenamePersists() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.tabBars.buttons["Settings"].tap()
        app.scrollToAndTap("settings.household")

        let nameField = app.textFields["householdSettings.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.replaceText(with: "The Smiths")
        app.buttons["householdSettings.save"].tap()

        app.navigationBars.buttons.firstMatch.tap()
        app.scrollToAndTap("settings.household")
        XCTAssertEqual(nameField.value as? String, "The Smiths")
    }

    @MainActor
    func testMedicationLibrarySearchAndDetail() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.tabBars.buttons["Settings"].tap()
        app.scrollToAndTap("settings.medicationLibrary")

        let searchField = app.textFields["medicationLibrarySettings.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Ibuprofen")

        let resultIdentifier = "medicationLibrarySettings.result.ibuprofen-generic-100-5-suspension-example"
        let firstResult = app.buttons.matching(identifier: resultIdentifier).firstMatch
        XCTAssertTrue(firstResult.waitForExistence(timeout: 5))
        firstResult.tap()
        XCTAssertTrue(app.navigationBars["Generic"].waitForExistence(timeout: 5))
    }
}
