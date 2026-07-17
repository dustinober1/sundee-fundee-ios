import XCTest
@testable import SundeeFundeeKit

final class DeloadWorkoutIntegrationTests: XCTestCase {
    private func assessment(_ state: ReadinessState, confidence: ReadinessConfidence = .high) -> ReadinessAssessment {
        ReadinessAssessment(assessmentDate: Date(), state: state, totalScore: state == .ready ? 90 : 45, confidence: confidence, subScores: [:], availableSignals: [], missingSignals: [], staleSignals: [], positiveReasons: [], cautionReasons: [], modelVersion: "2.0")
    }

    func testNormalEntryPreservesStandardRequest() throws {
        let decision = DeloadDecisionService.evaluate(readiness: assessment(.ready), trainingLoad: .balanced, pain: 0, history: .none)
        let request = BestNextWorkoutRequestBuilder.build(defaultEquipment: .fullGym, latestEnergy: .high, painLogs: [], todayDecisionKind: .modify, deloadDecision: decision)
        XCTAssertEqual(request.energyLevel, .high)
        XCTAssertEqual(BestNextWorkoutRequestBuilder.adjustment(for: decision).decision?.mode, .normal)
    }

    func testReducedAndActiveRecoveryEntryLowerRecoveryDemand() throws {
        let reduced = DeloadDecisionService.evaluate(readiness: assessment(.recover), trainingLoad: .balanced, pain: 0, history: .none)
        let active = DeloadDecisionService.evaluate(readiness: assessment(.ready), trainingLoad: .balanced, pain: 8, history: .none)
        let reducedRequest = BestNextWorkoutRequestBuilder.build(defaultEquipment: .fullGym, latestEnergy: .high, painLogs: [], todayDecisionKind: .modify, deloadDecision: reduced)
        let activeRequest = BestNextWorkoutRequestBuilder.build(defaultEquipment: .fullGym, latestEnergy: .high, painLogs: [], todayDecisionKind: .modify, deloadDecision: active)
        XCTAssertEqual(reducedRequest.energyLevel, .medium)
        XCTAssertEqual(activeRequest.energyLevel, .low)
        XCTAssertTrue(BestNextWorkoutRequestBuilder.adjustment(for: active).explanation.contains("Active recovery"))
    }

    @MainActor
    func testGuestAndMissingReadinessUseNormalFallback() async {
        let guest = BestNextWorkoutViewModel(dataClient: MockCloudKitClient(), isGuest: true)
        _ = await guest.buildWorkout()
        XCTAssertNil(guest.adjustment.decision)
        XCTAssertTrue(guest.adjustment.isStandardSession)

        let missing = BestNextWorkoutViewModel(dataClient: MockCloudKitClient())
        _ = await missing.buildWorkout()
        XCTAssertNil(missing.adjustment.decision)
    }

    @MainActor
    func testGuestAuthStateUpdateClearsPersistedDeloadAdjustment() async {
        let viewModel = BestNextWorkoutViewModel(dataClient: MockCloudKitClient())
        viewModel.updateGuestState(true)
        _ = await viewModel.buildWorkout()

        XCTAssertTrue(viewModel.adjustment.isStandardSession)
        XCTAssertNil(viewModel.adjustment.decision)
    }

    @MainActor
    func testStaleReadinessAssessmentDoesNotTriggerDeload() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let staleAssessment = ReadinessAssessment(
            assessmentDate: yesterday, state: .recover, totalScore: 20,
            confidence: .high, subScores: [:], availableSignals: [],
            missingSignals: [], staleSignals: [], positiveReasons: [],
            cautionReasons: [], modelVersion: "2.0"
        )
        let client = MockCloudKitClient()
        try await client.save(
            DailyReadinessRecord(assessment: staleAssessment, timeZone: .current),
            recordType: DailyReadinessRecord.recordType
        )

        let viewModel = BestNextWorkoutViewModel(dataClient: client)
        _ = await viewModel.buildWorkout()

        XCTAssertNil(viewModel.adjustment.decision)
        XCTAssertTrue(viewModel.adjustment.isStandardSession)
    }

    @MainActor
    func testIncompleteWorkoutsDoNotIncreaseRecentTrainingLoad() async throws {
        let client = MockCloudKitClient()
        try await client.save(
            DailyReadinessRecord(assessment: assessment(.ready), timeZone: .current),
            recordType: DailyReadinessRecord.recordType
        )
        for index in 0..<4 {
            let plannedWorkout = Workout(
                id: "planned-\(index)",
                date: Date().addingTimeInterval(Double(index) * -3_600),
                name: "Planned workout \(index)",
                exercises: [],
                completedAt: nil
            )
            try await client.save(plannedWorkout, recordType: "Workout")
        }

        let viewModel = BestNextWorkoutViewModel(dataClient: client)
        _ = await viewModel.buildWorkout()

        XCTAssertEqual(viewModel.adjustment.decision?.mode, .normal)
        XCTAssertFalse(viewModel.adjustment.decision?.reasonCodes.contains(.highTrainingLoad) == true)
    }
}
