import Foundation

// MARK: - DeterministicCoachService

/// Coach service that uses pure domain logic from Phase 2 services.
///
/// This is the fallback for devices without Apple Intelligence.
/// It provides the same structured responses but generates summaries
/// and explanations using template-based text rather than AI.
///
/// The key principle: deterministic services make the decisions,
/// this service packages and explains them.
public final class DeterministicCoachService: CoachServiceProtocol, @unchecked Sendable {

    /// Optional coach profile for user preference-aware substitutions.
    public var coachProfile: CoachProfile?

    public init(coachProfile: CoachProfile? = nil) {
        self.coachProfile = coachProfile
    }

    // MARK: - Generate Workout

    public func generateWorkout(
        context: CoachContext,
        preferences: QuestionnaireAnswers
    ) async throws -> CoachWorkoutResponse {
        // Use existing domain logic to build exercises
        let exercises = buildExercisePlan(preferences: preferences, context: context)

        // Apply weights from maxes
        let eMult = energyMultiplier(preferences.energyLevel)
        let cMult = aiCyclePhaseMultiplier(context.cyclePhase)
        let weighted = applyWeights(
            exercises: exercises,
            maxes: context.maxes,
            energyMult: eMult,
            cycleMult: cMult
        )

        // Assign rest times
        let final = weighted.map { ex -> GeneratedExercise in
            guard ex.restMinutes == nil else { return ex }
            return GeneratedExercise(
                id: ex.id, name: ex.name, sets: ex.sets, reps: ex.reps,
                weightKg: ex.weightKg,
                restMinutes: assignRestMinutes(bodyweight: ex.bodyweightOnly, reps: ex.reps),
                notes: ex.notes, reasoning: ex.reasoning, bodyweightOnly: ex.bodyweightOnly
            )
        }

        let summary = buildCoachingSummary(preferences: preferences, context: context)
        let tips = buildTips(context: context)

        let workout = GeneratedWorkout(
            id: UUID().uuidString,
            createdAt: Date(),
            isFavorite: false,
            coachingSummary: summary,
            exercises: final,
            questionnaire: preferences
        )

        return CoachWorkoutResponse(
            workout: workout,
            coachingSummary: summary,
            tips: tips
        )
    }

    // MARK: - Get Insights

    public func getInsights(context: CoachContext) async throws -> CoachInsightsResponse {
        let plateaus = context.plateaus
        let trends = context.trends

        var actions: [String] = []
        var summaryParts: [String] = []

        // Strength plateaus
        if !plateaus.isEmpty {
            let names = plateaus.prefix(3).map(\.exerciseName).joined(separator: ", ")
            summaryParts.append("\(plateaus.count) lift(s) have stalled: \(names).")
            for p in plateaus.prefix(2) {
                actions.append(p.recommendation)
            }
        }

        // Volume plateaus
        if !context.volumePlateaus.isEmpty {
            let volNames = context.volumePlateaus.prefix(2).map(\.exerciseName).joined(separator: ", ")
            summaryParts.append("Volume has plateaued on \(volNames).")
            for p in context.volumePlateaus.prefix(1) {
                actions.append(p.recommendation)
            }
        }

        // Progress slowdown warnings
        for warning in context.progressWarnings.prefix(2) {
            summaryParts.append(warning.message)
            actions.append(warning.message)
        }

        // Trends
        for trend in trends {
            summaryParts.append(trend.message)
            if trend.severity == .warning {
                actions.append(trend.message)
            }
        }

        if summaryParts.isEmpty {
            summaryParts.append("Looking good — keep up your current training rhythm.")
        }

        return CoachInsightsResponse(
            plateaus: plateaus,
            trends: trends,
            summary: summaryParts.joined(separator: " "),
            priorityActions: actions
        )
    }

    // MARK: - Suggest Substitutions

    public func suggestSubstitutions(
        for exercise: String,
        context: CoachContext
    ) async throws -> CoachSubstitutionResponse {
        let equipmentContext: SubstitutionRanker.EquipmentContext
        switch context.equipment {
        case .fullGym: equipmentContext = .fullGym
        case .homeDumbbells: equipmentContext = .homeDumbbells
        case .bodyweightOnly: equipmentContext = .bodyweightOnly
        case .outdoor: equipmentContext = .bodyweightOnly
        }

        let subs = SubstitutionRanker.rank(
            substitutesFor: exercise,
            injuries: context.injuries,
            equipment: equipmentContext,
            profile: coachProfile
        )

        var explanation: String
        if context.injuries.isEmpty {
            explanation = "These alternatives target the same muscle groups as \(exercise)."
        } else {
            explanation = "These alternatives avoid movements that may aggravate your current injuries while targeting similar muscle groups."
        }

        if context.equipment != .fullGym {
            explanation += " Filtered for your available equipment."
        }

        return CoachSubstitutionResponse(
            originalExercise: exercise,
            substitutions: subs,
            explanation: explanation
        )
    }

    // MARK: - Adapt Weekly Plan

    public func adaptWeeklyPlan(
        plan: [ScheduleReshuffler.PlannedSession],
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int,
        context: CoachContext
    ) async throws -> CoachPlanResponse {
        let result = ScheduleReshuffler.reshuffle(
            plan: plan,
            completedDays: completedDays,
            missedDays: missedDays,
            currentDay: currentDay
        )

        var explanation = result.summary
        var volumeWarning: String?

        // Check if the reshuffle packed too much into remaining days
        if !result.droppedSessions.isEmpty {
            explanation += " Consider adding these to next week's plan."
        }

        // Check for overreaching risk
        let warningTrends = context.trends.filter { $0.type == .overreaching }
        if !warningTrends.isEmpty {
            volumeWarning = "You've been training at high volume recently. Consider dropping the extra session and focusing on recovery."
        }

        return CoachPlanResponse(
            result: result,
            explanation: explanation,
            volumeWarning: volumeWarning
        )
    }

