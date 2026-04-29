import XCTest
@testable import SundeeFundeeKit

final class GrowthLinkServiceTests: XCTestCase {
    func testCaptionUsesChallengeContextAndReferralCode() {
        let context = ShareContext(
            surface: .challenge,
            sourceID: "Challenge 123",
            title: "500K Volume Challenge",
            referralCode: "ABCD1234"
        )

        let caption = GrowthLinkService.caption(for: context)

        XCTAssertTrue(caption.contains("500K Volume Challenge"))
        XCTAssertTrue(caption.contains("ABCD1234"))
        XCTAssertTrue(caption.contains("apps.apple.com"))
    }

    func testLinkAddsSafeCampaignMetadata() {
        let context = ShareContext(
            surface: .personalRecord,
            sourceID: "Bench Press!",
            title: "New PR",
            referralCode: "A B C"
        )

        let url = GrowthLinkService.link(for: context).absoluteString

        XCTAssertTrue(url.contains("ct=personalRecord"))
        XCTAssertTrue(url.contains("mt=benchpress"))
        XCTAssertTrue(url.contains("ref=abc"))
    }
}
