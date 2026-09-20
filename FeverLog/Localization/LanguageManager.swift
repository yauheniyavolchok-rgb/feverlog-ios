import Observation
import SwiftUI

/// Owns the device-local language selection, independent of the system
/// language and never household-synchronized (same v1 scope as
/// `ThemeManager`'s appearance mode).
@Observable
@MainActor
final class LanguageManager {
    private static let languageKey = "localization.appLanguage"

    private let settingsStore: AppSettingsStore

    var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            settingsStore.setString(language.rawValue, forKey: Self.languageKey)
            L10nLocale.current = language.resolvedLocale
        }
    }

    init(settingsStore: AppSettingsStore = UserDefaultsSettingsStore()) {
        self.settingsStore = settingsStore
        let resolved: AppLanguage
        if let raw = settingsStore.string(forKey: Self.languageKey), let saved = AppLanguage(rawValue: raw) {
            resolved = saved
        } else {
            resolved = .system
        }
        language = resolved
        L10nLocale.current = resolved.resolvedLocale
    }
}
