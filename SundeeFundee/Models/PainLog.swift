import SwiftData
import Foundation

enum SymptomType: String, CaseIterable, Codable {
    case sharp, dull, stiffness, instability
    var displayName: String {
        switch self {
        case .sharp:       return "Sharp"
        case .dull:        return "Dull"
        case .stiffness:   return "Stiffness"
        case .instability: return "Instability"
        }
    }
}

enum IntensityContext: String, CaseIterable, Codable {
    case duringWarmup = "during_warmup"
    case duringWorkSet = "during_work_set"
    case postWorkout = "post_workout"
    var displayName: String {
        switch self {
        case .duringWarmup:  return "During Warmup"
        case .duringWorkSet: return "During Work Set"
        case .postWorkout:   return "Post Workout"
        }
    }
}

@Model
final class PainLog {
    var id: String
    var injuryProfileID: String
    var painLevel: Int
    var workoutID: String?
    var notes: String?
    var recordedAt: Date
    /// Exercise that triggered the symptom.
    var triggerExercise: String?
    /// Type of symptom (sharp/dull/stiffness/instability).
    var symptomTypeRaw: String?
    /// When the symptom occurred relative to the workout.
    var intensityContextRaw: String?

    init(
        id: String = UUID().uuidString,
        injuryProfileID: String,
        painLevel: Int,
        workoutID: String? = nil,
        notes: String? = nil,
        recordedAt: Date = .now,
        triggerExercise: String? = nil,
        symptomType: SymptomType? = nil,
        intensityContext: IntensityContext? = nil
    ) {
        self.id = id
        self.injuryProfileID = injuryProfileID
        self.painLevel = painLevel
        self.workoutID = workoutID
        self.notes = notes
        self.recordedAt = recordedAt
        self.triggerExercise = triggerExercise
        self.symptomTypeRaw = symptomType?.rawValue
        self.intensityContextRaw = intensityContext?.rawValue
    }

    var symptomType: SymptomType? {
        get { symptomTypeRaw.flatMap { SymptomType(rawValue: $0) } }
        set { symptomTypeRaw = newValue?.rawValue }
    }

    var intensityContext: IntensityContext? {
        get { intensityContextRaw.flatMap { IntensityContext(rawValue: $0) } }
        set { intensityContextRaw = newValue?.rawValue }
    }
}
