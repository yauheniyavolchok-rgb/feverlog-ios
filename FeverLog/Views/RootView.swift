import SwiftData
import SwiftUI

struct RootView: View {
    @State private var themeManager = ThemeManager()
    @State private var onboardingStore = OnboardingStateStore()
    @State private var childStore = ChildStore()
    @State private var showingSplash = true
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Minimum time the logo-only splash stays up, so it reads as an
    /// intentional brand moment rather than a flash — independent of how
    /// fast the (synchronous, local) initial data load actually finishes.
    private static let minimumSplashDuration: UInt64 = 500_000_000

    var body: some View {
        Group {
            if showingSplash {
                SplashScreen()
            } else if onboardingStore.isCompleted {
                MainTabView()
            } else {
                OnboardingContainerView(onFinish: { onboardingStore.complete() })
            }
        }
        .environment(themeManager)
        .environment(childStore)
        .environment(\.feverPalette, themeManager.palette(for: systemColorScheme))
        .preferredColorScheme(themeManager.appearanceMode.preferredColorScheme)
        .task {
            childStore.configure(context: modelContext)
            try? childStore.loadInitialStateIfNeeded()
            try? await Task.sleep(nanoseconds: Self.minimumSplashDuration)
            if reduceMotion {
                showingSplash = false
            } else {
                withAnimation {
                    showingSplash = false
                }
            }
        }
    }
}

#Preview {
    RootView()
}
