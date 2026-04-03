import Foundation

// MARK: - PreferenceLearner

/// Analyzes workout history, substitution decisions, and edits to learn
/// the user's training preferences over time.
///
/// Pure domain logic — no framework dependencies.
/// Call `learn()` with historical data to produce an updated `CoachProfile`.
public enum PreferenceLearner {

    // MARK: - Learn from History

    /// Analyzes all available data and produces an updated CoachProfile.
    ///
    /// - Parameters:
    ///   - existingProfile: The current profile (or a fresh default).
    ///   - workouts: Completed workouts (recent history).
    ///   - edits: Recorded workout edits.
    ///   - substitutions: Substitution accept/reject decisions.
    ///   - questionnaires: Past questionnaire answers.
    /// - Returns: An updated CoachProfile reflecting learned preferences.
    public static func learn(
        existingProfile: CoachProfile,
        workouts: [CompletedWorkoutRecord],
        edits: [WorkoutEdit] = [],
        substitutions: [AcceptedSubstitution] = [],
        questionnaires: [QuestionnaireAnswers] = []
    ) -> CoachProfile {
        var profile = existingProfile

        // Session duration preference
        if !questionnaires.isEmpty {
            let avgMinutes = questionnaires.map(\.timeMinutes).reduce(0, +) / questionnaires.count
            profile.preferredSessionMinutes = avgMinutes
        }

        // Focus area preferences
        if !questionnaires.isEmpty {
            profile.preferredFocusAreas = topFocusAreas(from: questionnaires)
        }

        // Equipment preference
        if !questionnaires.isEmpty {
            profile.preferredEquipment = dominantEquipment(from: questionnaires)
        }

        // Favorite exercises (most frequently appeared in workouts)
        profile.favoriteExercises = topExercises(from: workouts, limit: 10)

        // Avoided exercises (removed in edits or rejected in substitutions)
        profile.avoidedExercises = avoidedExercises(
            edits: edits,
            substitutions: substitutions
        )

        // Average workouts per week (rolling 4-week)
        profile.avgWorkoutsPerWeek = averageWeeklyWorkouts(from: workouts, weeks: 4)

        // Energy distribution
        if !questionnaires.isEmpty {
            profile.energyDistribution = buildEnergyDistribution(from: questionnaires)
        }

        profile.totalWorkoutsObserved = workouts.count
        profile.lastUpdated = Date()

        return profile
    }

    // MARK: - Weekly Summary Generation

    /// Generates a weekly summary from completed workouts.
    ///
    /// - Parameters:
    ///   - workouts: All completed workout records.
    ///   - weekStart: The Monday of the week to summarize.
    ///   - profile: The current coach profile (for context).
    /// - Returns: A weekly summary, or nil if no workouts in that week.
    public static func generateWeeklySummary(
        workouts: [CompletedWorkoutRecord],
        weekStart: Date,
        profile: CoachProfile
    ) -> CoachWeeklySummary? {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return nil
        }

        let weekWorkouts = workouts.filter { $0.date >= weekStart && $0.date < weekEnd }
        guard !weekWorkouts.isEmpty else { return nil }

        let totalMinutes = weekWorkouts.compactMap(\.duration).reduce(0, +)
        let allExercises = weekWorkouts.flatMap(\.exerciseNames)
        let muscleGroups = Set(allExercises.compactMap {
            WeeklyLoadAnalyzer.classifyMuscleGroup($0)
        }).sorted()

        // Build observations
        var observations: [String] = []

        let majorGroups: Set<String> = ["Lower", "Upper Push", "Upper Pull", "Core"]
        let missing = majorGroups.subtracting(Set(muscleGroups))
        if !missing.isEmpty {
            observations.append("Missed \(missing.sorted().joined(separator: ", ")) this week.")
        }

        if weekWorkouts.count >= 5 {
            observations.append("High frequency week — \(weekWorkouts.count) sessions.")
        } else if weekWorkouts.count <= 1 {
            observations.append("Light week — only \(weekWorkouts.count) session(s).")
        }

        // Build recommendations
        var recommendations: [String] = []

        if !missing.isEmpty {
            recommendations.append("Try to hit \(missing.sorted().first ?? "missing groups") early next week.")
        }

        if weekWorkouts.count >= 6 {
            recommendations.append("Consider a lighter week to recover.")
        }

        if weekWorkouts.count < Int(profile.avgWorkoutsPerWeek.rounded()) - 1 && profile.avgWorkoutsPerWeek > 0 {
            recommendations.append("Below your usual \(Int(profile.avgWorkoutsPerWeek.rounded())) sessions/week — try to get back on track.")
        }

        if recommendations.isEmpty {
            recommendations.append("Solid week. Keep the momentum going.")
        }

        return CoachWeeklySummary(
            weekStartDate: weekStart,
            workoutsCompleted: weekWorkouts.count,
            totalMinutes: totalMinutes,
            muscleGroupsHit: muscleGroups,
            observations: observations,
            recommendations: recommendations
        )
    }

    // MARK: - Private Helpers

    private static func topFocusAreas(from questionnaires: [QuestionnaireAnswers]) -> [String] {
        var counts: [String: Int] = [:]
        for q in questionnaires {
            counts[q.focus.rawValue, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.map(\.key)
    }

    private static func dominantEquipment(from questionnaires: [QuestionnaireAnswers]) -> String {
        var counts: [String: Int] = [:]
        for q in questionnaires {
            counts[q.equipment.rawValue, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? "full_gym"
    }

    private static func topExercises(
        from workouts: [CompletedWorkoutRecord],
        limit: Int
    ) -> [String] {
        var counts: [String: Int] = [:]
        for w in workouts {
            for name in w.exerciseNames {
                counts[name, default: 0] += 1
            }
        }
        return Array(counts.sorted { $0.value > $1.value }.map(\.key).prefix(limit))
    }

    private static func avoidedExercises(
        edits: [WorkoutEdit],
        substitutions: [AcceptedSubstitution]
    ) -> [String] {
        var avoidCounts: [String: Int] = [:]

        // Exercises removed in edits
        for edit in edits where edit.editType == .removedExercise {
            avoidCounts[edit.exerciseName, default: 0] += 1
        }

        // Exercises swapped away from
        for edit in edits where edit.editType == .swappedExercise {
            avoidCounts[edit.exerciseName, default: 0] += 1
        }

        // Rejected substitutions (user wanted to keep doing the exercise)
        // — this is NOT an avoid signal; it means they like the original

        // Substitutions where the user accepted moving AWAY from an exercise
        for sub in substitutions where sub.accepted {
            avoidCounts[sub.originalExercise, default: 0] += 1
        }

        // Only flag exercises avoided 2+ times
        return avoidCounts.filter { $0.value >= 2 }.sorted { $0.value > $1.value }.map(\.key)
    }

    private static func averageWeeklyWorkouts(
        from workouts: [CompletedWorkoutRecord],
        weeks: Int
    ) -> Double {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .weekOfYear, value: -weeks, to: Date()) else {
            return 0
        }
        let recent = workouts.filter { $0.date >= cutoff }
        return Double(recent.count) / Double(weeks)
    }

    private static func buildEnergyDistribution(
        from questionnaires: [QuestionnaireAnswers]
    ) -> EnergyDistribution {
        var dist = EnergyDistribution()
        for q in questionnaires {
            switch q.energyLevel {
            case .low: dist.lowCount += 1
            case .medium: dist.mediumCount += 1
            case .high: dist.highCount += 1
            }
        }
        return dist
    }
}
