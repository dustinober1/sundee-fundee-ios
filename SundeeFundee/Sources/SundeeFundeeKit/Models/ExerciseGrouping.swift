import Foundation

// MARK: - ExerciseGrouping

/// Defines grouping metadata for supersets or circuits.
public struct ExerciseGrouping: Equatable, Codable, Sendable {
    public enum GroupType: String, Equatable, Codable, Sendable {
        case straight
        case superset
        case circuit
    }

    /// Identifier tying grouped exercises together (e.g. "group-A").
    public let groupID: String

    /// The style of grouping: superset (paired) or circuit (3+).
    public let groupType: GroupType

    /// Human-facing display tag (e.g. "A1", "A2", "B1", "B2").
    public let label: String

    /// Transition rest seconds between movements in the group (e.g. 30s).
    public let transitionRestSeconds: Int

    /// Recovery rest seconds after finishing the entire group round (e.g. 90-120s).
    public let groupRestSeconds: Int

    public init(
        groupID: String,
        groupType: GroupType = .superset,
        label: String,
        transitionRestSeconds: Int = 30,
        groupRestSeconds: Int = 90
    ) {
        self.groupID = groupID
        self.groupType = groupType
        self.label = label
        self.transitionRestSeconds = transitionRestSeconds
        self.groupRestSeconds = groupRestSeconds
    }
}
