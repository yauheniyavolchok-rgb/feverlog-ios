import Foundation
import SwiftData

@Model
final class SymptomEntry {
    var id: UUID
    var childID: UUID
    var child: Child?

    /// Raw values of symptom identifiers selected for this entry (Phase 7
    /// defines the concrete symptom category set).
    var symptomIdentifiers: [String]
    var recordedAt: Date

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    init(
        id: UUID = UUID(),
        child: Child,
        symptomIdentifiers: [String],
        recordedAt: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.childID = child.id
        self.child = child
        self.symptomIdentifiers = symptomIdentifiers
        self.recordedAt = recordedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension SymptomEntry: SyncableRecord {}
