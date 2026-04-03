import XCTest
@testable import SundeeFundeeKit

final class PlateCalculatorTests: XCTestCase {
    func testCalculatePlates_185lbs() {
        // 185 = 45 (bar) + 70 per side = 45+25 per side
        let plates = calculatePlates(targetWeight: 185, barWeight: 45)

        // Should have 45s and 25s
        XCTAssertEqual(plates.count, 2)
        XCTAssertEqual(plates[0].weight, 45)
        XCTAssertEqual(plates[0].count, 1)
        XCTAssertEqual(plates[1].weight, 25)
        XCTAssertEqual(plates[1].count, 1)
    }

    func testCalculatePlates_225lbs() {
        // 225 = 45 (bar) + 90 per side = 45+45 per side
        let plates = calculatePlates(targetWeight: 225, barWeight: 45)

        XCTAssertEqual(plates.count, 1)
        XCTAssertEqual(plates[0].weight, 45)
        XCTAssertEqual(plates[0].count, 2)  // Two 45lb plates per side
    }

    func testCalculatePlates_InvalidWeight() {
        // Less than bar weight should return empty
        let plates = calculatePlates(targetWeight: 35, barWeight: 45)
        XCTAssertTrue(plates.isEmpty)
    }
}
