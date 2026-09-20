import Foundation
import SwiftData
import Testing
@testable import FeverLog

@MainActor
@Suite("RecentIllnessSummaryService")
struct RecentIllnessSummaryServiceTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainerFactory.makeInMemoryContainer()
    }

    private func makeChild(in container: ModelContainer) throws -> Child {
        let context = container.mainContext
        let household = try SwiftDataHouseholdRepository(context: context).createGuestHouseholdIfNeeded()
        return try SwiftDataChildRepository(context: context).create(
            name: "Ava",
            birthday: .now,
            avatarIdentifier: ChildAvatarOption.star.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.mint.rawValue,
            household: household
        )
    }

    @Test("reports no recent readings when none exist")
    func noRecentReadings() throws {
        let container = try makeContainer()
        let child = try makeChild(in: container)
        let provider = SwiftDataRecentIllnessSummaryProvider(context: container.mainContext)

        let summary = try provider.summary(for: child, withinDays: 7)

        #expect(summary == .noRecentReadings)
    }

    @Test("counts only elevated-or-above readings within the window")
    func countsElevatedReadingsWithinWindow() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeChild(in: container)

        context.insert(TemperatureLog(child: child, temperatureCelsius: 36.8, measurementMethod: .oral, recordedAt: .now))
        context.insert(TemperatureLog(child: child, temperatureCelsius: 38.5, measurementMethod: .oral, recordedAt: .now))
        let old = Calendar(identifier: .gregorian).date(byAdding: .day, value: -30, to: .now) ?? .now
        context.insert(TemperatureLog(child: child, temperatureCelsius: 39.5, measurementMethod: .oral, recordedAt: old))
        try context.save()

        let provider = SwiftDataRecentIllnessSummaryProvider(context: context)
        let summary = try provider.summary(for: child, withinDays: 7)

        #expect(summary == .elevatedReadings(count: 1, sinceDays: 7))
    }

    @Test("excludes soft-deleted readings")
    func excludesSoftDeletedReadings() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let child = try makeChild(in: container)

        let log = TemperatureLog(child: child, temperatureCelsius: 39.0, measurementMethod: .oral, recordedAt: .now)
        log.deletedAt = .now
        context.insert(log)
        try context.save()

        let provider = SwiftDataRecentIllnessSummaryProvider(context: context)
        let summary = try provider.summary(for: child, withinDays: 7)

        #expect(summary == .noRecentReadings)
    }
}
