import Foundation

/// Every language the app has localization *structure* for. `.system`
/// follows the device language when supported, falling back to English.
/// Per the spec, language selection is device-local in v1 and independent
/// of the household — never synchronized.
///
/// TODO(Phase 10, translation review): Only `.english` has been reviewed.
/// The rest are machine-drafted and marked `needs_review` in
/// Localizable.xcstrings. Every other locale needs native-language review
/// before it can be presented to users as a supported language.
/// Completion: review status documented per locale; reviewed locales have
/// zero `needs_review` entries among release-visible keys.
/// Release blocker: yes for any locale other than English.
enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case system
    case english = "en"
    case ukrainian = "uk"
    case russian = "ru"
    case dutch = "nl"
    case spanish = "es"
    case german = "de"
    case polish = "pl"

    /// The `Locale` `String(localized:locale:)` should resolve strings
    /// against. `.system` resolves to the device's current locale so
    /// `String(localized:)`'s normal fallback-to-English behavior applies
    /// exactly as it would with no override at all.
    var resolvedLocale: Locale {
        switch self {
        case .system: Locale.current
        default: Locale(identifier: rawValue)
        }
    }

    var localizedLabel: String {
        switch self {
        case .system: L10n.LanguageSettings.system
        case .english: "English"
        case .ukrainian: "Українська"
        case .russian: "Русский"
        case .dutch: "Nederlands"
        case .spanish: "Español"
        case .german: "Deutsch"
        case .polish: "Polski"
        }
    }
}
