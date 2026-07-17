import XCTest
@testable import SundeeFundeeKit

final class ShareURLTests: XCTestCase {
    func testAppStoreURLIsValidHTTPS() {
        XCTAssertEqual(ShareURL.appStore.scheme, "https")
        XCTAssertEqual(ShareURL.appStore.host, "apps.apple.com")
        XCTAssertTrue(ShareURL.appStore.absoluteString.contains("id6759870888"))
    }

    func testShareCaptionContainsAppStoreURL() {
        XCTAssertTrue(ShareURL.shareCaption.contains(ShareURL.appStore.absoluteString))
        XCTAssertTrue(ShareURL.shareCaption.contains("Sundee Fundee"))
    }

    func testSanitizedPayloadNeverContainsCallerContext() {
        let rawTitle = "PRIVATE readiness title"
        let rawReferral = "SECRET-REFERRAL"
        let rawSourceID = "private-source-id"

        XCTAssertFalse(ShareURL.sanitizedCaption.contains(rawTitle))
        XCTAssertFalse(ShareURL.sanitizedCaption.contains(rawReferral))
        XCTAssertFalse(ShareURL.sanitizedCaption.contains(rawSourceID))
        XCTAssertFalse(ShareURL.sanitizedLink.absoluteString.contains(rawTitle))
        XCTAssertFalse(ShareURL.sanitizedLink.absoluteString.contains(rawReferral))
        XCTAssertFalse(ShareURL.sanitizedLink.absoluteString.contains(rawSourceID))
    }
}
