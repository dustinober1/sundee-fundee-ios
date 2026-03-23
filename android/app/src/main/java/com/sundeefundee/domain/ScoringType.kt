package com.sundeefundee.domain

/**
 * Types of workout scoring.
 */
enum class ScoringType(val displayName: String, val description: String) {
    TIME("Time", "Finish time (lower is better)"),
    ROUNDS_AND_REPS("Rounds + Reps", "Number of complete rounds plus partial reps"),
    REPS("Reps", "Total reps completed"),
    WEIGHT("Weight", "Maximum weight lifted"),
    DISTANCE("Distance", "Distance covered"),
    CALORIES("Calories", "Calories burned"),
    METERS("Meters", "Distance in meters (rowing, skiing, etc.)"),
    PR("Personal Record", "Personal best performance"),
    LOAD("Load", "Total weight moved (volume)"),
    HOLD("Hold", "Time held in position");

    companion object {
        /**
         * Parses a string value to ScoringType.
         */
        fun fromString(value: String): ScoringType {
            return entries.find {
                it.name.equals(value, ignoreCase = true) ||
                it.displayName.equals(value, ignoreCase = true)
            } ?: TIME
        }

        /**
         * Returns true if lower is better for this scoring type.
         */
        fun isLowerBetter(type: ScoringType): Boolean {
            return when (type) {
                TIME, REPS, ROUNDS_AND_REPS, CALORIES, METERS, LOAD -> false
                WEIGHT, DISTANCE, PR -> true
                HOLD -> false
            }
        }

        /**
         * Returns the unit for a scoring type.
         */
        fun getUnit(type: ScoringType): String {
            return when (type) {
                TIME -> "time"
                ROUNDS_AND_REPS -> "rounds+reps"
                REPS -> "reps"
                WEIGHT -> "lbs/kg"
                DISTANCE -> "miles/km"
                CALORIES -> "cal"
                METERS -> "m"
                PR -> "time/weight"
                LOAD -> "lbs/kg"
                HOLD -> "seconds"
            }
        }
    }
}
