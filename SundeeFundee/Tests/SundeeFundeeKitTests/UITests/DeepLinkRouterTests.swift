import XCTest
@testable import SundeeFundeeKit

final class DeepLinkRouterTests: XCTestCase {
    func testParsesCycleRoute() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://cycle")!)

        XCTAssertEqual(route, .cycle)
    }

    func testParsesCheckInRoute() {
        let route = DeepLinkRouter.route(for: URL(string: "sundeefundee://today/check-in")!)

        XCTAssertEqual(route, .todayCheckIn)
    }

    func testRejectsWrongScheme() {
        let route = DeepLinkRouter.route(for: URL(string: "https://sundeefundee.com")!)

        XCTAssertNil(route)
    }
}
