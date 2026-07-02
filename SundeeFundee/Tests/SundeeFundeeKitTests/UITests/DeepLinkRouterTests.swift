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
}
