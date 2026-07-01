import XCTest
@testable import SundeeFundeeKit

final class CoachPlanFeedbackServiceTests: XCTestCase {
    func testSubmitSavesMetadataOnlyFeedback() async throws {
        let client = MockCloudKitClient()
        let service = CoachPlanFeedbackService(dataClient: client)

        try await service.submit(
            rating: .helpful,
            surface: "coach_plan_preview",
            workoutID: "workout-1",
            copySource: "deterministic_fallback",
            promptVersion: "v1",
            reasonCodes: ["lowEnergyReducedVolume", "equipmentLimitedExercisePool"]
        )

        let records: [CoachPlanFeedbackRecord] = try await client.fetchAll(recordType: "CoachPlanFeedback")
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.ratingRaw, "helpful")
        XCTAssertEqual(records.first?.surface, "coach_plan_preview")
        XCTAssertEqual(records.first?.copySource, "deterministic_fallback")
        XCTAssertEqual(records.first?.promptVersion, "v1")
        XCTAssertEqual(records.first?.reasonCodesJSON, "[\"lowEnergyReducedVolume\",\"equipmentLimitedExercisePool\"]")
        XCTAssertNil(records.first?.rawPrompt)
        XCTAssertNil(records.first?.rawOutput)
    }
}
