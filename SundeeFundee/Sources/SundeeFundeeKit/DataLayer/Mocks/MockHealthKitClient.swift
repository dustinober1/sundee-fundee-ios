import Foundation
import HealthKit

// MARK: - MockHealthKitClient

/// A mock implementation of `HealthClientProtocol` for unit testing.
///
/// `MockHealthKitClient` provides an in-memory storage solution that simulates
/// HealthKit operations without requiring actual HealthKit access. It's designed
/// for use in unit tests to verify health data behavior in isolation.
///
/// ## Thread Safety
/// This class uses a serial dispatch queue for thread-safe access to storage.
/// All operations are synchronized to prevent data races in concurrent tests.
///
/// ## Example Usage
/// ```swift
/// let mockClient = MockHealthKitClient()
///
/// // Set up mock data
/// mockClient.setMockWorkouts([workout1, workout2])
///
/// // Fetch with date filtering
/// let workouts = try await mockClient.fetchWorkouts(
///     startDate: startDate,
///     endDate: endDate,
///     limit: 10
/// )
///
/// // Reset for next test
/// mockClient.reset()
/// ```
public final class MockHealthKitClient: HealthClientProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// In-memory storage for mock workouts.
    private var mockWorkouts: [HKWorkout] = []

    /// In-memory storage for mock menstrual cycle samples.
    private var mockMenstrualCycles: [HKCategorySample] = []

    /// In-memory storage for mock active energy samples.
    private var mockActiveEnergy: [HKQuantitySample] = []

    /// In-memory storage for mock HRV samples.
    private var mockHeartRateVariability: [HKQuantitySample] = []

    /// In-memory storage for mock resting heart rate samples.
    private var mockRestingHeartRate: [HKQuantitySample] = []

    /// Serial queue for thread-safe access.
    private let queue = DispatchQueue(label: "com.sundeefundee.mock-healthkit-client", qos: .userInitiated)

    /// Whether the mock simulates HealthKit availability.
    /// Set to `false` to test error handling when HealthKit is unavailable.
    public var isAvailable: Bool = true

    /// Whether authorization has been granted.
    /// Set to `false` to simulate authorization denial.
    public var authorizationGranted: Bool = true

    /// Whether to simulate query failures.
    /// Set to `true` to test error handling for failed queries.
    public var shouldFailQueries: Bool = false

    /// Number of times `saveWorkout` has been called successfully.
    /// Use this in tests to verify that a workout save was attempted.
    public private(set) var saveWorkoutCallCount: Int = 0

    // MARK: - Initialization

    /// Creates a new MockHealthKitClient with empty storage.
    public init() {}

    // MARK: - HealthClientProtocol

    /// Requests authorization to read and write health data types.
    ///
    /// - Parameters:
    ///   - typesToRead: The health data types to read (ignored in mock).
    ///   - typesToWrite: The health data types to write (ignored in mock).
    /// - Throws: `HealthError.notAvailable` if `isAvailable` is false,
    ///           `HealthError.authorizationDenied` if `authorizationGranted` is false.
    public func requestAuthorization(
        typesToRead: Set<HKObjectType>,
        typesToWrite: Set<HKSampleType>
    ) async throws {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard authorizationGranted else {
            let feature = typesToRead.map { $0.identifier }.joined(separator: ", ")
            throw HealthError.authorizationDenied(feature: feature)
        }

        // In mock, authorization always succeeds if flags are set
    }

    /// Fetches workouts from in-memory storage.
    ///
    /// - Parameters:
    ///   - startDate: Optional start date for the query range.
    ///   - endDate: Optional end date for the query range.
    ///   - limit: Maximum number of workouts to return.
    /// - Returns: An array of HKWorkout samples filtered by date range.
    /// - Throws: `HealthError.notAvailable` if `isAvailable` is false,
    ///           `HealthError.queryFailed` if `shouldFailQueries` is true.
    public func fetchWorkouts(
        startDate: Date?,
        endDate: Date?,
        limit: Int
    ) async throws -> [HKWorkout] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard !shouldFailQueries else {
            throw HealthError.queryFailed(underlying: nil)
        }

        let workouts = queue.sync {
            mockWorkouts
        }

        // Filter by date range
        let filtered = workouts.filter { workout in
            let afterStart = startDate.map { workout.startDate >= $0 } ?? true
            let beforeEnd = endDate.map { workout.startDate <= $0 } ?? true
            return afterStart && beforeEnd
        }

        // Sort by start date descending (most recent first)
        let sorted = filtered.sorted { $0.startDate > $1.startDate }

        // Apply limit
        if limit == HKObjectQueryNoLimit || limit >= sorted.count {
            return sorted
        }
        return Array(sorted.prefix(limit))
    }

    /// Fetches menstrual cycle data from in-memory storage.
    ///
    /// - Parameters:
    ///   - startDate: Optional start date for the query range.
    ///   - endDate: Optional end date for the query range.
    ///   - limit: Maximum number of cycles to return.
    /// - Returns: An array of HKCategorySample samples filtered by date range.
    /// - Throws: `HealthError.notAvailable` if `isAvailable` is false,
    ///           `HealthError.queryFailed` if `shouldFailQueries` is true.
    public func fetchMenstrualCycles(
        startDate: Date?,
        endDate: Date?,
        limit: Int
    ) async throws -> [HKCategorySample] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard !shouldFailQueries else {
            throw HealthError.queryFailed(underlying: nil)
        }

        let cycles = queue.sync {
            mockMenstrualCycles
        }

        // Filter by date range
        let filtered = cycles.filter { sample in
            let afterStart = startDate.map { sample.startDate >= $0 } ?? true
            let beforeEnd = endDate.map { sample.startDate <= $0 } ?? true
            return afterStart && beforeEnd
        }

        // Sort by start date descending
        let sorted = filtered.sorted { $0.startDate > $1.startDate }

        // Apply limit
        if limit == HKObjectQueryNoLimit || limit >= sorted.count {
            return sorted
        }
        return Array(sorted.prefix(limit))
    }

    /// Fetches active energy burned samples from in-memory storage.
    ///
    /// - Parameters:
    ///   - startDate: Start date for the query range.
    ///   - endDate: End date for the query range.
    /// - Returns: An array of HKQuantitySample samples filtered by date range.
    /// - Throws: `HealthError.notAvailable` if `isAvailable` is false,
    ///           `HealthError.queryFailed` if `shouldFailQueries` is true.
    public func fetchActiveEnergy(
        startDate: Date,
        endDate: Date
    ) async throws -> [HKQuantitySample] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard !shouldFailQueries else {
            throw HealthError.queryFailed(underlying: nil)
        }

        let samples = queue.sync {
            mockActiveEnergy
        }

        // Filter by date range
        let filtered = samples.filter { sample in
            sample.startDate >= startDate && sample.startDate <= endDate
        }

        // Sort by start date descending
        return filtered.sorted { $0.startDate > $1.startDate }
    }

    /// Fetches heart rate variability samples from in-memory storage.
    ///
    /// - Parameters:
    ///   - startDate: Start date for the query range.
    ///   - endDate: End date for the query range.
    /// - Returns: An array of HKQuantitySample samples filtered by date range.
    /// - Throws: `HealthError.notAvailable` if `isAvailable` is false,
    ///           `HealthError.queryFailed` if `shouldFailQueries` is true.
    public func fetchHeartRateVariability(
        startDate: Date,
        endDate: Date
    ) async throws -> [HKQuantitySample] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard !shouldFailQueries else {
            throw HealthError.queryFailed(underlying: nil)
        }

        let samples = queue.sync {
            mockHeartRateVariability
        }

        // Filter by date range
        let filtered = samples.filter { sample in
            sample.startDate >= startDate && sample.startDate <= endDate
        }

        // Sort by start date descending
        return filtered.sorted { $0.startDate > $1.startDate }
    }

    /// Fetches resting heart rate samples from in-memory storage.
    ///
    /// - Parameters:
    ///   - startDate: Start date for the query range.
    ///   - endDate: End date for the query range.
    /// - Returns: An array of HKQuantitySample samples filtered by date range.
    /// - Throws: `HealthError.notAvailable` if `isAvailable` is false,
    ///           `HealthError.queryFailed` if `shouldFailQueries` is true.
    public func fetchRestingHeartRate(
        startDate: Date,
        endDate: Date
    ) async throws -> [HKQuantitySample] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard !shouldFailQueries else {
            throw HealthError.queryFailed(underlying: nil)
        }

        let samples = queue.sync {
            mockRestingHeartRate
        }

        // Filter by date range
        let filtered = samples.filter { sample in
            sample.startDate >= startDate && sample.startDate <= endDate
        }

        // Sort by start date descending
        return filtered.sorted { $0.startDate > $1.startDate }
    }

    /// Saves a workout to in-memory storage.
    ///
    /// - Parameters:
    ///   - startDate: The workout start time.
    ///   - endDate: The workout end time.
    ///   - totalEnergyBurned: Total calories burned during the workout.
    ///   - exercises: Array of exercise data (used for metadata).
    /// - Throws: `HealthError.notAvailable` if `isAvailable` is false,
    ///           `HealthError.queryFailed` if `shouldFailQueries` is true.
    public func saveWorkout(
        startDate: Date,
        endDate: Date,
        totalEnergyBurned: Double,
        exercises: [Exercise]
    ) async throws {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard !shouldFailQueries else {
            throw HealthError.queryFailed(underlying: nil)
        }

        queue.sync {
            saveWorkoutCallCount += 1
        }
    }

    public func requestStandardAuthorization() async throws {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard authorizationGranted else {
            throw HealthError.authorizationDenied(feature: "standard types")
        }
    }

    // MARK: - Test Helpers

    /// Clears all stored mock data.
    ///
    /// Call this method between tests to ensure a clean state.
    public func reset() {
        queue.sync {
            mockWorkouts.removeAll()
            mockMenstrualCycles.removeAll()
            mockActiveEnergy.removeAll()
            mockHeartRateVariability.removeAll()
            mockRestingHeartRate.removeAll()
            saveWorkoutCallCount = 0
            isAvailable = true
            authorizationGranted = true
            shouldFailQueries = false
        }
    }

    /// Sets mock workout data.
    ///
    /// - Parameter workouts: The workouts to store.
    public func setMockWorkouts(_ workouts: [HKWorkout]) {
        queue.sync {
            mockWorkouts = workouts
        }
    }

    /// Adds a single mock workout.
    ///
    /// - Parameter workout: The workout to add.
    public func addMockWorkout(_ workout: HKWorkout) {
        queue.sync {
            mockWorkouts.append(workout)
        }
    }

    /// Sets mock menstrual cycle data.
    ///
    /// - Parameter cycles: The menstrual cycle samples to store.
    public func setMockMenstrualCycles(_ cycles: [HKCategorySample]) {
        queue.sync {
            mockMenstrualCycles = cycles
        }
    }

    /// Adds a single mock menstrual cycle sample.
    ///
    /// - Parameter cycle: The menstrual cycle sample to add.
    public func addMockMenstrualCycle(_ cycle: HKCategorySample) {
        queue.sync {
            mockMenstrualCycles.append(cycle)
        }
    }

    /// Sets mock active energy data.
    ///
    /// - Parameter samples: The active energy samples to store.
    public func setMockActiveEnergy(_ samples: [HKQuantitySample]) {
        queue.sync {
            mockActiveEnergy = samples
        }
    }

    /// Adds a single mock active energy sample.
    ///
    /// - Parameter sample: The active energy sample to add.
    public func addMockActiveEnergy(_ sample: HKQuantitySample) {
        queue.sync {
            mockActiveEnergy.append(sample)
        }
    }

    /// Sets mock heart rate variability data.
    ///
    /// - Parameter samples: The HRV samples to store.
    public func setMockHeartRateVariability(_ samples: [HKQuantitySample]) {
        queue.sync {
            mockHeartRateVariability = samples
        }
    }

    /// Adds a single mock HRV sample.
    ///
    /// - Parameter sample: The HRV sample to add.
    public func addMockHeartRateVariability(_ sample: HKQuantitySample) {
        queue.sync {
            mockHeartRateVariability.append(sample)
        }
    }

    /// Sets mock resting heart rate data.
    ///
    /// - Parameter samples: The resting heart rate samples to store.
    public func setMockRestingHeartRate(_ samples: [HKQuantitySample]) {
        queue.sync {
            mockRestingHeartRate = samples
        }
    }

    /// Adds a single mock resting heart rate sample.
    ///
    /// - Parameter sample: The resting heart rate sample to add.
    public func addMockRestingHeartRate(_ sample: HKQuantitySample) {
        queue.sync {
            mockRestingHeartRate.append(sample)
        }
    }

    /// Returns the count of stored mock workouts.
    ///
    /// - Returns: The number of stored mock workouts.
    public func workoutCount() -> Int {
        queue.sync {
            mockWorkouts.count
        }
    }

    /// Returns the count of stored mock menstrual cycles.
    ///
    /// - Returns: The number of stored mock menstrual cycle samples.
    public func menstrualCycleCount() -> Int {
        queue.sync {
            mockMenstrualCycles.count
        }
    }

    /// Returns the count of stored mock active energy samples.
    ///
    /// - Returns: The number of stored mock active energy samples.
    public func activeEnergyCount() -> Int {
        queue.sync {
            mockActiveEnergy.count
        }
    }

    /// Returns the count of stored mock HRV samples.
    ///
    /// - Returns: The number of stored mock HRV samples.
    public func heartRateVariabilityCount() -> Int {
        queue.sync {
            mockHeartRateVariability.count
        }
    }

    /// Returns the count of stored mock resting heart rate samples.
    ///
    /// - Returns: The number of stored mock resting heart rate samples.
    public func restingHeartRateCount() -> Int {
        queue.sync {
            mockRestingHeartRate.count
        }
    }
}

