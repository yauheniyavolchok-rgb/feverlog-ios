import SwiftData
import SwiftUI

struct ChildProfileScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ChildStore.self) private var childStore
    @Environment(\.feverPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    let child: Child

    @State private var activeWeight: WeightHistory?
    @State private var weightHistory: [WeightHistory] = []
    @State private var illnessSummary: RecentIllnessSummary = .noRecentReadings
    @State private var showingEditForm = false
    @State private var showingAddWeight = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                HStack(spacing: Spacing.md) {
                    Image(systemName: ChildAvatarOption(rawValue: child.avatarIdentifier)?.rawValue ?? "star.fill")
                        .font(.system(size: 28))
                        .frame(width: Spacing.xxl, height: Spacing.xxl)
                        .background(avatarColor.opacity(0.3))
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(child.name)
                            .font(Typography.sectionTitle)
                            .foregroundStyle(palette.primaryText)
                        Text(ageText)
                            .font(Typography.body)
                            .foregroundStyle(palette.secondaryText)
                    }
                }
                .accessibilityElement(children: .combine)
            }

            Section(L10n.ChildProfile.weightLabel) {
                HStack {
                    Text(weightText)
                        .foregroundStyle(palette.primaryText)
                    Spacer()
                    Button(L10n.ChildProfile.weightAddButton) { showingAddWeight = true }
                        .accessibilityIdentifier("childProfile.addWeight")
                }

                if weightHistory.isEmpty {
                    Text(L10n.ChildProfile.weightHistoryEmpty)
                        .foregroundStyle(palette.secondaryText)
                } else {
                    ForEach(weightHistory, id: \.id) { entry in
                        HStack {
                            Text(entry.effectiveDate, style: .date)
                            Spacer()
                            Text("\(entry.weight, specifier: "%.1f") \(entry.unit.rawValue)")
                        }
                        .foregroundStyle(palette.secondaryText)
                    }
                }
            }

            Section(L10n.ChildProfile.recentIllnessTitle) {
                Text(illnessSummaryText)
                    .foregroundStyle(palette.secondaryText)
            }

            Section {
                Button(L10n.ChildProfile.editButton) { showingEditForm = true }
                    .accessibilityIdentifier("childProfile.edit")
                Button(L10n.ChildProfile.deleteButton, role: .destructive) { showingDeleteConfirmation = true }
                    .accessibilityIdentifier("childProfile.delete")
            }
        }
        .navigationTitle(child.name)
        .task { await loadData() }
        .sheet(isPresented: $showingEditForm, onDismiss: onEditFormDismissed) {
            NavigationStack {
                ChildFormScreen(existingChild: child)
            }
        }
        .sheet(isPresented: $showingAddWeight) {
            NavigationStack {
                WeightEntryFormScreen(child: child) {
                    Task { await loadData() }
                }
            }
        }
        .confirmationDialog(
            L10n.ChildProfile.deleteConfirmTitle,
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.ChildProfile.deleteConfirmConfirm, role: .destructive, action: deleteChild)
            Button(L10n.ChildProfile.deleteConfirmCancel, role: .cancel) {}
        } message: {
            Text(L10n.ChildProfile.deleteConfirmMessage)
        }
    }

    private var avatarColor: Color {
        (ChildAvatarColorOption(rawValue: child.avatarColorIdentifier) ?? .mint).color(in: palette)
    }

    private var ageText: String {
        let age = AgeCalculator.age(from: child.birthday)
        return "\(L10n.ChildProfile.ageYears(age.years)) \(L10n.ChildProfile.ageMonths(age.months))"
    }

    private var weightText: String {
        guard let activeWeight else { return L10n.ChildProfile.weightMissing }
        return String(format: "%.1f %@", activeWeight.weight, activeWeight.unit.rawValue)
    }

    private var illnessSummaryText: String {
        switch illnessSummary {
        case .noRecentReadings:
            L10n.ChildProfile.recentIllnessNoReadings
        case .elevatedReadings(let count, let days):
            L10n.ChildProfile.recentIllnessElevated(count, days)
        }
    }

    private func onEditFormDismissed() {
        Task { await loadData() }
    }

    private func loadData() async {
        do {
            let weightRepository = SwiftDataWeightHistoryRepository(context: modelContext)
            activeWeight = try weightRepository.activeWeight(for: child, at: .now)
            weightHistory = try weightRepository.fetchHistory(for: child)

            let illnessProvider = SwiftDataRecentIllnessSummaryProvider(context: modelContext)
            illnessSummary = try illnessProvider.summary(for: child, withinDays: 7)
        } catch {
            // Non-fatal: leave prior state, surfaced only via empty/missing states.
        }
    }

    private func deleteChild() {
        do {
            try childStore.softDelete(child)
            dismiss()
        } catch {
            // Non-fatal: the confirmation dialog can be reopened to retry.
        }
    }
}
