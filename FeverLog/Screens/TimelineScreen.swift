import FeverLogEngine
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

/// One row's worth of timeline content, regardless of which underlying
/// SwiftData record it came from. Cards distinguish entry types by icon and
/// accent color together — never color alone.
enum TimelineItemKind {
    case temperature(TemperatureLog)
    case medication(MedicationLog)
    case symptom(SymptomEntry)
    case note(NoteEntry)
}

struct TimelineItem: Identifiable {
    let child: Child
    let date: Date
    let kind: TimelineItemKind

    var id: UUID {
        switch kind {
        case .temperature(let log): log.id
        case .medication(let log): log.id
        case .symptom(let entry): entry.id
        case .note(let entry): entry.id
        }
    }
}

enum TimelineEditTarget: Identifiable, Hashable {
    case temperature(TemperatureLog, Child)
    case medication(MedicationLog, MedicationRule, Child)
    case symptom(SymptomEntry, Child)
    case note(NoteEntry, Child)

    var id: UUID {
        switch self {
        case .temperature(let log, _): log.id
        case .medication(let log, _, _): log.id
        case .symptom(let entry, _): entry.id
        case .note(let entry, _): entry.id
        }
    }

    static func == (lhs: TimelineEditTarget, rhs: TimelineEditTarget) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct TimelineScreen: View {
    @Environment(ChildStore.self) private var childStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    @State private var items: [TimelineItem] = []
    @State private var medications: [MedicationRule] = []
    @State private var sortMode: TimelineSortMode = .time
    @State private var editTarget: TimelineEditTarget?

    private var dayGroups: [TimelineDayGroup<TimelineItem>] {
        TimelineGrouping.groupByDay(items, date: \.date)
    }

    private var childGroups: [(child: Child, items: [TimelineItem])] {
        childStore.children.compactMap { child in
            let childItems = items.filter { $0.child.id == child.id }.sorted { $0.date > $1.date }
            guard !childItems.isEmpty else { return nil }
            return (child, childItems)
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
            } else if items.isEmpty {
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
                                ForEach(group.items) { item in
                                    row(for: item, showOwner: true)
                                }
                            }
                        }
                    } else {
                        ForEach(childGroups, id: \.child.id) { group in
                            Section(header: childSectionHeader(group.child)) {
                                ForEach(group.items) { item in
                                    row(for: item, showOwner: false)
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
            if !items.isEmpty {
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
        .navigationDestination(item: $editTarget) { target in
            editDestination(for: target)
        }
    }

    private var swipeActions: TimelineSwipeActions {
        TimelineSwipeActions(
            modelContext: modelContext,
            palette: palette,
            medications: medications,
            onReload: { Task { await reload() } },
            onEdit: { editTarget = $0 }
        )
    }

    @ViewBuilder
    private func row(for item: TimelineItem, showOwner: Bool) -> some View {
        let owner = showOwner ? item.child : nil
        let actions = swipeActions
        switch item.kind {
        case .temperature(let log):
            TemperatureLogRow(log: log, owner: owner)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) { actions.temperature(log, child: item.child) }
        case .medication(let log):
            MedicationLogRow(log: log, owner: owner)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) { actions.medication(log, child: item.child) }
        case .symptom(let entry):
            SymptomEntryRow(entry: entry, owner: owner)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) { actions.symptom(entry, child: item.child) }
        case .note(let entry):
            NoteEntryRow(entry: entry, owner: owner)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) { actions.note(entry, child: item.child) }
        }
    }

    @ViewBuilder
    private func editDestination(for target: TimelineEditTarget) -> some View {
        switch target {
        case .temperature(let log, let child):
            TemperatureEntryScreen(child: child, existingLog: log) {
                Task { await reload() }
            }
        case .medication(let log, let rule, let child):
            MedicationDoseEntryScreen(child: child, rule: rule, existingLog: log) {
                Task { await reload() }
            }
        case .symptom(let entry, let child):
            SymptomEntryScreen(child: child, existingEntry: entry) {
                Task { await reload() }
            }
        case .note(let entry, let child):
            NoteEntryScreen(child: child, existingEntry: entry) {
                Task { await reload() }
            }
        }
    }

    // MARK: - Section headers / labels

    private func childSectionHeader(_ child: Child) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: ChildAvatarOption(rawValue: child.avatarIdentifier)?.rawValue ?? "star.fill")
                .foregroundStyle((ChildAvatarColorOption(rawValue: child.avatarColorIdentifier) ?? .mint).color(in: palette))
            Text(child.name)
        }
    }

    private func dayLabel(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return L10n.Timeline.today }
        if calendar.isDateInYesterday(day) { return L10n.Timeline.yesterday }
        return day.formatted(.dateTime.month(.wide).day().year())
    }

    // MARK: - Data loading

    private func reload() async {
        medications = MedicationCatalog.loadBundled()

        let temperatureRepository = SwiftDataTemperatureLogRepository(context: modelContext)
        let medicationRepository = SwiftDataMedicationLogRepository(context: modelContext)
        let symptomRepository = SwiftDataSymptomEntryRepository(context: modelContext)
        let noteRepository = SwiftDataNoteEntryRepository(context: modelContext)

        var result: [TimelineItem] = []
        for child in childStore.children {
            let temperatureLogs = (try? temperatureRepository.fetchAll(for: child)) ?? []
            result.append(contentsOf: temperatureLogs.map {
                TimelineItem(child: child, date: $0.recordedAt, kind: .temperature($0))
            })

            let medicationLogs = (try? medicationRepository.fetchAll(for: child)) ?? []
            result.append(contentsOf: medicationLogs.map {
                TimelineItem(child: child, date: $0.administeredAt, kind: .medication($0))
            })

            let symptomEntries = (try? symptomRepository.fetchAll(for: child)) ?? []
            result.append(contentsOf: symptomEntries.map {
                TimelineItem(child: child, date: $0.recordedAt, kind: .symptom($0))
            })

            let noteEntries = (try? noteRepository.fetchAll(for: child)) ?? []
            result.append(contentsOf: noteEntries.map {
                TimelineItem(child: child, date: $0.recordedAt, kind: .note($0))
            })
        }
        items = result
    }
}
