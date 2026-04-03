import XCTest
@testable import SundeeFundeeKit

final class BodyLocationTests: XCTestCase {

    // MARK: - bodyRegions

    func testBodyRegions_Contains17Regions() {
        XCTAssertEqual(bodyRegions.count, 17)
    }

    func testBodyRegions_AllHaveNonEmptyFields() {
        for r in bodyRegions {
            XCTAssertFalse(r.id.isEmpty, "Region should have non-empty id")
            XCTAssertFalse(r.displayName.isEmpty, "Region should have non-empty displayName")
            XCTAssertFalse(r.engineKey.isEmpty, "Region should have non-empty engineKey")
        }
    }

    func testBodyRegions_AllIDsAreUnique() {
        let ids = bodyRegions.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testBodyRegions_HeadHasEngineKeyHead() {
        let r = bodyRegions.first { $0.id == "head" }
        XCTAssertEqual(r?.engineKey, "head")
    }

    func testBodyRegions_ShouldersHaveEngineKeyShoulder() {
        let left = bodyRegions.first { $0.id == "shoulder_left" }
        let right = bodyRegions.first { $0.id == "shoulder_right" }
        XCTAssertEqual(left?.engineKey, "shoulder")
        XCTAssertEqual(right?.engineKey, "shoulder")
    }

    func testBodyRegions_BackRegionsHaveEngineKeyBack() {
        let upper = bodyRegions.first { $0.id == "upper_back" }
        let lower = bodyRegions.first { $0.id == "lower_back" }
        XCTAssertEqual(upper?.engineKey, "back")
        XCTAssertEqual(lower?.engineKey, "back")
    }

    func testBodyRegions_KneesHaveEngineKeyKnee() {
        let left = bodyRegions.first { $0.id == "knee_left" }
        let right = bodyRegions.first { $0.id == "knee_right" }
        XCTAssertEqual(left?.engineKey, "knee")
        XCTAssertEqual(right?.engineKey, "knee")
    }

    // MARK: - parseRegions

    func testParseRegions_SingleRegion() {
        let result = parseRegions("head")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "head")
    }

    func testParseRegions_MultipleRegions() {
        let result = parseRegions("knee_left,ankle_right")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "knee_left")
        XCTAssertEqual(result[1].id, "ankle_right")
    }

    func testParseRegions_TrimsWhitespace() {
        let result = parseRegions(" shoulder_left , shoulder_right ")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "shoulder_left")
        XCTAssertEqual(result[1].id, "shoulder_right")
    }

    func testParseRegions_DropsUnknownIDs() {
        let result = parseRegions("knee_left,unknown_region")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "knee_left")
    }

    func testParseRegions_EmptyString() {
        XCTAssertTrue(parseRegions("").isEmpty)
    }

    func testParseRegions_WhitespaceOnly() {
        XCTAssertTrue(parseRegions("   ").isEmpty)
    }

    // MARK: - encodeRegions

    func testEncodeRegions_SingleRegion() {
        let regions = parseRegions("head")
        XCTAssertEqual(encodeRegions(regions), "head")
    }

    func testEncodeRegions_MultipleRegions() {
        let regions = parseRegions("knee_left,ankle_right")
        XCTAssertEqual(encodeRegions(regions), "knee_left,ankle_right")
    }

    func testEncodeRegions_EmptyArray() {
        XCTAssertEqual(encodeRegions([]), "")
    }

    // MARK: - Round-trip

    func testRoundTrip_MultiRegionString() {
        let original = "shoulder_left,lower_back,knee_right"
        XCTAssertEqual(encodeRegions(parseRegions(original)), original)
    }

    func testRoundTrip_AllRegions() {
        let all = bodyRegions.map(\.id).joined(separator: ",")
        XCTAssertEqual(encodeRegions(parseRegions(all)), all)
    }

    // MARK: - Recovery Phase

    func testRecoveryPhaseOrder_Contains5Phases() {
        XCTAssertEqual(recoveryPhaseOrder.count, 5)
    }

    func testRecoveryPhaseOrder_StartsWithAcute() {
        XCTAssertEqual(recoveryPhaseOrder.first, .acute)
    }

    func testRecoveryPhaseOrder_EndsWithResolved() {
        XCTAssertEqual(recoveryPhaseOrder.last, .resolved)
    }

    func testRecoveryPhaseOrder_CorrectSequence() {
        XCTAssertEqual(recoveryPhaseOrder, [.acute, .rehab, .lightLoad, .returnToPlay, .resolved])
    }

    // MARK: - recoveryPhaseDisplayName

    func testDisplayName_Acute() {
        XCTAssertEqual(recoveryPhaseDisplayName(.acute), "Acute")
    }

    func testDisplayName_Rehab() {
        XCTAssertEqual(recoveryPhaseDisplayName(.rehab), "Rehab")
    }

    func testDisplayName_LightLoad() {
        XCTAssertEqual(recoveryPhaseDisplayName(.lightLoad), "Light Load")
    }

    func testDisplayName_ReturnToPlay() {
        XCTAssertEqual(recoveryPhaseDisplayName(.returnToPlay), "Return to Play")
    }

    func testDisplayName_Resolved() {
        XCTAssertEqual(recoveryPhaseDisplayName(.resolved), "Resolved")
    }
}
