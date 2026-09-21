import SwiftUI
import UIKit

extension View {
    /// Posts a VoiceOver announcement whenever `message` transitions to a
    /// non-`nil` value. Validation errors in this app are surfaced as plain
    /// `Text`, which VoiceOver only reads if the user happens to navigate to
    /// it — this makes the error audible the moment it appears, the same
    /// way it's immediately visible sighted.
    func announcesAccessibilityErrors(_ message: String?) -> some View {
        onChange(of: message) { _, newValue in
            guard let newValue else { return }
            UIAccessibility.post(notification: .announcement, argument: newValue)
        }
    }
}
