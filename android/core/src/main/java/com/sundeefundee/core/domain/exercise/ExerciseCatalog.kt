package com.sundeefundee.core.domain.exercise

// MARK: - Weightlifting Category

enum class WeightliftingCategory {
    SQUAT,
    HIP_HINGE,
    PRESS,
    PULL,
    CARRY,
    OLYMPIC_WEIGHTLIFTING,
}

data class WeightliftingEntry(
    val id: String,
    val category: WeightliftingCategory,
)

object WeightliftingCatalog {
    val all: List<WeightliftingEntry> = listOf(
        // Squat
        WeightliftingEntry("Back Squat", WeightliftingCategory.SQUAT),
        WeightliftingEntry("Front Squat", WeightliftingCategory.SQUAT),
        WeightliftingEntry("Safety Bar Squat", WeightliftingCategory.SQUAT),
        WeightliftingEntry("Box Squat", WeightliftingCategory.SQUAT),
        WeightliftingEntry("Pause Squat", WeightliftingCategory.SQUAT),
        WeightliftingEntry("Goblet Squat", WeightliftingCategory.SQUAT),
        WeightliftingEntry("Leg Press", WeightliftingCategory.SQUAT),
        WeightliftingEntry("Hack Squat", WeightliftingCategory.SQUAT),
        WeightliftingEntry("Leg Extension", WeightliftingCategory.SQUAT),
        // Hip Hinge
        WeightliftingEntry("Conventional Deadlift (No Straps)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Conventional Deadlift (With Straps)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Romanian Deadlift (No Straps)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Romanian Deadlift (With Straps)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Sumo Deadlift (No Straps)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Sumo Deadlift (With Straps)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Trap Bar Deadlift (No Straps)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Trap Bar Deadlift (With Straps)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Good Morning", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Hip Thrust", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Leg Curl (Lying)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Leg Curl (Seated)", WeightliftingCategory.HIP_HINGE),
        WeightliftingEntry("Glute Ham Raise", WeightliftingCategory.HIP_HINGE),
        // Press
        WeightliftingEntry("Flat Barbell Bench Press", WeightliftingCategory.PRESS),
        WeightliftingEntry("Incline Barbell Bench Press", WeightliftingCategory.PRESS),
        WeightliftingEntry("Decline Barbell Bench Press", WeightliftingCategory.PRESS),
        WeightliftingEntry("Strict Press", WeightliftingCategory.PRESS),
        WeightliftingEntry("Push Press", WeightliftingCategory.PRESS),
        WeightliftingEntry("Dumbbell Bench Press", WeightliftingCategory.PRESS),
        WeightliftingEntry("Dumbbell Incline Press", WeightliftingCategory.PRESS),
        WeightliftingEntry("Dumbbell Overhead Press", WeightliftingCategory.PRESS),
        WeightliftingEntry("Dips (Weighted)", WeightliftingCategory.PRESS),
        WeightliftingEntry("Close Grip Bench Press", WeightliftingCategory.PRESS),
        // Pull
        WeightliftingEntry("Barbell Row", WeightliftingCategory.PULL),
        WeightliftingEntry("Pendlay Row", WeightliftingCategory.PULL),
        WeightliftingEntry("Pull-Up", WeightliftingCategory.PULL),
        WeightliftingEntry("Weighted Pull-Up", WeightliftingCategory.PULL),
        WeightliftingEntry("Lat Pulldown", WeightliftingCategory.PULL),
        WeightliftingEntry("Cable Row", WeightliftingCategory.PULL),
        WeightliftingEntry("Dumbbell Row", WeightliftingCategory.PULL),
        WeightliftingEntry("Face Pull", WeightliftingCategory.PULL),
        WeightliftingEntry("Bicep Curl (Barbell)", WeightliftingCategory.PULL),
        WeightliftingEntry("Bicep Curl (Dumbbell)", WeightliftingCategory.PULL),
        WeightliftingEntry("Hammer Curl", WeightliftingCategory.PULL),
        WeightliftingEntry("Upright Row", WeightliftingCategory.PULL),
        // Carry
        WeightliftingEntry("Farmers Carry", WeightliftingCategory.CARRY),
        WeightliftingEntry("Suitcase Carry", WeightliftingCategory.CARRY),
        WeightliftingEntry("Zercher Carry", WeightliftingCategory.CARRY),
        WeightliftingEntry("Yoke Walk", WeightliftingCategory.CARRY),
        // Olympic Weightlifting
        WeightliftingEntry("Squat Snatch", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Squat Clean", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Power Clean", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Power Snatch", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Hang Clean", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Hang Snatch", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Split Jerk", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Push Jerk", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Clean and Jerk", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Muscle Snatch", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
        WeightliftingEntry("Muscle Clean", WeightliftingCategory.OLYMPIC_WEIGHTLIFTING),
    )

    private val idSet: Set<String> = all.map { it.id }.toSet()

    fun contains(id: String): Boolean = idSet.contains(id)
}

// MARK: - Conditioning Category

enum class ConditioningScoringType {
    TIME,
    REPS,
}

data class ConditioningEntry(
    val id: String,
    val defaultScoringType: ConditioningScoringType,
)

object ConditioningCatalog {
    val all: List<ConditioningEntry> = listOf(
        // Reps-based
        ConditioningEntry("Wall Ball", ConditioningScoringType.REPS),
        ConditioningEntry("Box Jump", ConditioningScoringType.REPS),
        ConditioningEntry("Burpee", ConditioningScoringType.REPS),
        ConditioningEntry("Kettlebell Swing", ConditioningScoringType.REPS),
        ConditioningEntry("Double Under", ConditioningScoringType.REPS),
        ConditioningEntry("Pull-Up (Kipping)", ConditioningScoringType.REPS),
        ConditioningEntry("Toes-to-Bar", ConditioningScoringType.REPS),
        ConditioningEntry("Muscle-Up", ConditioningScoringType.REPS),
        ConditioningEntry("Push-Up", ConditioningScoringType.REPS),
        ConditioningEntry("Sit-Up", ConditioningScoringType.REPS),
        ConditioningEntry("Air Squat", ConditioningScoringType.REPS),
        ConditioningEntry("Thruster", ConditioningScoringType.REPS),
        ConditioningEntry("Rowing (Calories)", ConditioningScoringType.REPS),
        ConditioningEntry("Assault Bike (Calories)", ConditioningScoringType.REPS),
        ConditioningEntry("SkiErg (Calories)", ConditioningScoringType.REPS),
        ConditioningEntry("Box Step-up", ConditioningScoringType.REPS),
        ConditioningEntry("Lunges (Alternating)", ConditioningScoringType.REPS),
        ConditioningEntry("Wall Walk", ConditioningScoringType.REPS),
        ConditioningEntry("Handstand Push-up", ConditioningScoringType.REPS),
        ConditioningEntry("GHD Sit-up", ConditioningScoringType.REPS),
        ConditioningEntry("V-up", ConditioningScoringType.REPS),
        // Time-based
        ConditioningEntry("400m Run", ConditioningScoringType.TIME),
        ConditioningEntry("800m Run", ConditioningScoringType.TIME),
        ConditioningEntry("1-Mile Run", ConditioningScoringType.TIME),
        ConditioningEntry("5K Run", ConditioningScoringType.TIME),
        ConditioningEntry("500m Row", ConditioningScoringType.TIME),
        ConditioningEntry("2K Row", ConditioningScoringType.TIME),
        ConditioningEntry("1K Assault Bike", ConditioningScoringType.TIME),
        ConditioningEntry("2K SkiErg", ConditioningScoringType.TIME),
        ConditioningEntry("Plank Hold", ConditioningScoringType.TIME),
        ConditioningEntry("L-Sit Hold", ConditioningScoringType.TIME),
    )
}

// MARK: - Helpers

fun isWeightliftingExercise(id: String): Boolean = WeightliftingCatalog.contains(id)
