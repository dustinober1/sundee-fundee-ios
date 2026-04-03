import XCTest
@testable import SundeeFundeeKit

final class InjuryAdaptationEngineTests: XCTestCase {

    // MARK: - normalizeBodyRegions

    func testNormalize_KneeLeft_MapsToKnee() {
        let result = normalizeBodyRegions(regions: ["knee_left"])
        XCTAssertTrue(result.contains("knee"))
    }

    func testNormalize_ShoulderRight_MapsToShoulder() {
        let result = normalizeBodyRegions(regions: ["shoulder_right"])
        XCTAssertTrue(result.contains("shoulder"))
    }

    func testNormalize_ClinicalSynonym_ACL() {
        let result = normalizeBodyRegions(regions: [], freeText: "ACL tear")
        XCTAssertTrue(result.contains("knee"))
    }

    func testNormalize_ClinicalSynonym_RotatorCuff() {
        let result = normalizeBodyRegions(regions: [], freeText: "rotator cuff strain")
        XCTAssertTrue(result.contains("shoulder"))
    }

    func testNormalize_ClinicalSynonym_Sciatica() {
        let result = normalizeBodyRegions(regions: [], freeText: "sciatica")
        XCTAssertTrue(result.contains("back"))
    }

    func testNormalize_ClinicalSynonym_CarpalTunnel() {
        let result = normalizeBodyRegions(regions: [], freeText: "carpal tunnel syndrome")
        XCTAssertTrue(result.contains("wrist"))
    }

    func testNormalize_EmptyInputs() {
        let result = normalizeBodyRegions(regions: [], freeText: "")
        XCTAssertTrue(result.isEmpty)
    }

    func testNormalize_Deduplicates() {
        let result = normalizeBodyRegions(regions: ["knee_left", "knee_right"])
        XCTAssertEqual(result.filter { $0 == "knee" }.count, 1)
    }

    // MARK: - mostRestrictivePhase

    func testMostRestrictive_Empty_ReturnsNil() {
        XCTAssertNil(mostRestrictivePhase([]))
    }

    func testMostRestrictive_AcuteIsFirst() {
        XCTAssertEqual(mostRestrictivePhase([.rehab, .acute, .resolved]), .acute)
    }

    func testMostRestrictive_RehabBeforeLightLoad() {
        XCTAssertEqual(mostRestrictivePhase([.lightLoad, .rehab]), .rehab)
    }

    func testMostRestrictive_SinglePhase() {
        XCTAssertEqual(mostRestrictivePhase([.resolved]), .resolved)
    }

    // MARK: - buildRecoveryPrepBlock

    func testRecoveryPrepBlock_KneeInjury() {
        let injuries = [InjuryProfile(id: "i1", location: "knee_left", recoveryPhase: .rehab)]
        let block = buildRecoveryPrepBlock(injuries: injuries, phase: .rehab)
        XCTAssertFalse(block.isEmpty)
        XCTAssertTrue(block.allSatisfy { $0.sets == 3 && $0.reps == 12 })
    }

    func testRecoveryPrepBlock_DefaultPhase() {
        let injuries = [InjuryProfile(id: "i1", location: "shoulder_left", recoveryPhase: .returnToPlay)]
        let block = buildRecoveryPrepBlock(injuries: injuries)
        XCTAssertFalse(block.isEmpty)
        XCTAssertTrue(block.allSatisfy { $0.sets == 2 && $0.reps == 10 })
    }

    func testRecoveryPrepBlock_LightLoadPhase() {
        let injuries = [InjuryProfile(id: "i1", location: "knee_left", recoveryPhase: .lightLoad)]
        let block = buildRecoveryPrepBlock(injuries: injuries, phase: .lightLoad)
        XCTAssertTrue(block.allSatisfy { $0.reps == 15 })
    }
}
