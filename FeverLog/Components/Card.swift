import SwiftUI

struct Card<Content: View>: View {
    @Environment(\.feverPalette) private var palette

    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.md)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadiusToken.md, style: .continuous))
            .feverShadow(.card)
    }
}

#Preview {
    Card {
        Text("Card content")
    }
    .padding()
    .feverThemed()
}
