import XCTest
@testable import SundeeFundee

final class CyclePhaseCalculatorTests: XCTestCase {
    func testPhaseColorName_mapsPhasesToBrandPalette() {
        XCTAssertEqual(CyclePhaseCalculator.phaseColorName(.menstrual), "BrandDanger")
        XCTAssertEqual(CyclePhaseCalculator.phaseColorName(.follicular), "BrandGold")
        XCTAssertEqual(CyclePhaseCalculator.phaseColorName(.ovulation), "BrandOrange")
        XCTAssertEqual(CyclePhaseCalculator.phaseColorName(.luteal), "BrandNavy")
    }
}

