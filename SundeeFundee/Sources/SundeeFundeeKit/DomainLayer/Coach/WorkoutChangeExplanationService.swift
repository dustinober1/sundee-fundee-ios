import Foundation

public struct WorkoutChangeNote: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let message: String
    public let systemImage: String

    public init(id: String, title: String, message: String, systemImage: String) {
        self.id = id
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }
}

public enum WorkoutChangeExplanationService {
    public static func notes(
        context: CoachContext,
        energyLevel: EnergyLevel,
        equipment: EquipmentAccess
    ) -> [WorkoutChangeNote] {
        var notes: [WorkoutChangeNote] = []

        if let phase = context.cyclePhase {
            notes.append(WorkoutChangeNote(
                id: "cycle",
                title: "Cycle Phase",
                message: cycleMessage(phase: phase, confidence: context.cycleConfidence),
                systemImage: "arrow.triangle.2.circlepath"
            ))
        }

        notes.append(WorkoutChangeNote(
            id: "energy",
            title: "Energy",
            message: energyMessage(energyLevel),
            systemImage: "bolt"
        ))

        if equipment != .fullGym {
            notes.append(WorkoutChangeNote(
                id: "equipment",
                title: "Equipment",
                message: "Exercise choices were filtered for \(equipment.displayName).",
                systemImage: "dumbbell"
            ))
        }

        let activeInjuries = context.injuries.filter { $0.recoveryPhase != .resolved }
        if !activeInjuries.isEmpty {
            notes.append(WorkoutChangeNote(
                id: "injury",
                title: "Movement Constraints",
                message: "Exercises were narrowed around your active pain or injury records.",
                systemImage: "bandage"
            ))
        }

        if context.workoutsThisWeek >= 3 || context.progressWarnings.isEmpty == false {
            notes.append(WorkoutChangeNote(
                id: "recovery",
                title: "Recovery",
                message: "Recent workload was considered when choosing volume and intensity.",
                systemImage: "heart.text.square"
            ))
        }

        return notes
    }

    private static func cycleMessage(phase: CyclePhase, confidence: Double?) -> String {
        let confidencePrefix: String
        if let confidence, confidence < 0.7 {
            confidencePrefix = "Because confidence is not high, "
        } else {
            confidencePrefix = ""
        }

        switch phase {
        case .menstrual:
            return "\(confidencePrefix)volume and loading stay more conservative for the menstrual phase."
        case .follicular:
            return "\(confidencePrefix)progression is allowed because follicular phase often supports harder training."
        case .ovulation:
            return "\(confidencePrefix)strength-focused work can stay prominent during the ovulation window."
        case .luteal:
            return "\(confidencePrefix)volume is kept steady with room for more rest in the luteal phase."
        }
    }

    private static func energyMessage(_ energyLevel: EnergyLevel) -> String {
        switch energyLevel {
        case .low:
            return "Volume and intensity were reduced for a low-energy day."
        case .medium:
            return "Volume stays close to baseline for a normal-energy day."
        case .high:
            return "The plan can use slightly more challenging work for a high-energy day."
        }
    }
}
