import XCTest

extension XCUIApplication {
    @discardableResult
    func launchFreshPastOnboarding(extraArguments: [String] = []) -> XCUIApplication {
        launchArguments = ["--uitest-reset-state"] + extraArguments
        launch()
        buttons["onboarding.skip"].tap()
        return self
    }

    func createChild(named name: String, fromEmptyState: Bool) {
        if fromEmptyState {
            buttons["Add Child"].tap()
        } else {
            navigationBars.buttons["home.childSelector"].tap()
            buttons["Add Child"].tap()
        }
        let nameField = textFields["childForm.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        buttons["childForm.save"].tap()
    }
}

extension XCTestCase {
    /// The simulator has no scripted way to pre-grant local-notification
    /// permission, so scheduling a reminder for the first time in a fresh
    /// app install can surface the real system prompt. This registers an
    /// interruption monitor to dismiss it if it appears; it's a no-op once
    /// the app already has a permission decision.
    @discardableResult
    func handleNotificationPermissionPromptIfPresent() -> NSObjectProtocol {
        addUIInterruptionMonitor(withDescription: "Notification permission") { alert in
            let allowButton = alert.buttons["Allow"]
            guard allowButton.exists else { return false }
            allowButton.tap()
            return true
        }
    }
}

extension XCUIElement {
    /// Clears a text field before typing. Tapping a SwiftUI `TextField`
    /// reliably leaves the cursor at the *start* of its existing text
    /// rather than the end (confirmed via diagnostics), which makes a
    /// delete-key-based clear a no-op — nothing precedes the cursor, so new
    /// digits get prepended instead of replacing the old value. A hardware-
    /// keyboard-style Select All (⌘A) selects the field's full contents
    /// regardless of cursor position, so the following `typeText` reliably
    /// replaces it.
    func clearAndTypeText(_ text: String) {
        let selectAll = XCUIApplication().menuItems["Select All"]
        press(forDuration: 1.2)
        if selectAll.waitForExistence(timeout: 2) {
            selectAll.tap()
        }
        typeText(text)
    }
}
