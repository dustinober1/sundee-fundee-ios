import XCTest
@testable import SundeeFundeeKit

final class SharePrivacyTests: XCTestCase {
    func testPrivateDefaultDisclosureKeepsSensitiveOptionsOnDevice() {
        XCTAssertEqual(
            SharePrivacyOptions.privateDefault.shareDisclosureText,
            "Only information shown in this preview is shared. Health data and private notes not shown here stay on your device."
        )
    }

    func testCycleEnabledDisclosureSaysCycleContextMayBeIncluded() {
        let options = SharePrivacyOptions(showCycleContext: true)

        XCTAssertEqual(
            options.shareDisclosureText,
            "Only information shown in this preview is shared. Cycle context may be included when available. Other health data and private notes not shown here stay on your device."
        )
    }

    func testPainEnabledDisclosureSaysPainContextMayBeIncluded() {
        let options = SharePrivacyOptions(showPainContext: true)

        XCTAssertEqual(
            options.shareDisclosureText,
            "Only information shown in this preview is shared. Pain context may be included when available. Other health data and private notes not shown here stay on your device."
        )
    }

    func testCycleAndPainEnabledDisclosureSaysBothContextsMayBeIncluded() {
        let options = SharePrivacyOptions(
            showCycleContext: true,
            showPainContext: true
        )

        XCTAssertEqual(
            options.shareDisclosureText,
            "Only information shown in this preview is shared. Cycle context and pain context may be included when available. Other health data and private notes not shown here stay on your device."
        )
    }

    func testExactDateEnabledDisclosureSaysExactDateMayBeIncluded() {
        let options = SharePrivacyOptions(showExactDate: true)

        XCTAssertEqual(
            options.shareDisclosureText,
            "Only information shown in this preview is shared. An exact date may be included when available. Health data and private notes not shown here stay on your device."
        )
    }

    func testDefaultPrivacyOptionsArePrivate() {
        let options = SharePrivacyOptions.privateDefault
        XCTAssertFalse(options.showCycleContext)
        XCTAssertFalse(options.showPainContext)
        XCTAssertFalse(options.showExactDate)
    }

    func testDefaultPrivacyRedactsSensitiveTerms() {
        let options = SharePrivacyOptions.privateDefault
        let source = "Cycle phase day 12 with pain notes."
        let redacted = options.redactSensitiveText(source)

        XCTAssertFalse(redacted.localizedCaseInsensitiveContains("cycle"))
        XCTAssertFalse(redacted.localizedCaseInsensitiveContains("phase"))
        XCTAssertFalse(redacted.localizedCaseInsensitiveContains("pain"))
    }

    func testDefaultPrivacyHidesExactDate() {
        let options = SharePrivacyOptions.privateDefault
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertEqual(options.redactedDateText(for: date), "Recent Session")
    }

    func testEnabledPrivacyTogglesPreserveTerms() {
        let options = SharePrivacyOptions(
            showCycleContext: true,
            showPainContext: true,
            showExactDate: true
        )
        let source = "Cycle phase day 12 with pain notes."
        let redacted = options.redactSensitiveText(source)

        XCTAssertTrue(redacted.localizedCaseInsensitiveContains("cycle"))
        XCTAssertTrue(redacted.localizedCaseInsensitiveContains("phase"))
        XCTAssertTrue(redacted.localizedCaseInsensitiveContains("pain"))
        XCTAssertNotEqual(options.redactedDateText(for: Date(timeIntervalSince1970: 1_700_000_000)), "Recent Session")
    }

    func testSanitizedShareSheetOpenedDoesNotUseCallerSource() throws {
        let context = ShareContext(
            surface: .completedWorkout,
            sourceID: "workout-123",
            title: "Private workout",
            referralCode: "secret-code"
        )
        let summary = try ShareSanitizedSummary(
            title: "Ready to train",
            subtitle: "Keep building momentum",
            metricLabel: nil,
            metricValue: nil,
            modelVersion: "v2"
        )

        XCTAssertNil(
            ShareCardVariant.readiness(summary: summary).shareSheetOpenedSource(shareContext: context)
        )
        XCTAssertNil(
            ShareCardVariant.deload(summary: summary).shareSheetOpenedSource(shareContext: context)
        )
    }
}
