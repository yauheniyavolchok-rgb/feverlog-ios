import XCTest

final class QuickLogUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // `.firstMatch` rather than a single-element lookup: confirmationDialog
    // action buttons momentarily appear twice in the accessibility snapshot
    // while the dialog's presentation animation is still settling (confirmed
    // via UI-hierarchy inspection — both copies share the same identifier,
    // label, and on-screen frame, so either is a valid tap target).
    private func logQuickEntry(in app: XCUIApplication, type: String, degree: Int) {
        app.buttons["home.quickAdd"].tap()
        let typeButton = app.buttons["quickAdd.\(type)"]
        XCTAssertTrue(typeButton.waitForExistence(timeout: 5))
        typeButton.tap()
        let degreeButton = app.buttons.matching(identifier: "quickLog.\(type).degree\(degree)").firstMatch
        XCTAssertTrue(degreeButton.waitForExistence(timeout: 5))
        degreeButton.tap()

        // The degree tap dismisses the whole Quick Add sheet (confirmation
        // dialog dismissal + sheet dismissal chained). Tapping again
        // immediately races that animation, so wait for Home's Quick Add
        // button to reappear before the caller does anything else.
        XCTAssertTrue(app.buttons["home.quickAdd"].waitForExistence(timeout: 5))
    }

    /// `swipeLeft()` synthesizes its drag distance from the *target
    /// element's own frame*. Quick log rows' type label ("Poop", "Drink")
    /// is only ~38pt wide — swiping on that narrow `staticText` directly
    /// (as the equivalent symptom/note tests do with their longer labels)
    /// doesn't cover enough horizontal distance to trigger the List's
    /// swipe-actions gesture recognizer, confirmed via UI-hierarchy
    /// inspection: 5 retries in, the cell's frame is still completely
    /// unchanged, not just delayed. Swiping the full-width containing cell
    /// instead gives the gesture real travel distance.
    private func swipeLeftRevealingAction(rowLabel: String, buttonLabel: String, in app: XCUIApplication) {
        let cell = app.cells.containing(.staticText, identifier: rowLabel).firstMatch
        let actionButton = app.buttons[buttonLabel]
        for _ in 0..<5 where !actionButton.exists {
            cell.swipeLeft()
            _ = actionButton.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(actionButton.exists, "\"\(buttonLabel)\" action never appeared after swiping")
    }

    @MainActor
    func testLoggingFoodAppearsOnTimelineWithChosenDegree() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        logQuickEntry(in: app, type: "food", degree: 2)

        app.tabBars.buttons["Timeline"].tap()
        XCTAssertTrue(app.staticTexts["Food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["· Small portion"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEveryQuickLogTypeCanBeLogged() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        let types = ["food", "drink", "pee", "poop", "vomit", "breath"]
        for type in types {
            logQuickEntry(in: app, type: type, degree: 1)
        }

        app.tabBars.buttons["Timeline"].tap()
        XCTAssertTrue(app.staticTexts["Food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Drink"].exists)
        XCTAssertTrue(app.staticTexts["Pee"].exists)
        XCTAssertTrue(app.staticTexts["Poop"].exists)
        XCTAssertTrue(app.staticTexts["Vomit"].exists)
        XCTAssertTrue(app.staticTexts["Breathing"].exists)
    }

    @MainActor
    func testQuickAddPopupCanBeCancelled() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        app.buttons["home.quickAdd"].tap()
        app.buttons["quickAdd.vomit"].tap()
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()

        // The Quick Add sheet itself should still be open (cancelling the
        // popup doesn't dismiss the whole sheet), and nothing was logged.
        XCTAssertTrue(app.buttons["quickAdd.vomit"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()

        app.tabBars.buttons["Timeline"].tap()
        XCTAssertTrue(app.staticTexts["No entries yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeleteQuickLogEntry() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        logQuickEntry(in: app, type: "poop", degree: 3)

        app.tabBars.buttons["Timeline"].tap()
        let row = app.staticTexts["Poop"]
        // Confirmed via UI-hierarchy inspection that the row does appear
        // correctly, just occasionally a couple seconds past a 5s wait —
        // Timeline's reload lagging the tab switch, not incorrect data.
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        swipeLeftRevealingAction(rowLabel: "Poop", buttonLabel: "Delete", in: app)
        app.buttons["Delete"].tap()

        XCTAssertTrue(app.staticTexts["No entries yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEditQuickLogEntryChangesDegree() throws {
        let app = XCUIApplication().launchFreshPastOnboarding()
        app.createChild(named: "Ava", fromEmptyState: true)

        logQuickEntry(in: app, type: "drink", degree: 1)

        app.tabBars.buttons["Timeline"].tap()
        let row = app.staticTexts["Drink"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        swipeLeftRevealingAction(rowLabel: "Drink", buttonLabel: "Edit", in: app)
        app.buttons["Edit"].tap()

        let degree3 = app.buttons["quickLogEdit.degree3"]
        XCTAssertTrue(degree3.waitForExistence(timeout: 5))
        degree3.tap()
        app.buttons["quickLogEdit.save"].tap()

        XCTAssertTrue(app.staticTexts["· Drinking well"].waitForExistence(timeout: 5))
    }
}
