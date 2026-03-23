package com.sundeefundee.domain

/**
 * Types of workouts (WOD formats).
 */
enum class WodType(val displayName: String, val description: String) {
    FOR_TIME("For Time", "Complete the workout as fast as possible"),
    AMRAP("AMRAP", "As Many Rounds As Possible in the given time"),
    EMOM("EMOM", "Every Minute On the Minute - complete work within each minute"),
    E90MOM("E90MOM", "Every 90 Seconds On the Minute"),
    E2MOM("E2MOM", "Every 2 Minutes On the Minute"),
    TABATA("Tabata", "20 seconds work, 10 seconds rest, 8 rounds"),
    Cindy("Cindy", "5 Pull-ups, 10 Push-ups, 15 Air Squats - AMRAP 20 min"),
    GRACE("Grace", "30 Clean & Jerks for time"),
    HELEN("Helen", "3 rounds: 400m Run, 21 KB Swings, 12 Pull-ups"),
    FRAN("Fran", "21-15-9 Thrusters and Pull-ups for time"),
    KAREN("Karen", "150 Wall Ball Shots for time"),
    DT("DT", "5 rounds: 12 Deadlifts, 9 Hang Power Cleans, 6 Push Jerks"),
    MURPH("Murph", "1 Mile Run, 100 Pull-ups, 200 Push-ups, 300 Squats, 1 Mile Run"),
    FGB("Fight Gone Bad", "3 rounds, 1 min each station, max reps"),
    HEAVY_DAY("Heavy Day", "Strength focused workout with heavy weights"),
    ENDURANCE("Endurance", "Long duration cardio-focused workout"),
    GIRLS("Girls", "Named benchmark WODs (Fran, Grace, Helen, etc.)"),
    CUSTOM("Custom", "User-defined workout format");

    companion object {
        /**
         * Parses a string value to WodType.
         */
        fun fromString(value: String): WodType {
            return entries.find {
                it.name.equals(value, ignoreCase = true) ||
                it.displayName.equals(value, ignoreCase = true)
            } ?: CUSTOM
        }

        /**
         * Returns all WOD types that are benchmark workouts.
         */
        fun benchmarkWodTypes(): List<WodType> {
            return listOf(CINDY, GRACE, HELEN, FRAN, KAREN, DT, MURPH, FGB)
        }
    }
}
