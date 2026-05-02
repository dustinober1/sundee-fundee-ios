import Foundation

public struct CoachDecisionPacket: Codable, Sendable, Equatable {
    public let promptVersion: String
    public let durationMinutes: Int?
    public let focus: WorkoutFocus?
    public let energyLevel: EnergyLevel?
    public let equipment: EquipmentAccess?
    public let cyclePhase: CyclePhase?
    public let workoutsThisWeek: Int
    public let activeInjuryCount: Int
    public let selectedExerciseNames: [String]
    public let allowedExerciseNames: [String]
    public let reasonCodes: [CoachReasonCode]
    public let cautionCodes: [CoachReasonCode]
    public let deterministicSummary: String
    public let deterministicTips: [String]

    public init(
        promptVersion: String,
        durationMinutes: Int?,
        focus: WorkoutFocus?,
        energyLevel: EnergyLevel?,
        equipment: EquipmentAccess?,
        cyclePhase: CyclePhase?,
        workoutsThisWeek: Int,
        activeInjuryCount: Int,
        selectedExerciseNames: [String],
        allowedExerciseNames: [String],
        reasonCodes: [CoachReasonCode],
        cautionCodes: [CoachReasonCode],
        deterministicSummary: String,
        deterministicTips: [String]
    ) {
        self.promptVersion = promptVersion
        self.durationMinutes = durationMinutes
        self.focus = focus
        self.energyLevel = energyLevel
        self.equipment = equipment
        self.cyclePhase = cyclePhase
        self.workoutsThisWeek = workoutsThisWeek
        self.activeInjuryCount = activeInjuryCount
        self.selectedExerciseNames = selectedExerciseNames
        self.allowedExerciseNames = allowedExerciseNames
        self.reasonCodes = reasonCodes
        self.cautionCodes = cautionCodes
        self.deterministicSummary = deterministicSummary
        self.deterministicTips = deterministicTips
    }

    public func sanitizedForPrompt() -> String {
        var lines: [String] = []
        lines.append("Prompt version: \(promptVersion)")
        if let durationMinutes { lines.append("Duration minutes: \(durationMinutes)") }
        if let focus { lines.append("Focus: \(focus.rawValue)") }
        if let energyLevel { lines.append("Energy: \(energyLevel.rawValue)") }
        if let equipment { lines.append("Equipment: \(equipment.rawValue)") }
        if let cyclePhase { lines.append("Cycle phase: \(cyclePhase.rawValue)") } else { lines.append("Cycle phase: unavailable") }
        lines.append("Workouts this week: \(workoutsThisWeek)")
        lines.append("Movement constraint count: \(activeInjuryCount)")
        lines.append("Selected exercises: \(selectedExerciseNames.joined(separator: ", "))")
        lines.append("Allowed exercises: \(allowedExerciseNames.joined(separator: ", "))")
        lines.append("Reason codes: \(reasonCodes.map(\.rawValue).joined(separator: ", "))")
        lines.append("Caution codes: \(cautionCodes.map(\.rawValue).joined(separator: ", "))")
        lines.append("Deterministic summary: \(deterministicSummary)")
        if !deterministicTips.isEmpty { lines.append("Deterministic tips: \(deterministicTips.joined(separator: " | "))") }
        return lines.joined(separator: "\n")
    }
}
