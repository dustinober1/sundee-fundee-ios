import Foundation

// MARK: - Injury Models

/// An injury or chronic condition being tracked
public struct Injury: Codable, Sendable, Identifiable {
    public let id: String
    /// Body regions affected (comma-separated IDs)
    public let locationIds: String
    /// Name/description of the injury
    public let name: String
    /// Current recovery phase
    public let recoveryPhase: RecoveryPhase
    /// When the injury was logged
    public let dateCreated: Date
    /// When the recovery phase was last updated
    public let phaseUpdated: Date
    /// Additional notes
    public let notes: String?

    public init(
        id: String,
        locationIds: String,
        name: String,
        recoveryPhase: RecoveryPhase,
        dateCreated: Date,
        phaseUpdated: Date,
        notes: String? = nil
    ) {
        self.id = id
        self.locationIds = locationIds
        self.name = name
        self.recoveryPhase = recoveryPhase
        self.dateCreated = dateCreated
        self.phaseUpdated = phaseUpdated
        self.notes = notes
    }

    /// Parse body regions from location IDs
    public var bodyRegions: [BodyRegion] {
        return BodyRegions.parseRegions(locationIds)
    }
}

/// A pain log entry for tracking day-to-day pain levels
public struct DailyPainLog: Codable, Sendable, Identifiable {
    public let id: String
    /// Body regions experiencing pain (comma-separated IDs)
    public let locationIds: String
    /// Pain intensity (1-10 scale)
    public let intensity: Int
    /// Pain type/category
    public let painType: PainType
    /// When the pain was logged
    public let date: Date
    /// Additional context
    public let notes: String?

    public init(
        id: String,
        locationIds: String,
        intensity: Int,
        painType: PainType,
        date: Date,
        notes: String? = nil
    ) {
        self.id = id
        self.locationIds = locationIds
        self.intensity = intensity
        self.painType = painType
        self.date = date
        self.notes = notes
    }

    /// Parse body regions from location IDs
    public var bodyRegions: [BodyRegion] {
        return BodyRegions.parseRegions(locationIds)
    }

    /// Validate pain intensity is in valid range
    public var isValidIntensity: Bool {
        return (1...10).contains(intensity)
    }
}

/// Type/category of pain
public enum PainType: String, Codable, Sendable, CaseIterable {
    case acute
    case chronic
    case soreness
    case stiffness
    case sharp
    case dull
    case aching
    case other

    /// Display name for the pain type
    public var displayName: String {
        switch self {
        case .acute: return "Acute Pain"
        case .chronic: return "Chronic Pain"
        case .soreness: return "Soreness"
        case .stiffness: return "Stiffness"
        case .sharp: return "Sharp Pain"
        case .dull: return "Dull Ache"
        case .aching: return "Aching"
        case .other: return "Other"
        }
    }

    /// Color indicator for the pain type
    public var color: String {
        switch self {
        case .acute: return "red"
        case .chronic: return "orange"
        case .soreness: return "yellow"
        case .stiffness: return "blue"
        case .sharp: return "red"
        case .dull: return "green"
        case .aching: return "yellow"
        case .other: return "gray"
        }
    }
}

/// Pain level category for display
public enum PainLevel: String, Codable, Sendable {
    case none
    case mild
    case moderate
    case severe
    case extreme

    /// Get pain level from intensity (1-10 scale)
    public static func from(intensity: Int) -> PainLevel {
        switch intensity {
        case 0: return .none
        case 1...3: return .mild
        case 4...6: return .moderate
        case 7...8: return .severe
        case 9...10: return .extreme
        default: return .moderate
        }
    }

    /// Display name for the pain level
    public var displayName: String {
        switch self {
        case .none: return "No Pain"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        case .extreme: return "Extreme"
        }
    }

    /// Color indicator for the pain level
    public var color: String {
        switch self {
        case .none: return "green"
        case .mild: return "yellow"
        case .moderate: return "orange"
        case .severe: return "red"
        case .extreme: return "purple"
        }
    }
}
