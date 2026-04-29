import HealthKit
import XCTest
@testable import SundeeFundeeKit

// MARK: - HealthKitClientTests
//
// NOTE: HealthKit tests require a real device with HealthKit capability.
// Most tests check for availability and will skip gracefully on unsupported platforms.
// Use MockHealthKitClient for unit testing without HealthKit.

final class HealthKitClientTests: XCTestCase {
    var sut: HealthKitClient!

    override func setUp() async throws {
        sut = HealthKitClient()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Availability Tests

    func testIsAvailable_ReturnsHealthDataAvailability() async {
        let isAvailable = sut.isAvailable
        // This should match HKHealthStore.isHealthDataAvailable()
        XCTAssertEqual(isAvailable, HKHealthStore.isHealthDataAvailable())
    }

    func testInit_CreatesClient() async {
        let client = HealthKitClient()
        XCTAssertNotNil(client)
    }

    func testInit_WithHealthStore_CreatesClient() async {
        let healthStore = HKHealthStore()
        let client = HealthKitClient(healthStore: healthStore)
        XCTAssertNotNil(client)
    }

    // MARK: - Standard Types Tests

    func testStandardReadTypes_ContainsExpectedTypes() async {
        let readTypes = HealthKitClient.standardReadTypes

        // Workout type should always be present
        XCTAssertTrue(readTypes.contains(HKObjectType.workoutType()))

        // Check for optional types if available on this platform
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            XCTAssertTrue(readTypes.contains(heartRate))
        }
        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            XCTAssertTrue(readTypes.contains(restingHeartRate))
        }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            XCTAssertTrue(readTypes.contains(hrv))
        }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            XCTAssertTrue(readTypes.contains(activeEnergy))
        }
        if let menstrualFlow = HKObjectType.categoryType(forIdentifier: .menstrualFlow) {
            XCTAssertTrue(readTypes.contains(menstrualFlow))
        }
    }

    func testStandardWriteTypes_ContainsWorkoutType() async {
        let writeTypes = HealthKitClient.standardWriteTypes

        XCTAssertTrue(writeTypes.contains(HKObjectType.workoutType()))
    }
}

// MARK: - HealthError Tests (these can run without HealthKit)

final class HealthErrorTests: XCTestCase {
    func testNotAvailable_Description() {
        let error = HealthError.notAvailable

        XCTAssertEqual(error.errorDescription, "HealthKit is not available on this device.")
    }

    func testNotAvailable_RecoverySuggestion() {
        let error = HealthError.notAvailable

        XCTAssertEqual(error.recoverySuggestion, "HealthKit requires an iPhone or Apple Watch.")
    }

    func testAuthorizationDenied_Description() {
        let error = HealthError.authorizationDenied(feature: "heart rate")

        XCTAssertEqual(error.errorDescription, "Authorization denied for heart rate. Please enable in Settings > Privacy & Security > Health.")
    }

    func testAuthorizationDenied_RecoverySuggestion() {
        let error = HealthError.authorizationDenied(feature: "workouts")

        XCTAssertEqual(error.recoverySuggestion, "Open Settings and grant access to health data.")
    }

    func testNoData_Description() {
        let error = HealthError.noData(type: "HRV")

        XCTAssertEqual(error.errorDescription, "No HRV data available.")
    }

    func testNoData_RecoverySuggestion() {
        let error = HealthError.noData(type: "workouts")

        XCTAssertEqual(error.recoverySuggestion, "Start tracking health data to see your history.")
    }

    func testQueryFailed_WithUnderlying_Description() {
        let underlying = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Query timeout"])
        let error = HealthError.queryFailed(underlying: underlying)

        XCTAssertTrue(error.errorDescription!.contains("Health query failed"))
        XCTAssertTrue(error.errorDescription!.contains("Query timeout"))
    }

    func testQueryFailed_WithoutUnderlying_Description() {
        let error = HealthError.queryFailed(underlying: nil)

        XCTAssertEqual(error.errorDescription, "Health query failed.")
    }

    func testQueryFailed_RecoverySuggestion() {
        let error = HealthError.queryFailed(underlying: nil)

        XCTAssertEqual(error.recoverySuggestion, "Try again later or contact support if the issue persists.")
    }
}

// MARK: - Authorization Tests (Require device)

extension HealthKitClientTests {
    /// This test will be skipped on simulators or devices without HealthKit.
    func testRequestAuthorization_WhenNotAvailable_ThrowsNotAvailable() async throws {
        let isAvailable = sut.isAvailable

        guard !isAvailable else {
            throw XCTSkip("HealthKit is available, skipping not available test")
        }

        do {
            try await sut.requestAuthorization(typesToRead: [], typesToWrite: [])
            XCTFail("Expected to throw HealthError.notAvailable")
        } catch {
            XCTAssertTrue(error is HealthError)
            if let healthError = error as? HealthError {
                if case .notAvailable = healthError {
                    // Success
                } else {
                    XCTFail("Expected .notAvailable, got \(healthError)")
                }
            }
        }
    }

