import SwiftData

enum ModelContainerFactory {
    static var allModelTypes: [any PersistentModel.Type] {
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

    static func makeSchema() -> Schema {
        Schema(allModelTypes)
    }

    static func makeProductionContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: makeSchema(), isStoredInMemoryOnly: false)
        return try ModelContainer(for: makeSchema(), configurations: [configuration])
    }

    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: makeSchema(), isStoredInMemoryOnly: true)
        return try ModelContainer(for: makeSchema(), configurations: [configuration])
    }
}
