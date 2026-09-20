import SwiftUI

// TODO(Phase 1, illustration assets): Add final illustration assets after the functional flows are stable.
// Completion: production assets replace development placeholders and pass accessibility review.
// Release blocker: no if the final release intentionally uses the placeholder-free text-only design.
struct EmptyStateView: View {
    @Environment(\.feverPalette) private var palette

    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(palette.secondaryText)
                .accessibilityHidden(true)
            Text(title)
                .font(Typography.sectionTitle)
                .foregroundStyle(palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "thermometer",
        title: "No entries yet",
        message: "Add a temperature reading to get started."
    )
    .feverThemed()
}
