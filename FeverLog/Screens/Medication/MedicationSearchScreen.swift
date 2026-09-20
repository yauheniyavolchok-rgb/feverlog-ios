import FeverLogEngine
import SwiftUI

struct MedicationSearchScreen: View {
    @Environment(\.feverPalette) private var palette

    let onSelect: (MedicationRule) -> Void

    @State private var query = ""
    @State private var allMedications: [MedicationRule] = []

    private var results: [MedicationRule] {
        MedicationCatalog.search(allMedications, query: query)
    }

    var body: some View {
        Group {
            if results.isEmpty {
                EmptyStateView(
                    systemImage: "cross.case",
                    title: L10n.MedicationSearch.emptyTitle,
                    message: L10n.MedicationSearch.emptyMessage
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
            } else {
                List(results) { rule in
                    Button {
                        onSelect(rule)
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
                    .accessibilityIdentifier("medicationSearch.result.\(rule.id)")
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $query, prompt: L10n.MedicationSearch.searchPlaceholder)
        .navigationTitle(L10n.MedicationSearch.title)
        .task {
            allMedications = MedicationCatalog.loadBundled()
        }
    }
}
