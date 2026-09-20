import Observation
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case timeline
    case charts
    case settings

    var id: String { rawValue }
}

/// `NavigationPath` only records pushes made via `NavigationLink(value:)` +
/// `.navigationDestination(for:)`. The Settings screens that need their
/// push preserved across a language-change remount (see `RootView`'s
/// `.id(languageManager.language)`) use this value-based routing instead of
/// a plain destination-closure `NavigationLink`.
enum SettingsRoute: Hashable, Sendable {
    case language
}

@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var timelinePath = NavigationPath()
    var chartsPath = NavigationPath()
    var settingsPath = NavigationPath()
}
