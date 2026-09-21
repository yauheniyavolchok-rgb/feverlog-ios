import SwiftData
import SwiftUI
import UIKit

struct TemperatureEntryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    let child: Child
    /// Non-nil when editing or duplicating an existing entry. Duplicating
    /// passes an entry with `isDuplicate = true` so Save always creates a
    /// new record rather than mutating the original.
    var existingLog: TemperatureLog?
    var isDuplicate: Bool = false
    var onSaved: () -> Void = {}

    @State private var temperatureCelsius: Double
    @State private var measurementMethod: TemperatureMeasurementMethod
    @State private var recordedAt: Date
    @State private var note: String
    @State private var errorMessage: String?

    private static let stepValues: [Double] = (340...420).map { Double($0) / 10.0 }

    init(child: Child, existingLog: TemperatureLog? = nil, isDuplicate: Bool = false, onSaved: @escaping () -> Void = {}) {
        self.child = child
        self.existingLog = existingLog
        self.isDuplicate = isDuplicate
        self.onSaved = onSaved
        _temperatureCelsius = State(initialValue: existingLog?.temperatureCelsius ?? 37.0)
        _measurementMethod = State(initialValue: existingLog?.measurementMethod ?? .ear)
        _recordedAt = State(initialValue: isDuplicate ? .now : (existingLog?.recordedAt ?? .now))
        _note = State(initialValue: existingLog?.note ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(L10n.TemperatureEntry.valueLabel, selection: $temperatureCelsius) {
                ForEach(Self.stepValues, id: \.self) { value in
                    Text(String(format: "%.1f°C", value)).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .accessibilityIdentifier("temperatureEntry.picker")

            Form {
                Section {
                    Picker(L10n.TemperatureEntry.methodLabel, selection: $measurementMethod) {
                        ForEach(TemperatureMeasurementMethod.allCases, id: \.self) { method in
                            Text(method.rawValue.capitalized).tag(method)
                        }
                    }
                    .accessibilityIdentifier("temperatureEntry.method")

                    DatePicker(L10n.TemperatureEntry.dateLabel, selection: $recordedAt, in: ...Date.now)
                        .accessibilityIdentifier("temperatureEntry.date")

                    TextField(L10n.TemperatureEntry.noteLabel, text: $note)
                        .accessibilityIdentifier("temperatureEntry.note")
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(palette.danger)
                }
            }
        }
        .navigationTitle(existingLog != nil && !isDuplicate ? L10n.TemperatureEntry.editTitle : L10n.TemperatureEntry.addTitle)
        .announcesAccessibilityErrors(errorMessage)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.TemperatureEntry.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.TemperatureEntry.save, action: save)
                    .accessibilityIdentifier("temperatureEntry.save")
            }
        }
    }

    private func save() {
        let validation = TemperatureValidator.validate(temperatureCelsius)
        guard case .success(let validatedValue) = validation else {
            errorMessage = L10n.TemperatureEntry.outOfRangeError
            return
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let repository = SwiftDataTemperatureLogRepository(context: modelContext)

        do {
            if let existingLog, !isDuplicate {
                existingLog.temperatureCelsius = validatedValue
                existingLog.measurementMethod = measurementMethod
                existingLog.recordedAt = recordedAt
                existingLog.note = trimmedNote.isEmpty ? nil : trimmedNote
                try repository.update(existingLog)
            } else {
                _ = try repository.create(
                    temperatureCelsius: validatedValue,
                    measurementMethod: measurementMethod,
                    recordedAt: recordedAt,
                    note: trimmedNote.isEmpty ? nil : trimmedNote,
                    child: child
                )
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
