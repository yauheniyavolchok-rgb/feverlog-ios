import FeverLogEngine
import SwiftUI

struct MedicationSafetyCard: View {
    @Environment(\.feverPalette) private var palette

    let result: MedicationSafetyResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(orderedStatuses, id: \.self) { status in
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Image(systemName: symbol(for: status))
                        .foregroundStyle(color(for: status))
                    Text(text(for: status))
                        .font(Typography.caption)
                        .foregroundStyle(palette.primaryText)
                }
            }

            if let doseCount = result.doseCount {
                labeledRow(L10n.MedicationSafety.doseCountLabel, value: "\(doseCount)")
            }
            if let rollingTotal = result.rollingTotalMilligrams {
                labeledRow(L10n.MedicationSafety.rollingTotalLabel, value: String(format: "%.0f mg", rollingTotal.doubleValue))
            }
            if let nextEligibleDate = result.nextEligibleDate {
                labeledRow(L10n.MedicationSafety.nextEligibleLabel, value: nextEligibleDate.formatted(date: .omitted, time: .shortened))
            }
        }
        .padding(Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    private func labeledRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(palette.secondaryText)
            Spacer()
            Text(value)
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(palette.primaryText)
        }
    }

    /// Deterministic, most-severe-first ordering for display — the engine's
    /// `statuses` is an unordered `Set`.
    private var orderedStatuses: [MedicationSafetyStatus] {
        let priority: [MedicationSafetyStatus] = [
            .invalidInput,
            .maximumExceeded,
            .unusualDose,
            .intervalWarning,
            .approachingMaximum,
            .missingWeight,
            .missingRule,
            .normal
        ]
        return priority.filter { result.statuses.contains($0) }
    }

    private func text(for status: MedicationSafetyStatus) -> String {
        switch status {
        case .normal: L10n.MedicationSafety.statusNormal
        case .missingWeight: L10n.MedicationSafety.statusMissingWeight
        case .missingRule: L10n.MedicationSafety.statusMissingRule
        case .intervalWarning: L10n.MedicationSafety.statusIntervalWarning
        case .approachingMaximum: L10n.MedicationSafety.statusApproachingMaximum
        case .unusualDose: L10n.MedicationSafety.statusUnusualDose
        case .maximumExceeded: L10n.MedicationSafety.statusMaximumExceeded
        case .invalidInput: L10n.MedicationSafety.statusInvalidInput
        }
    }

    private func symbol(for status: MedicationSafetyStatus) -> String {
        switch status {
        case .normal: "checkmark.circle.fill"
        case .missingWeight, .missingRule: "questionmark.circle.fill"
        case .intervalWarning, .approachingMaximum: "exclamationmark.triangle.fill"
        case .unusualDose, .maximumExceeded, .invalidInput: "xmark.octagon.fill"
        }
    }

    private func color(for status: MedicationSafetyStatus) -> Color {
        switch status {
        case .normal: palette.success
        case .missingWeight, .missingRule: palette.secondaryText
        case .intervalWarning, .approachingMaximum: palette.warning
        case .unusualDose, .maximumExceeded, .invalidInput: palette.danger
        }
    }
}
