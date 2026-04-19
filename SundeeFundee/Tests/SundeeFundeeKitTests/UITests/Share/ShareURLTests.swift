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
}
