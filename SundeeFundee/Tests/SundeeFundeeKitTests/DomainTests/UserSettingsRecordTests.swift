import XCTest
@testable import SundeeFundeeKit

final class UserSettingsRecordTests: XCTestCase {
    func testDecodesLegacySettingsWithoutDefaultEquipmentAsFullGym() throws {
        let json = """
        {
          "id": "user_settings",
          "cycleTrackingEnabled": true,
          "weightUnit": "lbs",
          "experienceLevel": "intermediate",
          "primaryGoal": "strength"
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(UserSettingsRecord.self, from: json)

        XCTAssertEqual(record.defaultEquipment, .fullGym)
        XCTAssertEqual(record.defaultEquipmentRaw, EquipmentAccess.fullGym.rawValue)
    }

    func testDecodesInvalidDefaultEquipmentAsFullGym() throws {
        let json = """
        {
          "id": "user_settings",
          "cycleTrackingEnabled": false,
          "weightUnit": "kg",
          "experienceLevel": "beginner",
          "primaryGoal": "endurance",
          "defaultEquipmentRaw": "garage_magic"
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(UserSettingsRecord.self, from: json)

        XCTAssertEqual(record.defaultEquipment, .fullGym)
        XCTAssertEqual(record.defaultEquipmentRaw, EquipmentAccess.fullGym.rawValue)
    }
}
