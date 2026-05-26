import XCTest
@testable import SundeeFundeeKit

final class EquipmentProfileServiceTests: XCTestCase {
    func testDefaultSeededProfilesAreGymHomeAndTravel() async {
        let client = MockCloudKitClient()
        let service = EquipmentProfileService(dataClient: client)

        let profiles = await service.loadProfiles()

        XCTAssertEqual(profiles.map(\.name), ["Gym", "Home", "Travel"])
        XCTAssertEqual(profiles.map(\.equipment), [.fullGym, .homeDumbbells, .bodyweightOnly])
        XCTAssertEqual(profiles.filter(\.isDefault).map(\.name), ["Gym"])
        XCTAssertEqual(client.recordCount(for: "EquipmentProfile"), 0)
    }

    func testSavingNewDefaultClearsPreviousDefault() async throws {
        let client = MockCloudKitClient()
        let service = EquipmentProfileService(dataClient: client)
        try await client.save(
            [
                makeProfile(id: "gym", name: "Gym", equipment: .fullGym, isDefault: true, sortOrder: 0),
                makeProfile(id: "home", name: "Home", equipment: .homeDumbbells, isDefault: false, sortOrder: 1)
            ],
            recordType: "EquipmentProfile"
        )

        try await service.saveProfile(
            makeProfile(id: "home", name: "Home", equipment: .homeDumbbells, isDefault: true, sortOrder: 1)
        )

        let profiles = await service.loadProfiles()
        XCTAssertEqual(profiles.filter(\.isDefault).map(\.name), ["Home"])
        XCTAssertEqual(profiles.first(where: { $0.name == "Gym" })?.isDefault, false)
    }

    func testProfilesSortBySortOrderThenName() async throws {
        let client = MockCloudKitClient()
        let service = EquipmentProfileService(dataClient: client)
        try await client.save(
            [
                makeProfile(id: "gamma", name: "Gamma", equipment: .resistanceBands, sortOrder: 2),
                makeProfile(id: "beta", name: "Beta", equipment: .bodyweightOnly, sortOrder: 1),
                makeProfile(id: "alpha", name: "Alpha", equipment: .fullGym, sortOrder: 1)
            ],
            recordType: "EquipmentProfile"
        )

        let profiles = await service.loadProfiles()

        XCTAssertEqual(profiles.map(\.name), ["Alpha", "Beta", "Gamma"])
    }

    func testSavingDuplicateNamesNormalizesToOneSavedProfilePerName() async throws {
        let client = MockCloudKitClient()
        let service = EquipmentProfileService(dataClient: client)

        try await service.saveProfile(
            makeProfile(id: "home-old", name: " Home ", equipment: .homeDumbbells, sortOrder: 1)
        )
        try await service.saveProfile(
            makeProfile(id: "home-new", name: "home", equipment: .resistanceBands, isDefault: true, sortOrder: 4)
        )

        let profiles = await service.loadProfiles()
        let homeProfiles = profiles.filter { $0.name == "Home" }
        XCTAssertEqual(homeProfiles.count, 1)
        XCTAssertEqual(homeProfiles.first?.equipment, .resistanceBands)
        XCTAssertEqual(homeProfiles.first?.isDefault, true)

        let savedRecords = try await client.fetchAll(recordType: "EquipmentProfile") as [EquipmentProfile]
        XCTAssertEqual(savedRecords.count, 1)
        XCTAssertEqual(savedRecords.first?.name, "Home")
    }
}

private func makeProfile(
    id: String = UUID().uuidString,
    name: String,
    equipment: EquipmentAccess,
    isDefault: Bool = false,
    sortOrder: Int = 0,
    date: Date = Date(timeIntervalSince1970: 1_700_000_000)
) -> EquipmentProfile {
    EquipmentProfile(
        id: id,
        name: name,
        equipmentRaw: equipment.rawValue,
        isDefault: isDefault,
        sortOrder: sortOrder,
        dateCreated: date,
        dateUpdated: date
    )
}
