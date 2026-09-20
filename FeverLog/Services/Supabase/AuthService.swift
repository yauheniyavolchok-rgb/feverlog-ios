import Foundation
import Observation
import Supabase

enum AuthServiceError: Error, Sendable, Equatable {
    case notConfigured
}

/// Owns the current Supabase auth session. The app never shows a login
/// screen up front — `bootstrapSessionIfNeeded()` silently establishes an
/// anonymous session on first launch (best-effort; offline failures are
/// swallowed and retried later by the sync coordinator, never surfaced to
/// the user or allowed to block local functionality). Linking a permanent
/// identity (Apple/Google/Email) preserves `auth.uid()` — the user, their
/// household, and their children never change identity.
@Observable
@MainActor
final class AuthService {
    private(set) var currentUserID: UUID?
    private(set) var isAnonymous = true
    private(set) var isBootstrapped = false

    private let client: SupabaseAuthClient?

    init(client: SupabaseAuthClient?) {
        self.client = client
        if let user = client?.currentUser {
            currentUserID = user.id
            isAnonymous = user.isAnonymous
            isBootstrapped = true
        }
    }

    var isConfigured: Bool { client != nil }

    /// No-op when Supabase isn't configured (guest-only build/CI) or when a
    /// session already exists. Never throws — see type-level doc comment.
    func bootstrapSessionIfNeeded() async {
        guard let client, client.currentUser == nil else { return }
        do {
            let session = try await client.signInAnonymously()
            apply(session.user)
            isBootstrapped = true
        } catch {
            // Offline or transient failure. Local functionality is
            // unaffected; the next app-open or sync retry tries again.
        }
    }

    func linkApple(idToken: String, nonce: String) async throws {
        guard let client else { throw AuthServiceError.notConfigured }
        let credentials = OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
        let session = try await client.linkIdentityWithIdToken(credentials: credentials)
        apply(session.user)
    }

    /// Opens the system browser for Google's OAuth consent screen. The
    /// caller completes the flow by passing the resulting redirect URL to
    /// `handleAuthCallback(url:)` from `.onOpenURL`.
    func beginGoogleLink(redirectTo: URL) async throws {
        guard let client else { throw AuthServiceError.notConfigured }
        try await client.linkIdentity(provider: .google, redirectTo: redirectTo)
    }

    @discardableResult
    func handleAuthCallback(url: URL) async throws -> Bool {
        guard let client else { throw AuthServiceError.notConfigured }
        let session = try await client.session(from: url)
        apply(session.user)
        return true
    }

    /// Sends a one-time code to `email` for linking it to the current
    /// (typically anonymous) user. Does not create a new user or session.
    func requestEmailLinkCode(email: String) async throws {
        guard let client else { throw AuthServiceError.notConfigured }
        _ = try await client.update(user: UserAttributes(email: email))
    }

    func confirmEmailLinkCode(email: String, code: String) async throws {
        guard let client else { throw AuthServiceError.notConfigured }
        let response = try await client.verifyOTP(email: email, token: code, type: .emailChange)
        if case .session(let session) = response {
            apply(session.user)
        }
    }

    /// Ends the remote session only. Local SwiftData records are never
    /// touched — they remain fully visible and editable offline. The next
    /// bootstrap establishes a fresh anonymous session.
    func signOut() async throws {
        guard let client else { return }
        try await client.signOut()
        currentUserID = nil
        isAnonymous = true
        isBootstrapped = false
    }

    private func apply(_ user: User) {
        currentUserID = user.id
        isAnonymous = user.isAnonymous
    }
}
