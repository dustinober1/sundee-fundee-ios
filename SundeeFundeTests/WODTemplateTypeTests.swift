import XCTest
@testable import SundeeFundee

final class WODTemplateTypeTests: XCTestCase {
    func testInitFromRawValue() {
        XCTAssertEqual(WODTemplateType(rawValue: "strength"), .strength)
        XCTAssertEqual(WODTemplateType(rawValue: "amrap"), .amrap)
        XCTAssertEqual(WODTemplateType(rawValue: "emom"), .emom)
        XCTAssertEqual(WODTemplateType(rawValue: "forTime"), .forTime)
        XCTAssertEqual(WODTemplateType(rawValue: "circuit"), .circuit)
    }

    func testUnknownRawValueDefaultsToStrength() {
        XCTAssertEqual(WODTemplateType.from("garbage"), .strength)
        XCTAssertEqual(WODTemplateType.from(""), .strength)
    }

    func testDisplayName() {
        XCTAssertEqual(WODTemplateType.strength.displayName, "Strength")
        XCTAssertEqual(WODTemplateType.amrap.displayName, "AMRAP")
        XCTAssertEqual(WODTemplateType.emom.displayName, "EMOM")
        XCTAssertEqual(WODTemplateType.forTime.displayName, "For Time")
        XCTAssertEqual(WODTemplateType.circuit.displayName, "Circuit")
    }

    func testRequiresTimer() {
        XCTAssertTrue(WODTemplateType.amrap.requiresTimer)
        XCTAssertTrue(WODTemplateType.emom.requiresTimer)
        XCTAssertTrue(WODTemplateType.forTime.requiresTimer)
        XCTAssertFalse(WODTemplateType.strength.requiresTimer)
        XCTAssertFalse(WODTemplateType.circuit.requiresTimer)
    }
}
