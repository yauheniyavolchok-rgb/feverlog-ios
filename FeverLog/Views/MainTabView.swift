import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                HomeScreen()
            }
            .tabItem { Label(L10n.Nav.home, systemImage: Icon.home) }
            .tag(AppTab.home)

            NavigationStack(path: $router.timelinePath) {
                TimelineScreen()
            }
            .tabItem { Label(L10n.Nav.timeline, systemImage: Icon.timeline) }
            .tag(AppTab.timeline)

            NavigationStack(path: $router.chartsPath) {
                ChartsScreen()
            }
            .tabItem { Label(L10n.Nav.charts, systemImage: Icon.charts) }
            .tag(AppTab.charts)

            NavigationStack(path: $router.settingsPath) {
                SettingsScreen()
            }
            .tabItem { Label(L10n.Nav.settings, systemImage: Icon.settings) }
            .tag(AppTab.settings)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewContainer.shared)
        .environment(ThemeManager(settingsStore: InMemorySettingsStore()))
        .environment(ChildStore())
        .environment(AppRouter())
        .feverThemed()
}
