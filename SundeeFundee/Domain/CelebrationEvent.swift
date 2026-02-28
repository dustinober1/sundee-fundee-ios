import Foundation

enum CelebrationEvent: Equatable, Sendable {
    case workoutCompleted(durationSeconds: Int, volumeKg: Double)
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
        switch self {
        case .workoutCompleted(let secs, let vol):
            let minutes = secs / 60
            return "\(minutes)min | \(Int(vol))kg total volume"
        case .newPersonalRecord(let name, let kg):
            return "\(name) — \(String(format: "%.1f", kg))kg estimated 1RM"
        case .programCompleted(let name):
            return "You finished \(name). Time to level up!"
        case .weightMilestone(let name, let kg):
            return "\(name) hit \(Int(kg))kg!"
        }
    }
}
