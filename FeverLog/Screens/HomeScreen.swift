import SwiftData
import SwiftUI

// TODO(Phase 4, Home medication summary): Replace temporary medication countdown content after Phase 6.
// Completion: Home displays medication information derived from local medication records and the safety engine.
// Release blocker: yes if placeholder medication content remains visible in a release.
// TODO(Phase 4, Home symptom summary): Replace temporary symptom chips after Phase 7.
// Completion: Home displays locally stored symptom information or an explicit empty state.
// Release blocker: yes if placeholder symptom content remains visible in a release.
struct HomeScreen: View {
    @Environment(ChildStore.self) private var childStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingAddChild = false
    @State private var showingQuickAdd = false
    @State private var todayLogs: [TemperatureLog] = []

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
                        Text(greetingText(for: selectedChild))
                            .font(Typography.screenTitle)
                            .foregroundStyle(palette.primaryText)
                            .accessibilityAddTraits(.isHeader)

                        NavigationLink(value: selectedChild.id) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(selectedChild.name)
                                    .font(Typography.sectionTitle)
                                    .foregroundStyle(palette.primaryText)
                                TemperatureHeroCard(latestLog: todayLogs.first)
                            }
                        }
                        .buttonStyle(.plain)

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
                    }
                    .padding(Spacing.md)
                }
                .safeAreaInset(edge: .bottom) {
                    addButton
                }
            }
        }
        .background(palette.background)
        .navigationTitle(L10n.Nav.home)
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
                    Task { await reloadTodayLogs() }
                }
            }
        }
        .task(id: childStore.selectedChildID) { await reloadTodayLogs() }
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
                Button(child.name) {
                    childStore.selectedChildID = child.id
                }
            }
            Divider()
            Button {
                showingAddChild = true
            } label: {
                Label(L10n.Home.addChildButton, systemImage: Icon.add)
            }
        } label: {
            Label(childStore.selectedChild?.name ?? "", systemImage: "chevron.down")
        }
        .accessibilityLabel(L10n.Home.childSelectorLabel)
        .accessibilityIdentifier("home.childSelector")
    }

    private func greetingText(for child: Child) -> String {
        "\(GreetingProvider.greeting().localized), \(child.name.isEmpty ? "" : child.name)"
    }

    private func reloadTodayLogs() async {
        guard let child = childStore.selectedChild else {
            todayLogs = []
            return
        }
        do {
            let all = try SwiftDataTemperatureLogRepository(context: modelContext).fetchAll(for: child)
            let calendar = Calendar.current
            todayLogs = all.filter { calendar.isDateInToday($0.recordedAt) }
        } catch {
            todayLogs = []
        }
    }
}
