import SwiftUI

struct SecondaryButton: View {
    @Environment(\.feverPalette) private var palette

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.body.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: Spacing.xxl)
        }
        .buttonStyle(.bordered)
        .tint(palette.accentBlue)
    }
}

#Preview {
    SecondaryButton(title: "Cancel", action: {})
        .padding()
        .feverThemed()
}
