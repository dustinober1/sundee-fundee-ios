import Foundation

// MARK: - WorkoutCalorieBurnEstimator

/// Pure domain service that calculates realistic active energy expenditure (kcal)
/// for completed strength training workouts to reliably credit Apple Fitness rings.
public struct WorkoutCalorieBurnEstimator: Sendable {
    /// Estimates total active kilocalories burned during a workout.
    ///
    /// - Parameters:
    ///   - durationSeconds: Total elapsed duration of the workout in seconds.
    ///   - completedSetsCount: Number of successfully completed sets.
    ///   - averageRPE: Subjective effort rating on 1-10 scale (optional).
    ///   - userWeightKg: User's body mass in kilograms (optional, defaults to 70kg).
    ///   - isSupersetOrCircuit: Whether the workout utilized supersets or conditioning circuits.
    /// - Returns: Total estimated active kilocalories burned.
    public static func estimateCalories(
        durationSeconds: TimeInterval,
        completedSetsCount: Int,
        averageRPE: Double? = nil,
        userWeightKg: Double? = nil,
        isSupersetOrCircuit: Bool = false
    ) -> Double {
        guard durationSeconds > 0 && completedSetsCount > 0 else {
            return 0.0
        }

        let weightKg = userWeightKg ?? 70.0
        let hours = durationSeconds / 3600.0

        // 1. Base Metabolic Equivalent of Task (MET) for strength training
        var met: Double
        if let rpe = averageRPE {
            switch rpe {
            case ..<6.0:
                met = 3.8 // Light strength / active recovery
            case 6.0..<7.5:
                met = 4.8 // Moderate strength training
            case 7.5..<8.5:
                met = 5.8 // Vigorous strength training
            default:
                met = 6.5 // Heavy / high intensity
            }
        } else {
            met = 5.0 // Standard default strength training MET
        }

        // 2. Superset / Circuit bonus (denser work, shorter rests, higher heart rate)
        if isSupersetOrCircuit {
            met += 0.8
        }

        // 3. Density check: adjust if user had long pauses between sets
        let setsPerHour = Double(completedSetsCount) / max(hours, 0.1)
        if setsPerHour < 8.0 {
            // Low density (e.g. powerlifting with 5+ min rests)
            met *= 0.85
        }

        // 4. Formula: kcal = MET * weightKg * hours
        let rawKcal = met * weightKg * hours
        return (rawKcal * 10.0).rounded() / 10.0
    }
}
