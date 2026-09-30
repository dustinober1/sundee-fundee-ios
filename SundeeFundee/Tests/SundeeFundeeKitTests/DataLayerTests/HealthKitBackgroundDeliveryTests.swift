import HealthKit
import XCTest
@testable import SundeeFundeeKit

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
final class HealthKitBackgroundDeliveryTests: XCTestCase {
    private var mockHealth: MockHealthKitClient!
    private var mockDataClient: MockCloudKitClient!
    private var previousClient: (any DataClientProtocol)?
    private var defaults: UserDefaults!
    private var previousDefaults: UserDefaults?

    override func setUp() async throws {
        try await super.setUp()
        mockHealth = MockHealthKitClient()
        mockDataClient = MockCloudKitClient()

        previousDefaults = SharedSnapshotStore.defaults
        defaults = UserDefaults(suiteName: "HealthKitBackgroundDeliveryTests.\(UUID().uuidString)") ?? .standard
        SharedSnapshotStore.defaults = defaults
        SharedSnapshotStore.clear()
    }

    override func tearDown() async throws {
        SharedSnapshotStore.clear()
        SharedSnapshotStore.defaults = previousDefaults
        defaults = nil
        previousDefaults = nil
        mockHealth = nil
        mockDataClient = nil
        try await super.tearDown()
    }

    private func makeReadinessService() -> DailyReadinessService {
        let builder = DailyTrainingContextBuilder(
            healthProvider: FixedHealthProvider(value: .empty),
            historyProvider: FixedHistoryProvider(value: HistoryReadinessSnapshot(
                subjective: SubjectiveReadinessSnapshot(energy: 7, fatigue: 3),
                training: .empty,
                pain: nil
            ))
        )
        return DailyReadinessService(contextBuilder: builder, dataClient: mockDataClient)
    }

    func testStartObserving_RegistersExpectedTypes() async {
        let coordinator = HealthKitBackgroundDeliveryCoordinator(
            healthClient: mockHealth,
            readinessService: makeReadinessService()
        )

        await coordinator.startObserving()

        let registered = mockHealth.enabledBackgroundDeliveryTypes
        XCTAssertFalse(registered.isEmpty)

        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            XCTAssertTrue(registered.contains(hrvType))
        }
        if let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            XCTAssertTrue(registered.contains(rhrType))
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            XCTAssertTrue(registered.contains(sleepType))
        }
    }

    func testStartObserving_WhenNotAvailable_DoesNotRegister() async {
        mockHealth.isAvailable = false
        let coordinator = HealthKitBackgroundDeliveryCoordinator(
            healthClient: mockHealth,
            readinessService: makeReadinessService()
        )

        await coordinator.startObserving()

        XCTAssertTrue(mockHealth.enabledBackgroundDeliveryTypes.isEmpty)
    }

    func testEvaluateMorningReadiness_Throttling() async {
        let coordinator = HealthKitBackgroundDeliveryCoordinator(
            healthClient: mockHealth,
            readinessService: makeReadinessService()
        )

        // First run with force: true sets lastAssessmentTime
        let firstResult = await coordinator.evaluateMorningReadiness(force: true)
        XCTAssertTrue(firstResult)

        // Immediate subsequent call with force: false must be throttled
        let throttled = await coordinator.evaluateMorningReadiness(force: false)
        XCTAssertFalse(throttled)

        // Forcing bypasses throttle
        let forced = await coordinator.evaluateMorningReadiness(force: true)
        XCTAssertTrue(forced)
    }

    func testSaveMenstrualFlow_WritesToHealthKitWithMetadata() async throws {
        let now = Date()
        try await mockHealth.saveMenstrualFlow(
            startDate: now,
            endDate: nil,
            flow: .unspecified,
            isStartOfCycle: true
        )

        XCTAssertEqual(mockHealth.saveMenstrualFlowCallCount, 1)
        XCTAssertEqual(mockHealth.menstrualCycleCount(), 1)

        let cycles = try await mockHealth.fetchMenstrualCycles(startDate: nil, endDate: nil, limit: 10)
        let sample = try XCTUnwrap(cycles.first)
        XCTAssertEqual(sample.startDate, now)
        XCTAssertEqual(sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool, true)
        XCTAssertEqual(sample.metadata?["com.sundeefundee.origin"] as? String, "manual_period_log")
        XCTAssertEqual(sample.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool, true)
    }
}

private actor FixedHealthProvider: HealthReadinessProviding {
    let value: PhysiologicalReadinessSnapshot
    init(value: PhysiologicalReadinessSnapshot) { self.value = value }
    func load(assessmentDate: Date, calendar: Calendar) async -> PhysiologicalReadinessSnapshot { value }
}

private actor FixedHistoryProvider: HistoryReadinessProviding {
    let value: HistoryReadinessSnapshot
    init(value: HistoryReadinessSnapshot) { self.value = value }
    func load(assessmentDate: Date, calendar: Calendar) async -> HistoryReadinessSnapshot { value }
}
