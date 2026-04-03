import Foundation

// MARK: - Body Region

/// A body region that can be injured
public struct BodyRegion: Codable, Sendable, Identifiable {
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

/// All recognized body regions
public let bodyRegions: [BodyRegion] = [
    BodyRegion(id: "head",            displayName: "Head",            engineKey: "head"),
    BodyRegion(id: "neck",            displayName: "Neck",            engineKey: "neck"),
    BodyRegion(id: "shoulder_left",   displayName: "Left Shoulder",   engineKey: "shoulder"),
    BodyRegion(id: "shoulder_right",  displayName: "Right Shoulder",  engineKey: "shoulder"),
    BodyRegion(id: "chest",           displayName: "Chest",           engineKey: "chest"),
    BodyRegion(id: "upper_back",      displayName: "Upper Back",      engineKey: "back"),
    BodyRegion(id: "lower_back",      displayName: "Lower Back",      engineKey: "back"),
    BodyRegion(id: "elbow_left",      displayName: "Left Elbow",      engineKey: "elbow"),
    BodyRegion(id: "elbow_right",     displayName: "Right Elbow",     engineKey: "elbow"),
    BodyRegion(id: "wrist_left",      displayName: "Left Wrist",      engineKey: "wrist"),
    BodyRegion(id: "wrist_right",     displayName: "Right Wrist",     engineKey: "wrist"),
    BodyRegion(id: "hip_left",        displayName: "Left Hip",        engineKey: "hip"),
    BodyRegion(id: "hip_right",       displayName: "Right Hip",       engineKey: "hip"),
    BodyRegion(id: "knee_left",       displayName: "Left Knee",       engineKey: "knee"),
    BodyRegion(id: "knee_right",      displayName: "Right Knee",      engineKey: "knee"),
    BodyRegion(id: "ankle_left",      displayName: "Left Ankle",      engineKey: "ankle"),
    BodyRegion(id: "ankle_right",     displayName: "Right Ankle",     engineKey: "ankle"),
]

private let regionMap: [String: BodyRegion] = {
    Dictionary(uniqueKeysWithValues: bodyRegions.map { ($0.id, $0) })
}()

/// Parse a comma-separated string of region IDs into BodyRegion objects.
/// Unrecognized IDs are silently dropped.
public func parseRegions(_ raw: String) -> [BodyRegion] {
    guard !raw.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
    return raw
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
        .compactMap { regionMap[$0] }
}

/// Encode an array of BodyRegion objects to a comma-separated string of IDs.
public func encodeRegions(_ regions: [BodyRegion]) -> String {
    regions.map(\.id).joined(separator: ",")
}

// MARK: - Recovery Phase

/// Phase of injury recovery, from most severe to resolved
public enum RecoveryPhase: String, Codable, Sendable, CaseIterable {
    case acute
    case rehab
    case lightLoad
    case returnToPlay
    case resolved
}

/// Canonical ordering from acute (most severe) to resolved
public let recoveryPhaseOrder: [RecoveryPhase] = [
    .acute, .rehab, .lightLoad, .returnToPlay, .resolved,
]

/// Display name for a recovery phase
public func recoveryPhaseDisplayName(_ phase: RecoveryPhase) -> String {
    switch phase {
    case .acute:        return "Acute"
    case .rehab:        return "Rehab"
    case .lightLoad:    return "Light Load"
    case .returnToPlay: return "Return to Play"
    case .resolved:     return "Resolved"
    }
}
