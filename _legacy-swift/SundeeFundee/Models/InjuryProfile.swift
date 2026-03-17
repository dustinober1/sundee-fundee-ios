import SwiftData
import Foundation

enum InjuryStatus: String, Codable {
    case active, resolved
}

@Model
final class InjuryProfile {
    var id: String
    var userID: String
    var location: String
    var movementLimitations: String
    var recoveryGoal: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    var resolvedAt: Date?
    /// Five-phase recovery arc: acute → rehab → lightLoad → returnToPlay → resolved.
    /// Default "acute" for new injuries and backward compat with existing records.
    var recoveryPhaseRaw: String
    /// Structured body regions, comma-separated raw values from BodyLocation.Region.
    var locationRegionsRaw: String
    /// IDs of injury disclaimers the user has acknowledged, stored as comma-separated string.
    var acknowledgedDisclaimerIDsRaw: String

    init(
        id: String,
        userID: String,
        location: String = "",
        movementLimitations: String = "",
        recoveryGoal: String = "",
        status: InjuryStatus = .active,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        resolvedAt: Date? = nil
    ) {
        self.id = id
        self.userID = userID
        self.location = location
        self.movementLimitations = movementLimitations
        self.recoveryGoal = recoveryGoal
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.resolvedAt = resolvedAt
        self.recoveryPhaseRaw = RecoveryPhase.acute.rawValue
        self.locationRegionsRaw = ""
        self.acknowledgedDisclaimerIDsRaw = ""
    }

    var status: InjuryStatus {
        get { InjuryStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var recoveryPhase: RecoveryPhase {
        get { RecoveryPhase(rawValue: recoveryPhaseRaw) ?? .acute }
        set { recoveryPhaseRaw = newValue.rawValue }
    }

    var locationRegions: [BodyLocation.Region] {
        get { BodyLocation.parseRegions(locationRegionsRaw) }
        set { locationRegionsRaw = BodyLocation.encodeRegions(newValue) }
    }

    var isActive: Bool { recoveryPhase != .resolved }

    var isComplete: Bool {
        !location.trimmingCharacters(in: .whitespaces).isEmpty &&
        !movementLimitations.trimmingCharacters(in: .whitespaces).isEmpty &&
        !recoveryGoal.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var acknowledgedDisclaimerIDs: Set<String> {
        get {
            Set(acknowledgedDisclaimerIDsRaw.split(separator: ",").map(String.init))
        }
        set {
            acknowledgedDisclaimerIDsRaw = newValue.sorted().joined(separator: ",")
        }
    }
}
