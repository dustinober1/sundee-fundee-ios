import Foundation

public enum TodayTrainingDecisionService {
    public static func decision(
        recoveryScore: RecoveryScore?,
        cyclePhase: CyclePhase?,
        cycleConfidence: Double?,
        painIntensity: Int?,
        energyLevel: EnergyLevel?,
        weeklyPlanProgress: WeeklyPlanProgress?,
        deloadRecommended: Bool
    ) -> TodayTrainingDecision {
        var reasons: [String] = []
        let scoreValue = recoveryScore?.total
        let phaseName = cyclePhase.map(phaseLabel) ?? "unknown phase"

        if let scoreValue {
            reasons.append("Recovery score is \(scoreValue)/100.")
        } else {
            reasons.append("Recovery score is missing, so guidance uses available context.")
        }

        if let painIntensity {
            reasons.append("Pain check-in is \(painIntensity)/10.")
        }

        if let cycleConfidence {
            reasons.append("Cycle confidence is \(Int((cycleConfidence * 100).rounded()))%.")
        }

        if let energyLevel {
            reasons.append("Selected energy is \(energyLevel.rawValue).")
        }

        if let weeklyPlanProgress {
            reasons.append(weeklyPlanProgress.displayText + ".")
        }

        if deloadRecommended {
            return TodayTrainingDecision(
                kind: .recover,
                title: "Take an active recovery day",
                subtitle: "Recent load and recovery trends suggest a deload is the better move today.",
                reasons: reasons + ["Deload is recommended from recent fatigue signals."],
                primaryActionTitle: "Start Active Recovery",
                systemImage: "figure.cooldown"
            )
        }

        if let painIntensity, painIntensity >= 7 {
            return TodayTrainingDecision(
                kind: .recover,
                title: "Recover before pushing today",
                subtitle: "High pain was logged. Use a lighter session or active recovery.",
                reasons: reasons + ["Pain level is high enough to avoid heavy loading."],
                primaryActionTitle: "Start Active Recovery",
                systemImage: "cross.case.fill"
            )
        }

        if let scoreValue, scoreValue < 40 {
            return TodayTrainingDecision(
                kind: .recover,
                title: "Recover today",
                subtitle: "Your readiness is low. Choose recovery work to protect tomorrow's performance.",
                reasons: reasons + ["Low recovery score indicates high fatigue risk."],
                primaryActionTitle: "Start Active Recovery",
                systemImage: "bed.double.fill"
            )
        }

        let lowConfidenceCycle = (cycleConfidence ?? 1.0) < 0.35
        let moderateScore = (scoreValue ?? 55) < 70
        let lowEnergy = energyLevel == .low
        let moderatePain = (painIntensity ?? 0) >= 4

        if moderateScore || lowEnergy || lowConfidenceCycle || moderatePain {
            return TodayTrainingDecision(
                kind: .modify,
                title: "Train with modifications",
                subtitle: "A lighter or shorter version of your \(phaseName) session is recommended today.",
                reasons: reasons + ["Adjusting volume or exercise selection keeps momentum without overreaching."],
                primaryActionTitle: "Build Modified Session",
                systemImage: "slider.horizontal.3"
            )
        }

        return TodayTrainingDecision(
            kind: .train,
            title: "Train as planned",
            subtitle: "Your signals support a full-strength session today.",
            reasons: reasons + ["No major readiness blockers were detected."],
            primaryActionTitle: "Start Planned Workout",
            systemImage: "figure.strengthtraining.traditional"
        )
    }

    private static func phaseLabel(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual:
            return "menstrual"
        case .follicular:
            return "follicular"
        case .ovulation:
            return "ovulation"
        case .luteal:
            return "luteal"
        }
    }
}
