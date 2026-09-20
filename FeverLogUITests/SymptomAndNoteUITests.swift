import XCTest

final class SymptomAndNoteUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func recordSymptom(in app: XCUIApplication, categories: [String] = ["breathing", "pain"]) {
        app.buttons["home.quickAdd"].tap()
        app.buttons["quickAdd.symptoms"].tap()
        let saveButton = app.buttons["symptomEntry.save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        for category in categories {
            let categoryButton = app.buttons["symptomEntry.category.\(category)"]
            XCTAssertTrue(categoryButton.waitForExistence(timeout: 5))
            categoryButton.tap()
        }
        saveButton.tap()
    }

    private func recordNote(in app: XCUIApplication, text: String = "Seemed more tired than usual today.") {
        app.buttons["home.quickAdd"].tap()
        app.buttons["quickAdd.note"].tap()
        let textView = app.textViews["noteEntry.text"]
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        textView.tap()
        textView.typeText(text)
        app.buttons["noteEntry.save"].tap()
    }

    @MainActor
    func testRecordSymptomAppearsOnHomeAndTimeline() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        recordSymptom(in: app)

        XCTAssertTrue(app.staticTexts["Breathing, Pain"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Timeline"].tap()
        XCTAssertTrue(app.staticTexts["Breathing, Pain"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSaveIsDisabledUntilACategoryIsSelected() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.buttons["home.quickAdd"].tap()
        app.buttons["quickAdd.symptoms"].tap()

        let saveButton = app.buttons["symptomEntry.save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertFalse(saveButton.isEnabled)

        app.buttons["symptomEntry.category.general"].tap()
        XCTAssertTrue(saveButton.isEnabled)
    }

    @MainActor
    func testEditSymptomEntry() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)
        recordSymptom(in: app, categories: ["general"])

        app.tabBars.buttons["Timeline"].tap()
        let row = app.staticTexts["General"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()

        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let sleepCategoryButton = app.buttons["symptomEntry.category.sleep"]
        XCTAssertTrue(sleepCategoryButton.waitForExistence(timeout: 5))
        sleepCategoryButton.tap()
        app.buttons["symptomEntry.save"].tap()

        XCTAssertTrue(app.staticTexts["Sleep, General"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDuplicateSymptomEntry() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)
        recordSymptom(in: app, categories: ["general"])

        app.tabBars.buttons["Timeline"].tap()
        let row = app.staticTexts["General"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()

        app.buttons["Duplicate"].tap()

        let matches = app.staticTexts.matching(identifier: "General")
        XCTAssertTrue(matches.element(boundBy: 1).waitForExistence(timeout: 5))
        XCTAssertEqual(matches.count, 2)
    }

    @MainActor
    func testDeleteSymptomEntry() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)
        recordSymptom(in: app, categories: ["general"])

        app.tabBars.buttons["Timeline"].tap()
        let row = app.staticTexts["General"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()

        app.buttons["Delete"].tap()

        XCTAssertTrue(app.staticTexts["No entries yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testRecordNoteAppearsInTimeline() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        recordNote(in: app, text: "Slept through the night.")

        app.tabBars.buttons["Timeline"].tap()
        XCTAssertTrue(app.staticTexts["Slept through the night."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSaveIsDisabledForBlankNote() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.buttons["home.quickAdd"].tap()
        app.buttons["quickAdd.note"].tap()

        let saveButton = app.buttons["noteEntry.save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertFalse(saveButton.isEnabled)
    }

    @MainActor
    func testDeleteNoteEntry() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)
        recordNote(in: app, text: "A note to delete.")

        app.tabBars.buttons["Timeline"].tap()
        let row = app.staticTexts["A note to delete."]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()

        app.buttons["Delete"].tap()

        XCTAssertTrue(app.staticTexts["No entries yet"].waitForExistence(timeout: 5))
    }
}
