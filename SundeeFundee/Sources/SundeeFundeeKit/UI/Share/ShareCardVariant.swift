import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ShareSummary
//
// Compact summary block used as overlay content on SelfieOverlayShareView.

public struct ShareSummary: Sendable, Equatable {
    public let title: String
    public let exerciseCount: Int
    public let totalVolume: Double
    public let durationMinutes: Int
    public let weightUnit: String

    public init(
        title: String,
        exerciseCount: Int,
        totalVolume: Double,
        durationMinutes: Int,
        weightUnit: String = "lb"
    ) {
        self.title = title
        self.exerciseCount = exerciseCount
        self.totalVolume = totalVolume
        self.durationMinutes = durationMinutes
        self.weightUnit = weightUnit
    }

    /// Build a summary from a Workout, picking lb as the display unit.
    public init(workout: Workout, weightUnit: String = "lb") {
        self.init(
            title: workout.name,
            exerciseCount: workout.exercises.count,
            totalVolume: workout.totalVolume,
            durationMinutes: workout.duration,
            weightUnit: weightUnit
        )
    }
}

// MARK: - ShareCardVariant
//
// The data payload driving which card is rendered. Views are matched by
// variant in `ShareCardRenderer`.

public enum ShareCardVariant: Sendable {
    case completedWorkout(workout: Workout, personalRecords: Set<String>)
    case newPR(exerciseName: String, weight: Double, unit: String, previousBest: Double?)
    case cycleInsight(phase: CyclePhase, cycleDay: Int, insight: String)
    case coachSummary(title: String, subtitle: String, badge: String, bullets: [String])
    case weeklyRecap(title: String, subtitle: String, badge: String, bullets: [String])
    #if canImport(UIKit)
    case selfieOverlay(image: UIImage, summary: ShareSummary)
    #endif

    /// Preview title used for the native share sheet.
    public var shareTitle: String {
        switch self {
        case .completedWorkout(let workout, _):
            return workout.name
        case .newPR(let exercise, let weight, let unit, _):
            return "New PR — \(exercise) \(formatWeight(weight)) \(unit)"
        case .cycleInsight:
            return "Cycle-aware training"
        case .coachSummary(let title, _, _, _):
            return title
        case .weeklyRecap(let title, _, _, _):
            return title
        #if canImport(UIKit)
        case .selfieOverlay(_, let summary):
            return summary.title
        #endif
        }
    }

    private func formatWeight(_ w: Double) -> String {
        if w == floor(w) { return "\(Int(w))" }
        return String(format: "%.1f", w)
    }
}
