import XCTest

extension XCUIApplication {
    @discardableResult
    func launchFreshPastOnboarding() -> XCUIApplication {
        launchArguments = ["--uitest-reset-state"]
        launch()
        buttons["onboarding.skip"].tap()
        return self
    }

    func createChild(named name: String, fromEmptyState: Bool) {
        if fromEmptyState {
            buttons["Add Child"].tap()
        } else {
            navigationBars.buttons["Add Child"].tap()
        }
        let nameField = textFields["childForm.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        buttons["childForm.save"].tap()
    }
}

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = value as? String else {
            typeText(text)
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
        typeText(text)
    }
}
