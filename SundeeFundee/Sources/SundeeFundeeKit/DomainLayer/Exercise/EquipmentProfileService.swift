import Foundation

public actor EquipmentProfileService {
    private let dataClient: DataClientProtocol

    public init(dataClient: DataClientProtocol) {
        self.dataClient = dataClient
    }

    public func loadProfiles() async -> [EquipmentProfile] {
        do {
            let stored = try await fetchStoredProfiles()
            return normalizedSortedProfiles(stored.isEmpty ? Self.seededProfiles : stored)
        } catch {
            return Self.seededProfiles
        }
    }

    public func saveProfile(_ profile: EquipmentProfile) async throws {
        var stored = try await fetchStoredProfiles()
        let normalizedProfile = normalized(profile)
        let normalizedName = Self.normalizedNameKey(normalizedProfile.name)
        let matchingProfiles = stored.filter { Self.normalizedNameKey($0.name) == normalizedName }
        let existing = matchingProfiles.first
        let now = Date()
        let profileToSave = EquipmentProfile(
            id: existing?.id ?? normalizedProfile.id,
            name: normalizedProfile.name,
            equipmentRaw: normalizedProfile.equipment.rawValue,
            isDefault: normalizedProfile.isDefault,
            sortOrder: normalizedProfile.sortOrder,
            dateCreated: existing?.dateCreated ?? normalizedProfile.dateCreated,
            dateUpdated: now
        )

        stored.removeAll { Self.normalizedNameKey($0.name) == normalizedName }
        stored.append(profileToSave)

        if profileToSave.isDefault {
            stored = stored.map { profile in
                var updated = profile
                if updated.id != profileToSave.id, updated.isDefault {
                    updated.isDefault = false
                    updated.dateUpdated = now
                }
                return updated
            }
        }

        for duplicate in matchingProfiles where duplicate.id != profileToSave.id {
            try await dataClient.delete(recordType: Self.recordType, id: duplicate.id)
        }
        try await dataClient.save(normalizedSortedProfiles(stored), recordType: Self.recordType)
    }

    public func setDefault(profileID: String) async throws {
        let stored = try await fetchStoredProfiles()
        let source = stored.isEmpty ? Self.seededProfiles : stored
        guard source.contains(where: { $0.id == profileID }) else {
            throw DataError.invalidData(description: "Equipment profile not found")
        }

        let now = Date()
        let updated = source.map { profile in
            var next = normalized(profile)
            let shouldBeDefault = next.id == profileID
            if next.isDefault != shouldBeDefault {
                next.dateUpdated = now
            }
            next.isDefault = shouldBeDefault
            return next
        }
        try await dataClient.save(normalizedSortedProfiles(updated), recordType: Self.recordType)
    }

    public func defaultProfile() async -> EquipmentProfile {
        let profiles = await loadProfiles()
        return profiles.first(where: \.isDefault) ?? profiles.first ?? Self.seededProfiles[0]
    }

    private func fetchStoredProfiles() async throws -> [EquipmentProfile] {
        try await dataClient.fetchAll(recordType: Self.recordType)
    }

    private func normalizedSortedProfiles(_ profiles: [EquipmentProfile]) -> [EquipmentProfile] {
        var profilesByName: [String: EquipmentProfile] = [:]

        for profile in profiles.map(normalized) {
            let key = Self.normalizedNameKey(profile.name)
            guard let existing = profilesByName[key] else {
                profilesByName[key] = profile
                continue
            }

            if shouldReplace(existing: existing, with: profile) {
                profilesByName[key] = profile
            }
        }

        return profilesByName.values.sorted {
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func shouldReplace(existing: EquipmentProfile, with candidate: EquipmentProfile) -> Bool {
        if candidate.isDefault != existing.isDefault {
            return candidate.isDefault
        }
        return candidate.dateUpdated > existing.dateUpdated
    }

    private func normalized(_ profile: EquipmentProfile) -> EquipmentProfile {
        EquipmentProfile(
            id: profile.id,
            name: Self.normalizedDisplayName(profile.name, equipment: profile.equipment),
            equipmentRaw: profile.equipment.rawValue,
            isDefault: profile.isDefault,
            sortOrder: profile.sortOrder,
            dateCreated: profile.dateCreated,
            dateUpdated: profile.dateUpdated
        )
    }

    private static var recordType: String { EquipmentProfile.recordType }

    private static let seededProfiles: [EquipmentProfile] = {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        return [
            EquipmentProfile(
                id: "seed-gym",
                name: "Gym",
                equipmentRaw: EquipmentAccess.fullGym.rawValue,
                isDefault: true,
                sortOrder: 0,
                dateCreated: date,
                dateUpdated: date
            ),
            EquipmentProfile(
                id: "seed-home",
                name: "Home",
                equipmentRaw: EquipmentAccess.homeDumbbells.rawValue,
                isDefault: false,
                sortOrder: 1,
                dateCreated: date,
                dateUpdated: date
            ),
            EquipmentProfile(
                id: "seed-travel",
                name: "Travel",
                equipmentRaw: EquipmentAccess.bodyweightOnly.rawValue,
                isDefault: false,
                sortOrder: 2,
                dateCreated: date,
                dateUpdated: date
            )
        ]
    }()

    private static func normalizedDisplayName(_ name: String, equipment: EquipmentAccess) -> String {
        let trimmed = name
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let fallback = equipment.displayName
        let displayName = trimmed.isEmpty ? fallback : trimmed

        switch normalizedNameKey(displayName) {
        case "gym":
            return "Gym"
        case "home":
            return "Home"
        case "travel":
            return "Travel"
        default:
            return displayName
        }
    }

    private static func normalizedNameKey(_ name: String) -> String {
        name
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .lowercased()
    }
}
