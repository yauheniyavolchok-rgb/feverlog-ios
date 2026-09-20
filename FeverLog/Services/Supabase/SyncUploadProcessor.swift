import Foundation
import Supabase
import SwiftData

/// Uploads pending/retry-ready sync queue items. Each item's payload is
/// built fresh from the current SwiftData record right before sending
/// (never from a stale snapshot captured at enqueue time), matching the
/// spec's "serialize the current local record snapshot" upload step.
///
/// Ordering note: `children` rows are uploaded before any other entity
/// type each cycle, since every other table's row references a child by
/// foreign key. A child-dependent item attempted before its child has
/// landed remotely fails with a Postgres FK-violation error, which this
/// processor treats like any other transient failure — bounded backoff,
/// retried next cycle. This is a deliberate simplification over building
/// an explicit dependency graph: it self-heals within one or two sync
/// cycles and never loses data, matching "sync failures do not block
/// local data entry."
@MainActor
final class SyncUploadProcessor {
    private let context: ModelContext
    private let queueRepository: SyncQueueRepository
    private let uploadClient: SyncUploadClient?

    init(context: ModelContext, queueRepository: SyncQueueRepository, uploadClient: SyncUploadClient?) {
        self.context = context
        self.queueRepository = queueRepository
        self.uploadClient = uploadClient
    }

    /// No-op when Supabase isn't configured. Never throws — a failed
    /// upload never removes or hides a local record, and the caller can
    /// simply try again later.
    func processPendingUploads(now: Date = .now) async {
        guard let uploadClient else { return }
        guard let items = try? queueRepository.fetchReadyForUpload(now: now) else { return }

        let ordered = items.sorted { lhs, rhs in
            (lhs.entityType == "children" ? 0 : 1) < (rhs.entityType == "children" ? 0 : 1)
        }

        for item in ordered {
            await process(item, uploadClient: uploadClient, now: now)
        }
    }

    private func process(_ item: SyncQueueItem, uploadClient: SyncUploadClient, now: Date) async {
        guard let json = buildPayload(for: item) else {
            // Not ready yet (e.g. household not linked, or the local
            // record no longer exists). Leave pending; retried next cycle.
            return
        }

        try? queueRepository.markInFlight(item)
        item.payload = try? SyncJSONCoding.encoder.encode(json)

        do {
            try await uploadClient.upsert(table: item.entityType, json: json)
            try queueRepository.markCompleted(item)
        } catch {
            let nextRetryAt = SyncRetryPolicy.nextRetryDate(forAttempt: item.retryCount, from: now)
            try? queueRepository.markFailed(item, error: String(describing: error), nextRetryAt: nextRetryAt)
        }
    }

