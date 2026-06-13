import XCTest
@testable import SundeeFundeeKit

final class SupportTipProductTests: XCTestCase {
    func testProductContractUsesRepeatableSupportTipLanguage() {
        XCTAssertEqual(SupportTipProduct.id, "com.sundeefundee.app.support.tip199")
        XCTAssertEqual(SupportTipProduct.referenceName, "Support the Developer Tip 1.99")
        XCTAssertEqual(SupportTipProduct.displayName, "Support the Developer")
        XCTAssertFalse(SupportTipProduct.description.localizedCaseInsensitiveContains("donation"))
        XCTAssertFalse(SupportTipProduct.description.localizedCaseInsensitiveContains("unlock"))
        XCTAssertTrue(SupportTipProduct.description.localizedCaseInsensitiveContains("optional"))
    }

    func testFailureMessagesAreUserFacing() {
        XCTAssertEqual(
            SupportTipStoreError.productUnavailable.userMessage,
            "Support tips are unavailable right now. Please try again later."
        )
        XCTAssertEqual(
            SupportTipStoreError.unverifiedTransaction.userMessage,
            "The purchase could not be verified. Check your App Store purchase history or try again later."
        )
        XCTAssertEqual(
            SupportTipStoreError.unexpectedProductType.userMessage,
            "Support tips are unavailable right now. Please try again later."
        )
        XCTAssertFalse(SupportTipStoreError.storeKitFailure.userMessage.contains("localizedDescription"))
    }
}
