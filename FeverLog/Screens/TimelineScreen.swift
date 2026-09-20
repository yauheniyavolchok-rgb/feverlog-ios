import SwiftData
import SwiftUI

struct TimelineScreen: View {
    @Environment(ChildStore.self) private var childStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    @State private var logs: [TemperatureLog] = []
    @State private var editingLog: TemperatureLog?
    @State private var showingEditScreen = false

    private var groups: [TimelineDayGroup<TemperatureLog>] {
        TimelineGrouping.groupByDay(logs, date: \.recordedAt)
    }

    var body: some View {
        Group {
            if childStore.selectedChild == nil {
                PlaceholderScreen(
                    navigationTitle: L10n.Nav.timeline,
                    systemImage: Icon.timeline,
                    title: L10n.Screens.timelineTitle,
                    message: L10n.Screens.timelinePlaceholderMessage
                )
            } else if logs.isEmpty {
                EmptyStateView(
                    systemImage: Icon.timeline,
                    title: L10n.Timeline.emptyTitle,
                    message: L10n.Timeline.emptyMessage
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
            } else {
                List {
                    ForEach(groups) { group in
                        Section(header: Text(dayLabel(for: group.day))) {
                            ForEach(group.items, id: \.id) { log in
                                TemperatureLogRow(log: log)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { delete(log) } label: {
                                            Label(L10n.Timeline.delete, systemImage: "trash")
                                        }
                                        Button { duplicate(log) } label: {
                                            Label(L10n.Timeline.duplicate, systemImage: "plus.square.on.square")
                                        }
                                        .tint(palette.accentBlue)
                                        Button {
                                            beginEditing(log)
                                        } label: {
                                            Label(L10n.Timeline.edit, systemImage: "pencil")
                                        }
                                        .tint(palette.accentLavender)
                                    }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(L10n.Nav.timeline)
        .task(id: childStore.selectedChildID) { await reload() }
        .navigationDestination(isPresented: $showingEditScreen) {
            if let child = childStore.selectedChild, let editingLog {
                TemperatureEntryScreen(child: child, existingLog: editingLog) {
                    Task { await reload() }
                }
            }
        }
    }

    private func beginEditing(_ log: TemperatureLog) {
        editingLog = log
        showingEditScreen = true
    }

    private func dayLabel(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return L10n.Timeline.today }
        if calendar.isDateInYesterday(day) { return L10n.Timeline.yesterday }
        return day.formatted(.dateTime.month(.wide).day().year())
    }

    private func reload() async {
        guard let child = childStore.selectedChild else {
            logs = []
            return
        }
        do {
            logs = try SwiftDataTemperatureLogRepository(context: modelContext).fetchAll(for: child)
        } catch {
            logs = []
        }
    }

    private func duplicate(_ log: TemperatureLog) {
        guard let child = childStore.selectedChild else { return }
        do {
            let repository = SwiftDataTemperatureLogRepository(context: modelContext)
            _ = try repository.create(
                temperatureCelsius: log.temperatureCelsius,
                measurementMethod: log.measurementMethod,
                recordedAt: .now,
                note: log.note,
                child: child
            )
            Task { await reload() }
        } catch {
            // Non-fatal: the row remains as-is if duplication fails.
        }
    }

    private func delete(_ log: TemperatureLog) {
        do {
            try SwiftDataTemperatureLogRepository(context: modelContext).softDelete(log)
            Task { await reload() }
        } catch {
            // Non-fatal: the row remains as-is if deletion fails.
        }
    }
}
