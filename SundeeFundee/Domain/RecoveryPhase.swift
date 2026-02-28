import Foundation

/// Five-phase recovery arc that drives how the InjuryAdaptationEngine behaves.
/// Stored as raw `String` on `InjuryProfile` for CloudKit compatibility.
enum RecoveryPhase: String, CaseIterable, Codable {
    case acute
    case rehab
    case lightLoad
    case returnToPlay
    case resolved

    var displayName: String {
        switch self {
        case .acute:        return "Acute"
        case .rehab:        return "Rehab"
        case .lightLoad:    return "Light Load"
        case .returnToPlay: return "Return to Play"
        case .resolved:     return "Resolved"
        }
    }
}
