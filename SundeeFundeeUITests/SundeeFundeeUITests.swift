import XCTest
import SwiftUI
@testable import SundeeFundee

final class SundeeFundeeUITests: XCTestCase {
    // Placeholder for UI tests — to be expanded in Phase 12
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // Sign in with Apple button should be visible on first launch
        XCTAssertTrue(app.staticTexts["Sundee Fundee"].waitForExistence(timeout: 5))
    }
}
