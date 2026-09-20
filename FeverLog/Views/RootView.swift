import SwiftData
import SwiftUI

struct RootView: View {
    @State private var themeManager = ThemeManager()
    @State private var languageManager = LanguageManager()
    @State private var onboardingStore = OnboardingStateStore()
    /// Owned here, outside the `.id(languageManager.language)` boundary below,
    /// so a language change — which force-remounts `MainTabView` to refresh
    /// every static `L10n` string — doesn't also reset tab selection or pop
    /// navigation. `NavigationStack` replays its destinations from `path`,
    /// so preserving this instance across the remount keeps the user where
    /// they were, just re-rendered in the new language.
    @State private var router = AppRouter()
    @State private var childStore = ChildStore()
    @State private var authService = AuthService(client: SupabaseClientProvider.shared?.auth)
    @State private var showingSplash = true
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

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
        .id(languageManager.language)
        .environment(themeManager)
        .environment(languageManager)
        .environment(childStore)
        .environment(authService)
        .environment(router)
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
        .task {
            // Best-effort, never blocks the splash or local functionality —
            // see SyncCoordinator/AuthService doc comments.
            await SyncCoordinator(authService: authService, context: modelContext).runCycle()
        }
        .onOpenURL { url in
            Task { try? await authService.handleAuthCallback(url: url) }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await SyncCoordinator(authService: authService, context: modelContext).runCycle() }
        }
    }
}

#Preview {
    RootView()
}
