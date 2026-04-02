import Foundation
import HealthKit

// MARK: - HealthKitClient

/// Thread-safe actor for HealthKit database operations.
///
/// `HealthKitClient` provides a type-safe interface for reading and writing health data
/// including workouts, menstrual cycles, and various health metrics. It uses Swift's
/// actor model to ensure thread-safe access to HealthKit APIs.
///
/// ## Example Usage
/// ```swift
/// let healthClient = HealthKitClient()
///
/// if healthClient.isAvailable {
///     try await healthClient.requestAuthorization(
///         typesToRead: [.workoutType(), .heartRateType()],
///         typesToWrite: [.workoutType()]
///     )
///     let workouts = try await healthClient.fetchRecentWorkouts(days: 30)
/// }
/// ```
public actor HealthKitClient: @preconcurrency HealthClientProtocol {
    // MARK: - Properties

    /// The HealthKit store.
    private let healthStore: HKHealthStore

    // MARK: - Initialization

    /// Creates a HealthKitClient with a new HKHealthStore instance.
    public init() {
        self.healthStore = HKHealthStore()
    }

    /// Creates a HealthKitClient with a custom HKHealthStore (useful for testing).
    ///
    /// - Parameter healthStore: The HealthKit store to use.
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - HealthClientProtocol

    /// Whether HealthKit is available on this device.
    public var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Requests authorization to read and write health data types.
    ///
    /// - Parameters:
    ///   - typesToRead: The health data types to read.
    ///   - typesToWrite: The health data types to write.
    /// - Throws: `HealthError` if authorization fails or is denied.
    public func requestAuthorization(
        typesToRead: Set<HKObjectType>,
        typesToWrite: Set<HKSampleType>
    ) async throws {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: HealthError.queryFailed(underlying: error))
                } else if !success {
                    // User declined authorization for one or more types
                    let feature = typesToRead.map { $0.identifier }.joined(separator: ", ")
                    continuation.resume(throwing: HealthError.authorizationDenied(feature: feature))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Fetches workouts from HealthKit.
    ///
    /// - Parameters:
    ///   - startDate: Optional start date for the query range.
    ///   - endDate: Optional end date for the query range.
    ///   - limit: Maximum number of workouts to return.
    /// - Returns: An array of HKWorkout samples.
    /// - Throws: `HealthError` if the query fails.
    public func fetchWorkouts(
        startDate: Date?,
        endDate: Date?,
        limit: Int
    ) async throws -> [HKWorkout] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        let workoutType = HKObjectType.workoutType()
        let predicate = buildDatePredicate(startDate: startDate, endDate: endDate)

        return try await fetchSamples(
            sampleType: workoutType,
            predicate: predicate,
            sortDescriptor: NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false),
            limit: limit
        ) as? [HKWorkout] ?? []
    }

    /// Fetches menstrual cycle data from HealthKit.
    ///
    /// - Parameters:
    ///   - startDate: Optional start date for the query range.
    ///   - endDate: Optional end date for the query range.
    ///   - limit: Maximum number of cycles to return.
    /// - Returns: An array of HKCategorySample samples representing menstrual cycles.
    /// - Throws: `HealthError` if the query fails.
    public func fetchMenstrualCycles(
        startDate: Date?,
        endDate: Date?,
        limit: Int
    ) async throws -> [HKCategorySample] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        // Menstrual flow is represented as a category sample
        guard let cycleType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else {
            throw HealthError.noData(type: "menstrual cycle")
        }

        let predicate = buildDatePredicate(startDate: startDate, endDate: endDate)

        return try await fetchSamples(
            sampleType: cycleType,
            predicate: predicate,
            sortDescriptor: NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false),
            limit: limit
        ) as? [HKCategorySample] ?? []
    }

    /// Fetches active energy burned samples.
    ///
    /// - Parameters:
    ///   - startDate: Start date for the query range.
    ///   - endDate: End date for the query range.
    /// - Returns: An array of HKQuantitySample samples for active energy.
    /// - Throws: `HealthError` if the query fails.
    public func fetchActiveEnergy(
        startDate: Date,
        endDate: Date
    ) async throws -> [HKQuantitySample] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthError.noData(type: "active energy")
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await fetchSamples(
            sampleType: energyType,
            predicate: predicate,
            sortDescriptor: NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false),
            limit: HKObjectQueryNoLimit
        ) as? [HKQuantitySample] ?? []
    }

    /// Fetches heart rate variability samples.
    ///
    /// - Parameters:
    ///   - startDate: Start date for the query range.
    ///   - endDate: End date for the query range.
    /// - Returns: An array of HKQuantitySample samples for HRV.
    /// - Throws: `HealthError` if the query fails.
    public func fetchHeartRateVariability(
        startDate: Date,
        endDate: Date
    ) async throws -> [HKQuantitySample] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw HealthError.noData(type: "heart rate variability")
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await fetchSamples(
            sampleType: hrvType,
            predicate: predicate,
            sortDescriptor: NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false),
            limit: HKObjectQueryNoLimit
        ) as? [HKQuantitySample] ?? []
    }

    /// Fetches resting heart rate samples.
    ///
    /// - Parameters:
    ///   - startDate: Start date for the query range.
    ///   - endDate: End date for the query range.
    /// - Returns: An array of HKQuantitySample samples for resting heart rate.
    /// - Throws: `HealthError` if the query fails.
    public func fetchRestingHeartRate(
        startDate: Date,
        endDate: Date
    ) async throws -> [HKQuantitySample] {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        guard let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthError.noData(type: "resting heart rate")
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await fetchSamples(
            sampleType: rhrType,
            predicate: predicate,
            sortDescriptor: NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false),
            limit: HKObjectQueryNoLimit
        ) as? [HKQuantitySample] ?? []
    }

    /// Saves a workout to HealthKit.
    ///
    /// - Parameters:
    ///   - startDate: The workout start time.
    ///   - endDate: The workout end time.
    ///   - totalEnergyBurned: Total calories burned during the workout.
    ///   - exercises: Array of exercise data to include as metadata.
    /// - Throws: `HealthError` if saving fails.
    public func saveWorkout(
        startDate: Date,
        endDate: Date,
        totalEnergyBurned: Double,
        exercises: [Exercise]
    ) async throws {
        guard isAvailable else {
            throw HealthError.notAvailable
        }

        // Create energy quantity (calories)
        let energyQuantity = HKQuantity(
            unit: HKUnit.kilocalorie(),
            doubleValue: totalEnergyBurned
        )

        // Build metadata from exercises
        var metadata: [String: Any] = [:]
        metadata[HKMetadataKeyWorkoutBrandName] = "Sundee Fundee"

        // Add exercise count to metadata
        metadata["com.sundeefundee.exerciseCount"] = exercises.count

        // Create workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining

        // Create the workout using HKWorkoutBuilder
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)

        // Begin collection
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.beginCollection(withStart: startDate) { success, error in
                if let error = error {
                    continuation.resume(throwing: HealthError.queryFailed(underlying: error))
                } else if !success {
                    continuation.resume(throwing: HealthError.queryFailed(underlying: nil))
                } else {
                    continuation.resume()
                }
            }
        }

        // Create energy sample to add to the workout
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let energySample = HKQuantitySample(
            type: energyType,
            quantity: energyQuantity,
            start: startDate,
            end: endDate,
            metadata: metadata
        )

        // Add the energy sample
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.add([energySample]) { success, error in
                if let error = error {
                    continuation.resume(throwing: HealthError.queryFailed(underlying: error))
                } else if !success {
                    continuation.resume(throwing: HealthError.queryFailed(underlying: nil))
                } else {
                    continuation.resume()
                }
            }
        }

        // End collection
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.endCollection(withEnd: endDate) { success, error in
                if let error = error {
                    continuation.resume(throwing: HealthError.queryFailed(underlying: error))
                } else if !success {
                    continuation.resume(throwing: HealthError.queryFailed(underlying: nil))
                } else {
                    continuation.resume()
                }
            }
        }

        // Finish the workout
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKWorkout?, Error>) in
            builder.finishWorkout { workout, error in
                if let error = error {
                    continuation.resume(throwing: HealthError.queryFailed(underlying: error))
                } else {
                    continuation.resume(returning: workout)
                }
            }
        }
    }

    // MARK: - Private Helpers

    /// Builds a date predicate from optional start and end dates.
    private func buildDatePredicate(startDate: Date?, endDate: Date?) -> NSPredicate? {
        if let startDate = startDate, let endDate = endDate {
            return HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        } else if let startDate = startDate {
            return HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        } else if let endDate = endDate {
            return HKQuery.predicateForSamples(withStart: nil, end: endDate, options: [])
        } else {
            return nil
        }
    }

    /// Fetches samples of a given type with predicate and sort descriptor.
    private func fetchSamples(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        sortDescriptor: NSSortDescriptor?,
        limit: Int
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptor != nil ? [sortDescriptor!] : nil,
                resultsHandler: { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: HealthError.queryFailed(underlying: error))
                    } else if let samples = samples {
                        continuation.resume(returning: samples)
                    } else {
                        continuation.resume(returning: [])
                    }
                }
            )

            healthStore.execute(query)
        }
    }
}

// MARK: - Convenience Extensions

extension HealthKitClient {
    /// Standard types to read for workout tracking.
    public static var standardReadTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.workoutType(),
        ]

        // Add optional types if available
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHeartRate)
        }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let menstrualFlow = HKObjectType.categoryType(forIdentifier: .menstrualFlow) {
            types.insert(menstrualFlow)
        }

        return types
    }

    /// Standard types to write for workout tracking.
    public static var standardWriteTypes: Set<HKSampleType> {
        [
            HKObjectType.workoutType(),
        ]
    }

    /// Requests authorization for standard workout tracking types.
    public func requestStandardAuthorization() async throws {
        try await requestAuthorization(
            typesToRead: Self.standardReadTypes,
            typesToWrite: Self.standardWriteTypes
        )
    }
}