    private func buildPayload(for item: SyncQueueItem) -> AnyJSON? {
        let entityID = item.entityID
        switch item.entityType {
        case "children":
            return fetchChild(id: entityID).flatMap(encode)
        case "weight_history":
            return fetchOne(WeightHistory.self, predicate: #Predicate { $0.id == entityID }).flatMap(encode)
        case "temperature_logs":
            return fetchOne(TemperatureLog.self, predicate: #Predicate { $0.id == entityID }).flatMap(encode)
        case "medication_logs":
            return fetchOne(MedicationLog.self, predicate: #Predicate { $0.id == entityID }).flatMap(encode)
        case "symptoms":
            return fetchOne(SymptomEntry.self, predicate: #Predicate { $0.id == entityID }).flatMap(encode)
        case "notes":
            return fetchOne(NoteEntry.self, predicate: #Predicate { $0.id == entityID }).flatMap(encode)
        default:
            return nil
        }
    }

    private func fetchChild(id: UUID) -> Child? {
        fetchOne(Child.self, predicate: #Predicate { $0.id == id })
    }

    private func fetchOne<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>) -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private var currentUserID: UUID? { SupabaseClientProvider.shared?.auth.currentUser?.id }

    private func encode(_ child: Child) -> AnyJSON? {
        guard let remoteHouseholdID = child.household?.remoteHouseholdID else { return nil }
        let record = ChildRemoteRecord(
            id: child.id,
            householdID: remoteHouseholdID,
            name: child.name,
            birthday: SyncJSONCoding.dateOnlyString(child.birthday),
            avatarIdentifier: child.avatarIdentifier,
            avatarColorIdentifier: child.avatarColorIdentifier,
            cachedWeightValue: child.cachedWeightValue,
            cachedWeightUnit: child.cachedWeightUnit?.rawValue,
            createdBy: currentUserID,
            createdAt: child.createdAt,
            updatedAt: child.updatedAt,
            deletedAt: child.deletedAt
        )
        return try? decodeToJSON(record)
    }

    private func encode(_ entry: WeightHistory) -> AnyJSON? {
        let record = WeightHistoryRemoteRecord(
            id: entry.id,
            childID: entry.childID,
            weight: entry.weight,
            unit: entry.unit.rawValue,
            effectiveDate: SyncJSONCoding.dateOnlyString(entry.effectiveDate),
            createdBy: currentUserID,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            deletedAt: entry.deletedAt
        )
        return try? decodeToJSON(record)
    }

    private func encode(_ log: TemperatureLog) -> AnyJSON? {
        let record = TemperatureLogRemoteRecord(
            id: log.id,
            childID: log.childID,
            temperatureCelsius: log.temperatureCelsius,
            measurementMethod: log.measurementMethod.rawValue,
            recordedAt: log.recordedAt,
            note: log.note,
            createdBy: currentUserID,
            createdAt: log.createdAt,
            updatedAt: log.updatedAt,
            deletedAt: log.deletedAt
        )
        return try? decodeToJSON(record)
    }

    private func encode(_ log: MedicationLog) -> AnyJSON? {
        let record = MedicationLogRemoteRecord(
            id: log.id,
            childID: log.childID,
            medicationDefinitionID: log.medicationDefinitionID,
            activeIngredientSnapshot: log.activeIngredientSnapshot,
            concentrationValueSnapshot: log.concentrationValueSnapshot,
            concentrationMillilitersSnapshot: log.concentrationMillilitersSnapshot,
            concentrationUnitSnapshot: log.concentrationUnitSnapshot,
            formSnapshot: log.formSnapshot,
            brandSnapshot: log.brandSnapshot,
            ruleVersionSnapshot: log.ruleVersionSnapshot,
            sourceVersionSnapshot: log.sourceVersionSnapshot,
            volumeMilliliters: log.volumeMilliliters,
            calculatedMilligrams: log.calculatedMilligrams,
            calculatedMilligramsPerKilogram: log.calculatedMilligramsPerKilogram,
            weightUsedForCalculation: log.weightUsedForCalculation,
            weightUnitUsedForCalculation: log.weightUnitUsedForCalculation?.rawValue,
            calculationStatus: log.calculationStatus.rawValue,
            administeredAt: log.administeredAt,
            createdBy: currentUserID,
            createdAt: log.createdAt,
            updatedAt: log.updatedAt,
            deletedAt: log.deletedAt
        )
        return try? decodeToJSON(record)
    }

    private func encode(_ entry: SymptomEntry) -> AnyJSON? {
        let record = SymptomRemoteRecord(
            id: entry.id,
            childID: entry.childID,
            symptomIdentifiers: entry.symptomIdentifiers,
            recordedAt: entry.recordedAt,
            createdBy: currentUserID,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            deletedAt: entry.deletedAt
        )
        return try? decodeToJSON(record)
    }

    private func encode(_ entry: NoteEntry) -> AnyJSON? {
        let record = NoteRemoteRecord(
            id: entry.id,
            childID: entry.childID,
            text: entry.text,
            recordedAt: entry.recordedAt,
            createdBy: currentUserID,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            deletedAt: entry.deletedAt
        )
        return try? decodeToJSON(record)
    }

    private func decodeToJSON(_ value: some Encodable) throws -> AnyJSON {
        let data = try SyncJSONCoding.encoder.encode(value)
        return try SyncJSONCoding.decoder.decode(AnyJSON.self, from: data)
    }
}
