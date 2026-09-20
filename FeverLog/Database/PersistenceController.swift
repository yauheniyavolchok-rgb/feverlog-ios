import SwiftData

// TODO(Phase 2, SwiftData migration plan): Add migration plans when the schema changes after the first release.
// Completion: a versioned migration strategy and migration tests exist before the first schema-changing release.
// Release blocker: yes for any release that changes the persisted schema without migration coverage.
@MainActor
final class PersistenceController {
    let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    /// The app cannot function without local storage — a failure here is a
    /// genuine, unrecoverable startup condition, not a scenario to degrade
    /// gracefully from.
    static func production() -> PersistenceController {
        do {
            return PersistenceController(container: try ModelContainerFactory.makeProductionContainer())
        } catch {
            fatalError("Failed to create the production SwiftData container: \(error)")
        }
    }

    static func inMemoryForTesting() -> PersistenceController {
        do {
            return PersistenceController(container: try ModelContainerFactory.makeInMemoryContainer())
        } catch {
            fatalError("Failed to create the in-memory SwiftData container: \(error)")
        }
    }

    var mainContext: ModelContext {
        container.mainContext
    }
}