// MARK: - Factory Helpers for Creating Mock Data

extension MockHealthKitClient {

    /// Creates a mock HKWorkout for testing.
    ///
    /// - Parameters:
    ///   - startDate: The workout start date.
    ///   - endDate: The workout end date.
    ///   - totalEnergyBurned: Total calories burned (default: 100).
    ///   - activityType: The activity type (default: traditionalStrengthTraining).
    /// - Returns: A mock HKWorkout instance.
    public static func createMockWorkout(
        startDate: Date,
        endDate: Date,
        totalEnergyBurned: Double = 100,
        activityType: HKWorkoutActivityType = .traditionalStrengthTraining
    ) -> HKWorkout {
        let energyQuantity = HKQuantity(
            unit: HKUnit.kilocalorie(),
            doubleValue: totalEnergyBurned
        )

        return HKWorkout(
            activityType: activityType,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: energyQuantity,
            totalDistance: nil,
            metadata: [HKMetadataKeyWorkoutBrandName: "Sundee Fundee"]
        )
    }

    /// Creates a mock HKQuantitySample for active energy testing.
    ///
    /// - Parameters:
    ///   - startDate: The sample start date.
    ///   - endDate: The sample end date.
    ///   - kilocalories: The energy value in kilocalories.
    /// - Returns: A mock HKQuantitySample instance for active energy.
    public static func createMockActiveEnergy(
        startDate: Date,
        endDate: Date,
        kilocalories: Double
    ) -> HKQuantitySample? {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }

