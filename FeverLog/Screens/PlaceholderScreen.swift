import SwiftUI

// TODO(Phase 1, placeholder screens): Replace placeholder screen content as feature phases are implemented.
// Completion: each placeholder screen is replaced by its completed feature screen or an explicit non-placeholder empty state.
// Release blocker: yes for any user-facing placeholder remaining in the release.
struct PlaceholderScreen: View {
    @Environment(\.feverPalette) private var palette

    let navigationTitle: String
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        EmptyStateView(systemImage: systemImage, title: title, message: message)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.background)
            .navigationTitle(navigationTitle)
    }
}
