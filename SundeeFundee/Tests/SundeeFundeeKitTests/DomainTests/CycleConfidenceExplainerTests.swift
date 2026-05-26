import XCTest
@testable import SundeeFundeeKit

final class CycleConfidenceExplainerTests: XCTestCase {
    func testNilConfidence() {
        let explanation = CycleConfidenceExplainer.explain(confidence: nil)
        XCTAssertEqual(explanation.label, "No Confidence Yet")
    }

    func testLowConfidence() {
        let explanation = CycleConfidenceExplainer.explain(confidence: 0.2)
        XCTAssertEqual(explanation.label, "Low Confidence")
        XCTAssertTrue(explanation.actionTitle.localizedCaseInsensitiveContains("update"))
    }

    func testMediumConfidence() {
        let explanation = CycleConfidenceExplainer.explain(confidence: 0.5)
        XCTAssertEqual(explanation.label, "Medium Confidence")
    }

    func testHighConfidence() {
        let explanation = CycleConfidenceExplainer.explain(confidence: 0.9)
        XCTAssertEqual(explanation.label, "High Confidence")
    }
}
