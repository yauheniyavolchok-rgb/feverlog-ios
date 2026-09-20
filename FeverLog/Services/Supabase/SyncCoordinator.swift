import Foundation
import SwiftData

/// The single entry point the app calls to run one sync cycle: link the
/// household if needed, then upload anything pending. Safe to call
/// repeatedly (app launch, scene foreground, pull-to-refresh, a manual
/// "Sync Now" action) — every step is idempotent, and a failure at any
/// point never blocks local reads or writes.
@MainActor
final class SyncCoordinator {
    private let authService: AuthService
    private let context: ModelContext

    init(authService: AuthService, context: ModelContext) {
        self.authService = authService
        self.context = context
    }

    func runCycle() async {
        let client = SupabaseClientProvider.shared

        let householdCoordinator = HouseholdSyncCoordinator(
            authService: authService,
            syncClient: client.map(LiveSupabaseHouseholdSyncClient.init),
            context: context
        )
        await householdCoordinator.bootstrapIfNeeded()

        let uploadProcessor = SyncUploadProcessor(
            context: context,
            queueRepository: SwiftDataSyncQueueRepository(context: context),
            uploadClient: client.map(LiveSyncUploadClient.init)
        )
        await uploadProcessor.processPendingUploads()
    }
}
