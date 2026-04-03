import XCTest
@testable import SundeeFundeeKit

final class BodyLocationTests: XCTestCase {

    // MARK: - bodyRegions

    func testBodyRegions_Contains17Regions() {
        XCTAssertEqual(BodyRegions.allRegions.count, 17)
    }

    func testBodyRegions_AllHaveNonEmptyFields() {
        for r in BodyRegions.allRegions {
            XCTAssertFalse(r.id.isEmpty, "Region should have non-empty id")
            XCTAssertFalse(r.displayName.isEmpty, "Region should have non-empty displayName")
            XCTAssertFalse(r.engineKey.isEmpty, "Region should have non-empty engineKey")
        }
    }

    func testBodyRegions_AllIDsAreUnique() {
        let ids = BodyRegions.allRegions.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testBodyRegions_HeadHasEngineKeyHead() {
        let r = BodyRegions.allRegions.first { $0.id == "head" }
        XCTAssertEqual(r?.engineKey, "head")
    }

    func testBodyRegions_ShouldersHaveEngineKeyShoulder() {
        let left = BodyRegions.allRegions.first { $0.id == "shoulder_left" }
        let right = BodyRegions.allRegions.first { $0.id == "shoulder_right" }
        XCTAssertEqual(left?.engineKey, "shoulder")
        XCTAssertEqual(right?.engineKey, "shoulder")
    }

    func testBodyRegions_BackRegionsHaveEngineKeyBack() {
        let upper = BodyRegions.allRegions.first { $0.id == "upper_back" }
        let lower = BodyRegions.allRegions.first { $0.id == "lower_back" }
        XCTAssertEqual(upper?.engineKey, "back")
        XCTAssertEqual(lower?.engineKey, "back")
    }

    func testBodyRegions_KneesHaveEngineKeyKnee() {
        let left = BodyRegions.allRegions.first { $0.id == "knee_left" }
        let right = BodyRegions.allRegions.first { $0.id == "knee_right" }
        XCTAssertEqual(left?.engineKey, "knee")
        XCTAssertEqual(right?.engineKey, "knee")
    }

    // MARK: - parseRegions

    func testParseRegions_SingleRegion() {
        let result = BodyRegions.parseRegions("head")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "head")
    }

    func testParseRegions_MultipleRegions() {
        let result = BodyRegions.parseRegions("knee_left,ankle_right")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "knee_left")
        XCTAssertEqual(result[1].id, "ankle_right")
    }

    func testParseRegions_TrimsWhitespace() {
        let result = BodyRegions.parseRegions(" shoulder_left , shoulder_right ")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "shoulder_left")
        XCTAssertEqual(result[1].id, "shoulder_right")
    }

    func testParseRegions_DropsUnknownIDs() {
        let result = BodyRegions.parseRegions("knee_left,unknown_region")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "knee_left")
    }

    func testParseRegions_EmptyString() {
        XCTAssertTrue(BodyRegions.parseRegions("").isEmpty)
    }

    func testParseRegions_WhitespaceOnly() {
        XCTAssertTrue(BodyRegions.parseRegions("   ").isEmpty)
    }

    // MARK: - encodeRegions

    func testEncodeRegions_SingleRegion() {
        let regions = BodyRegions.parseRegions("head")
        XCTAssertEqual(BodyRegions.encodeRegions(regions), "head")
    }

    func testEncodeRegions_MultipleRegions() {
        let regions = BodyRegions.parseRegions("knee_left,ankle_right")
        XCTAssertEqual(BodyRegions.encodeRegions(regions), "knee_left,ankle_right")
    }

    func testEncodeRegions_EmptyArray() {
        XCTAssertEqual(BodyRegions.encodeRegions([]), "")
    }

    // MARK: - Round-trip

    func testRoundTrip_MultiRegionString() {
        let original = "shoulder_left,lower_back,knee_right"
        XCTAssertEqual(BodyRegions.encodeRegions(BodyRegions.parseRegions(original)), original)
    }

    func testRoundTrip_AllRegions() {
        let all = BodyRegions.allRegions.map(\.id).joined(separator: ",")
        XCTAssertEqual(BodyRegions.encodeRegions(BodyRegions.parseRegions(all)), all)
    }

    // MARK: - Recovery Phase

    func testRecoveryPhaseOrder_Contains5Phases() {
        XCTAssertEqual(RecoveryPhase.allCases.count, 5)
    }

    func testRecoveryPhaseOrder_StartsWithAcute() {
        XCTAssertEqual(RecoveryPhase.allCases.first, .acute)
    }

    func testRecoveryPhaseOrder_EndsWithResolved() {
        XCTAssertEqual(RecoveryPhase.allCases.last, .resolved)
    }

    func testRecoveryPhaseOrder_CorrectSequence() {
        XCTAssertEqual(RecoveryPhase.allCases, [.acute, .rehab, .lightLoad, .returnToPlay, .resolved])
    }

    // MARK: - RecoveryPhase displayName

    func testDisplayName_Acute() {
        XCTAssertEqual(RecoveryPhase.acute.displayName, "Acute")
    }

    func testDisplayName_Rehab() {
        XCTAssertEqual(RecoveryPhase.rehab.displayName, "Rehab")
    }

    func testDisplayName_LightLoad() {
        XCTAssertEqual(RecoveryPhase.lightLoad.displayName, "Light Load")
    }

    func testDisplayName_ReturnToPlay() {
        XCTAssertEqual(RecoveryPhase.returnToPlay.displayName, "Return to Play")
    }

    func testDisplayName_Resolved() {
        XCTAssertEqual(RecoveryPhase.resolved.displayName, "Resolved")
    }
}
