import SwiftData
import SwiftUI

struct WeightEntryFormScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette
    @Environment(UnitsManager.self) private var unitsManager

    let child: Child
    let onSaved: () -> Void

    @State private var weightValue: Double = 5.0
    @State private var unit: WeightUnit = .kilograms
    @State private var effectiveDate: Date = .now
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(L10n.WeightForm.valueLabel)
                    Spacer()
                    TextField(
                        L10n.WeightForm.valueLabel,
                        value: $weightValue,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("weightForm.value")
                }

                Picker(L10n.WeightForm.unitLabel, selection: $unit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue.capitalized).tag(unit)
                    }
                }
                .accessibilityIdentifier("weightForm.unit")

                DatePicker(L10n.WeightForm.effectiveDateLabel, selection: $effectiveDate, in: ...Date.now, displayedComponents: .date)
                    .accessibilityIdentifier("weightForm.effectiveDate")
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(palette.danger)
            }
        }
        .navigationTitle(L10n.WeightForm.title)
        .announcesAccessibilityErrors(errorMessage)
        .task { unit = unitsManager.defaultWeightUnit }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.WeightForm.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.WeightForm.save, action: save)
                    .disabled(weightValue <= 0)
                    .accessibilityIdentifier("weightForm.save")
            }
        }
    }

    private func save() {
        do {
            let repository = SwiftDataWeightHistoryRepository(context: modelContext)
            _ = try repository.addWeight(weightValue, unit: unit, effectiveDate: effectiveDate, child: child)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
