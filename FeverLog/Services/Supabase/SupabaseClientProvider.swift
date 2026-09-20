import Foundation
import Supabase

/// Lazily creates the shared `SupabaseClient`. `nil` whenever the app isn't
/// configured with a project URL/anon key (fresh clone, guest-only CI, or a
/// deliberately offline build) — every caller must treat that as "Supabase
/// disabled" and fall back to local-only behavior rather than crashing.
enum SupabaseClientProvider {
    static let shared: SupabaseClient? = {
        guard let url = SupabaseConfig.url, let anonKey = SupabaseConfig.anonKey else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }()
}
