import Foundation

public enum TodayTrainingDecisionService {
    public static func decision(
        cyclePhase: CyclePhase?,
        cycleConfidence: Double?,
        painIntensity: Int?,
        energyLevel: EnergyLevel?,
        weeklyPlanProgress: WeeklyPlanProgress?,
        deloadRecommended: Bool
    ) -> TodayTrainingDecision {
        var reasons: [String] = []
        let phaseName = cyclePhase.map(phaseLabel)

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
                subtitle: "Recent training context suggests a lighter day is the better move today.",
                reasons: reasons + ["A deload is recommended from available fatigue signals."],
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

        let lowConfidenceCycle = (cycleConfidence ?? 1.0) < 0.35
        let lowEnergy = energyLevel == .low
        let moderatePain = (painIntensity ?? 0) >= 4

        if lowEnergy || lowConfidenceCycle || moderatePain {
            let subtitle: String
            if let phaseName {
                subtitle = "A lighter or shorter version of your \(phaseName) session is recommended today."
            } else {
                subtitle = "A lighter or shorter session is recommended today."
            }
            return TodayTrainingDecision(
                kind: .modify,
                title: "Train with modifications",
                subtitle: subtitle,
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
