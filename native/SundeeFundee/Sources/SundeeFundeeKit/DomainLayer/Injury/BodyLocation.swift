import Foundation

// MARK: - Body Location

/// Body region for injury/pain tracking
public struct BodyRegion: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let displayName: String
    /// Maps to the injury engine's contraindication key
    public let engineKey: String

    public init(id: String, displayName: String, engineKey: String) {
        self.id = id
        self.displayName = displayName
        self.engineKey = engineKey
    }
}

/// All supported body regions
public struct BodyRegions {
    public static let allRegions: [BodyRegion] = [
        BodyRegion(id: "head", displayName: "Head", engineKey: "head"),
        BodyRegion(id: "neck", displayName: "Neck", engineKey: "neck"),
        BodyRegion(id: "shoulder_left", displayName: "Left Shoulder", engineKey: "shoulder"),
        BodyRegion(id: "shoulder_right", displayName: "Right Shoulder", engineKey: "shoulder"),
        BodyRegion(id: "chest", displayName: "Chest", engineKey: "chest"),
        BodyRegion(id: "upper_back", displayName: "Upper Back", engineKey: "back"),
        BodyRegion(id: "lower_back", displayName: "Lower Back", engineKey: "back"),
        BodyRegion(id: "elbow_left", displayName: "Left Elbow", engineKey: "elbow"),
        BodyRegion(id: "elbow_right", displayName: "Right Elbow", engineKey: "elbow"),
        BodyRegion(id: "wrist_left", displayName: "Left Wrist", engineKey: "wrist"),
        BodyRegion(id: "wrist_right", displayName: "Right Wrist", engineKey: "wrist"),
        BodyRegion(id: "hip_left", displayName: "Left Hip", engineKey: "hip"),
        BodyRegion(id: "hip_right", displayName: "Right Hip", engineKey: "hip"),
        BodyRegion(id: "knee_left", displayName: "Left Knee", engineKey: "knee"),
        BodyRegion(id: "knee_right", displayName: "Right Knee", engineKey: "knee"),
        BodyRegion(id: "ankle_left", displayName: "Left Ankle", engineKey: "ankle"),
        BodyRegion(id: "ankle_right", displayName: "Right Ankle", engineKey: "ankle"),
    ]

    private static let regionMap: [String: BodyRegion] = Dictionary(
        uniqueKeysWithValues: allRegions.map { ($0.id, $0) }
    )

    /// Find a region by ID
    public static func region(id: String) -> BodyRegion? {
        return regionMap[id]
    }

    /// Parse a comma-separated string of region IDs into BodyRegion objects
    public static func parseRegions(_ raw: String) -> [BodyRegion] {
        guard !raw.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        return raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { region(id: $0) }
    }

    /// Encode an array of BodyRegion objects to a comma-separated string of IDs
    public static func encodeRegions(_ regions: [BodyRegion]) -> String {
        return regions.map { $0.id }.joined(separator: ",")
    }
}

// MARK: - Recovery Phase

/// Recovery phase for an injury (canonical ordering from acute to resolved)
public enum RecoveryPhase: String, Codable, Sendable, CaseIterable, Comparable {
    case acute
    case rehab
    case lightLoad
    case returnToPlay
    case resolved

    /// Display name for the recovery phase
    public var displayName: String {
        switch self {
        case .acute: return "Acute"
        case .rehab: return "Rehab"
        case .lightLoad: return "Light Load"
        case .returnToPlay: return "Return to Play"
        case .resolved: return "Resolved"
        }
    }

    /// Numeric value for ordering (lower = more severe)
    public var orderValue: Int {
        switch self {
        case .acute: return 0
        case .rehab: return 1
        case .lightLoad: return 2
        case .returnToPlay: return 3
        case .resolved: return 4
        }
    }

    /// Comparison for sorting
    public static func < (lhs: RecoveryPhase, rhs: RecoveryPhase) -> Bool {
        return lhs.orderValue < rhs.orderValue
    }
}
