import Foundation

// MARK: - CycleSettingsRecord

/// User's menstrual cycle tracking settings.
///
/// At most one record exists per user. Uses a fixed `id` so every save
/// upserts the same record instead of creating duplicates.
public struct CycleSettingsRecord: Codable, Sendable, Equatable {
    public let id: String
    public let averageCycleLengthDays: Int
    public let lastPeriodStart: Date?
    public let terminologyStyleRaw: String?
    public let isGymPrivacyEnabled: Bool?
    public let showSharkWeekBanner: Bool?

    public var terminologyStyle: CycleTerminologyStyle {
        terminologyStyleRaw.flatMap(CycleTerminologyStyle.init(rawValue:)) ?? .physiological
    }

    public var isGymPrivacy: Bool {
        isGymPrivacyEnabled ?? false
    }

    public var showsBanner: Bool {
        showSharkWeekBanner ?? true
    }

    public init(
        averageCycleLengthDays: Int,
        lastPeriodStart: Date? = nil,
        terminologyStyle: CycleTerminologyStyle = .physiological,
        isGymPrivacyEnabled: Bool = false,
        showSharkWeekBanner: Bool = true
    ) {
        self.id = "cycle_settings"
        self.averageCycleLengthDays = averageCycleLengthDays
        self.lastPeriodStart = lastPeriodStart
        self.terminologyStyleRaw = terminologyStyle.rawValue
        self.isGymPrivacyEnabled = isGymPrivacyEnabled
        self.showSharkWeekBanner = showSharkWeekBanner
    }

    enum CodingKeys: String, CodingKey {
        case id
        case averageCycleLengthDays
        case lastPeriodStart
        case terminologyStyleRaw
        case isGymPrivacyEnabled
        case showSharkWeekBanner
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? "cycle_settings"
        self.averageCycleLengthDays = try container.decode(Int.self, forKey: .averageCycleLengthDays)
        self.lastPeriodStart = try? container.decodeIfPresent(Date.self, forKey: .lastPeriodStart)
        self.terminologyStyleRaw = try? container.decodeIfPresent(String.self, forKey: .terminologyStyleRaw)

        if let b = try? container.decodeIfPresent(Bool.self, forKey: .isGymPrivacyEnabled) {
            self.isGymPrivacyEnabled = b
        } else if let i = try? container.decodeIfPresent(Int.self, forKey: .isGymPrivacyEnabled) {
            self.isGymPrivacyEnabled = (i != 0)
        } else {
            self.isGymPrivacyEnabled = false
        }

        if let b = try? container.decodeIfPresent(Bool.self, forKey: .showSharkWeekBanner) {
            self.showSharkWeekBanner = b
        } else if let i = try? container.decodeIfPresent(Int.self, forKey: .showSharkWeekBanner) {
            self.showSharkWeekBanner = (i != 0)
        } else {
            self.showSharkWeekBanner = true
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(averageCycleLengthDays, forKey: .averageCycleLengthDays)
        try container.encodeIfPresent(lastPeriodStart, forKey: .lastPeriodStart)
        try container.encodeIfPresent(terminologyStyleRaw, forKey: .terminologyStyleRaw)
        try container.encode(isGymPrivacyEnabled ?? false, forKey: .isGymPrivacyEnabled)
        try container.encode(showSharkWeekBanner ?? true, forKey: .showSharkWeekBanner)
    }
}
