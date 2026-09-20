import Foundation
import Supabase

/// Thin wrapper over the three household-lifecycle RPCs defined in the
/// Phase 9 SQL migration, so `HouseholdSyncCoordinator`'s orchestration
/// logic can be unit tested against a fake instead of a network client.
protocol SupabaseHouseholdSyncClient: Sendable {
    /// Calls `create_personal_household(p_household_id)`. Idempotent: if
    /// this user already owns a household, the RPC returns that existing
    /// id regardless of what's passed here.
    func createPersonalHousehold(id: UUID) async throws -> UUID
    /// Calls `create_household_invite()`. Only a household owner may call
    /// this successfully — the RPC enforces that server-side.
    func createHouseholdInvite() async throws -> String
    /// Calls `redeem_household_invite(invite_code)`, returning the id of
    /// the household the caller just joined.
    func redeemHouseholdInvite(code: String) async throws -> UUID
}

struct LiveSupabaseHouseholdSyncClient: SupabaseHouseholdSyncClient {
    let client: SupabaseClient

    func createPersonalHousehold(id: UUID) async throws -> UUID {
        try await client.rpc("create_personal_household", params: ["p_household_id": id]).execute().value
    }

    func createHouseholdInvite() async throws -> String {
        try await client.rpc("create_household_invite").execute().value
    }

    func redeemHouseholdInvite(code: String) async throws -> UUID {
        try await client.rpc("redeem_household_invite", params: ["invite_code": code]).execute().value
    }
}
