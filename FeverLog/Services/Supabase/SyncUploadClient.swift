import Foundation
import Supabase

/// Thin wrapper over the single PostgREST call the upload processor needs,
/// so its retry/ordering/coalescing orchestration can be unit tested
/// against a fake instead of a network client.
protocol SyncUploadClient: Sendable {
    func upsert(table: String, json: AnyJSON) async throws
}

struct LiveSyncUploadClient: SyncUploadClient {
    let client: SupabaseClient

    func upsert(table: String, json: AnyJSON) async throws {
        _ = try await client.from(table).upsert(json).execute()
    }
}
