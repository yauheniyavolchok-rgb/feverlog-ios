import SwiftUI

enum AppearanceMode: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark
    case calmNight

    /// `nil` means "follow the system setting". Calm Night forces the dark
    /// UIKit/SwiftUI chrome (keyboard, alerts, share sheets) since it is a
    /// dim theme, even though its own token values differ from `.dark`.
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        case .calmNight: return .dark
        }
    }

    var localizedLabel: String {
        switch self {
        case .system: return L10n.Appearance.system
        case .light: return L10n.Appearance.light
        case .dark: return L10n.Appearance.dark
        case .calmNight: return L10n.Appearance.calmNight
        }
    }
}
