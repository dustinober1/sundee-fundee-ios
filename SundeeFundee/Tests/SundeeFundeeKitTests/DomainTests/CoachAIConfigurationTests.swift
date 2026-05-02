import XCTest
@testable import SundeeFundeeKit

final class CoachAIConfigurationTests: XCTestCase {
    func testDisablesAfterTwoConsecutiveValidationFailuresAndResetOnAccept() async {
        let config = CoachAIConfiguration()
        let initial = await config.shouldUseOnDeviceCopy()
        XCTAssertTrue(initial)
        await config.recordRejectedCopy()
        let afterOneFailure = await config.shouldUseOnDeviceCopy()
        XCTAssertTrue(afterOneFailure)
        await config.recordAcceptedCopy()
        let afterAccept = await config.shouldUseOnDeviceCopy()
        XCTAssertTrue(afterAccept)
        await config.recordRejectedCopy()
        await config.recordRejectedCopy()
        let afterTwoFailures = await config.shouldUseOnDeviceCopy()
        XCTAssertFalse(afterTwoFailures)
    }
}
