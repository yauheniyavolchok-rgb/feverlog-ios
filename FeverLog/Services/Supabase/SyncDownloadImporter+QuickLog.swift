import Foundation
import SwiftData

// Split from SyncDownloadImporter.swift purely to stay under SwiftLint's
// type-body-length limit — see that file's header comment for the shared
// import-method contract this follows.
extension SyncDownloadImporter {
    @discardableResult
    func importQuickLog(_ remote: QuickLogRemoteRecord, child: Child) -> Bool {
        let id = remote.id
        let existing = fetchOne(QuickLogEntry.self, predicate: #Predicate { $0.id == id })
        let type = QuickLogType(rawValue: remote.type) ?? .food

        if let existing {
            guard shouldApply(remote: remote, localID: existing.id, localUpdatedAt: existing.updatedAt) else { return false }
            existing.type = type
            existing.degree = remote.degree
            existing.recordedAt = remote.recordedAt
            existing.updatedAt = remote.updatedAt
            existing.deletedAt = remote.deletedAt
            existing.lastSyncedAt = .now
        } else {
            let entry = QuickLogEntry(
                id: remote.id,
                child: child,
                type: type,
                degree: remote.degree,
                recordedAt: remote.recordedAt,
                createdAt: remote.createdAt,
                updatedAt: remote.updatedAt
            )
            entry.deletedAt = remote.deletedAt
            entry.lastSyncedAt = .now
            context.insert(entry)
        }
        try? context.save()
        return true
    }
}
