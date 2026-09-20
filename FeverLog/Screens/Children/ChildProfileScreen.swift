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
    @State private var insights: ChildFeverInsightsSummary?
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
                insightsContent
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

    @ViewBuilder
    private var insightsContent: some View {
        if let insights, insights.hasAnyReadings {
            insightRow(L10n.ChildProfile.insightSpikeCount, value: "\(insights.spikeCount)")
            insightRow(L10n.ChildProfile.insightFeverDuration, value: durationText(insights.totalFeverDuration))
            insightRow(
                L10n.ChildProfile.insightFeverFreeInterval,
                value: insights.longestFeverFreeInterval.map(durationText) ?? L10n.ChildProfile.insightInsufficientData
            )
            insightRow(
                L10n.ChildProfile.insightTemperatureChange,
                value: insights.temperatureChangeOverFourHours.map(changeText) ?? L10n.ChildProfile.insightInsufficientData
            )
        } else {
            Text(L10n.ChildProfile.recentIllnessNoReadings)
                .foregroundStyle(palette.secondaryText)
        }
    }

    private func insightRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(palette.primaryText)
            Spacer()
            Text(value)
                .foregroundStyle(palette.secondaryText)
        }
    }

    private func durationText(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: interval) ?? "0m"
    }

    private func changeText(_ change: Double) -> String {
        String(format: "%+.1f°C", change)
    }

    private func onEditFormDismissed() {
        Task { await loadData() }
    }

    private func loadData() async {
        do {
            let weightRepository = SwiftDataWeightHistoryRepository(context: modelContext)
            activeWeight = try weightRepository.activeWeight(for: child, at: .now)
            weightHistory = try weightRepository.fetchHistory(for: child)

            let insightsProvider = SwiftDataChildFeverInsightsProvider(context: modelContext)
            insights = try insightsProvider.summary(for: child, withinDays: 30)
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
