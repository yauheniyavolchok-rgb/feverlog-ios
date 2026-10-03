import FeverLogEngine
import SwiftData
import SwiftUI
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drbaby.feverlog", category: "TimelineSwipeActions")

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
    let onError: (String) -> Void

    @ViewBuilder
    func temperature(_ log: TemperatureLog, child: Child) -> some View {
        Button(role: .destructive) {
            do {
                try SwiftDataTemperatureLogRepository(context: modelContext).softDelete(log)
                onReload()
            } catch {
                onError(error.localizedDescription)
                logger.error("Failed to delete temperature log \(log.id, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        } label: {
            Label(L10n.Timeline.delete, systemImage: "trash")
        }
        Button {
            do {
                let repository = SwiftDataTemperatureLogRepository(context: modelContext)
                _ = try repository.create(
                    temperatureCelsius: log.temperatureCelsius,
                    measurementMethod: log.measurementMethod,
                    recordedAt: .now,
                    note: log.note,
                    child: child
                )
                onReload()
            } catch {
                onError(error.localizedDescription)
                logger.error("""
                Failed to duplicate temperature log \(log.id, privacy: .public): \
                \(String(describing: error), privacy: .public)
                """)
            }
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
            do {
                try SwiftDataMedicationLogRepository(context: modelContext).softDelete(log)
                onReload()
            } catch {
                onError(error.localizedDescription)
                logger.error("Failed to delete medication log \(log.id, privacy: .public): \(String(describing: error), privacy: .public)")
            }
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
            do {
                try SwiftDataSymptomEntryRepository(context: modelContext).softDelete(entry)
                onReload()
            } catch {
                onError(error.localizedDescription)
                logger.error("Failed to delete symptom entry \(entry.id, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        } label: {
            Label(L10n.Timeline.delete, systemImage: "trash")
        }
        Button {
            do {
                let repository = SwiftDataSymptomEntryRepository(context: modelContext)
                _ = try repository.create(symptomIdentifiers: entry.symptomIdentifiers, recordedAt: .now, child: child)
                onReload()
            } catch {
                onError(error.localizedDescription)
                logger.error("""
                Failed to duplicate symptom entry \(entry.id, privacy: .public): \
                \(String(describing: error), privacy: .public)
                """)
            }
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
            do {
                try SwiftDataNoteEntryRepository(context: modelContext).softDelete(entry)
                onReload()
            } catch {
                onError(error.localizedDescription)
                logger.error("Failed to delete note entry \(entry.id, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        } label: {
            Label(L10n.Timeline.delete, systemImage: "trash")
        }
        Button {
            do {
                let repository = SwiftDataNoteEntryRepository(context: modelContext)
                _ = try repository.create(text: entry.text, recordedAt: .now, child: child)
                onReload()
            } catch {
                onError(error.localizedDescription)
                logger.error("Failed to duplicate note entry \(entry.id, privacy: .public): \(String(describing: error), privacy: .public)")
            }
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

    @ViewBuilder
    func quickLog(_ entry: QuickLogEntry, child: Child) -> some View {
        Button(role: .destructive) {
            do {
                try SwiftDataQuickLogEntryRepository(context: modelContext).softDelete(entry)
                onReload()
            } catch {
                onError(error.localizedDescription)
                logger.error("""
                Failed to delete quick log entry \(entry.id, privacy: .public): \
                \(String(describing: error), privacy: .public)
                """)
            }
        } label: {
            Label(L10n.Timeline.delete, systemImage: "trash")
        }
        Button {
            do {
                let repository = SwiftDataQuickLogEntryRepository(context: modelContext)
                _ = try repository.create(type: entry.type, degree: entry.degree, recordedAt: .now, child: child)
                onReload()
            } catch {
                onError(error.localizedDescription)
                logger.error("""
                Failed to duplicate quick log entry \(entry.id, privacy: .public): \
                \(String(describing: error), privacy: .public)
                """)
            }
        } label: {
            Label(L10n.Timeline.duplicate, systemImage: "plus.square.on.square")
        }
        .tint(palette.accentBlue)
        Button {
            onEdit(.quickLog(entry, child))
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
        do {
            try SwiftDataMedicationLogRepository(context: modelContext).create(newLog)
            onReload()
        } catch {
            onError(error.localizedDescription)
            logger.error("Failed to duplicate medication log \(log.id, privacy: .public): \(String(describing: error), privacy: .public)")
        }
    }
}
