import XCTest
@testable import SundeeFundeeKit

final class ShareSanitizedSummaryTests: XCTestCase {
    func testSummaryRoundTripsAndContainsOnlyDisplayMetadata() throws {
        let summary = try ShareSanitizedSummary(title: "Workout complete", subtitle: "Upper body", metricLabel: "Volume", metricValue: "12,400 kg", modelVersion: "2.0")
        XCTAssertEqual(try JSONDecoder().decode(ShareSanitizedSummary.self, from: JSONEncoder().encode(summary)), summary)
        XCTAssertFalse(String(data: try JSONEncoder().encode(summary), encoding: .utf8)!.contains("pain"))
    }

    func testModelVersionMustNotBeEmpty() {
        XCTAssertNil(try? ShareSanitizedSummary(title: "Done", subtitle: nil, metricLabel: nil, metricValue: nil, modelVersion: ""))
    }

    func testSensitiveDisplayTextIsRejectedAcrossFields() {
        for field in ["HealthKit sleep", "Cycle phase", "Pain 8/10", "private note", "prompt: write this", "AI-generated text"] {
            XCTAssertThrowsError(try ShareSanitizedSummary(title: field, subtitle: nil, metricLabel: nil, metricValue: nil, modelVersion: "2.0"))
            XCTAssertThrowsError(try ShareSanitizedSummary(title: "Done", subtitle: field, metricLabel: nil, metricValue: nil, modelVersion: "2.0"))
            XCTAssertThrowsError(try ShareSanitizedSummary(title: "Done", subtitle: nil, metricLabel: field, metricValue: nil, modelVersion: "2.0"))
            XCTAssertThrowsError(try ShareSanitizedSummary(title: "Done", subtitle: nil, metricLabel: nil, metricValue: field, modelVersion: "2.0"))
        }
    }

    func testDecodingAlsoEnforcesSafeContent() throws {
        let data = #"{"title":"Done","subtitle":"pain: 8","metricLabel":null,"metricValue":null,"modelVersion":"2.0"}"#.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ShareSanitizedSummary.self, from: data))
    }

    func testDecodingEnforcesRequiredFields() {
        let emptyTitle = #"{"title":"  ","subtitle":null,"metricLabel":null,"metricValue":null,"modelVersion":"2.0"}"#.data(using: .utf8)!
        let emptyVersion = #"{"title":"Done","subtitle":null,"metricLabel":null,"metricValue":null,"modelVersion":"  "}"#.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ShareSanitizedSummary.self, from: emptyTitle))
        XCTAssertThrowsError(try JSONDecoder().decode(ShareSanitizedSummary.self, from: emptyVersion))
    }
}
