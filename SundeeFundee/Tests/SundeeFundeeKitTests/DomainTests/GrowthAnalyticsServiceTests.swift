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

    func testTrackDropsSensitiveMetadataAtAnalyticsBoundary() async throws {
        let client = MockCloudKitClient()
        let service = GrowthAnalyticsService(dataClient: client)

        await service.track(
            GrowthEventName.shareSheetOpened,
            source: "cycle phase day 12",
            properties: [
                "surface": "dashboard",
                "pain_intensity": "8",
                "private_note": "keep this confidential"
            ]
        )

        let events: [GrowthEvent] = try await client.fetchAll(recordType: "GrowthEvent")
        XCTAssertNil(events.first?.source)
        let properties = try XCTUnwrap(events.first?.propertiesJSON)
        XCTAssertTrue(properties.contains("surface"))
        XCTAssertFalse(properties.contains("pain_intensity"))
        XCTAssertFalse(properties.contains("private_note"))
    }
}
