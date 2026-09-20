import SwiftData
import SwiftUI

/// Offline queue visibility for debugging, per the Phase 9 spec. Shows
/// every non-completed sync queue item with its status, entity, and last
/// error (if any) — nothing here is user-facing polish, it's a diagnostic
/// view.
struct SyncStatusScreen: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    @State private var items: [SyncQueueItem] = []
    @State private var isSyncing = false

    private var pendingCount: Int { items.filter { $0.status == .pending || $0.status == .inFlight }.count }
    private var failedCount: Int { items.filter { $0.status == .failed }.count }

    var body: some View {
        List {
            if !authService.isConfigured {
                Section {
                    Text(L10n.SyncStatus.notConfiguredMessage)
                        .foregroundStyle(palette.secondaryText)
                }
            }

            Section {
                HStack {
                    Text(L10n.SyncStatus.pendingCount)
                    Spacer()
                    Text("\(pendingCount)").foregroundStyle(palette.secondaryText)
                }
                HStack {
                    Text(L10n.SyncStatus.failedCount)
                    Spacer()
                    Text("\(failedCount)").foregroundStyle(palette.danger)
                }
                Button(L10n.SyncStatus.syncNow) { Task { await syncNow() } }
                    .disabled(isSyncing || !authService.isConfigured)
                    .accessibilityIdentifier("syncStatus.syncNow")
            }

            if items.isEmpty {
                Section {
                    Text(L10n.SyncStatus.queueEmptyMessage)
                        .foregroundStyle(palette.secondaryText)
                }
            } else {
                Section {
                    ForEach(items, id: \.id) { item in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text(item.entityType)
                                    .font(Typography.body.weight(.semibold))
                                Spacer()
                                Text(item.status.rawValue)
                                    .font(Typography.caption)
                                    .foregroundStyle(item.status == .failed ? palette.danger : palette.secondaryText)
                            }
                            if let lastError = item.lastError {
                                Text(lastError)
                                    .font(Typography.caption)
                                    .foregroundStyle(palette.danger)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.SyncStatus.title)
        .task { await reload() }
    }

    private func syncNow() async {
        isSyncing = true
        defer { isSyncing = false }
        await SyncCoordinator(authService: authService, context: modelContext).runCycle()
        await reload()
    }

    private func reload() async {
        let descriptor = FetchDescriptor<SyncQueueItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let all = (try? modelContext.fetch(descriptor)) ?? []
        items = all.filter { $0.status != .completed }
    }
}
