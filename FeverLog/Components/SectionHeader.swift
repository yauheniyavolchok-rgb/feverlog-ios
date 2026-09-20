import SwiftUI

struct SectionHeader: View {
    @Environment(\.feverPalette) private var palette

    let title: String

    var body: some View {
        Text(title)
            .font(Typography.sectionTitle)
            .foregroundStyle(palette.primaryText)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SectionHeader(title: "Today")
        .padding()
        .feverThemed()
}
