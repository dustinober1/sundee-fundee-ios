import Foundation

public enum BestNextWorkoutRequestBuilder {
    public static func build(
        defaultEquipment: EquipmentAccess,
        latestEnergy: EnergyLevel?,
        painLogs: [DailyPainLog],
        todayDecisionKind: TodayTrainingDecisionKind
    ) -> QuickWorkoutRequest {
        let highPain = painLogs.contains { $0.intensity >= 6 }
        let decision: TodayTrainingDecisionKind = highPain ? .recover : todayDecisionKind
        let energy: EnergyLevel = highPain ? .low : (latestEnergy ?? .medium)

        return QuickWorkoutRequest(
            timeMinutes: 20,
            focus: .fullBody,
            energyLevel: energy,
            equipment: defaultEquipment,
            todayDecisionKind: decision,
            painLogs: painLogs
        )
    }
}
