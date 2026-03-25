import Foundation

enum GeminiWorkoutPrompt {

    static let systemInstruction = "You are a certified strength and conditioning coach designing personalized workouts. Return valid JSON only. No markdown fences, no explanation outside the JSON."

    static func build(from context: WorkoutGenerationContext) -> String {
        var sections: [String] = []

        sections.append("""
        Design a personalized workout with these parameters:
        - Duration: \(context.timeMinutes) minutes
        - Focus: \(context.focus.displayName)
        - Energy level: \(context.energyLevel.rawValue)
        - Equipment: \(context.equipment.displayName)
        - Experience: \(context.experienceLevel)
        - Goal: \(context.primaryGoal)
        - Gender: \(context.gender)
        - Weight unit preference: \(context.weightUnit)
        """)

        if !context.maxes.isEmpty {
            let maxLines = context.maxes.map { "  - \($0.name): \($0.weightKg)kg" }.joined(separator: "\n")
            sections.append("1RM Maxes (use these to calculate working weights):\n\(maxLines)")
        }

        if !context.recentWorkouts.isEmpty {
            let recentLines = context.recentWorkouts.prefix(5).map { "  - \($0.focus) (\($0.durationMinutes)min)" }.joined(separator: "\n")
            sections.append("Recent workouts (avoid repeating these):\n\(recentLines)")
        }

        if let phase = context.cyclePhase {
            sections.append("Menstrual cycle phase: \(phase). Adjust intensity and exercise selection appropriately for this phase.")
        }

        if !context.activeInjuries.isEmpty {
            let injuryLines = context.activeInjuries.map { "  - \($0.location) (\($0.phase)): avoid \($0.restrictions.joined(separator: ", "))" }.joined(separator: "\n")
            sections.append("Active injuries — substitute or remove contraindicated exercises:\n\(injuryLines)")
        }

        sections.append("""
        Return a JSON object with this exact structure:
        {
          "coachingSummary": "2-3 sentences explaining the workout design choices",
          "exercises": [
            {
              "name": "Exercise Name",
              "sets": 4,
              "reps": "8-10",
              "weightKg": 60.0,
              "restMinutes": 2.0,
              "notes": "coaching cues",
              "reasoning": "why this exercise was chosen",
              "bodyweightOnly": false
            }
          ]
        }

        weightKg should be null for bodyweight exercises. Use the 1RM data to calculate appropriate working weights (typically 65-85% of 1RM depending on rep range). Return only valid JSON.
        """)

        return sections.joined(separator: "\n\n")
    }
}
