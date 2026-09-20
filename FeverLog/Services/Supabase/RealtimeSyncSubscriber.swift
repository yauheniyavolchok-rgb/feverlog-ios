import Foundation
import Supabase
import SwiftData

/// Subscribes to Postgres change events for every synchronized table and
/// imports each one through `SyncDownloadImporter`, so the app never
/// renders a remote event directly — it always lands in SwiftData first,
/// and SwiftUI observes the result as usual.
///
/// This is the one piece of the sync engine that cannot be exercised
/// against a real Postgres instance in this environment (Realtime needs a
/// live Supabase project's websocket gateway, not just its database) — it
/// is implemented against the documented `supabase-swift` Realtime API
/// and should be smoke-tested against a real project before shipping.
@MainActor
final class RealtimeSyncSubscriber {
    private let client: SupabaseClient
    private let context: ModelContext
    private var channel: RealtimeChannelV2?
    private var subscriptions: [RealtimeSubscription] = []

    private static let childScopedTables = ["weight_history", "temperature_logs", "medication_logs", "symptoms", "notes"]

    init(client: SupabaseClient, context: ModelContext) {
        self.client = client
        self.context = context
    }

    func start() async {
        guard channel == nil else { return }
        let channel = client.channel("household-sync")
        self.channel = channel

        for table in ["children"] + Self.childScopedTables {
            let subscription = channel.onPostgresChange(AnyAction.self, table: table) { [weak self] action in
                Task { @MainActor [weak self] in
                    self?.handle(table: table, action: action)
                }
            }
            subscriptions.append(subscription)
        }

        await channel.subscribe()
    }

    func stop() async {
        guard let channel else { return }
        await client.removeChannel(channel)
        self.channel = nil
        subscriptions = []
    }

    private func handle(table: String, action: AnyAction) {
        // Deletes never occur in this schema (soft delete is an UPDATE),
        // so only insert/update carry a record worth importing.
        let record: JSONObject?
        switch action {
        case .insert(let insert): record = insert.record
        case .update(let update): record = update.record
        case .delete: record = nil
        }
        guard let record else { return }

        do {
            let data = try SyncJSONCoding.encoder.encode(record)
            try dispatch(table: table, data: data)
        } catch {
            // Malformed or unrecognized event — never corrupt local state;
            // simply skip it. The next full sync (or a subsequent valid
            // event for the same row) will reconcile any gap.
        }
    }

    private func dispatch(table: String, data: Data) throws {
        let importer = SyncDownloadImporter(context: context)

        switch table {
        case "children":
            try dispatchChild(data: data, importer: importer)
        case "weight_history":
            try dispatchChildScoped(
                data: data, importer: importer, import: importer.importWeightHistory, childID: \WeightHistoryRemoteRecord.childID
            )
        case "temperature_logs":
            try dispatchChildScoped(
                data: data, importer: importer, import: importer.importTemperatureLog, childID: \TemperatureLogRemoteRecord.childID
            )
        case "medication_logs":
            try dispatchChildScoped(
                data: data, importer: importer, import: importer.importMedicationLog, childID: \MedicationLogRemoteRecord.childID
            )
        case "symptoms":
            try dispatchChildScoped(
                data: data, importer: importer, import: importer.importSymptom, childID: \SymptomRemoteRecord.childID
            )
        case "notes":
            try dispatchChildScoped(
                data: data, importer: importer, import: importer.importNote, childID: \NoteRemoteRecord.childID
            )
        default:
            break
        }
    }

    private func dispatchChild(data: Data, importer: SyncDownloadImporter) throws {
        let remote = try SyncJSONCoding.decoder.decode(ChildRemoteRecord.self, from: data)
        guard let household = fetchHousehold(remoteID: remote.householdID) else { return }
        importer.importChild(remote, household: household)
    }

    private func dispatchChildScoped<Record: Decodable>(
        data: Data,
        importer: SyncDownloadImporter,
        import importRecord: (Record, Child) -> Bool,
        childID: KeyPath<Record, UUID>
    ) throws {
        let remote = try SyncJSONCoding.decoder.decode(Record.self, from: data)
        guard let child = fetchChild(id: remote[keyPath: childID]) else { return }
        importRecord(remote, child)
    }

    /// A child referenced by an incoming child-scoped record must already
    /// exist locally (children always sync before their dependents — see
    /// `SyncUploadProcessor`'s ordering note). If it doesn't yet, the event
    /// is dropped; the child's own event (already in flight or about to
    /// arrive) will bring it in, and a later full sync reconciles the rest.
    private func fetchChild(id: UUID) -> Child? {
        var descriptor = FetchDescriptor<Child>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func fetchHousehold(remoteID: UUID) -> Household? {
        var descriptor = FetchDescriptor<Household>(predicate: #Predicate { $0.remoteHouseholdID == remoteID })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
