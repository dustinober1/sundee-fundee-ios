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

    func testTrackDropsCycleInsightSourceAndSurfaceMetadata() async throws {
        let client = MockCloudKitClient()
        let service = GrowthAnalyticsService(dataClient: client)

        await service.track(
            GrowthEventName.shareSheetOpened,
            source: ShareSurface.cycleInsight.rawValue,
            properties: ["surface": ShareSurface.cycleInsight.rawValue]
        )

        let events: [GrowthEvent] = try await client.fetchAll(recordType: "GrowthEvent")
        let event = try XCTUnwrap(events.first)
        XCTAssertNil(event.source)
        XCTAssertNil(event.propertiesJSON)
    }

    func testTrackRejectsUnknownEventName() async {
        let client = MockCloudKitClient()
        let service = GrowthAnalyticsService(dataClient: client)

        await service.track("custom_event", source: "dashboard", properties: ["surface": "dashboard"])

        XCTAssertEqual(client.recordCount(for: "GrowthEvent"), 0)
    }

    func testTrackDropsArbitraryTitleAndPrivateTextStructurally() async throws {
        let client = MockCloudKitClient()
        let service = GrowthAnalyticsService(dataClient: client)

        await service.track(
            GrowthEventName.shareSheetOpened,
            source: "dashboard",
            properties: [
                "title": "My private journal entry about a diagnosis",
                "from": "Generated text with health details",
                "surface": "dashboard",
                "workoutID": "workout-123"
            ]
        )

        let events: [GrowthEvent] = try await client.fetchAll(recordType: "GrowthEvent")
        let properties = try XCTUnwrap(events.first?.propertiesJSON)
        XCTAssertFalse(properties.contains("title"))
        XCTAssertFalse(properties.contains("from"))
        XCTAssertTrue(properties.contains("surface"))
        XCTAssertTrue(properties.contains("workoutID"))
    }
}
