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
    case quickLog(QuickLogEntry)
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
        case .quickLog(let entry): entry.id
        }
    }
}

enum TimelineEditTarget: Identifiable, Hashable {
    case temperature(TemperatureLog, Child)
    case medication(MedicationLog, MedicationRule, Child)
    case symptom(SymptomEntry, Child)
    case note(NoteEntry, Child)
    case quickLog(QuickLogEntry, Child)

    var id: UUID {
        switch self {
        case .temperature(let log, _): log.id
        case .medication(let log, _, _): log.id
        case .symptom(let entry, _): entry.id
        case .note(let entry, _): entry.id
        case .quickLog(let entry, _): entry.id
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
    @State private var errorMessage: String?

    /// How far back `reload()` fetches, in 14-day increments — starts
    /// covering just the most recent window; "Load more" grows it rather
    /// than ever fetching the full, unbounded history at once.
    @State private var windowDays = 14
    @State private var hasMoreHistory = true
    @State private var isLoadingMore = false

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
                    systemImage: Icon.timeline,
                    title: L10n.Screens.timelineTitle,
                    message: L10n.Screens.timelinePlaceholderMessage
                )
            } else if items.isEmpty && !hasMoreHistory {
                // `!hasMoreHistory` matters here: an empty *current window*
                // with older history still available (e.g. nothing logged
                // in the last 14 days but plenty before that) must not be
                // confused with truly no history ever — that's what the
                // "Load more" row below is for instead.
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

                    if hasMoreHistory {
                        loadMoreRow
                    }
                }
                .listStyle(.plain)
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(palette.danger)
            }
        }
        .announcesAccessibilityErrors(errorMessage)
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
            onEdit: { editTarget = $0 },
            onError: { errorMessage = $0 }
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
        case .quickLog(let entry):
            QuickLogEntryRow(entry: entry, owner: owner)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) { actions.quickLog(entry, child: item.child) }
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
        case .quickLog(let entry, _):
            QuickLogEntryEditScreen(existingEntry: entry) {
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

    private var loadMoreRow: some View {
        Button {
            Task { await loadMore() }
        } label: {
            HStack {
                Spacer()
                if isLoadingMore {
                    ProgressView()
                } else {
                    Text(L10n.Timeline.loadMore)
                }
                Spacer()
            }
        }
        .disabled(isLoadingMore)
        .listRowSeparator(.hidden)
        .accessibilityIdentifier("timeline.loadMore")
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
        let cutoff = Calendar.current.date(byAdding: .day, value: -windowDays, to: .now) ?? .now

        let temperatureRepository = SwiftDataTemperatureLogRepository(context: modelContext)
        let medicationRepository = SwiftDataMedicationLogRepository(context: modelContext)
        let symptomRepository = SwiftDataSymptomEntryRepository(context: modelContext)
        let noteRepository = SwiftDataNoteEntryRepository(context: modelContext)
        let quickLogRepository = SwiftDataQuickLogEntryRepository(context: modelContext)

        var result: [TimelineItem] = []
        var moreHistoryExists = false
        for child in childStore.children {
            let temperatureLogs = (try? temperatureRepository.fetchAll(for: child, since: cutoff)) ?? []
            result.append(contentsOf: temperatureLogs.map {
                TimelineItem(child: child, date: $0.recordedAt, kind: .temperature($0))
            })

            let medicationLogs = (try? medicationRepository.fetchAll(for: child, since: cutoff)) ?? []
            result.append(contentsOf: medicationLogs.map {
                TimelineItem(child: child, date: $0.administeredAt, kind: .medication($0))
            })

            let symptomEntries = (try? symptomRepository.fetchAll(for: child, since: cutoff)) ?? []
            result.append(contentsOf: symptomEntries.map {
                TimelineItem(child: child, date: $0.recordedAt, kind: .symptom($0))
            })

            let noteEntries = (try? noteRepository.fetchAll(for: child, since: cutoff)) ?? []
            result.append(contentsOf: noteEntries.map {
                TimelineItem(child: child, date: $0.recordedAt, kind: .note($0))
            })

            let quickLogEntries = (try? quickLogRepository.fetchAll(for: child, since: cutoff)) ?? []
            result.append(contentsOf: quickLogEntries.map {
                TimelineItem(child: child, date: $0.recordedAt, kind: .quickLog($0))
            })

            if !moreHistoryExists {
                moreHistoryExists = (try? temperatureRepository.hasEntry(for: child, before: cutoff)) == true
                    || (try? medicationRepository.hasEntry(for: child, before: cutoff)) == true
                    || (try? symptomRepository.hasEntry(for: child, before: cutoff)) == true
                    || (try? noteRepository.hasEntry(for: child, before: cutoff)) == true
                    || (try? quickLogRepository.hasEntry(for: child, before: cutoff)) == true
            }
        }
        items = result
        hasMoreHistory = moreHistoryExists
    }

    private func loadMore() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        windowDays += 14
        await reload()
        isLoadingMore = false
    }
}
