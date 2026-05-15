import XCTest
@testable import SundeeFundeeKit

final class GrowthLinkServiceTests: XCTestCase {
    func testLinkAddsShareUtmMetadataWithoutProviderToken() {
        let context = ShareContext(
            surface: .completedWorkout,
            sourceID: "Upper Body Strength",
            title: "Workout Done"
        )

        let url = GrowthLinkService.link(for: context)
        let items = queryItems(for: url)

        XCTAssertEqual(items["utm_source"], "sundee_ios")
        XCTAssertEqual(items["utm_medium"], "share")
        XCTAssertEqual(items["utm_term"], "app_store")
        XCTAssertEqual(items["utm_campaign"], "completedWorkout")
        XCTAssertEqual(items["utm_content"], "Upper Body Strength")
        XCTAssertNil(items["pt"])
        XCTAssertNil(items["ct"])
        XCTAssertNil(items["mt"])
    }

    func testLinkAddsProviderAttributionWhenConfigured() {
        let context = ShareContext(
            surface: .personalRecord,
            sourceID: "Bench Press!",
            title: "New PR"
        )

        let url = GrowthLinkService.link(
            for: context,
            configuration: GrowthLinkConfiguration(providerToken: "12345")
        )
        let items = queryItems(for: url)

        XCTAssertEqual(items["pt"], "12345")
        XCTAssertEqual(items["ct"], "personalrecord_bench_press")
        XCTAssertEqual(items["mt"], "8")
    }

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

        XCTAssertTrue(url.contains("utm_campaign=personalRecord"))
        XCTAssertTrue(url.contains("utm_content=Bench%20Press!"))
        XCTAssertTrue(url.contains("ref=abc"))
    }

    private func queryItems(for url: URL) -> [String: String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })
    }
}
