@testable import SundeeFundeeKit
import XCTest

final class DeepLinkRouterTests: XCTestCase {
    func testParsesCycleRoute() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://cycle")!)

        XCTAssertEqual(route, .cycle)
    }

    func testParsesCheckInRoute() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://today/check-in")!)

        XCTAssertEqual(route, .todayCheckIn)
    }

    func testCheckInRouteTargetsTodayAndOpensCheckIn() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://today/check-in")!)

        XCTAssertEqual(route?.targetTab, .today)
        XCTAssertTrue(route?.opensQuickCheckIn == true)
    }

    func testCycleRouteTargetsCycleWithoutOpeningCheckIn() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://cycle")!)

        XCTAssertEqual(route?.targetTab, .cycle)
        XCTAssertFalse(route?.opensQuickCheckIn == true)
    }

    func testRejectsWrongScheme() {
        let route = DeepLinkRouter.route(for: URL(string: "https://sundeefundee.com")!)

        XCTAssertNil(route)
    }

    // MARK: - Challenge Invite Codes

    func testParsesInviteCodeFromHost() {
        let code = DeepLinkRouter.inviteCode(for: URL(string: "sundeefundee://invite/ABCD1234")!)

        XCTAssertEqual(code, "ABCD1234")
    }

    func testParsesInviteCodeFromPath() {
        let code = DeepLinkRouter.inviteCode(for: URL(string: "sundeefundee:///invite/ABCD1234")!)

        XCTAssertEqual(code, "ABCD1234")
    }

    func testParsesInviteCodeFromJoinQuery() {
        let code = DeepLinkRouter.inviteCode(for: URL(string: "sundeefundee://join?code=abcd1234")!)

        XCTAssertEqual(code, "ABCD1234")
    }

    func testInviteCodeNormalizesLowercaseAndStripsPadding() {
        let code = DeepLinkRouter.inviteCode(for: URL(string: "sundeefundee://invite/abcd-1234")!)

        XCTAssertEqual(code, "ABCD1234")
    }

    func testInviteCodeCapsLengthAtTwelve() {
        let code = DeepLinkRouter.inviteCode(for: URL(string: "sundeefundee://invite/ABCDEFGHIJKLMNOPQRST")!)

        XCTAssertEqual(code, "ABCDEFGHIJKL")
    }

    func testInviteParsingRejectsWrongSchemeAndUnknownHosts() {
        XCTAssertNil(DeepLinkRouter.inviteCode(for: URL(string: "https://sundeefundee.com/invite/ABCD1234")!))
        XCTAssertNil(DeepLinkRouter.inviteCode(for: URL(string: "sundeefundee://cycle")!))
        XCTAssertNil(DeepLinkRouter.inviteCode(for: URL(string: "sundeefundee://invite")!))
    }

    func testInviteURIRoundTripsThroughParser() {
        let url = GrowthLinkService.inviteDeepLink(code: "ABCD1234")

        XCTAssertEqual(DeepLinkRouter.inviteCode(for: url), "ABCD1234")
        XCTAssertEqual(DeepLinkRouter.inviteURL(code: "ABCD1234"), url)
    }

    // MARK: - Readiness Detail Route

    func testParsesReadinessDetailRoute() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://today/readiness")!)

        XCTAssertEqual(route, .readinessDetail)
    }

    func testReadinessDetailRouteTargetsTodayAndOpensReadinessDetailOnly() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://today/readiness")!)

        XCTAssertEqual(route?.targetTab, .today)
        XCTAssertTrue(route?.opensReadinessDetail == true)
        XCTAssertFalse(route?.opensQuickCheckIn == true)
    }

    func testReadinessDetailRouteURLRoundTrips() {
        let url = DeepLinkRouter.url(for: .readinessDetail)

        XCTAssertEqual(DeepLinkRouter.route(for: url), .readinessDetail)
    }
}
