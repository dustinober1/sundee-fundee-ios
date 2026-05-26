import CloudKit
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

    func testReportsPersistedProfilesSeparatelyFromSeededDefaults() async throws {
        let client = MockCloudKitClient()
        let service = EquipmentProfileService(dataClient: client)

        let hasProfilesBeforeSave = await service.hasPersistedProfiles()
        XCTAssertFalse(hasProfilesBeforeSave)

        try await client.save(
            makeProfile(id: "gym", name: "Gym", equipment: .fullGym, isDefault: true, sortOrder: 0),
            recordType: "EquipmentProfile"
        )

        let hasProfilesAfterSave = await service.hasPersistedProfiles()
        XCTAssertTrue(hasProfilesAfterSave)
    }

    func testDuplicateCleanupDoesNotDeleteRecordsWhenReplacementSaveFails() async {
        let client = SaveFailingProfileClient(
            profiles: [
                makeProfile(id: "home-old", name: "Home", equipment: .homeDumbbells, sortOrder: 1),
                makeProfile(id: "home-duplicate", name: " home ", equipment: .resistanceBands, sortOrder: 4)
            ]
        )
        let service = EquipmentProfileService(dataClient: client)

        do {
            try await service.saveProfile(
                makeProfile(id: "home-new", name: "HOME", equipment: .bodyweightOnly, isDefault: true, sortOrder: 2)
            )
            XCTFail("Expected save failure")
        } catch {
            // Expected save failure; duplicate cleanup should not have run yet.
        }

        let deletedRecordIDs = await client.deletedRecordIDs()
        let storedProfileIDs = await client.storedProfileIDs().sorted()
        XCTAssertEqual(deletedRecordIDs, [])
        XCTAssertEqual(storedProfileIDs, ["home-duplicate", "home-old"])
    }

    func testDefaultSelectionUsesLegacySettingsWhenNoProfilesArePersisted() async {
        let client = MockCloudKitClient()
        let service = EquipmentProfileService(dataClient: client)
        let profiles = await service.loadProfiles()

        let selection = AIWorkoutEquipmentDefaultResolver.resolve(
            profiles: profiles,
            hasPersistedProfiles: false,
            legacyDefaultEquipment: .homeDumbbells
        )

        XCTAssertEqual(selection.equipment, .homeDumbbells)
        XCTAssertEqual(selection.selectedProfileID, "seed-home")
    }

    func testDefaultSelectionPrefersPersistedProfileOverLegacySettings() async {
        let persistedDefault = makeProfile(
            id: "travel",
            name: "Travel",
            equipment: .bodyweightOnly,
            isDefault: true,
            sortOrder: 2
        )

        let selection = AIWorkoutEquipmentDefaultResolver.resolve(
            profiles: [persistedDefault],
            hasPersistedProfiles: true,
            legacyDefaultEquipment: .homeDumbbells
        )

        XCTAssertEqual(selection.equipment, .bodyweightOnly)
        XCTAssertEqual(selection.selectedProfileID, "travel")
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

private actor SaveFailingProfileClient: DataClientProtocol {
    private var profiles: [EquipmentProfile]
    private var deletedIDs: [String] = []

    init(profiles: [EquipmentProfile]) {
        self.profiles = profiles
    }

    func storedProfileIDs() -> [String] {
        profiles.map(\.id)
    }

    func deletedRecordIDs() -> [String] {
        deletedIDs
    }

    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        guard recordType == EquipmentProfile.recordType else { return [] }
        return profiles as? [T] ?? []
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        throw DataError.networkError(underlying: nil)
    }

    func delete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async throws {
        let ids = recordIDs.map(\.recordName)
        deletedIDs.append(contentsOf: ids)
        profiles.removeAll { ids.contains($0.id) }
    }

    func deleteAllData() async throws {}
}
