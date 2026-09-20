import SwiftData
import SwiftUI

struct HomeScreen: View {
    @Environment(ChildStore.self) private var childStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingAddChild = false
    @State private var showingQuickAdd = false
    @State private var todayLogs: [TemperatureLog] = []
    @State private var todayMedicationLogs: [MedicationLog] = []
    @State private var todaySymptomEntries: [SymptomEntry] = []

    var body: some View {
        Group {
            if childStore.children.isEmpty {
                EmptyStateView(
                    systemImage: Icon.temperature,
                    title: L10n.Home.noChildTitle,
                    message: L10n.Home.noChildMessage
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    PrimaryButton(title: L10n.Home.addChildButton) { showingAddChild = true }
                        .padding(Spacing.lg)
                }
            } else if let selectedChild = childStore.selectedChild {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        NavigationLink(value: selectedChild.id) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(selectedChild.name)
                                    .font(Typography.sectionTitle)
                                    .foregroundStyle(palette.primaryText)
                                TemperatureHeroCard(latestLog: todayLogs.first)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.childCard")

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            SectionHeader(title: L10n.Home.todayTitle)
                            if todayLogs.isEmpty {
                                Text(L10n.Home.todayEmpty)
                                    .font(Typography.body)
                                    .foregroundStyle(palette.secondaryText)
                            } else {
                                ForEach(todayLogs, id: \.id) { log in
                                    TemperatureLogRow(log: log)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            SectionHeader(title: L10n.Home.medicationsTitle)
                            if todayMedicationLogs.isEmpty {
                                Text(L10n.Home.medicationsEmpty)
                                    .font(Typography.body)
                                    .foregroundStyle(palette.secondaryText)
                            } else {
                                ForEach(todayMedicationLogs, id: \.id) { log in
                                    MedicationLogRow(log: log)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            SectionHeader(title: L10n.Home.symptomsTitle)
                            if todaySymptomEntries.isEmpty {
                                Text(L10n.Home.symptomsEmpty)
                                    .font(Typography.body)
                                    .foregroundStyle(palette.secondaryText)
                            } else {
                                ForEach(todaySymptomEntries, id: \.id) { entry in
                                    SymptomEntryRow(entry: entry)
                                }
                            }
                        }
                    }
                    .padding(Spacing.md)
                }
                .safeAreaInset(edge: .bottom) {
                    addButton
                }
            }
        }
        .background(palette.background)
        .navigationDestination(for: UUID.self) { childID in
            if let child = childStore.children.first(where: { $0.id == childID }) {
                ChildProfileScreen(child: child)
            }
        }
        .toolbar {
            if !childStore.children.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    childSelectorMenu
                }
            }
        }
        .sheet(isPresented: $showingAddChild) {
            NavigationStack {
                ChildFormScreen()
            }
        }
        .sheet(isPresented: $showingQuickAdd) {
            if let selectedChild = childStore.selectedChild {
                QuickAddSheet(child: selectedChild) {
                    Task { await reloadTodayData() }
                }
            }
        }
        .task(id: childStore.selectedChildID) { await reloadTodayData() }
    }

    private var addButton: some View {
        Button {
            showingQuickAdd = true
        } label: {
            Image(systemName: Icon.add)
                .font(.system(size: 22, weight: .semibold))
                .frame(width: Spacing.xxl, height: Spacing.xxl)
                .background(palette.accentBlue)
                .foregroundStyle(.white)
                .clipShape(Circle())
        }
        .padding(Spacing.md)
        .accessibilityIdentifier("home.quickAdd")
        .accessibilityLabel(L10n.QuickAdd.title)
    }

    private var childSelectorMenu: some View {
        Menu {
            ForEach(childStore.children, id: \.id) { child in
                Button {
                    childStore.selectedChildID = child.id
                } label: {
                    Label(child.name, systemImage: ChildAvatarOption(rawValue: child.avatarIdentifier)?.rawValue ?? "star.fill")
                }
            }
            Divider()
            Button {
                showingAddChild = true
            } label: {
                Label(L10n.Home.addChildButton, systemImage: Icon.add)
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                if let selectedChild = childStore.selectedChild {
                    Image(systemName: ChildAvatarOption(rawValue: selectedChild.avatarIdentifier)?.rawValue ?? "star.fill")
                        .foregroundStyle(avatarColor(for: selectedChild))
                        .accessibilityHidden(true)
                }
                Text(childStore.selectedChild?.name ?? "")
                    .accessibilityHidden(true)
                Image(systemName: "chevron.down")
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(L10n.Home.childSelectorLabel)
        .accessibilityIdentifier("home.childSelector")
    }

    private func avatarColor(for child: Child) -> Color {
        (ChildAvatarColorOption(rawValue: child.avatarColorIdentifier) ?? .mint).color(in: palette)
    }

    private func reloadTodayData() async {
        guard let child = childStore.selectedChild else {
            todayLogs = []
            todayMedicationLogs = []
            todaySymptomEntries = []
            return
        }
        let calendar = Calendar.current
        do {
            let allTemperatureLogs = try SwiftDataTemperatureLogRepository(context: modelContext).fetchAll(for: child)
            todayLogs = allTemperatureLogs.filter { calendar.isDateInToday($0.recordedAt) }
        } catch {
            todayLogs = []
        }
        do {
            let allMedicationLogs = try SwiftDataMedicationLogRepository(context: modelContext).fetchAll(for: child)
            todayMedicationLogs = allMedicationLogs.filter { calendar.isDateInToday($0.administeredAt) }
        } catch {
            todayMedicationLogs = []
        }
        do {
            let allSymptomEntries = try SwiftDataSymptomEntryRepository(context: modelContext).fetchAll(for: child)
            todaySymptomEntries = allSymptomEntries.filter { calendar.isDateInToday($0.recordedAt) }
        } catch {
            todaySymptomEntries = []
        }
    }
}
