import Foundation
import SwiftData

@Model
final class Child {
    var id: UUID
    var householdID: UUID
    var household: Household?

    var name: String
    var birthday: Date
    var avatarIdentifier: String
    var avatarColorIdentifier: String

    /// Non-authoritative cache of the most recent weight, for fast display
    /// only. The authoritative value is always derived from `WeightHistory`
    /// via `WeightHistoryRepository.activeWeight(for:at:)`.
    var cachedWeightValue: Double?
    var cachedWeightUnit: WeightUnit?

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var lastSyncedAt: Date?
    var syncVersion: Int

    @Relationship(deleteRule: .cascade, inverse: \WeightHistory.child)
    var weightHistory: [WeightHistory] = []

    @Relationship(deleteRule: .cascade, inverse: \TemperatureLog.child)
    var temperatureLogs: [TemperatureLog] = []

    @Relationship(deleteRule: .cascade, inverse: \MedicationLog.child)
    var medicationLogs: [MedicationLog] = []

    @Relationship(deleteRule: .cascade, inverse: \SymptomEntry.child)
    var symptomEntries: [SymptomEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \NoteEntry.child)
    var notes: [NoteEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \Reminder.child)
    var reminders: [Reminder] = []

    init(
        id: UUID = UUID(),
        household: Household,
        name: String,
        birthday: Date,
        avatarIdentifier: String,
        avatarColorIdentifier: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.householdID = household.id
        self.household = household
        self.name = name
        self.birthday = birthday
        self.avatarIdentifier = avatarIdentifier
        self.avatarColorIdentifier = avatarColorIdentifier
        self.cachedWeightValue = nil
        self.cachedWeightUnit = nil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = nil
        self.lastSyncedAt = nil
        self.syncVersion = 0
    }
}

extension Child: SyncableRecord {}
