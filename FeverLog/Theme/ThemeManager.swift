import Observation
import SwiftUI

/// Owns the device-local appearance selection and resolves it to a concrete
/// `ColorPalette`. Appearance is device-local in v1 and is never
/// household-synchronized.
@Observable
final class ThemeManager {
    private static let appearanceModeKey = "theme.appearanceMode"

    private let settingsStore: AppSettingsStore

    var appearanceMode: AppearanceMode {
        didSet {
            guard appearanceMode != oldValue else { return }
            settingsStore.setString(appearanceMode.rawValue, forKey: Self.appearanceModeKey)
        }
    }

    init(settingsStore: AppSettingsStore = UserDefaultsSettingsStore()) {
        self.settingsStore = settingsStore
        if let raw = settingsStore.string(forKey: Self.appearanceModeKey),
           let mode = AppearanceMode(rawValue: raw) {
            appearanceMode = mode
        } else {
            appearanceMode = .system
        }
    }

    func palette(for systemColorScheme: ColorScheme) -> ColorPalette {
        switch appearanceMode {
        case .system:
            return systemColorScheme == .dark ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        case .calmNight:
            return .calmNight
        }
    }
}