    // MARK: - Private Helpers

    private func buildExercisePlan(
        preferences: QuestionnaireAnswers,
        context: CoachContext
    ) -> [GeneratedExercise] {
        let targetCount = max(3, preferences.timeMinutes / 10)
        var pool: [(name: String, bw: Bool)] = exercisePool(for: preferences.focus)

        // Filter by equipment
        if preferences.equipment == .bodyweightOnly {
            pool = pool.filter { $0.bw }
            if pool.isEmpty {
                pool = [("Push-Up", true), ("Air Squat", true), ("Burpee", true), ("Plank Hold", true)]
            }
        }

        // Filter by injuries
        if !context.injuries.isEmpty {
            pool = pool.filter { entry in
                !InjuryAdaptationEngine.isContraindicated(
                    exerciseName: entry.name,
                    exerciseCategory: nil,
                    injuries: context.injuries
                )
            }
        }

        let selected = Array(pool.shuffled().prefix(targetCount))
        let setsPerExercise = preferences.energyLevel == .low ? 3 : 4
        let reps = preferences.focus == .conditioning ? "12-15" : "6-8"

        return selected.enumerated().map { index, entry in
            GeneratedExercise(
                id: UUID().uuidString,
                name: entry.name,
                sets: setsPerExercise,
                reps: reps,
                reasoning: index == 0 ? "Primary movement for \(preferences.focus.rawValue.replacingOccurrences(of: "_", with: " "))" : nil,
                bodyweightOnly: entry.bw
            )
        }
    }

    private func exercisePool(for focus: WorkoutFocus) -> [(name: String, bw: Bool)] {
        switch focus {
        case .upperBody, .push:
            return [("Flat Barbell Bench Press", false), ("Strict Press", false),
                    ("Dumbbell Incline Press", false), ("Dips (Weighted)", false),
                    ("Close Grip Bench Press", false), ("Face Pull", false), ("Push-Up", true)]
        case .pull:
            return [("Barbell Row", false), ("Pull-Up", true), ("Lat Pulldown", false),
                    ("Cable Row", false), ("Dumbbell Row", false),
                    ("Bicep Curl (Barbell)", false), ("Face Pull", false)]
        case .lowerBody:
            return [("Back Squat", false), ("Romanian Deadlift (No Straps)", false),
                    ("Leg Press", false), ("Hip Thrust", false),
                    ("Leg Curl (Lying)", false), ("Leg Extension", false), ("Goblet Squat", false)]
        case .fullBody:
            return [("Back Squat", false), ("Flat Barbell Bench Press", false),
                    ("Barbell Row", false), ("Strict Press", false),
                    ("Romanian Deadlift (No Straps)", false), ("Pull-Up", true)]
        case .core:
            return [("Plank Hold", true), ("V-up", true), ("GHD Sit-up", true),
                    ("Toes-to-Bar", true), ("Sit-Up", true), ("L-Sit Hold", true)]
        case .conditioning:
            return [("Burpee", true), ("Kettlebell Swing", false), ("Wall Ball", false),
                    ("Box Jump", true), ("Thruster", false), ("Air Squat", true), ("Push-Up", true)]
        }
    }

    private func buildCoachingSummary(
        preferences: QuestionnaireAnswers,
        context: CoachContext
    ) -> String {
        var parts: [String] = []
        let focusName = preferences.focus.rawValue.replacingOccurrences(of: "_", with: " ")
        parts.append("\(preferences.timeMinutes)-minute \(focusName) session")

        if let phase = context.cyclePhase {
            let mult = aiCyclePhaseMultiplier(phase)
            if mult < 1.0 {
                parts.append("loads scaled to \(Int(mult * 100))% for \(phase) phase")
            } else if mult > 1.0 {
                parts.append("peak phase — push intensity to \(Int(mult * 100))%")
            }
        }

        let eMult = energyMultiplier(preferences.energyLevel)
        if eMult < 1.0 {
            parts.append("adjusted for lower energy today")
        } else if eMult > 1.0 {
            parts.append("high energy — weights bumped up")
        }

        if !context.injuries.isEmpty {
            parts.append("exercises filtered around \(context.injuries.count) active injury(s)")
        }

        return parts.joined(separator: ". ") + "."
    }

    private func buildTips(context: CoachContext) -> [String] {
        var tips: [String] = []

        if let phase = context.cyclePhase {
            switch phase {
            case .menstrual:
                tips.append("Focus on movement quality over weight today. Listen to your body.")
            case .follicular:
                tips.append("Rising energy — great time to push for progress on key lifts.")
            case .ovulation:
                tips.append("Peak strength window. Try for a PR if you're feeling it.")
            case .luteal:
                tips.append("You may feel warmer and more fatigued. Slightly longer rest periods can help.")
            }
        }

        if !context.plateaus.isEmpty {
            tips.append("Consider varying your rep scheme on stalled lifts this week.")
        }

        if context.workoutsThisWeek >= 5 {
            tips.append("You've trained \(context.workoutsThisWeek) times this week. Recovery is productive too.")
        }

        return tips
    }
}
