import XCTest
@testable import SundeeFundeeKit

final class GrowthAnalyticsServiceTests: XCTestCase {
    func testTrackSavesGrowthEventRecord() async throws {
        let client = MockCloudKitClient()
        let service = GrowthAnalyticsService(dataClient: client)

        await service.track(
            GrowthEventName.firstWorkoutStarted,
            source: "test",
            properties: ["surface": "onboarding"]
        )

        XCTAssertEqual(client.recordCount(for: "GrowthEvent"), 1)
        let events: [GrowthEvent] = try await client.fetchAll(recordType: "GrowthEvent")
        XCTAssertEqual(events.first?.name, GrowthEventName.firstWorkoutStarted)
        XCTAssertEqual(events.first?.source, "test")
        XCTAssertNotNil(events.first?.propertiesJSON)
    }
}
