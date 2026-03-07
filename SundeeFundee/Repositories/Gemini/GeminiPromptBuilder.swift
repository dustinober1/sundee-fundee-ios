import Foundation

enum GeminiPromptBuilder {

    // MARK: - System Prompt

    static let systemPrompt: String = """
        You are an experienced strength and conditioning coach. Design a workout that:
        - Prioritizes compound movements appropriate for the athlete's experience level
        - Respects all injury restrictions — never program contraindicated movements
        - Accounts for menstrual cycle phase when provided (adjust intensity/volume)
        - Applies energy level to load selection
        - Avoids repeating exercises from recent workouts when possible
        - Uses the athlete's known maxes to calculate working weights (prescribe specific kg values)
        - Provides brief reasoning for each exercise choice
        - Includes a coaching summary explaining the overall session design
        """

    // MARK: - User Prompt

    static func userPrompt(from context: WorkoutGenerationContext) -> String {
        var sections: [String] = []

        // Basic info
        sections.append("""
            Focus: \(context.focus.displayName)
            Duration: \(context.timeMinutes) minutes
            Energy Level: \(context.energyLevel.rawValue)
            Equipment: \(context.equipment.displayName)
            Experience Level: \(context.experienceLevel)
            Primary Goal: \(context.primaryGoal)
            Gender: \(context.gender)
            Weight Unit: \(context.weightUnit)
            """)

        // Maxes
        if !context.maxes.isEmpty {
            var maxesSection = "Known Maxes:\n"
            for max in context.maxes {
                maxesSection += "- \(max.name): \(max.weightKg) kg\n"
            }
            maxesSection += "Prefer programming exercises the athlete has maxes for."
            sections.append(maxesSection)
        }

        // Cycle phase
        if let phase = context.cyclePhase {
            var cycleSection = "Cycle Phase: \(phase)"
            if let readiness = context.readinessTier {
                cycleSection += "\nReadiness: \(readiness)"
            }
            sections.append(cycleSection)
        }

        // Injuries
        if !context.activeInjuries.isEmpty {
            var injurySection = "Active Injuries:\n"
            for injury in context.activeInjuries {
                injurySection += "- \(injury.location) (\(injury.phase))"
                if !injury.restrictions.isEmpty {
                    injurySection += " — restrictions: \(injury.restrictions.joined(separator: ", "))"
                }
                injurySection += "\n"
            }
            sections.append(injurySection.trimmingCharacters(in: .newlines))
        }

        // Recent workouts (limit to 5)
        if !context.recentWorkouts.isEmpty {
            let capped = Array(context.recentWorkouts.prefix(5))
            var recentSection = "Recent Workouts:\n"
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            for workout in capped {
                let dateStr = formatter.string(from: workout.date)
                recentSection += "- \(dateStr): \(workout.focus), \(workout.durationMinutes) min — \(workout.exercises.joined(separator: ", "))\n"
            }
            sections.append(recentSection.trimmingCharacters(in: .newlines))
        }

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Response Schema

    nonisolated(unsafe) static let responseSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "coachingSummary": ["type": "string"],
            "exercises": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "sets": ["type": "integer"],
                        "reps": ["type": "string"],
                        "weightKg": ["type": "number"],
                        "restMinutes": ["type": "number"],
                        "notes": ["type": "string"],
                        "reasoning": ["type": "string"],
                        "bodyweightOnly": ["type": "boolean"]
                    ] as [String: Any],
                    "required": ["name", "sets", "reps", "bodyweightOnly"]
                ] as [String: Any]
            ] as [String: Any]
        ] as [String: Any],
        "required": ["coachingSummary", "exercises"]
    ]
}
