import SwiftData
import SwiftUI

enum TimelineSortMode: String, CaseIterable, Identifiable {
    case time
    case child

    var id: String { rawValue }

    var label: String {
        switch self {
        case .time: L10n.Timeline.sortByTime
        case .child: L10n.Timeline.sortByChild
        }
    }
}

struct TimelineScreen: View {
    @Environment(ChildStore.self) private var childStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    @State private var logsByChildID: [UUID: [TemperatureLog]] = [:]
    @State private var sortMode: TimelineSortMode = .time
    @State private var editingLog: TemperatureLog?
    @State private var showingEditScreen = false

    private var allLogs: [TemperatureLog] {
        logsByChildID.values.flatMap { $0 }
    }

    private var dayGroups: [TimelineDayGroup<TemperatureLog>] {
        TimelineGrouping.groupByDay(allLogs, date: \.recordedAt)
    }

    private var childGroups: [(child: Child, logs: [TemperatureLog])] {
        childStore.children.compactMap { child in
            guard let logs = logsByChildID[child.id], !logs.isEmpty else { return nil }
            return (child, logs.sorted { $0.recordedAt > $1.recordedAt })
        }
    }

    var body: some View {
        Group {
            if childStore.children.isEmpty {
                PlaceholderScreen(
                    navigationTitle: L10n.Nav.timeline,
                    systemImage: Icon.timeline,
                    title: L10n.Screens.timelineTitle,
                    message: L10n.Screens.timelinePlaceholderMessage
                )
            } else if allLogs.isEmpty {
                EmptyStateView(
                    systemImage: Icon.timeline,
                    title: L10n.Timeline.emptyTitle,
                    message: L10n.Timeline.emptyMessage
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
            } else {
                List {
                    if sortMode == .time {
                        ForEach(dayGroups) { group in
                            Section(header: Text(dayLabel(for: group.day))) {
                                ForEach(group.items, id: \.id) { log in
                                    row(for: log, owner: log.child)
                                }
                            }
                        }
                    } else {
                        ForEach(childGroups, id: \.child.id) { group in
                            Section(header: childSectionHeader(group.child)) {
                                ForEach(group.logs, id: \.id) { log in
                                    row(for: log, owner: nil)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(L10n.Nav.timeline)
        .toolbar {
            if !allLogs.isEmpty {
                ToolbarItem(placement: .principal) {
                    Picker(L10n.Timeline.sortLabel, selection: $sortMode) {
                        ForEach(TimelineSortMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("timeline.sortMode")
                }
            }
        }
        .task(id: childStore.children.map(\.id)) { await reload() }
        .navigationDestination(isPresented: $showingEditScreen) {
            if let editingLog, let child = editingLog.child {
                TemperatureEntryScreen(child: child, existingLog: editingLog) {
                    Task { await reload() }
                }
            }
        }
    }

    private func row(for log: TemperatureLog, owner: Child?) -> some View {
        TemperatureLogRow(log: log, owner: owner)
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

    private func childSectionHeader(_ child: Child) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: ChildAvatarOption(rawValue: child.avatarIdentifier)?.rawValue ?? "star.fill")
                .foregroundStyle((ChildAvatarColorOption(rawValue: child.avatarColorIdentifier) ?? .mint).color(in: palette))
            Text(child.name)
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
        let repository = SwiftDataTemperatureLogRepository(context: modelContext)
        var result: [UUID: [TemperatureLog]] = [:]
        for child in childStore.children {
            result[child.id] = (try? repository.fetchAll(for: child)) ?? []
        }
        logsByChildID = result
    }

    private func duplicate(_ log: TemperatureLog) {
        guard let child = log.child else { return }
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
