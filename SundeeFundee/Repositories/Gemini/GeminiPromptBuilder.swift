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
        - Uses the athlete's known maxes to calculate working weights
        - Prescribes all weights in POUNDS (lbs)

        CRITICAL WEIGHT RULES — you MUST follow these exactly:

        BARBELL weights:
        - Men use a 45 lb bar, women use a 35 lb bar
        - Available plates per side: 45, 25, 15, 10, 5, 2.5 lb
        - Total weight MUST equal bar + (plates per side × 2), where plates per side sum to a multiple of 2.5 lb
        - Valid total lb examples (men's bar): 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105, 110, 115, 120, 125, 130, 135, 140, 145, 150, 155, 160, 165, 170, 175, 180, 185, 190, 195, 200, 205, 210, 215, 220, 225, 230, 235, 240, 245, 250, 255, 260, 265, 270, 275, 280, 285, 290, 295, 300, 315, 335, 365, 405
        - NEVER prescribe a barbell weight that cannot be built with the plates above (e.g., 227.5 lb is impossible)

        DUMBBELL weights — ONLY use these exact lb values: 10, 15, 20, 25, 35, 40, 50, 70
        - NEVER prescribe dumbbell weights between these values (e.g., 30 lb, 45 lb are not available)

        KETTLEBELL weights — ONLY use these exact lb values: 15, 25, 32, 53, 70
        - NEVER prescribe a kettlebell weight other than 15, 25, 32, 53, or 70 lb

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
                maxesSection += "- \(max.name): \(Int(max.weightLb.rounded())) lb\n"
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

        // Skills to practice
        if !context.desiredSkills.isEmpty {
            let skillsSection = """
                Skills to Practice: \(context.desiredSkills.joined(separator: ", "))
                Include structured skill work for each — progressions appropriate for the user's experience level.
                """
            sections.append(skillsSection)
        }

        // Body weight
        if let bodyWeight = context.bodyWeightKg {
            let bodyWeightLb = bodyWeight * WeightUnitConversion.poundsPerKilogram
            sections.append("Body Weight: \(Int(bodyWeightLb.rounded())) lb")
        }

        // Benchmark history
        if !context.benchmarkSummaries.isEmpty {
            var benchmarkSection = "Benchmark History:\n"
            for benchmark in context.benchmarkSummaries {
                benchmarkSection += "- \(benchmark.name): \(benchmark.bestScore) (\(benchmark.scoringType))\n"
            }
            sections.append(benchmarkSection.trimmingCharacters(in: .newlines))
        }

        // Recent pain activity
        if !context.recentPainActivity.isEmpty {
            var painSection = "Recent Pain Activity (last 7 days):\n"
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            for pain in context.recentPainActivity {
                let dateStr = formatter.string(from: pain.lastRecordedDate)
                painSection += "- \(pain.injuryID): pain level \(pain.lastPainLevel) on \(dateStr)\n"
            }
            sections.append(painSection.trimmingCharacters(in: .newlines))
        }

        // Training consistency
        if let rate = context.workoutCompletionRate {
            let percentage = Int(rate * 100)
            var consistencySection = "Training Consistency: \(percentage)% (last 28 days)"
            if rate < 0.6 {
                consistencySection += "\nReduce volume — user has low completion rate."
            } else if rate > 0.9 {
                consistencySection += "\nCan increase intensity/volume — user is highly consistent."
            }
            sections.append(consistencySection)
        }

        // Travel mode constraints
        if context.travelModeEnabled {
            sections.append("""
                TRAVEL MODE ACTIVE:
                - User is traveling — minimize space requirements
                - Avoid exercises requiring jumping or loud impacts (no box jumps, burpees with jumps, or dropping weights)
                - Prefer exercises that can be done in a small room or hotel gym
                - Keep noise levels low — no slamming or dropping weights
                """)
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
                        "weightLb": ["type": "number"],
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
