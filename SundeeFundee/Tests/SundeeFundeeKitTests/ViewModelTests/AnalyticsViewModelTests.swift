import Testing
import Foundation
import CloudKit
@testable import SundeeFundeeKit

// MARK: - Test Helpers

private let calendar = Calendar.current

private func makeDate(year: Int, month: Int, day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
}

private func makeWorkout(
    date: Date,
    completedAt: Date? = nil,
    volume: Double = 0
) -> Workout {
    let sets: [ExerciseSet]
    if volume > 0 {
        sets = [ExerciseSet(
            reps: 1,
            prescribedWeight: volume,
            type: .fixed,
            completedWeight: volume
        )]
    } else {
        sets = []
    }
    return Workout(
        id: UUID().uuidString,
        date: date,
        name: "Test Workout",
        exercises: [
            Exercise(
                id: UUID().uuidString,
                name: "Squat",
                category: .compound,
                bodyweight: 0,
                targetSets: sets
            )
        ],
        completedAt: completedAt
    )
}

private func makeORM(
    exerciseName: String,
    weight: Double,
    unit: WeightUnit = .lbs,
    date: Date
) -> OneRepMaxRecord {
    OneRepMaxRecord(
        id: UUID().uuidString,
        exerciseName: exerciseName,
        weight: weight,
        unit: unit,
        date: date
    )
}

private func makeCyclePhase(
    phase: CyclePhase,
    start: Date,
    end: Date,
    confidence: Double = 0.9
) -> CyclePhaseInfo {
    CyclePhaseInfo(
        phase: phase,
        confidence: confidence,
        startDate: start,
        endDate: end
    )
}

// MARK: - AnalyticsViewModel Tests

@Suite("AnalyticsViewModel")
@MainActor
struct AnalyticsViewModelTests {

    // MARK: - Helpers

    /// Creates a ViewModel with seeded mock data and a given subscription tier.
    private func makeViewModel(
        tier: SubscriptionTier = .free,
        ormRecords: [OneRepMaxRecord] = [],
        workouts: [Workout] = [],
        phases: [CyclePhaseInfo] = []
    ) async throws -> AnalyticsViewModel {
        let mockData = MockCloudKitClient()
        let mockSub = MockSubscriptionClient(
            subscription: SubscriptionInfo(tier: tier, status: .active)
        )

        // Seed mock data client with records
        try await mockData.save(ormRecords, recordType: "OneRepMaxRecord")
        try await mockData.save(workouts, recordType: "Workout")
        try await mockData.save(phases, recordType: "CyclePhaseInfo")

        return AnalyticsViewModel(
            dataClient: mockData,
            subscriptionClient: mockSub
        )
    }

    // MARK: - Data Loading

