import Foundation
import SwiftData

/// In-memory SwiftData container pre-populated with sample data, for use in
/// SwiftUI previews only. Never touches the production on-disk store.
@MainActor
enum PreviewContainer {
    static let shared: ModelContainer = {
        do {
            let container = try ModelContainerFactory.makeInMemoryContainer()
            let context = container.mainContext

            let household = Household(displayName: "Preview Household")
            context.insert(household)

            let child = Child(
                household: household,
                name: "Ava",
                birthday: Calendar.current.date(byAdding: .month, value: -14, to: .now) ?? .now,
                avatarIdentifier: "avatar.bear",
                avatarColorIdentifier: "mint"
            )
            context.insert(child)

            let weight = WeightHistory(child: child, weight: 10.4, unit: .kilograms, effectiveDate: .now)
            context.insert(weight)

            let temperature = TemperatureLog(
                child: child,
                temperatureCelsius: 38.2,
                measurementMethod: .ear,
                recordedAt: .now
            )
            context.insert(temperature)

            try context.save()
            return container
        } catch {
            fatalError("Failed to create the preview SwiftData container: \(error)")
        }
    }()
}
