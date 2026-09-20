import SwiftUI

struct ChartsScreen: View {
    var body: some View {
        PlaceholderScreen(
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
