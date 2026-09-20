import SwiftUI

struct OnboardingContainerView: View {
    @Environment(\.feverPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onFinish: () -> Void

    @State private var pageIndex = 0
    private let pages = OnboardingPages.all

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingPageView(content: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            HStack {
                Button(L10n.Onboarding.skip, action: onFinish)
                    .frame(minHeight: Spacing.xxl)
                    .accessibilityIdentifier("onboarding.skip")

                Spacer()

                PrimaryButton(
                    title: isLastPage ? L10n.Onboarding.getStarted : L10n.Onboarding.next,
                    action: advance
                )
                .fixedSize()
                .accessibilityIdentifier(isLastPage ? "onboarding.getStarted" : "onboarding.next")
            }
            .padding(Spacing.lg)
        }
        .background(palette.background)
    }

    private var isLastPage: Bool {
        pageIndex == pages.count - 1
    }

    private func advance() {
        guard !isLastPage else {
            onFinish()
            return
        }
        if reduceMotion {
            pageIndex += 1
        } else {
            withAnimation {
                pageIndex += 1
            }
        }
    }
}

#Preview {
    OnboardingContainerView(onFinish: {})
        .feverThemed()
}
