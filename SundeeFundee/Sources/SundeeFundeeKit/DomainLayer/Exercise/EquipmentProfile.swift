import Foundation

public struct EquipmentProfile: Codable, Sendable, Identifiable, Equatable {
    public static let recordType = "EquipmentProfile"

    public let id: String
    public var name: String
    public var equipmentRaw: String
    public var isDefault: Bool
    public var sortOrder: Int
    public var dateCreated: Date
    public var dateUpdated: Date

    public var equipment: EquipmentAccess {
        EquipmentAccess(rawValue: equipmentRaw) ?? .fullGym
    }

    public init(
        id: String,
        name: String,
        equipmentRaw: String,
        isDefault: Bool,
        sortOrder: Int,
        dateCreated: Date,
        dateUpdated: Date
    ) {
        self.id = id
        self.name = name
        self.equipmentRaw = equipmentRaw
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.dateCreated = dateCreated
        self.dateUpdated = dateUpdated
    }

    // CloudKit can surface Bool fields as Int64 through dictionary-backed decoders.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let rawEquipment = try container.decodeIfPresent(String.self, forKey: .equipmentRaw)
            ?? EquipmentAccess.fullGym.rawValue
        equipmentRaw = EquipmentAccess(rawValue: rawEquipment)?.rawValue
            ?? EquipmentAccess.fullGym.rawValue
        if let boolValue = try? container.decode(Bool.self, forKey: .isDefault) {
            isDefault = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isDefault) {
            isDefault = intValue != 0
        } else {
            isDefault = false
        }
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        dateUpdated = try container.decodeIfPresent(Date.self, forKey: .dateUpdated) ?? dateCreated
    }
}
