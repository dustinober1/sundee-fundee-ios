import Foundation

enum CelebrationEvent: Equatable, Sendable {
    case workoutCompleted(durationSeconds: Int)
    case newPersonalRecord(exerciseName: String, weightKg: Double)
    case programCompleted(programName: String)
    case weightMilestone(exerciseName: String, thresholdKg: Double)

    var title: String {
        switch self {
        case .workoutCompleted:
            return "Workout Complete!"
        case .newPersonalRecord:
            return "New Personal Record!"
        case .programCompleted:
            return "Program Complete!"
        case .weightMilestone:
            return "Weight Milestone!"
        }
    }

    var subtitle: String {
        subtitle(unit: .kilograms)
    }

    func subtitle(unit: WeightUnit) -> String {
        switch self {
        case .workoutCompleted(let secs):
            let minutes = secs / 60
            return minutes > 0 ? "Completed in \(minutes) min" : "Workout saved!"
        case .newPersonalRecord(let name, let kg):
            let formatted = WeightUnitConversion.formatWithUnit(kilograms: kg, unit: unit)
            return "\(name) — \(formatted) estimated 1RM"
        case .programCompleted(let name):
            return "You finished \(name). Time to level up!"
        case .weightMilestone(let name, let kg):
            let formatted = WeightUnitConversion.formatWithUnit(kilograms: kg, unit: unit, maximumFractionDigits: 0)
            return "\(name) hit \(formatted)!"
        }
    }
}
