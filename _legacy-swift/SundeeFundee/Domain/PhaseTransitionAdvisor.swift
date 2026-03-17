import Foundation

/// Pure logic rules for suggesting recovery phase transitions based on pain trends.
/// User always manually confirms — no auto-transitions.
enum PhaseTransitionAdvisor {

    struct Suggestion {
        let injuryID: String
        let currentPhase: RecoveryPhase
        let suggestedPhase: RecoveryPhase
    }

    /// Evaluates whether an injury is ready to advance to the next phase.
    /// Returns nil if no transition is suggested.
    static func evaluateTransition(
        injuryID: String,
        currentPhase: RecoveryPhase,
        painLogs: [PainLog]
    ) -> Suggestion? {
        let recentLogs = Array(painLogs.prefix(5))

        switch currentPhase {
        case .acute:
            // acute → rehab: 3 consecutive days pain ≤ 5
            if meetsThreshold(recentLogs, count: 3, maxPain: 5) {
                return Suggestion(injuryID: injuryID, currentPhase: .acute, suggestedPhase: .rehab)
            }
        case .rehab:
            // rehab → lightLoad: 3 consecutive days pain ≤ 3
            if meetsThreshold(recentLogs, count: 3, maxPain: 3) {
                return Suggestion(injuryID: injuryID, currentPhase: .rehab, suggestedPhase: .lightLoad)
            }
        case .lightLoad:
            // lightLoad → returnToPlay: 3 consecutive days pain ≤ 2
            if meetsThreshold(recentLogs, count: 3, maxPain: 2) {
                return Suggestion(injuryID: injuryID, currentPhase: .lightLoad, suggestedPhase: .returnToPlay)
            }
        case .returnToPlay:
            // returnToPlay → resolved: 5 consecutive days pain ≤ 1
            if meetsThreshold(recentLogs, count: 5, maxPain: 1) {
                return Suggestion(injuryID: injuryID, currentPhase: .returnToPlay, suggestedPhase: .resolved)
            }
        case .resolved:
            break
        }

        return nil
    }

    /// Checks if the N most recent logs all have pain at or below the threshold.
    /// Logs are assumed sorted newest-first.
    static func meetsThreshold(_ logs: [PainLog], count: Int, maxPain: Int) -> Bool {
        guard logs.count >= count else { return false }
        return logs.prefix(count).allSatisfy { $0.painLevel <= maxPain }
    }
}
