import Foundation

/// Reads Supabase project configuration injected into Info.plist from
/// `Config/Base.xcconfig` (tracked) plus an optional, gitignored
/// `Config/Secrets.xcconfig` (see `Secrets.xcconfig.example`). A fresh
/// clone with no `Secrets.xcconfig` has empty values here, which is by
/// design — the whole app must build, launch, and work fully offline in
/// guest mode with Supabase disabled.
enum SupabaseConfig {
    static var url: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              !raw.isEmpty,
              let url = URL(string: raw) else { return nil }
        return url
    }

    static var anonKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
              !key.isEmpty else { return nil }
        return key
    }

    /// Whether the app has enough configuration to attempt any Supabase
    /// network operation at all. When `false`, sync and auth features must
    /// no-op rather than crash or block local functionality.
    static var isConfigured: Bool {
        url != nil && anonKey != nil
    }
}
