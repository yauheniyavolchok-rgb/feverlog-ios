import FeverLogEngine
import SwiftUI

struct MedicationLibrarySettingsScreen: View {
    @Environment(\.feverPalette) private var palette

    @State private var query = ""
    @State private var allMedications: [MedicationRule] = []

    private var results: [MedicationRule] {
        MedicationCatalog.search(allMedications, query: query)
    }

    var body: some View {
        // A `List`/`NavigationLink`-pushed destination nested inside the
        // Settings tab's `NavigationStack` (rather than at its root) does
        // not reliably surface a `.searchable()` search bar — confirmed via
        // UI test: the search field never appeared in the accessibility
        // tree despite the modifier being attached correctly. A plain
        // `TextField` search row sidesteps that platform quirk.
        List {
            Section {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(palette.secondaryText)
                        .accessibilityHidden(true)
                    TextField(L10n.MedicationLibrarySettings.searchPlaceholder, text: $query)
                        .accessibilityIdentifier("medicationLibrarySettings.search")
                }
            }

            if results.isEmpty {
                Section {
                    EmptyStateView(
                        systemImage: "cross.case",
                        title: L10n.MedicationLibrarySettings.emptyTitle,
                        message: L10n.MedicationLibrarySettings.emptyMessage
                    )
                }
            } else {
                Section {
                    ForEach(results) { rule in
                        NavigationLink {
                            MedicationLibraryDetailScreen(rule: rule)
                        } label: {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(rule.brand)
                                    .font(Typography.body.weight(.semibold))
                                    .foregroundStyle(palette.primaryText)
                                Text("\(rule.activeIngredient) · \(rule.strength)")
                                    .font(Typography.caption)
                                    .foregroundStyle(palette.secondaryText)
                            }
                        }
                        .accessibilityIdentifier("medicationLibrarySettings.result.\(rule.id)")
                    }
                }
            }
        }
        .navigationTitle(L10n.MedicationLibrarySettings.title)
        .task {
            allMedications = MedicationCatalog.loadBundled()
        }
    }
}

private struct MedicationLibraryDetailScreen: View {
    @Environment(\.feverPalette) private var palette

    let rule: MedicationRule

    var body: some View {
        List {
            Section {
                LabeledContent(L10n.MedicationLibrarySettings.brandLabel, value: rule.brand)
                LabeledContent(L10n.MedicationLibrarySettings.activeIngredientLabel, value: rule.activeIngredient)
                LabeledContent(L10n.MedicationLibrarySettings.strengthLabel, value: rule.strength)
                LabeledContent(L10n.MedicationLibrarySettings.formLabel, value: rule.form)
            }

            Section(L10n.MedicationLibrarySettings.singleDoseTitle) {
                if let rule = rule.singleDoseRule {
                    doseRuleRows(rule)
                } else {
                    Text(L10n.MedicationLibrarySettings.notConfigured)
                        .foregroundStyle(palette.secondaryText)
                }
            }

            Section(L10n.MedicationLibrarySettings.dailyMaximumTitle) {
                if let rule = rule.dailyMaximumRule {
                    dailyMaximumRows(rule)
                } else {
                    Text(L10n.MedicationLibrarySettings.notConfigured)
                        .foregroundStyle(palette.secondaryText)
                }
            }

            Section {
                LabeledContent(L10n.MedicationLibrarySettings.sourceLabel, value: "\(rule.sourceIdentifier) (\(rule.sourceVersion))")
            }
        }
        .navigationTitle(rule.brand)
    }

    @ViewBuilder
    private func doseRuleRows(_ rule: FeverLogEngine.SingleDoseRule) -> some View {
        if let value = rule.minMilligramsPerKilogram {
            LabeledContent(L10n.MedicationLibrarySettings.minLabel, value: "\(value) mg/kg")
        }
        if let value = rule.maxMilligramsPerKilogram {
            LabeledContent(L10n.MedicationLibrarySettings.maxLabel, value: "\(value) mg/kg")
        }
        if let value = rule.maxMilligramsPerDose {
            LabeledContent(L10n.MedicationLibrarySettings.maxPerDoseLabel, value: "\(value) mg")
        }
    }

    @ViewBuilder
    private func dailyMaximumRows(_ rule: FeverLogEngine.DailyMaximumRule) -> some View {
        if let value = rule.maxMilligramsPerKilogramPerDay {
            LabeledContent(L10n.MedicationLibrarySettings.maxPerDayPerKgLabel, value: "\(value) mg/kg/day")
        }
        if let value = rule.maxMilligramsPerDay {
            LabeledContent(L10n.MedicationLibrarySettings.maxPerDayLabel, value: "\(value) mg/day")
        }
        if let value = rule.maxDosesPerDay {
            LabeledContent(L10n.MedicationLibrarySettings.maxDosesPerDayLabel, value: "\(value)")
        }
        if let value = rule.minimumIntervalSeconds {
            LabeledContent(L10n.MedicationLibrarySettings.minIntervalLabel, value: "\(Int(value / 3600))h")
        }
    }
}

#Preview {
    NavigationStack { MedicationLibrarySettingsScreen() }
        .feverThemed()
}
