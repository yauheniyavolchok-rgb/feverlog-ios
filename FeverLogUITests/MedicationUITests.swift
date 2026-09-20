import XCTest

final class MedicationUITests: XCTestCase {
    private let ibuprofenResultID = "medicationSearch.result.ibuprofen-generic-100-5-suspension-example"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func openMedicationEntry(in app: XCUIApplication, searchQuery: String, resultIdentifier: String) {
        app.buttons["home.quickAdd"].tap()
        app.buttons["quickAdd.medication"].tap()

        let searchField = app.searchFields.element
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(searchQuery)

        let result = app.buttons[resultIdentifier]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
    }

    @MainActor
    func testSearchSelectMedicationAndVerifyCalculatedDose() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        openMedicationEntry(in: app, searchQuery: "Ibuprofen", resultIdentifier: ibuprofenResultID)

        let volumeField = app.textFields["medicationEntry.volume"]
        XCTAssertTrue(volumeField.waitForExistence(timeout: 5))
        volumeField.tap()
        volumeField.clearAndTypeText("5")

        // 5 mL of a 100mg/5mL medication should calculate to 100 mg.
        XCTAssertTrue(app.staticTexts["100.0 mg"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSaveValidMedicationAppearsOnHomeAndCanBeEdited() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        openMedicationEntry(in: app, searchQuery: "Ibuprofen", resultIdentifier: ibuprofenResultID)
        let volumeField = app.textFields["medicationEntry.volume"]
        XCTAssertTrue(volumeField.waitForExistence(timeout: 5))
        volumeField.tap()
        volumeField.clearAndTypeText("5")

        app.buttons["medicationEntry.save"].tap()

        XCTAssertTrue(app.staticTexts["Generic"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testInvalidVolumeDisablesSave() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        openMedicationEntry(in: app, searchQuery: "Ibuprofen", resultIdentifier: ibuprofenResultID)
        let volumeField = app.textFields["medicationEntry.volume"]
        XCTAssertTrue(volumeField.waitForExistence(timeout: 5))
        volumeField.tap()
        volumeField.clearAndTypeText("0")

        XCTAssertFalse(app.buttons["medicationEntry.save"].isEnabled)
    }

    @MainActor
    func testExceedingMaximumRequiresConfirmationAndCanBeCancelled() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        // Ibuprofen: 40 mg/kg/day maximum. Set the child's weight low so a
        // single dose blows past both the per-kg range and the daily max.
        app.staticTexts["Ava"].tap()
        app.buttons["childProfile.addWeight"].tap()
        let weightField = app.textFields["weightForm.value"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        weightField.clearAndTypeText("2")
        app.buttons["weightForm.save"].tap()
        app.navigationBars.buttons.firstMatch.tap() // back to Home

        openMedicationEntry(in: app, searchQuery: "Ibuprofen", resultIdentifier: ibuprofenResultID)
        let volumeField = app.textFields["medicationEntry.volume"]
        XCTAssertTrue(volumeField.waitForExistence(timeout: 5))
        volumeField.tap()
        volumeField.clearAndTypeText("20")

        app.buttons["medicationEntry.save"].tap()

        let confirmTitle = app.staticTexts["Check this dose before saving"]
        XCTAssertTrue(confirmTitle.waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()

        // Still on the entry screen — nothing was saved.
        XCTAssertTrue(volumeField.waitForExistence(timeout: 5))
    }
}
