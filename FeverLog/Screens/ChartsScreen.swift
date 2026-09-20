import SwiftUI

struct ChartsScreen: View {
    var body: some View {
        PlaceholderScreen(
            navigationTitle: L10n.Nav.charts,
            systemImage: Icon.charts,
            title: L10n.Screens.chartsTitle,
            message: L10n.Screens.chartsPlaceholderMessage
        )
    }
}

#Preview {
    NavigationStack { ChartsScreen() }
        .feverThemed()
}
