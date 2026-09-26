import XCTest
@testable import SundeeFundeeKit

final class CycleSettingsTests: XCTestCase {
    func testDecodesLegacyCycleSettingsWithoutNewFields() throws {
        let json = """
        {
          "id": "cycle_settings",
          "averageCycleLengthDays": 29
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(CycleSettingsRecord.self, from: json)

        XCTAssertEqual(record.averageCycleLengthDays, 29)
        XCTAssertEqual(record.terminologyStyle, .physiological)
        XCTAssertFalse(record.isGymPrivacy)
        XCTAssertTrue(record.showsBanner)
    }

    func testDecodesCloudKitInt64Booleans() throws {
        let json = """
        {
          "id": "cycle_settings",
          "averageCycleLengthDays": 28,
          "terminologyStyleRaw": "hormone",
          "isGymPrivacyEnabled": 1,
          "showSharkWeekBanner": 0
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(CycleSettingsRecord.self, from: json)

        XCTAssertEqual(record.terminologyStyle, .hormone)
        XCTAssertTrue(record.isGymPrivacy)
        XCTAssertFalse(record.showsBanner)
    }

    func testRoundTripsCycleSettingsRecord() throws {
        let original = CycleSettingsRecord(
            averageCycleLengthDays: 31,
            lastPeriodStart: Date(timeIntervalSince1970: 1_700_000_000),
            terminologyStyle: .casual,
            isGymPrivacyEnabled: true,
            showSharkWeekBanner: false
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CycleSettingsRecord.self, from: encoded)

        XCTAssertEqual(decoded.averageCycleLengthDays, 31)
        XCTAssertEqual(decoded.terminologyStyle, .casual)
        XCTAssertTrue(decoded.isGymPrivacy)
        XCTAssertFalse(decoded.showsBanner)
    }

    func testTerminologyStyleRecommendations() {
        let casualRec = getPhaseRecommendation(phase: .menstrual, style: .casual)
        XCTAssertEqual(casualRec.title, "Shark Week")

        let physioRec = getPhaseRecommendation(phase: .menstrual, style: .physiological)
        XCTAssertEqual(physioRec.title, "Menstrual Phase")

        let hormoneRec = getPhaseRecommendation(phase: .menstrual, style: .hormone)
        XCTAssertEqual(hormoneRec.title, "Low Hormone Phase")
    }
}
