import XCTest
@testable import SundeeFundeeKit

final class UnitConverterTests: XCTestCase {
    func testLbsToKg() {
        XCTAssertEqual(lbsToKg(100), 45.36, accuracy: 0.01)
        XCTAssertEqual(lbsToKg(225), 102.06, accuracy: 0.01)
    }

    func testKgToLbs() {
        XCTAssertEqual(kgToLbs(45), 99.21, accuracy: 0.01)
        XCTAssertEqual(kgToLbs(100), 220.46, accuracy: 0.01)
    }

    func testRoundConversion() {
        XCTAssertEqual(lbsToKg(185), 83.91, accuracy: 0.01)
    }
}