        let quantity = HKQuantity(
            unit: HKUnit.kilocalorie(),
            doubleValue: kilocalories
        )

        return HKQuantitySample(
            type: energyType,
            quantity: quantity,
            start: startDate,
            end: endDate
        )
    }

    /// Creates a mock HKQuantitySample for heart rate variability testing.
    ///
    /// - Parameters:
    ///   - date: The sample date.
    ///   - milliseconds: The HRV value in milliseconds.
    /// - Returns: A mock HKQuantitySample instance for HRV.
    public static func createMockHeartRateVariability(
        date: Date,
        milliseconds: Double
    ) -> HKQuantitySample? {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }

        let quantity = HKQuantity(
            unit: HKUnit.secondUnit(with: .milli),
            doubleValue: milliseconds
        )

        return HKQuantitySample(
            type: hrvType,
            quantity: quantity,
            start: date,
            end: date
        )
    }

    /// Creates a mock HKQuantitySample for resting heart rate testing.
    ///
    /// - Parameters:
    ///   - date: The sample date.
    ///   - beatsPerMinute: The heart rate in BPM.
    /// - Returns: A mock HKQuantitySample instance for resting heart rate.
    public static func createMockRestingHeartRate(
        date: Date,
        beatsPerMinute: Double
    ) -> HKQuantitySample? {
        guard let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }

        let quantity = HKQuantity(
            unit: HKUnit.count().unitDivided(by: .minute()),
            doubleValue: beatsPerMinute
        )

        return HKQuantitySample(
            type: rhrType,
            quantity: quantity,
            start: date,
            end: date
        )
    }

    /// Creates a mock HKCategorySample for menstrual flow testing.
    ///
    /// - Parameters:
    ///   - startDate: The sample start date.
    ///   - endDate: The sample end date.
    ///   - value: The menstrual flow value (0=unspecified, 1=none, 2=light, 3=medium, 4=heavy).
    ///   - isStartOfCycle: Whether this sample marks the start of a menstrual cycle.
    /// - Returns: A mock HKCategorySample instance for menstrual flow.
    public static func createMockMenstrualCycle(
        startDate: Date,
        endDate: Date,
        value: Int = 3,  // medium
        isStartOfCycle: Bool = false
    ) -> HKCategorySample? {
        guard let cycleType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else {
            return nil
        }

        let metadata: [String: Any] = [
            HKMetadataKeyMenstrualCycleStart: isStartOfCycle
        ]

        return HKCategorySample(
            type: cycleType,
            value: value,
            start: startDate,
            end: endDate,
            metadata: metadata
        )
    }
}
