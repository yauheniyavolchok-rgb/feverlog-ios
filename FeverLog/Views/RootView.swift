import SwiftData
import SwiftUI

struct RootView: View {
    @State private var themeManager = ThemeManager()
    @State private var onboardingStore = OnboardingStateStore()
    @State private var childStore = ChildStore()
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if onboardingStore.isCompleted {
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
        }
    }
}

#Preview {
    RootView()
}
