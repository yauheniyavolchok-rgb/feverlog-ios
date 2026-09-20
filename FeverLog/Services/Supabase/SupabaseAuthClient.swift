import Foundation
import Supabase

/// Thin wrapper over the exact `Auth.AuthClient` surface `AuthService`
/// needs, so unit tests can exercise the bootstrap/linking/sign-out
/// business logic against a fake instead of a real network client.
protocol SupabaseAuthClient: Sendable {
    var currentUser: User? { get }

    @discardableResult
    func signInAnonymously() async throws -> Session

    @discardableResult
    func linkIdentityWithIdToken(credentials: OpenIDConnectCredentials) async throws -> Session

    func linkIdentity(provider: Provider, redirectTo: URL?) async throws

    @discardableResult
    func session(from url: URL) async throws -> Session

    @discardableResult
    func update(user: UserAttributes) async throws -> User

    @discardableResult
    func verifyOTP(email: String, token: String, type: EmailOTPType) async throws -> AuthResponse

    func signOut() async throws
}

extension AuthClient: SupabaseAuthClient {
    @discardableResult
    func signInAnonymously() async throws -> Session {
        try await signInAnonymously(data: nil, captchaToken: nil)
    }

    func linkIdentity(provider: Provider, redirectTo: URL?) async throws {
        try await linkIdentity(provider: provider, scopes: nil, redirectTo: redirectTo)
    }

    @discardableResult
    func update(user: UserAttributes) async throws -> User {
        try await update(user: user, redirectTo: nil)
    }

    @discardableResult
    func verifyOTP(email: String, token: String, type: EmailOTPType) async throws -> AuthResponse {
        try await verifyOTP(email: email, token: token, type: type, redirectTo: nil, captchaToken: nil)
    }

    func signOut() async throws {
        try await signOut(scope: .global)
    }
}
