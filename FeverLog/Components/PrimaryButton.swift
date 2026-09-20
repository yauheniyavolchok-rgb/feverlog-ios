import SwiftUI

struct PrimaryButton: View {
    @Environment(\.feverPalette) private var palette

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Spacing.xxl)
        }
        .buttonStyle(.borderedProminent)
        .tint(palette.accentBlue)
    }
}

#Preview {
    PrimaryButton(title: "Save", action: {})
        .padding()
        .feverThemed()
}
