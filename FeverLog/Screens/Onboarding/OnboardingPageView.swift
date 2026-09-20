import SwiftUI

// TODO(Phase 3, onboarding illustrations): Replace illustration placeholders with final production assets.
// Completion: production assets replace placeholders and pass accessibility review.
// Release blocker: no if the final design intentionally uses accessible text-only onboarding.
struct OnboardingPageView: View {
    @Environment(\.feverPalette) private var palette

    let content: OnboardingPageContent

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: content.systemImage)
                .font(.system(size: 64))
                .foregroundStyle(palette.accentBlue)
                .accessibilityHidden(true)
            Text(content.title)
                .font(Typography.screenTitle)
                .foregroundStyle(palette.primaryText)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(content.message)
                .font(Typography.body)
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingPageView(content: OnboardingPages.all[0])
        .feverThemed()
}
