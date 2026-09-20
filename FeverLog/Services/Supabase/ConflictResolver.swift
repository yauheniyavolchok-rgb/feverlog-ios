import Foundation

/// The minimal shape a conflict decision needs from either side —
/// decoupled from SwiftData/Supabase so `ConflictResolver` stays pure and
/// independently testable. `id` is a string because it must be compared
/// lexicographically as the tie-break signal, not just checked for
/// equality (see `remoteWins(local:remote:)`).
struct SyncVersionMetadata: Equatable, Sendable {
    let id: String
    let updatedAt: Date
}

/// Deterministic conflict resolution per the documented rule:
/// 1. Later `updatedAt` wins.
/// 2. If timestamps are exactly equal, the lexicographically greater
///    stable id wins.
///
/// Soft deletion participates in this same rule with no special case: a
/// tombstone is just a record whose `deletedAt`/`updatedAt` changed, so a
/// newer tombstone always wins over an older non-deleted update and can
/// never be resurrected by one, and vice versa — whichever side has the
/// later `updatedAt` fully wins, deleted or not.
///
/// `updatedAt` is a client-supplied timestamp (see the SQL migration's
/// header comment for the full rationale and the documented clock-skew
/// limitation this implies).
enum ConflictResolver {
    static func remoteWins(local: SyncVersionMetadata, remote: SyncVersionMetadata) -> Bool {
        if remote.updatedAt != local.updatedAt {
            return remote.updatedAt > local.updatedAt
        }
        return remote.id > local.id
    }
}
