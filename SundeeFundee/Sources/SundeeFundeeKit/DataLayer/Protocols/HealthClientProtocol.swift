import Foundation
import HealthKit

// MARK: - HealthError

/// Errors that can occur during HealthKit operations.
public enum HealthError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied(feature: String)
    case noData(type: String)
    case queryFailed(underlying: Error?)

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .authorizationDenied(let feature):
            return "Authorization denied for \(feature). Please enable in Settings > Privacy & Security > Health."
        case .noData(let type):
            return "No \(type) data available."
        case .queryFailed(let underlying):
            if let underlying = underlying {
                return "Health query failed: \(underlying.localizedDescription)"
            }
            return "Health query failed."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notAvailable:
            return "HealthKit requires an iPhone or Apple Watch."
        case .authorizationDenied:
            return "Open Settings and grant access to health data."
        case .noData:
            return "Start tracking health data to see your history."
        case .queryFailed:
            return "Try again later or contact support if the issue persists."
        }
    }
}

// MARK: - HealthClientProtocol

/// Protocol defining HealthKit operations.
///
/// Implementations handle reading and writing health data including workouts,
/// menstrual cycles, and various health metrics.
///
/// ## Example Usage
/// ```swift
/// if healthClient.isAvailable {
///     try await healthClient.requestAuthorization(
///         typesToRead: [.workoutType(), .heartRateType()],
///         typesToWrite: [.workoutType()]
///     )
///     let workouts = try await healthClient.fetchWorkouts()
/// }
/// ```
public protocol HealthClientProtocol: Sendable {
    /// Whether HealthKit is available on this device.
    nonisolated var isAvailable: Bool { get }

    /// Requests authorization to read and write health data types.
    ///
    /// - Parameters:
    ///   - typesToRead: The health data types to read.
    ///   - typesToWrite: The health data types to write.
    /// - Throws: `HealthError` if authorization fails or is denied.
    func requestAuthorization(
        typesToRead: Set<HKObjectType>,
        typesToWrite: Set<HKSampleType>
    ) async throws

    /// Fetches workouts from HealthKit.
    ///
    /// - Parameters:
    ///   - startDate: Optional start date for the query range.
    ///   - endDate: Optional end date for the query range.
    ///   - limit: Maximum number of workouts to return.
    /// - Returns: An array of HKWorkout samples.
    /// - Throws: `HealthError` if the query fails.
    func fetchWorkouts(
        startDate: Date?,
        endDate: Date?,
        limit: Int
    ) async throws -> [HKWorkout]

    /// Fetches menstrual cycle data from HealthKit.
    ///
    /// - Parameters:
    ///   - startDate: Optional start date for the query range.
    ///   - endDate: Optional end date for the query range.
    ///   - limit: Maximum number of cycles to return.
    /// - Returns: An array of HKCategorySample samples representing menstrual cycles.
    /// - Throws: `HealthError` if the query fails.
    func fetchMenstrualCycles(
        startDate: Date?,
        endDate: Date?,
        limit: Int
    ) async throws -> [HKCategorySample]

    /// Fetches active energy burned samples.
    ///
    /// - Parameters:
    ///   - startDate: Start date for the query range.
    ///   - endDate: End date for the query range.
    /// - Returns: An array of HKQuantitySample samples for active energy.
    /// - Throws: `HealthError` if the query fails.
    func fetchActiveEnergy(
        startDate: Date,
        endDate: Date
    ) async throws -> [HKQuantitySample]

    /// Fetches heart rate variability samples.
    ///
    /// - Parameters:
    ///   - startDate: Start date for the query range.
    ///   - endDate: End date for the query range.
    /// - Returns: An array of HKQuantitySample samples for HRV.
    /// - Throws: `HealthError` if the query fails.
    func fetchHeartRateVariability(
        startDate: Date,
        endDate: Date
    ) async throws -> [HKQuantitySample]

    /// Fetches resting heart rate samples.
    ///
    /// - Parameters:
    ///   - startDate: Start date for the query range.
    ///   - endDate: End date for the query range.
    /// - Returns: An array of HKQuantitySample samples for resting heart rate.
    /// - Throws: `HealthError` if the query fails.
    func fetchRestingHeartRate(
        startDate: Date,
        endDate: Date
    ) async throws -> [HKQuantitySample]

    /// Saves a workout to HealthKit.
    ///
    /// - Parameters:
    ///   - startDate: The workout start time.
    ///   - endDate: The workout end time.
    ///   - totalEnergyBurned: Total calories burned during the workout.
    ///   - exercises: Array of exercise data to include as metadata.
    /// - Throws: `HealthError` if saving fails.
    func saveWorkout(
        startDate: Date,
        endDate: Date,
        totalEnergyBurned: Double,
        exercises: [Exercise]
    ) async throws
}

// MARK: - Default Implementations

extension HealthClientProtocol {
    /// Fetches workouts with default parameters.
    public func fetchWorkouts() async throws -> [HKWorkout] {
        try await fetchWorkouts(startDate: nil, endDate: nil, limit: HKObjectQueryNoLimit)
    }

    /// Fetches recent workouts within a specified time interval.
    public func fetchRecentWorkouts(days: Int = 30, limit: Int = 100) async throws -> [HKWorkout] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        return try await fetchWorkouts(startDate: startDate, endDate: endDate, limit: limit)
    }

    /// Fetches menstrual cycles with default parameters.
    public func fetchMenstrualCycles() async throws -> [HKCategorySample] {
        try await fetchMenstrualCycles(startDate: nil, endDate: nil, limit: HKObjectQueryNoLimit)
    }

    /// Fetches active energy for today.
    public func fetchTodaysActiveEnergy() async throws -> [HKQuantitySample] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? Date()
        return try await fetchActiveEnergy(startDate: startDate, endDate: endDate)
    }

    /// Fetches HRV for the past week.
    public func fetchWeeklyHeartRateVariability() async throws -> [HKQuantitySample] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        return try await fetchHeartRateVariability(startDate: startDate, endDate: endDate)
    }

    /// Fetches resting heart rate for the past week.
    public func fetchWeeklyRestingHeartRate() async throws -> [HKQuantitySample] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        return try await fetchRestingHeartRate(startDate: startDate, endDate: endDate)
    }
}
