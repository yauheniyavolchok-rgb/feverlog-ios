import SwiftUI

struct Chip: View {
    @Environment(\.feverPalette) private var palette

    let title: String
    var systemImage: String?
    var isSelected: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: Spacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(Typography.caption.weight(.medium))
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: Spacing.xxl)
            .background(isSelected ? palette.accentMint.opacity(0.28) : palette.secondarySurface)
            .foregroundStyle(palette.primaryText)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

#Preview {
    HStack {
        Chip(title: "Fever", systemImage: "thermometer", isSelected: true)
        Chip(title: "Cough", systemImage: "wind")
    }
    .padding()
    .feverThemed()
}
