import SwiftData

// TODO(Phase 11, migration plan): SchemaV1 is the only version so far, so
// MigrationPlan.stages is intentionally empty. When the schema changes in a
// way SwiftData can't infer automatically (renaming/removing a property,
// splitting a model, changing a non-optional's type), add a `SchemaV2`
// enum below with the new `models`, and a `.custom`/`.lightweight`
// MigrationStage from V1 to V2 to MigrationPlan.stages — never edit
// SchemaV1 in place once it has shipped to a real device.
// Completion: a second VersionedSchema and a migration stage exist,
// covered by a test that migrates a V1-shaped store to V2 and asserts data
// survives.
// Release blocker: yes for any release that changes the persisted schema
// without a corresponding migration stage.
enum ModelContainerFactory {
    enum SchemaV1: VersionedSchema {
        static let versionIdentifier = Schema.Version(1, 0, 0)

        static var models: [any PersistentModel.Type] {
            [
                Household.self,
                HouseholdMember.self,
                Child.self,
                WeightHistory.self,
                TemperatureLog.self,
                MedicationDefinition.self,
                MedicationLog.self,
                SymptomEntry.self,
                NoteEntry.self,
                Reminder.self,
                SyncQueueItem.self
            ]
        }
    }

    enum MigrationPlan: SchemaMigrationPlan {
        static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
        static var stages: [MigrationStage] { [] }
    }

    static func makeSchema() -> Schema {
        Schema(versionedSchema: SchemaV1.self)
    }

    static func makeProductionContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: makeSchema(), isStoredInMemoryOnly: false)
        return try ModelContainer(for: makeSchema(), migrationPlan: MigrationPlan.self, configurations: [configuration])
    }

    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: makeSchema(), isStoredInMemoryOnly: true)
        return try ModelContainer(for: makeSchema(), configurations: [configuration])
    }
}