    @Test("loadAnalytics fetches and populates all chart data")
    func testLoadAnalytics() async throws {
        let recent = makeDate(year: 2026, month: 3, day: 1)

        let orm = makeORM(exerciseName: "Squat", weight: 200, date: recent)
        let workout = makeWorkout(date: recent, completedAt: recent, volume: 5000)

        let vm = try await makeViewModel(
            tier: .plus,
            ormRecords: [orm],
            workouts: [workout]
        )
        await vm.loadAnalytics()

        #expect(vm.strengthData.count == 1)
        #expect(vm.strengthData.first?.exerciseName == "Squat")
        #expect(vm.strengthData.first?.weight == 200)
        #expect(vm.volumeData.count == 1)
        #expect(vm.volumeData.first?.totalVolume == 5000)
        #expect(vm.frequencyData.count == 1)
        #expect(vm.availableExercises == ["Squat"])
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Empty Data

    @Test("loadAnalytics handles empty data gracefully")
    func testEmptyData() async throws {
        let vm = try await makeViewModel(tier: .free)
        await vm.loadAnalytics()

        #expect(vm.strengthData.isEmpty)
        #expect(vm.volumeData.isEmpty)
        #expect(vm.frequencyData.isEmpty)
        #expect(vm.cycleData.isEmpty)
        #expect(vm.availableExercises.isEmpty)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Time Range Change

    @Test("changing time range triggers re-aggregation")
    func testTimeRangeChange() async throws {
        let recent = makeDate(year: 2026, month: 3, day: 1)
        let old = makeDate(year: 2025, month: 6, day: 1)

        let recentORM = makeORM(exerciseName: "Squat", weight: 200, date: recent)
        let oldORM = makeORM(exerciseName: "Squat", weight: 150, date: old)

        let vm = try await makeViewModel(
            tier: .free,
            ormRecords: [recentORM, oldORM]
        )
        await vm.loadAnalytics()

        // Default is lastSixMonths — old record should be excluded
        #expect(vm.strengthData.count == 1)
        #expect(vm.strengthData.first?.weight == 200)

        // Switch to allTime — both records should appear
        vm.selectedTimeRange = .allTime
        #expect(vm.strengthData.count == 2)
    }

    // MARK: - Exercise Selection

    @Test("selectExercise filters strength data to single exercise")
    func testExerciseSelection() async throws {
        let date = makeDate(year: 2026, month: 3, day: 1)

        let squatORM = makeORM(exerciseName: "Squat", weight: 200, date: date)
        let benchORM = makeORM(exerciseName: "Bench Press", weight: 150, date: date)

        let vm = try await makeViewModel(
            tier: .free,
            ormRecords: [squatORM, benchORM]
        )
        await vm.loadAnalytics()

        // Initially all exercises shown
        #expect(vm.strengthData.count == 2)

        // Select squat
        vm.selectExercise("Squat")
        #expect(vm.strengthData.count == 1)
        #expect(vm.strengthData.first?.exerciseName == "Squat")

        // Deselect
        vm.selectExercise(nil)
        #expect(vm.strengthData.count == 2)
    }

    @Test("availableExercises contains sorted unique exercise names")
    func testAvailableExercises() async throws {
        let date = makeDate(year: 2026, month: 3, day: 1)

        let orm1 = makeORM(exerciseName: "Deadlift", weight: 250, date: date)
        let orm2 = makeORM(exerciseName: "Squat", weight: 200, date: date)
        let orm3 = makeORM(exerciseName: "Squat", weight: 210, date: date) // duplicate name

        let vm = try await makeViewModel(
            tier: .free,
            ormRecords: [orm1, orm2, orm3]
        )
        await vm.loadAnalytics()

        #expect(vm.availableExercises == ["Deadlift", "Squat"])
    }

    // MARK: - Subscription Gating

    @Test("free tier has no cycle access")
    func testFreeTierNoCycleAccess() async throws {
        let date = makeDate(year: 2026, month: 3, day: 1)
        let phase = makeCyclePhase(phase: .follicular, start: date, end: date)
        let workout = makeWorkout(date: date, completedAt: date, volume: 3000)

        let vm = try await makeViewModel(
            tier: .free,
            workouts: [workout],
            phases: [phase]
        )
        await vm.loadAnalytics()

        #expect(vm.subscriptionTier == .free)
        #expect(vm.hasCycleAccess == false)
        #expect(vm.cycleData.isEmpty)
    }

    @Test("plus tier has cycle access")
    func testPlusTierHasCycleAccess() async throws {
        let date = makeDate(year: 2026, month: 3, day: 1)
        let phaseStart = makeDate(year: 2026, month: 2, day: 25)
        let phaseEnd = makeDate(year: 2026, month: 3, day: 5)
        let phase = makeCyclePhase(phase: .follicular, start: phaseStart, end: phaseEnd)
        let workout = makeWorkout(date: date, completedAt: date, volume: 3000)

        let vm = try await makeViewModel(
            tier: .plus,
            workouts: [workout],
            phases: [phase]
        )
        await vm.loadAnalytics()

        #expect(vm.subscriptionTier == .plus)
        #expect(vm.hasCycleAccess == true)
        #expect(vm.cycleData.count == 1)
        #expect(vm.cycleData.first?.phase == .follicular)
    }

    @Test("premium tier has cycle access")
    func testPremiumTierHasCycleAccess() async throws {
        let date = makeDate(year: 2026, month: 3, day: 1)
        let phaseStart = makeDate(year: 2026, month: 2, day: 25)
        let phaseEnd = makeDate(year: 2026, month: 3, day: 5)
        let phase = makeCyclePhase(phase: .luteal, start: phaseStart, end: phaseEnd)
        let workout = makeWorkout(date: date, completedAt: date, volume: 4000)

        let vm = try await makeViewModel(
            tier: .premium,
            workouts: [workout],
            phases: [phase]
        )
        await vm.loadAnalytics()

        #expect(vm.hasCycleAccess == true)
        #expect(vm.cycleData.count == 1)
        #expect(vm.cycleData.first?.phase == .luteal)
    }

    // MARK: - Error Handling

    @Test("loadAnalytics sets errorMessage when data client throws")
    func testErrorHandling() async throws {
        let throwingDataClient = ThrowingMockDataClient()
        let mockSub = MockSubscriptionClient(
            subscription: SubscriptionInfo(tier: .free, status: .active)
        )

        let vm = AnalyticsViewModel(
            dataClient: throwingDataClient,
            subscriptionClient: mockSub
        )
        await vm.loadAnalytics()

        #expect(vm.errorMessage != nil)
        #expect(vm.strengthData.isEmpty)
        #expect(vm.volumeData.isEmpty)
        #expect(vm.frequencyData.isEmpty)
        #expect(vm.cycleData.isEmpty)
        #expect(vm.isLoading == false)
    }

    @Test("isLoading is reset to false after error")
    func testLoadingStateAfterError() async throws {
        let throwingDataClient = ThrowingMockDataClient()
        let mockSub = MockSubscriptionClient(
            subscription: SubscriptionInfo(tier: .free, status: .active)
        )

        let vm = AnalyticsViewModel(
            dataClient: throwingDataClient,
            subscriptionClient: mockSub
        )

        #expect(vm.isLoading == false)
        await vm.loadAnalytics()
        #expect(vm.isLoading == false)
    }

    // MARK: - Time Range + Exercise Interaction

    @Test("changing time range preserves exercise filter")
    func testTimeRangeChangePreservesExerciseFilter() async throws {
        let recent = makeDate(year: 2026, month: 3, day: 1)
        let old = makeDate(year: 2025, month: 3, day: 1)

        let squatRecent = makeORM(exerciseName: "Squat", weight: 200, date: recent)
        let benchRecent = makeORM(exerciseName: "Bench", weight: 150, date: recent)
        let squatOld = makeORM(exerciseName: "Squat", weight: 170, date: old)

        let vm = try await makeViewModel(
            tier: .free,
            ormRecords: [squatRecent, benchRecent, squatOld]
        )
        await vm.loadAnalytics()

        // Filter to squat
        vm.selectExercise("Squat")
        #expect(vm.strengthData.count == 1)
        #expect(vm.strengthData.first?.exerciseName == "Squat")

        // Expand time range — should still be filtered to squat
        vm.selectedTimeRange = .allTime
        let squatPoints = vm.strengthData.filter { $0.exerciseName == "Squat" }
        #expect(squatPoints.count == 2)
        #expect(vm.strengthData.count == 2)
    }

    // MARK: - Cycle Gating on Time Range Change

    @Test("cycle data remains empty for free tier after time range change")
    func testCycleGatingOnTimeRangeChange() async throws {
        let date = makeDate(year: 2026, month: 3, day: 1)
        let phase = makeCyclePhase(phase: .luteal, start: date, end: date)
        let workout = makeWorkout(date: date, completedAt: date, volume: 3000)

        let vm = try await makeViewModel(
            tier: .free,
            workouts: [workout],
            phases: [phase]
        )
        await vm.loadAnalytics()

        #expect(vm.cycleData.isEmpty)

        vm.selectedTimeRange = .allTime
        #expect(vm.cycleData.isEmpty)
    }
}

// MARK: - Throwing Mock Data Client

/// A data client that always throws, used for error handling tests.
private final class ThrowingMockDataClient: DataClientProtocol, @unchecked Sendable {
    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        throw DataError.networkError(underlying: nil)
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        throw DataError.networkError(underlying: nil)
    }

    func delete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async throws {
        throw DataError.networkError(underlying: nil)
    }

    func deleteAllData() async throws {
        throw DataError.networkError(underlying: nil)
    }
}
