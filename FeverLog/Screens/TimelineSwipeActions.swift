import FeverLogEngine
import SwiftData
import SwiftUI

/// Swipe-action buttons for each timeline entry type. Extracted from
/// `TimelineScreen` purely to keep that type's body within SwiftLint's
/// length limit — this still operates directly on the same model context
/// and calls back into the screen for reload/edit-navigation.
@MainActor
struct TimelineSwipeActions {
    let modelContext: ModelContext
    let palette: ColorPalette
    let medications: [MedicationRule]
    let onReload: () -> Void
    let onEdit: (TimelineEditTarget) -> Void

    @ViewBuilder
    func temperature(_ log: TemperatureLog, child: Child) -> some View {
        Button(role: .destructive) {
            try? SwiftDataTemperatureLogRepository(context: modelContext).softDelete(log)
            onReload()
        } label: {
            Label(L10n.Timeline.delete, systemImage: "trash")
        }
        Button {
            let repository = SwiftDataTemperatureLogRepository(context: modelContext)
            _ = try? repository.create(
                temperatureCelsius: log.temperatureCelsius,
                measurementMethod: log.measurementMethod,
                recordedAt: .now,
                note: log.note,
                child: child
            )
            onReload()
        } label: {
            Label(L10n.Timeline.duplicate, systemImage: "plus.square.on.square")
        }
        .tint(palette.accentBlue)
        Button {
            onEdit(.temperature(log, child))
        } label: {
            Label(L10n.Timeline.edit, systemImage: "pencil")
        }
        .tint(palette.accentLavender)
    }

    @ViewBuilder
    func medication(_ log: MedicationLog, child: Child) -> some View {
        Button(role: .destructive) {
            try? SwiftDataMedicationLogRepository(context: modelContext).softDelete(log)
            onReload()
        } label: {
            Label(L10n.Timeline.delete, systemImage: "trash")
        }
        Button {
            duplicateMedication(log, child: child)
        } label: {
            Label(L10n.Timeline.duplicate, systemImage: "plus.square.on.square")
        }
        .tint(palette.accentBlue)
        if let rule = medications.first(where: { $0.id == log.medicationDefinitionID }) {
            Button {
                onEdit(.medication(log, rule, child))
            } label: {
                Label(L10n.Timeline.edit, systemImage: "pencil")
            }
            .tint(palette.accentLavender)
        }
    }

    @ViewBuilder
    func symptom(_ entry: SymptomEntry, child: Child) -> some View {
        Button(role: .destructive) {
            try? SwiftDataSymptomEntryRepository(context: modelContext).softDelete(entry)
            onReload()
        } label: {
            Label(L10n.Timeline.delete, systemImage: "trash")
        }
        Button {
            let repository = SwiftDataSymptomEntryRepository(context: modelContext)
            _ = try? repository.create(symptomIdentifiers: entry.symptomIdentifiers, recordedAt: .now, child: child)
            onReload()
        } label: {
            Label(L10n.Timeline.duplicate, systemImage: "plus.square.on.square")
        }
        .tint(palette.accentBlue)
        Button {
            onEdit(.symptom(entry, child))
        } label: {
            Label(L10n.Timeline.edit, systemImage: "pencil")
        }
        .tint(palette.accentLavender)
    }

    @ViewBuilder
    func note(_ entry: NoteEntry, child: Child) -> some View {
        Button(role: .destructive) {
            try? SwiftDataNoteEntryRepository(context: modelContext).softDelete(entry)
            onReload()
        } label: {
            Label(L10n.Timeline.delete, systemImage: "trash")
        }
        Button {
            let repository = SwiftDataNoteEntryRepository(context: modelContext)
            _ = try? repository.create(text: entry.text, recordedAt: .now, child: child)
            onReload()
        } label: {
            Label(L10n.Timeline.duplicate, systemImage: "plus.square.on.square")
        }
        .tint(palette.accentBlue)
        Button {
            onEdit(.note(entry, child))
        } label: {
            Label(L10n.Timeline.edit, systemImage: "pencil")
        }
        .tint(palette.accentLavender)
    }

    private func duplicateMedication(_ log: MedicationLog, child: Child) {
        let newLog = MedicationLog(
            child: child,
            medicationDefinitionID: log.medicationDefinitionID,
            activeIngredientSnapshot: log.activeIngredientSnapshot,
            concentrationValueSnapshot: log.concentrationValueSnapshot,
            concentrationMillilitersSnapshot: log.concentrationMillilitersSnapshot,
            concentrationUnitSnapshot: log.concentrationUnitSnapshot,
            formSnapshot: log.formSnapshot,
            brandSnapshot: log.brandSnapshot,
            ruleVersionSnapshot: log.ruleVersionSnapshot,
            sourceVersionSnapshot: log.sourceVersionSnapshot,
            volumeMilliliters: log.volumeMilliliters,
            calculatedMilligrams: log.calculatedMilligrams,
            calculatedMilligramsPerKilogram: log.calculatedMilligramsPerKilogram,
            weightUsedForCalculation: log.weightUsedForCalculation,
            weightUnitUsedForCalculation: log.weightUnitUsedForCalculation,
            calculationStatus: log.calculationStatus,
            administeredAt: .now
        )
        try? SwiftDataMedicationLogRepository(context: modelContext).create(newLog)
        onReload()
    }
}