    /// Test fetching workouts when HealthKit is not available.
    func testFetchWorkouts_WhenNotAvailable_ThrowsNotAvailable() async throws {
        let isAvailable = sut.isAvailable

        guard !isAvailable else {
            throw XCTSkip("HealthKit is available, skipping not available test")
        }

        do {
            _ = try await sut.fetchWorkouts()
            XCTFail("Expected to throw HealthError.notAvailable")
        } catch {
            XCTAssertTrue(error is HealthError)
            if let healthError = error as? HealthError {
                if case .notAvailable = healthError {
                    // Success
                } else {
                    XCTFail("Expected .notAvailable, got \(healthError)")
                }
            }
        }
    }

    /// Test fetching menstrual cycles when HealthKit is not available.
    func testFetchMenstrualCycles_WhenNotAvailable_ThrowsNotAvailable() async throws {
        let isAvailable = sut.isAvailable

        guard !isAvailable else {
            throw XCTSkip("HealthKit is available, skipping not available test")
        }

        do {
            _ = try await sut.fetchMenstrualCycles()
            XCTFail("Expected to throw HealthError.notAvailable")
        } catch {
            XCTAssertTrue(error is HealthError)
            if let healthError = error as? HealthError {
                if case .notAvailable = healthError {
                    // Success
                } else {
                    XCTFail("Expected .notAvailable, got \(healthError)")
                }
            }
        }
    }

    /// Test fetching active energy when HealthKit is not available.
    func testFetchActiveEnergy_WhenNotAvailable_ThrowsNotAvailable() async throws {
        let isAvailable = sut.isAvailable

        guard !isAvailable else {
            throw XCTSkip("HealthKit is available, skipping not available test")
        }

        let now = Date()
        do {
            _ = try await sut.fetchActiveEnergy(startDate: now, endDate: now)
            XCTFail("Expected to throw HealthError.notAvailable")
        } catch {
            XCTAssertTrue(error is HealthError)
            if let healthError = error as? HealthError {
                if case .notAvailable = healthError {
                    // Success
                } else {
                    XCTFail("Expected .notAvailable, got \(healthError)")
                }
            }
        }
    }

    /// Test fetching HRV when HealthKit is not available.
    func testFetchHeartRateVariability_WhenNotAvailable_ThrowsNotAvailable() async throws {
        let isAvailable = sut.isAvailable

        guard !isAvailable else {
            throw XCTSkip("HealthKit is available, skipping not available test")
        }

        let now = Date()
        do {
            _ = try await sut.fetchHeartRateVariability(startDate: now, endDate: now)
            XCTFail("Expected to throw HealthError.notAvailable")
        } catch {
            XCTAssertTrue(error is HealthError)
            if let healthError = error as? HealthError {
                if case .notAvailable = healthError {
                    // Success
                } else {
                    XCTFail("Expected .notAvailable, got \(healthError)")
                }
            }
        }
    }

    /// Test fetching resting heart rate when HealthKit is not available.
    func testFetchRestingHeartRate_WhenNotAvailable_ThrowsNotAvailable() async throws {
        let isAvailable = sut.isAvailable

        guard !isAvailable else {
            throw XCTSkip("HealthKit is available, skipping not available test")
        }

        let now = Date()
        do {
            _ = try await sut.fetchRestingHeartRate(startDate: now, endDate: now)
            XCTFail("Expected to throw HealthError.notAvailable")
        } catch {
            XCTAssertTrue(error is HealthError)
            if let healthError = error as? HealthError {
                if case .notAvailable = healthError {
                    // Success
                } else {
                    XCTFail("Expected .notAvailable, got \(healthError)")
                }
            }
        }
    }

    /// Test saving workout when HealthKit is not available.
    func testSaveWorkout_WhenNotAvailable_ThrowsNotAvailable() async throws {
        let isAvailable = sut.isAvailable

        guard !isAvailable else {
            throw XCTSkip("HealthKit is available, skipping not available test")
        }

        let now = Date()
        do {
            try await sut.saveWorkout(
                startDate: now,
                endDate: now,
                totalEnergyBurned: 100,
                exercises: []
            )
            XCTFail("Expected to throw HealthError.notAvailable")
        } catch {
            XCTAssertTrue(error is HealthError)
            if let healthError = error as? HealthError {
                if case .notAvailable = healthError {
                    // Success
                } else {
                    XCTFail("Expected .notAvailable, got \(healthError)")
                }
            }
        }
    }
}

// MARK: - HealthError Equatable

extension HealthError: @retroactive Equatable {
    public static func == (lhs: HealthError, rhs: HealthError) -> Bool {
        switch (lhs, rhs) {
        case (.notAvailable, .notAvailable):
            return true
        case (.authorizationDenied(let l), .authorizationDenied(let r)):
            return l == r
        case (.noData(let l), .noData(let r)):
            return l == r
        case (.queryFailed, .queryFailed):
            // Can't compare underlying errors reliably
            return true
        default:
            return false
        }
    }
}
