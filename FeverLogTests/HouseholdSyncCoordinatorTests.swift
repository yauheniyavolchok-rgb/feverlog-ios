import Foundation
import Supabase
import SwiftData
import Testing
@testable import FeverLog

private final class FakeSupabaseHouseholdSyncClient: SupabaseHouseholdSyncClient, @unchecked Sendable {
    var createPersonalHouseholdError: Error?
    private(set) var createPersonalHouseholdCallCount = 0
    private(set) var lastRequestedID: UUID?
    var inviteCode = "ABC123"
    var joinedHouseholdID = UUID()

    func createPersonalHousehold(id: UUID) async throws -> UUID {
        createPersonalHouseholdCallCount += 1
        lastRequestedID = id
        if let createPersonalHouseholdError { throw createPersonalHouseholdError }
        return id
    }

    func createHouseholdInvite() async throws -> String { inviteCode }

    func redeemHouseholdInvite(code: String) async throws -> UUID { joinedHouseholdID }
}

private final class FakeSupabaseAuthClientForCoordinator: SupabaseAuthClient, @unchecked Sendable {
    var currentUser: User?

    func signInAnonymously() async throws -> Session {
        let user = User(
            id: UUID(), appMetadata: [:], userMetadata: [:], aud: "authenticated", createdAt: .now, updatedAt: .now, isAnonymous: true
        )
        currentUser = user
        return Session(
            accessToken: "t",
            tokenType: "bearer",
            expiresIn: 3600,
            expiresAt: Date.now.addingTimeInterval(3600).timeIntervalSince1970,
            refreshToken: "r",
            user: user
        )
    }

    func linkIdentityWithIdToken(credentials: OpenIDConnectCredentials) async throws -> Session { throw AuthServiceError.notConfigured }
    func linkIdentity(provider: Provider, redirectTo: URL?) async throws {}
    func session(from url: URL) async throws -> Session { throw AuthServiceError.notConfigured }
    func update(user: UserAttributes) async throws -> User { throw AuthServiceError.notConfigured }
    func verifyOTP(email: String, token: String, type: EmailOTPType) async throws -> AuthResponse { throw AuthServiceError.notConfigured }
    func signOut() async throws { currentUser = nil }
}

@MainActor
@Suite("HouseholdSyncCoordinator", .serialized)
struct HouseholdSyncCoordinatorTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemoryContainer()
    }

    @Test("with no sync client, a local household still exists but stays unlinked")
    func offlineStillCreatesLocalHousehold() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let authService = AuthService(client: FakeSupabaseAuthClientForCoordinator())
        let coordinator = HouseholdSyncCoordinator(authService: authService, syncClient: nil, context: context)

        let household = await coordinator.bootstrapIfNeeded()

        #expect(household != nil)
        #expect(household?.remoteHouseholdID == nil)
    }

    @Test("a working sync client links the local household using its own id")
    func linksHouseholdUsingLocalID() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let authService = AuthService(client: FakeSupabaseAuthClientForCoordinator())
        let syncClient = FakeSupabaseHouseholdSyncClient()
        let coordinator = HouseholdSyncCoordinator(authService: authService, syncClient: syncClient, context: context)

        let household = await coordinator.bootstrapIfNeeded()

        #expect(household?.remoteHouseholdID == household?.id)
        #expect(syncClient.lastRequestedID == household?.id)
    }

    @Test("calling bootstrap twice only creates the remote household once")
    func bootstrapIsIdempotent() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let authService = AuthService(client: FakeSupabaseAuthClientForCoordinator())
        let syncClient = FakeSupabaseHouseholdSyncClient()
        let coordinator = HouseholdSyncCoordinator(authService: authService, syncClient: syncClient, context: context)

        await coordinator.bootstrapIfNeeded()
        await coordinator.bootstrapIfNeeded()

        #expect(syncClient.createPersonalHouseholdCallCount == 1)
    }

    @Test("a failed remote link leaves the household usable locally, unlinked, for a later retry")
    func failedLinkLeavesHouseholdUnlinked() async throws {
        struct NetworkError: Error {}
        let container = try makeContainer()
        let context = container.mainContext
        let authService = AuthService(client: FakeSupabaseAuthClientForCoordinator())
        let syncClient = FakeSupabaseHouseholdSyncClient()
        syncClient.createPersonalHouseholdError = NetworkError()
        let coordinator = HouseholdSyncCoordinator(authService: authService, syncClient: syncClient, context: context)

        let household = await coordinator.bootstrapIfNeeded()

        #expect(household != nil)
        #expect(household?.remoteHouseholdID == nil)
    }

    @Test("createInvite delegates to the sync client")
    func createInviteDelegates() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let authService = AuthService(client: FakeSupabaseAuthClientForCoordinator())
        let syncClient = FakeSupabaseHouseholdSyncClient()
        syncClient.inviteCode = "XYZ789"
        let coordinator = HouseholdSyncCoordinator(authService: authService, syncClient: syncClient, context: context)

        let code = try await coordinator.createInvite()

        #expect(code == "XYZ789")
    }

    @Test("joining a household re-points the local household's remoteHouseholdID at the joined household")
    func joinHouseholdRepointsLocalHousehold() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let authService = AuthService(client: FakeSupabaseAuthClientForCoordinator())
        let syncClient = FakeSupabaseHouseholdSyncClient()
        let joinedID = UUID()
        syncClient.joinedHouseholdID = joinedID
        let coordinator = HouseholdSyncCoordinator(authService: authService, syncClient: syncClient, context: context)

        try await coordinator.joinHousehold(code: "ABC123")

        let households = try context.fetch(FetchDescriptor<Household>())
        #expect(households.count == 1)
        #expect(households.first?.remoteHouseholdID == joinedID)
    }
}
