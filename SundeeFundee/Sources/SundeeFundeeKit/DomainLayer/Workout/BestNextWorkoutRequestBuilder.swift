import Foundation

public enum BestNextWorkoutRequestBuilder {
    public struct Adjustment: Sendable, Equatable {
        public let decision: DeloadDecision?
        public let explanation: String
        public let isStandardSession: Bool

        public init(decision: DeloadDecision?, explanation: String, isStandardSession: Bool = false) {
            self.decision = decision
            self.explanation = explanation
            self.isStandardSession = isStandardSession
        }
    }

    public static func build(
        defaultEquipment: EquipmentAccess,
        latestEnergy: EnergyLevel?,
        painLogs: [DailyPainLog],
        todayDecisionKind: TodayTrainingDecisionKind,
        deloadDecision: DeloadDecision? = nil,
        useStandardSession: Bool = false
    ) -> QuickWorkoutRequest {
        let highPain = painLogs.contains { $0.intensity >= 6 }
        let decision: TodayTrainingDecisionKind = highPain ? .recover : todayDecisionKind
        let energy: EnergyLevel
        if highPain || (!useStandardSession && deloadDecision?.mode == .activeRecovery) {
            energy = .low
        } else if !useStandardSession && deloadDecision?.mode == .reduced {
            energy = .medium
        } else {
            energy = latestEnergy ?? .medium
        }

        return QuickWorkoutRequest(
            timeMinutes: 20,
            focus: .fullBody,
            energyLevel: energy,
            equipment: defaultEquipment,
            todayDecisionKind: decision,
            painLogs: painLogs
        )
    }

    public static func adjustment(for decision: DeloadDecision?, useStandardSession: Bool = false) -> Adjustment {
        guard let decision, !useStandardSession else {
            return Adjustment(decision: nil, explanation: "Using your standard session.", isStandardSession: true)
        }

        switch decision.mode {
        case .normal:
            return Adjustment(decision: decision, explanation: "Readiness supports your standard session today.")
        case .reduced:
            return Adjustment(decision: decision, explanation: "A lighter session is suggested today: fewer sets and a submaximal effort.")
        case .activeRecovery:
            return Adjustment(decision: decision, explanation: "Active recovery is suggested today: gentle movement and no hard efforts.")
        }
    }
}
