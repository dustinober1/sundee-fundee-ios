import Foundation

/// Generates standalone 10-15 minute recovery sessions for rest days.
/// Built from existing recovery prep blocks with phase-appropriate volume.
enum RehabSessionGenerator {

    /// Generates a rehab mini-session for the given injuries.
    /// Returns nil if no active injuries with rehab-appropriate phases exist.
    static func generateSession(injuries: [InjuryProfile]) -> ProgramSession? {
        let rehabInjuries = injuries.filter { $0.recoveryPhase == .rehab || $0.recoveryPhase == .lightLoad }
        guard !rehabInjuries.isEmpty else { return nil }

        var seen = Set<String>()
        var exercises: [ProgramExercise] = []

        for injury in rehabInjuries {
            let loc = injury.location.lowercased()
            let prepExercises = recoveryExercises(for: loc)

            for ex in prepExercises where !seen.contains(ex) {
                seen.insert(ex)
                let (sets, reps, notes) = volumeForPhase(injury.recoveryPhase)
                exercises.append(ProgramExercise(
                    exercise: ex,
                    variant: nil,
                    sets: sets,
                    reps: reps,
                    percent1RM: nil,
                    restMinutes: 0.5,
                    notes: notes,
                    bodyweightOnly: true
                ))
            }
        }

        guard !exercises.isEmpty else { return nil }

        return ProgramSession(
            sessionID: "rehab-\(UUID().uuidString.prefix(8))",
            sessionName: "Rehab Session",
            sessionType: "recovery",
            focus: "Recovery & Mobility",
            exercises: exercises
        )
    }

    private static func volumeForPhase(_ phase: RecoveryPhase) -> (ExerciseValue, ExerciseValue, String) {
        switch phase {
        case .rehab:
            return (.fixed(3), .fixed(12), "Rehab — controlled tempo, focus on form")
        case .lightLoad:
            return (.fixed(2), .fixed(15), "Light load — slow tempo, full ROM")
        default:
            return (.fixed(2), .fixed(10), "Recovery — gentle movement")
        }
    }

    private static let recoveryMap: [String: [String]] = [
        "knee":     ["Bird-Dogs", "Bodyweight Lunges", "Terminal Knee Extension", "Straight Leg Raises"],
        "shoulder": ["Banded Pull-Aparts", "Face Pulls", "Wall Slides", "Shoulder Circles"],
        "back":     ["Cat-Cow", "Bird-Dogs", "Dead Bug", "Pelvic Tilts"],
        "spine":    ["Cat-Cow", "Bird-Dogs", "Dead Bug", "McGill Curl-Up"],
        "hip":      ["Hip Circles", "Glute Bridges", "Clamshells", "90/90 Hip Stretch"],
        "ankle":    ["Ankle Circles", "Calf Raises (Partial)", "Towel Toe Curls"],
        "wrist":    ["Wrist Circles", "Prayer Stretch", "Reverse Wrist Curl"],
    ]

    private static func recoveryExercises(for location: String) -> [String] {
        var result: [String] = []
        for (key, exercises) in recoveryMap where location.contains(key) {
            result.append(contentsOf: exercises)
        }
        return result
    }
}
