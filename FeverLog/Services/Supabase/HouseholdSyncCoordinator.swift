import Foundation
import SwiftData

/// Bridges the local `Household` (SwiftData, always present, works fully
/// offline) to its Supabase counterpart. Establishing the remote link is
/// entirely best-effort: a fresh install with no connectivity keeps
/// working locally forever until connectivity returns, exactly like any
/// other queued sync operation.
@MainActor
final class HouseholdSyncCoordinator {
    private let authService: AuthService
    private let syncClient: SupabaseHouseholdSyncClient?
    private let context: ModelContext

    init(authService: AuthService, syncClient: SupabaseHouseholdSyncClient?, context: ModelContext) {
        self.authService = authService
        self.syncClient = syncClient
        self.context = context
    }

    /// Ensures a local household exists (always, offline-safe), then
    /// best-effort links it to a remote personal household once an
    /// authenticated session is available. Never throws.
    @discardableResult
    func bootstrapIfNeeded() async -> Household? {
        let householdRepository = SwiftDataHouseholdRepository(context: context)
        guard let household = try? householdRepository.createGuestHouseholdIfNeeded() else { return nil }

        await authService.bootstrapSessionIfNeeded()
        guard authService.currentUserID != nil, let syncClient else { return household }
        guard household.remoteHouseholdID == nil else { return household }

        do {
            let remoteID = try await syncClient.createPersonalHousehold(id: household.id)
            household.remoteHouseholdID = remoteID
            try householdRepository.update(household)
        } catch {
            // Offline or transient failure — retried on next bootstrap.
        }
        return household
    }

    /// Only meaningful for an already-linked (non-anonymous) owner — the
    /// `create_household_invite` RPC enforces that server-side regardless.
    func createInvite() async throws -> String {
        guard let syncClient else { throw AuthServiceError.notConfigured }
        return try await syncClient.createHouseholdInvite()
    }

    /// Redeems an invite code and re-points this device's local household
    /// at the joined household. The actual contents (children, logs, etc.)
    /// of the joined household arrive through the normal sync download
    /// path once `remoteHouseholdID` changes — this method only performs
    /// the join itself.
    func joinHousehold(code: String) async throws {
        guard let syncClient else { throw AuthServiceError.notConfigured }
        let remoteID = try await syncClient.redeemHouseholdInvite(code: code)

        let householdRepository = SwiftDataHouseholdRepository(context: context)
        let household = try householdRepository.createGuestHouseholdIfNeeded()
        household.remoteHouseholdID = remoteID
        try householdRepository.update(household)
    }
}
