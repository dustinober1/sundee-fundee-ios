import XCTest
@testable import SundeeFundeeKit

final class SharePrivacyPresetTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clean slate for every test
        UserDefaults.standard.removeObject(
            forKey: "com.sundeefundee.sharePrivacyPreset"
        )
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(
            forKey: "com.sundeefundee.sharePrivacyPreset"
        )
        super.tearDown()
    }

    // MARK: - privateDefault

    func testPrivateDefaultHasAllFieldsFalse() {
        let options = SharePrivacyOptions.privateDefault
        XCTAssertFalse(options.showCycleContext)
        XCTAssertFalse(options.showRecoveryScore)
        XCTAssertFalse(options.showPainContext)
        XCTAssertFalse(options.showExactDate)
    }

    // MARK: - Loading a saved preset

    func testSavedPresetReturnsSavedValues() {
        let preset = SharePrivacyOptions(
            showCycleContext: true,
            showRecoveryScore: true,
            showPainContext: false,
            showExactDate: true
        )
        SharePrivacyOptions.savedPreset = preset

        let loaded = SharePrivacyOptions.savedPreset
        XCTAssertEqual(loaded, preset)
        XCTAssertTrue(loaded.showCycleContext)
        XCTAssertTrue(loaded.showRecoveryScore)
        XCTAssertFalse(loaded.showPainContext)
        XCTAssertTrue(loaded.showExactDate)
    }

    func testSavedPresetReturnsPrivateDefaultWhenNoneSaved() {
        let loaded = SharePrivacyOptions.savedPreset
        XCTAssertEqual(loaded, SharePrivacyOptions.privateDefault)
    }

    // MARK: - Independence of fields

    func testSavingCycleContextDoesNotImplyPainContext() {
        let preset = SharePrivacyOptions(
            showCycleContext: true,
            showRecoveryScore: false,
            showPainContext: false,
            showExactDate: false
        )
        SharePrivacyOptions.savedPreset = preset

        let loaded = SharePrivacyOptions.savedPreset
        XCTAssertTrue(loaded.showCycleContext)
        XCTAssertFalse(loaded.showPainContext)
    }

    // MARK: - Round-trip encode / decode

    func testRoundTripEncodeDecode() throws {
        let original = SharePrivacyOptions(
            showCycleContext: true,
            showRecoveryScore: false,
            showPainContext: true,
            showExactDate: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SharePrivacyOptions.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertTrue(decoded.showCycleContext)
        XCTAssertFalse(decoded.showRecoveryScore)
        XCTAssertTrue(decoded.showPainContext)
        XCTAssertFalse(decoded.showExactDate)
    }

    func testRoundTripEncodeDecodeAllTrue() throws {
        let original = SharePrivacyOptions(
            showCycleContext: true,
            showRecoveryScore: true,
            showPainContext: true,
            showExactDate: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SharePrivacyOptions.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testRoundTripEncodeDecodeAllFalse() throws {
        let original = SharePrivacyOptions(
            showCycleContext: false,
            showRecoveryScore: false,
            showPainContext: false,
            showExactDate: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SharePrivacyOptions.self, from: data)

        XCTAssertEqual(decoded, original)
    }
}
