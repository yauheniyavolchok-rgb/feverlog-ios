import Observation
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case timeline
    case charts
    case settings

    var id: String { rawValue }
}

@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var timelinePath = NavigationPath()
    var chartsPath = NavigationPath()
    var settingsPath = NavigationPath()
}
