import Foundation

/// The locale every `L10n` string lookup resolves against. Read from
/// dozens of non-isolated `static var` computed properties throughout
/// `L10n.swift`/`L10n+Sync.swift`, which is why this isn't routed through
/// SwiftUI's environment or an `@Observable` type — those call sites
/// aren't views. `nonisolated(unsafe)` is safe here in practice: writes
/// only happen from `LanguageManager` on the main actor in response to an
/// explicit user action in Settings, and a language change already forces
/// a full view-tree rebuild (see `RootView`'s `.id(...)`), so there is no
/// meaningful concurrent-read-during-write window in the app's real usage.
enum L10nLocale {
    nonisolated(unsafe) static var current: Locale = .current

    /// `String(localized:locale:)`'s explicit-locale override is unreliable
    /// for this app's use case: Foundation appears to memoize the resolved
    /// bundle/string lookup the first time a key is read, so later calls
    /// with a *different* explicit `locale:` for the same key can keep
    /// returning the original language (confirmed via device-log tracing —
    /// the `locale:` argument received was correct, but the returned string
    /// wasn't). Reading directly from the specific `.lproj` bundle Xcode
    /// compiles `Localizable.xcstrings` into sidesteps that cache entirely.
    /// Falls back to `Bundle.main` for `.system` (no explicit override, so
    /// the OS's normal preferred-language resolution applies) and whenever
    /// the requested language has no matching bundle.
    static var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: current.identifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
