import Foundation
import Supabase
import Testing
@testable import FeverLog

private final class FakeSupabaseAuthClient: SupabaseAuthClient, @unchecked Sendable {
    var currentUser: User?
    var signInAnonymouslyError: Error?
    var linkIdentityWithIdTokenError: Error?
    private(set) var linkIdentityCalls: [(provider: Provider, redirectTo: URL?)] = []
    private(set) var signOutCallCount = 0
    var sessionFromURLResult: Session?

    private static func makeUser(id: UUID = UUID(), isAnonymous: Bool) -> User {
        User(
            id: id,
            appMetadata: [:],
            userMetadata: [:],
            aud: "authenticated",
            createdAt: .now,
            updatedAt: .now,
            isAnonymous: isAnonymous
        )
    }

    private static func makeSession(isAnonymous: Bool, userID: UUID = UUID()) -> Session {
        Session(
            accessToken: "token",
            tokenType: "bearer",
            expiresIn: 3600,
            expiresAt: Date.now.addingTimeInterval(3600).timeIntervalSince1970,
            refreshToken: "refresh",
            user: makeUser(id: userID, isAnonymous: isAnonymous)
        )
    }

    func signInAnonymously() async throws -> Session {
        if let signInAnonymouslyError { throw signInAnonymouslyError }
        let session = Self.makeSession(isAnonymous: true)
        currentUser = session.user
        return session
    }

    func linkIdentityWithIdToken(credentials: OpenIDConnectCredentials) async throws -> Session {
        if let linkIdentityWithIdTokenError { throw linkIdentityWithIdTokenError }
        let existingID = currentUser?.id ?? UUID()
        let session = Self.makeSession(isAnonymous: false, userID: existingID)
        currentUser = session.user
        return session
    }

    func linkIdentity(provider: Provider, redirectTo: URL?) async throws {
        linkIdentityCalls.append((provider, redirectTo))
    }

    func session(from url: URL) async throws -> Session {
        guard let sessionFromURLResult else { throw AuthServiceError.notConfigured }
        currentUser = sessionFromURLResult.user
        return sessionFromURLResult
    }

    func update(user: UserAttributes) async throws -> User {
        currentUser ?? Self.makeUser(isAnonymous: true)
    }

    func verifyOTP(email: String, token: String, type: EmailOTPType) async throws -> AuthResponse {
        let existingID = currentUser?.id ?? UUID()
        let session = Self.makeSession(isAnonymous: false, userID: existingID)
        currentUser = session.user
        return .session(session)
    }

    func signOut() async throws {
        signOutCallCount += 1
        currentUser = nil
    }
}

@MainActor
@Suite("AuthService")
struct AuthServiceTests {
    @Test("with no client configured, every operation reports notConfigured and never crashes")
    func notConfiguredIsSafe() async throws {
        let service = AuthService(client: nil)
        #expect(!service.isConfigured)

        await service.bootstrapSessionIfNeeded()
        #expect(service.currentUserID == nil)

        await #expect(throws: AuthServiceError.notConfigured) {
            try await service.linkApple(idToken: "x", nonce: "y")
        }
    }

    @Test("bootstrapSessionIfNeeded silently establishes an anonymous session")
    func bootstrapEstablishesAnonymousSession() async throws {
        let client = FakeSupabaseAuthClient()
        let service = AuthService(client: client)

        await service.bootstrapSessionIfNeeded()

        #expect(service.currentUserID != nil)
        #expect(service.isAnonymous)
    }

    @Test("bootstrapSessionIfNeeded never throws even when the network call fails")
    func bootstrapNeverThrowsOnFailure() async throws {
        struct NetworkError: Error {}
        let client = FakeSupabaseAuthClient()
        client.signInAnonymouslyError = NetworkError()
        let service = AuthService(client: client)

        await service.bootstrapSessionIfNeeded()

        #expect(service.currentUserID == nil)
        #expect(!service.isBootstrapped)
    }

    @Test("bootstrapSessionIfNeeded is a no-op once a session already exists")
    func bootstrapIsNoOpWithExistingSession() async throws {
        let client = FakeSupabaseAuthClient()
        try await client.signInAnonymously() // pre-establish a session directly on the fake
        let service = AuthService(client: client)

        await service.bootstrapSessionIfNeeded()

        #expect(service.currentUserID == client.currentUser?.id)
    }

    @Test("linking Apple preserves the same user id (auth.uid() never changes)")
    func linkingApplePreservesUserID() async throws {
        let client = FakeSupabaseAuthClient()
        let service = AuthService(client: client)
        await service.bootstrapSessionIfNeeded()
        let anonymousID = service.currentUserID

        try await service.linkApple(idToken: "token", nonce: "nonce")

        #expect(service.currentUserID == anonymousID)
        #expect(!service.isAnonymous)
    }

    @Test("confirming an email code preserves the same user id and clears isAnonymous")
    func confirmingEmailCodePreservesUserID() async throws {
        let client = FakeSupabaseAuthClient()
        let service = AuthService(client: client)
        await service.bootstrapSessionIfNeeded()
        let anonymousID = service.currentUserID

        try await service.requestEmailLinkCode(email: "a@example.com")
        try await service.confirmEmailLinkCode(email: "a@example.com", code: "123456")

        #expect(service.currentUserID == anonymousID)
        #expect(!service.isAnonymous)
    }

    @Test("signOut clears local auth state but never touches SwiftData")
    func signOutClearsState() async throws {
        let client = FakeSupabaseAuthClient()
        let service = AuthService(client: client)
        await service.bootstrapSessionIfNeeded()

        try await service.signOut()

        #expect(service.currentUserID == nil)
        #expect(service.isAnonymous)
        #expect(client.signOutCallCount == 1)
    }
}
