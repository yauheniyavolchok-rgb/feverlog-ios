import XCTest

extension XCUIApplication {
    @discardableResult
    func launchFreshPastOnboarding(extraArguments: [String] = []) -> XCUIApplication {
        launchArguments = ["--uitest-reset-state"] + extraArguments
        launch()
        buttons["onboarding.skip"].tap()
        return self
    }

    /// The Settings list has grown long enough that later rows aren't laid
    /// out (and so aren't found by identifier at all — not just unhittable)
    /// until scrolled into view. Swipes up until the target becomes
    /// hittable, then taps it.
    func scrollToAndTap(_ identifier: String, maxSwipes: Int = 10) {
        let target = buttons[identifier]
        var remaining = maxSwipes
        while !target.isHittable, remaining > 0 {
            swipeUp()
            remaining -= 1
        }
        target.tap()
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

    /// An alternative to `clearAndTypeText` for fields holding real
    /// existing text (names, in practice) rather than a short numeric
    /// value — the long-press-then-"Select All" callout `clearAndTypeText`
    /// relies on has shown up as flaky specifically for this case
    /// (confirmed via re-running in isolation, where it passes — a timing
    /// race with the callout appearing, not a deterministic bug). Deleting
    /// backward by the field's current length is unconditional and doesn't
    /// depend on a system UI callout appearing in time. Assumes the field
    /// was just tapped, so the cursor is wherever that leaves it, and
    /// backspaces from there.
    func replaceText(with text: String) {
        if let existing = value as? String, !existing.isEmpty {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        typeText(text)
    }
}
