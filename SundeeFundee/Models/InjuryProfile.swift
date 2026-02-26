import SwiftData
import Foundation

enum InjuryStatus: String, Codable {
    case active, resolved
}

@Model
final class InjuryProfile {
    @Attribute(.unique) var id: String
    var userID: String
    var location: String
    var movementLimitations: String
    var recoveryGoal: String
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    var resolvedAt: Date?
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
        self.acknowledgedDisclaimerIDsRaw = ""
    }

    var status: InjuryStatus {
        get { InjuryStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var isActive: Bool { status == .active }

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
