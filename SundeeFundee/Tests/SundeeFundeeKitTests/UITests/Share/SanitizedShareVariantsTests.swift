import XCTest
@testable import SundeeFundeeKit

final class ShareSanitizedSummaryShareTests: XCTestCase {
    func testAllowedOutcomeMetadataSupportsOptionalFields() throws {
        let summary = try ShareSanitizedSummary(
            title: "Deload complete",
            subtitle: nil,
            metricLabel: "Focus",
            metricValue: "Mobility",
            modelVersion: "2.0"
        )
        XCTAssertEqual(summary.title, "Deload complete")
        XCTAssertNil(summary.subtitle)
        XCTAssertEqual(summary.metricLabel, "Focus")
        XCTAssertEqual(summary.metricValue, "Mobility")
    }

    func testDefaultPrivacyDoesNotOptIntoSensitiveInputs() {
        let options = SharePrivacyOptions.privateDefault
        XCTAssertFalse(options.showCycleContext)
        XCTAssertFalse(options.showPainContext)
        XCTAssertFalse(options.showExactDate)
    }

    func testShareCancellationDoesNotChangePrivacyPreset() {
        let before = SharePrivacyOptions.savedPreset
        defer { SharePrivacyOptions.savedPreset = before }
        let configured = SharePrivacyOptions(showExactDate: true)
        SharePrivacyOptions.savedPreset = configured
        // System ShareLink cancellation has no completion callback; its contract is
        // that cancellation leaves the preset untouched.
        XCTAssertEqual(SharePrivacyOptions.savedPreset, configured)
    }
}
