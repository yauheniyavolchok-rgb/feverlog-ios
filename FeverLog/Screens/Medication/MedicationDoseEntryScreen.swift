import FeverLogEngine
import SwiftData
import SwiftUI
import UIKit

struct MedicationDoseEntryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    let child: Child
    let rule: MedicationRule
    /// Non-nil when editing an existing log — editing only ever recalculates
    /// and rewrites this one record's own snapshot.
    var existingLog: MedicationLog?
    var onSaved: () -> Void = {}

    @State private var volumeMilliliters: Decimal
    @State private var administrationTime: Date
    @State private var evaluation: MedicationSafetyResult?
    @State private var resolvedWeightKilograms: Decimal?
    @State private var showingConfirmation = false
    @State private var errorMessage: String?

    init(child: Child, rule: MedicationRule, existingLog: MedicationLog? = nil, onSaved: @escaping () -> Void = {}) {
        self.child = child
        self.rule = rule
        self.existingLog = existingLog
        self.onSaved = onSaved
        _volumeMilliliters = State(initialValue: existingLog.map { Decimal.fromUserInput($0.volumeMilliliters) } ?? 0)
        _administrationTime = State(initialValue: existingLog?.administeredAt ?? .now)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(rule.brand)
                        .font(Typography.body.weight(.semibold))
                    Text("\(rule.activeIngredient) · \(rule.strength)")
                        .font(Typography.caption)
                        .foregroundStyle(palette.secondaryText)
                }
            }

            Section {
                HStack {
                    Text(L10n.MedicationEntry.volumeLabel)
                    Spacer()
                    TextField(
                        L10n.MedicationEntry.volumeLabel,
                        value: $volumeMilliliters,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("medicationEntry.volume")
                    .onChange(of: volumeMilliliters) { _, _ in recalculate() }
                }

                DatePicker(L10n.MedicationEntry.dateLabel, selection: $administrationTime, in: ...Date.now)
                    .accessibilityIdentifier("medicationEntry.date")
                    .onChange(of: administrationTime) { _, _ in recalculate() }
            }

            if let evaluation {
                Section(L10n.MedicationEntry.calculationTitle) {
                    if let milligrams = evaluation.calculatedMilligrams {
                        labeledRow(L10n.MedicationEntry.milligramsLabel, value: String(format: "%.1f mg", milligrams.doubleValue))
                    }
                    if let mgPerKg = evaluation.calculatedMilligramsPerKilogram {
                        labeledRow(
                            L10n.MedicationEntry.milligramsPerKilogramLabel,
                            value: String(format: "%.1f mg/kg", mgPerKg.doubleValue)
                        )
                    }
                    if let range = recommendedRangeText {
                        labeledRow(L10n.MedicationEntry.recommendedRangeLabel, value: range)
                    }
                }

                Section(L10n.MedicationEntry.safetyTitle) {
                    MedicationSafetyCard(result: evaluation)
                        .accessibilityIdentifier("medicationEntry.safetyCard")
                }
            }

            Section {
                Text(L10n.MedicationSafety.disclaimer)
                    .font(Typography.caption)
                    .foregroundStyle(palette.secondaryText)
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(palette.danger)
            }
        }
        .navigationTitle(existingLog == nil ? L10n.MedicationEntry.addTitle : L10n.MedicationEntry.editTitle)
        .announcesAccessibilityErrors(errorMessage)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.MedicationEntry.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.MedicationEntry.save, action: attemptSave)
                    .disabled(!canSave)
                    .accessibilityIdentifier("medicationEntry.save")
            }
        }
        .task { recalculate() }
        .confirmationDialog(
            L10n.MedicationEntry.confirmTitle,
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.MedicationEntry.confirmSave, role: .destructive, action: performSave)
            Button(L10n.MedicationEntry.confirmCancel, role: .cancel) {}
        } message: {
            Text(L10n.MedicationEntry.confirmMessage)
        }
    }

    private func labeledRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(palette.secondaryText)
        }
    }

    private var recommendedRangeText: String? {
        guard let singleDose = rule.singleDoseRule,
              let min = singleDose.minMilligramsPerKilogram,
              let max = singleDose.maxMilligramsPerKilogram
        else { return nil }
        return String(format: "%.1f–%.1f mg/kg", min.doubleValue, max.doubleValue)
    }

    private var canSave: Bool {
        guard let evaluation else { return false }
        return !evaluation.statuses.contains(.invalidInput)
    }

    private var requiresConfirmation: Bool {
        guard let evaluation else { return false }
        return !evaluation.statuses.isDisjoint(with: [.maximumExceeded, .unusualDose, .intervalWarning])
    }

    private func recalculate() {
        do {
            let weightRepository = SwiftDataWeightHistoryRepository(context: modelContext)
            let activeWeight = try weightRepository.activeWeight(for: child, at: administrationTime)
            let weightInput = MedicationDoseInputMapper.weightInput(from: activeWeight)
            if case .known(let kilograms) = weightInput {
                resolvedWeightKilograms = kilograms
            } else {
                resolvedWeightKilograms = nil
            }

            let medicationLogRepository = SwiftDataMedicationLogRepository(context: modelContext)
            let allLogs = try medicationLogRepository.fetchAll(for: child)
            let otherLogs = allLogs.filter { $0.id != existingLog?.id }
            let priorDoses = MedicationDoseInputMapper.priorDoseAdministrations(from: otherLogs)

            let input = MedicationDoseEvaluationInput(
                rule: rule,
                volumeMilliliters: volumeMilliliters,
                weight: weightInput,
                administrationTime: administrationTime,
                priorDoses: priorDoses
            )
            evaluation = MedicationSafetyEngine.evaluate(input)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func attemptSave() {
        guard canSave else { return }
        if requiresConfirmation {
            showingConfirmation = true
        } else {
            performSave()
        }
    }

    private func performSave() {
        guard let evaluation else { return }
        let status = calculationStatus(for: evaluation)

        do {
            let repository = SwiftDataMedicationLogRepository(context: modelContext)
            if let existingLog {
                existingLog.volumeMilliliters = volumeMilliliters.doubleValue
                existingLog.administeredAt = administrationTime
                existingLog.calculatedMilligrams = evaluation.calculatedMilligrams?.doubleValue
                existingLog.calculatedMilligramsPerKilogram = evaluation.calculatedMilligramsPerKilogram?.doubleValue
                existingLog.weightUsedForCalculation = resolvedWeightKilograms?.doubleValue
                existingLog.weightUnitUsedForCalculation = resolvedWeightKilograms != nil ? .kilograms : nil
                existingLog.calculationStatus = status
                try repository.update(existingLog)
            } else {
                let log = MedicationLog(
                    child: child,
                    medicationDefinitionID: rule.id,
                    activeIngredientSnapshot: rule.activeIngredient,
                    concentrationValueSnapshot: rule.concentration.milligrams.doubleValue,
                    concentrationMillilitersSnapshot: rule.concentration.milliliters.doubleValue,
                    concentrationUnitSnapshot: "mg/mL",
                    formSnapshot: rule.form,
                    brandSnapshot: rule.brand,
                    ruleVersionSnapshot: "\(rule.databaseSchemaVersion)",
                    sourceVersionSnapshot: rule.sourceVersion,
                    volumeMilliliters: volumeMilliliters.doubleValue,
                    calculatedMilligrams: evaluation.calculatedMilligrams?.doubleValue,
                    calculatedMilligramsPerKilogram: evaluation.calculatedMilligramsPerKilogram?.doubleValue,
                    weightUsedForCalculation: resolvedWeightKilograms?.doubleValue,
                    weightUnitUsedForCalculation: resolvedWeightKilograms != nil ? .kilograms : nil,
                    calculationStatus: status,
                    administeredAt: administrationTime
                )
                try repository.create(log)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func calculationStatus(for result: MedicationSafetyResult) -> MedicationCalculationStatus {
        if result.statuses.contains(.invalidInput) { return .invalidInput }
        if result.statuses.contains(.missingWeight) { return .missingWeight }
        if result.statuses.contains(.missingRule) { return .missingRule }
        return .calculated
    }
}
