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
}
