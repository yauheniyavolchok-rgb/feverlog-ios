import Foundation
import Testing
@testable import FeverLog

@Suite("ConflictResolver")
struct ConflictResolverTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("later updatedAt wins regardless of id")
    func laterUpdatedAtWins() {
        let local = SyncVersionMetadata(id: "zzzzzzzz", updatedAt: now)
        let remote = SyncVersionMetadata(id: "aaaaaaaa", updatedAt: now.addingTimeInterval(1))
        #expect(ConflictResolver.remoteWins(local: local, remote: remote))
    }

    @Test("earlier updatedAt loses regardless of id")
    func earlierUpdatedAtLoses() {
        let local = SyncVersionMetadata(id: "aaaaaaaa", updatedAt: now)
        let remote = SyncVersionMetadata(id: "zzzzzzzz", updatedAt: now.addingTimeInterval(-1))
        #expect(!ConflictResolver.remoteWins(local: local, remote: remote))
    }

    @Test("exactly equal timestamps break the tie by lexicographically greater id")
    func equalTimestampsBreakTieByID() {
        let local = SyncVersionMetadata(id: "aaaaaaaa", updatedAt: now)
        let remoteWinner = SyncVersionMetadata(id: "bbbbbbbb", updatedAt: now)
        let remoteLoser = SyncVersionMetadata(id: "aaaaaaa0", updatedAt: now)

        #expect(ConflictResolver.remoteWins(local: local, remote: remoteWinner))
        #expect(!ConflictResolver.remoteWins(local: local, remote: remoteLoser))
    }

    @Test("identical metadata on both sides never lets remote win (idempotent re-application)")
    func identicalMetadataDoesNotFlip() {
        let metadata = SyncVersionMetadata(id: "aaaaaaaa", updatedAt: now)
        #expect(!ConflictResolver.remoteWins(local: metadata, remote: metadata))
    }

    @Test("a newer tombstone (later updatedAt) beats an older non-deleted update — the rule has no special case")
    func newerTombstoneWins() {
        // Soft-delete participates in the same rule as any other field
        // change: this test only asserts the *rule* — the caller decides
        // what "deleted" means when applying the winning side.
        let localStillActive = SyncVersionMetadata(id: "aaaaaaaa", updatedAt: now)
        let remoteTombstone = SyncVersionMetadata(id: "aaaaaaaa", updatedAt: now.addingTimeInterval(60))
        #expect(ConflictResolver.remoteWins(local: localStillActive, remote: remoteTombstone))
    }

    @Test("an older update can never resurrect a newer local tombstone")
    func olderUpdateCannotResurrectNewerTombstone() {
        let localTombstone = SyncVersionMetadata(id: "aaaaaaaa", updatedAt: now)
        let olderRemoteUpdate = SyncVersionMetadata(id: "aaaaaaaa", updatedAt: now.addingTimeInterval(-60))
        #expect(!ConflictResolver.remoteWins(local: localTombstone, remote: olderRemoteUpdate))
    }
}
