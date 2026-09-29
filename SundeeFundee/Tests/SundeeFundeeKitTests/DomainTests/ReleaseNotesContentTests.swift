import XCTest
@testable import SundeeFundeeKit

final class ReleaseNotesContentTests: XCTestCase {
    func testCurrentReleaseNotesMentionSupportTipAndV2Surfaces() {
        let text = ReleaseNotesContent.current.items.map(\.body).joined(separator: " ")

        XCTAssertTrue(text.contains("Support the Developer"))
        XCTAssertTrue(text.contains("Best Next 20 Min"))
        XCTAssertTrue(text.contains("Data Trust Center"))
        XCTAssertTrue(text.contains("Monthly Review"))
        XCTAssertTrue(text.contains("micro-pods"))
        XCTAssertTrue(text.contains("Apple Watch"))
        XCTAssertTrue(text.contains("plate loading"))
        XCTAssertTrue(text.contains("Siri"))
        XCTAssertFalse(text.contains("NEW IN 1.4"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("fundraiser"))
    }
}
