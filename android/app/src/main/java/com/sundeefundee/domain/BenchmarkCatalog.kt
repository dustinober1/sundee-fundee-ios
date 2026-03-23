package com.sundeefundee.domain

/**
 * Benchmark workout scoring types.
 */
enum class BenchmarkScoringType {
    TIME,
    REPS,
    WEIGHT,
    DISTANCE,
    ROUNDS_AND_REPS
}

/**
 * Information about a benchmark workout.
 */
data class BenchmarkInfo(
    val id: String,
    val name: String,
    val category: String,
    val description: String,
    val scoringType: BenchmarkScoringType
)

/**
 * Category group of benchmarks.
 */
data class BenchmarkCategoryGroup(
    val category: String,
    val entries: List<BenchmarkInfo>
)

/**
 * Hardcoded catalog of predefined benchmark workouts shipped with the app.
 *
 * Predefined entries have `userId = ""` and `isPredefined = true`.
 */
object BenchmarkCatalog {

    // MARK: - Category Constants

    const val CROSSFIT_WOD = "Classic WODs"
    const val STRENGTH = "Strength"
    const val ENDURANCE = "Endurance"
    const val GYMNASTICS = "Gymnastics"
    const val GENERAL_FITNESS = "General Fitness"

    // MARK: - Predefined Benchmarks

    private val predefined: List<BenchmarkInfo> by lazy {
        listOf(
            // Classic WODs — Time
            BenchmarkInfo(
                id = "predefined-fran",
                name = "Fran",
                category = CROSSFIT_WOD,
                description = "21-15-9 reps for time: Thrusters (95/65 lb), Pull-ups",
                scoringType = BenchmarkScoringType.TIME
            ),
            BenchmarkInfo(
                id = "predefined-helen",
                name = "Helen",
                category = CROSSFIT_WOD,
                description = "3 rounds for time: 400m Run, 21 KB Swings (53/35 lb), 12 Pull-ups",
                scoringType = BenchmarkScoringType.TIME
            ),
            BenchmarkInfo(
                id = "predefined-grace",
                name = "Grace",
                category = CROSSFIT_WOD,
                description = "For time: 30 Clean & Jerks (135/95 lb)",
                scoringType = BenchmarkScoringType.TIME
            ),
            BenchmarkInfo(
                id = "predefined-karen",
                name = "Karen",
                category = CROSSFIT_WOD,
                description = "For time: 150 Wall Ball Shots (20/14 lb to 10/9 ft target)",
                scoringType = BenchmarkScoringType.TIME
            ),
            BenchmarkInfo(
                id = "predefined-dt",
                name = "DT",
                category = CROSSFIT_WOD,
                description = "5 rounds for time: 12 Deadlifts, 9 Hang Power Cleans, 6 Push Jerks (155/105 lb)",
                scoringType = BenchmarkScoringType.TIME
            ),
            BenchmarkInfo(
                id = "predefined-murph",
                name = "Murph",
                category = CROSSFIT_WOD,
                description = "For time: 1-Mile Run, 100 Pull-ups, 200 Push-ups, 300 Air Squats, 1-Mile Run. Partition as needed. With 20/14 lb vest.",
                scoringType = BenchmarkScoringType.TIME
            ),
            BenchmarkInfo(
                id = "predefined-annie",
                name = "Annie",
                category = CROSSFIT_WOD,
                description = "50-40-30-20-10 reps for time: Double-Unders, Sit-ups",
                scoringType = BenchmarkScoringType.TIME
            ),

            // Classic WODs — Reps/Rounds
            BenchmarkInfo(
                id = "predefined-cindy",
                name = "Cindy",
                category = CROSSFIT_WOD,
                description = "AMRAP 20 min: 5 Pull-ups, 10 Push-ups, 15 Air Squats. Score = total rounds + partial reps.",
                scoringType = BenchmarkScoringType.ROUNDS_AND_REPS
            ),
            BenchmarkInfo(
                id = "predefined-fight-gone-bad",
                name = "Fight Gone Bad",
                category = CROSSFIT_WOD,
                description = "3 rounds, 1 min each station: Wall Ball (20/14 lb), SDHP (75/55 lb), Box Jump (20\"), Push Press (75/55 lb), Row (calories). 1 min rest between rounds. Score = total reps.",
                scoringType = BenchmarkScoringType.REPS
            ),

            // Strength — Weight (1RM)
            BenchmarkInfo(
                id = "predefined-1rm-back-squat",
                name = "1RM Back Squat",
                category = STRENGTH,
                description = "Find your 1-rep max back squat.",
                scoringType = BenchmarkScoringType.WEIGHT
            ),
            BenchmarkInfo(
                id = "predefined-1rm-conventional-deadlift",
                name = "1RM Conventional Deadlift (No Straps)",
                category = STRENGTH,
                description = "Find your 1-rep max conventional deadlift without straps.",
                scoringType = BenchmarkScoringType.WEIGHT
            ),
            BenchmarkInfo(
                id = "predefined-1rm-bench-press",
                name = "1RM Bench Press",
                category = STRENGTH,
                description = "Find your 1-rep max flat barbell bench press.",
                scoringType = BenchmarkScoringType.WEIGHT
            ),
            BenchmarkInfo(
                id = "predefined-1rm-overhead-press",
                name = "1RM Overhead Press",
                category = STRENGTH,
                description = "Find your 1-rep max strict barbell overhead press.",
                scoringType = BenchmarkScoringType.WEIGHT
            ),
            BenchmarkInfo(
                id = "predefined-1rm-clean-and-jerk",
                name = "1RM Clean and Jerk",
                category = STRENGTH,
                description = "Find your 1-rep max clean and jerk.",
                scoringType = BenchmarkScoringType.WEIGHT
            ),
            BenchmarkInfo(
                id = "predefined-1rm-snatch",
                name = "1RM Snatch",
                category = STRENGTH,
                description = "Find your 1-rep max snatch.",
                scoringType = BenchmarkScoringType.WEIGHT
            ),

            // Endurance — Time/Distance
            BenchmarkInfo(
                id = "predefined-1-mile-run",
                name = "1-Mile Run",
                category = ENDURANCE,
                description = "Run 1 mile (1.6 km) as fast as possible.",
                scoringType = BenchmarkScoringType.DISTANCE
            ),
            BenchmarkInfo(
                id = "predefined-5k-run",
                name = "5K Run",
                category = ENDURANCE,
                description = "Run 5 kilometers (3.1 miles) as fast as possible.",
                scoringType = BenchmarkScoringType.DISTANCE
            ),
            BenchmarkInfo(
                id = "predefined-1point5-mile-run",
                name = "1.5-Mile Run",
                category = ENDURANCE,
                description = "Run 1.5 miles (2.4 km) as fast as possible. Used to estimate VO2 Max (Cooper Test).",
                scoringType = BenchmarkScoringType.DISTANCE
            ),
            BenchmarkInfo(
                id = "predefined-2k-row",
                name = "2K Row",
                category = ENDURANCE,
                description = "Row 2000 meters on an ergometer as fast as possible.",
                scoringType = BenchmarkScoringType.DISTANCE
            ),

            // Gymnastics — Reps
            BenchmarkInfo(
                id = "predefined-max-pull-ups",
                name = "Max Pull-ups",
                category = GYMNASTICS,
                description = "Maximum strict pull-ups in one unbroken set.",
                scoringType = BenchmarkScoringType.REPS
            ),
            BenchmarkInfo(
                id = "predefined-max-push-ups",
                name = "Max Push-ups (2 min)",
                category = GYMNASTICS,
                description = "Maximum push-ups completed in 2 minutes.",
                scoringType = BenchmarkScoringType.REPS
            ),
            BenchmarkInfo(
                id = "predefined-max-hspu",
                name = "Max Handstand Push-ups",
                category = GYMNASTICS,
                description = "Maximum strict handstand push-ups in one unbroken set.",
                scoringType = BenchmarkScoringType.REPS
            ),
            BenchmarkInfo(
                id = "predefined-max-muscle-ups",
                name = "Max Muscle-ups",
                category = GYMNASTICS,
                description = "Maximum ring or bar muscle-ups in one unbroken set.",
                scoringType = BenchmarkScoringType.REPS
            ),

            // General Fitness
            BenchmarkInfo(
                id = "predefined-100-push-ups",
                name = "100 Push-ups for Time",
                category = GENERAL_FITNESS,
                description = "Complete 100 push-ups as fast as possible. Rest as needed.",
                scoringType = BenchmarkScoringType.TIME
            ),
            BenchmarkInfo(
                id = "predefined-100-sit-ups",
                name = "100 Sit-ups for Time",
                category = GENERAL_FITNESS,
                description = "Complete 100 sit-ups as fast as possible. Rest as needed.",
                scoringType = BenchmarkScoringType.TIME
            ),
            BenchmarkInfo(
                id = "predefined-l-sit-hold",
                name = "L-Sit Hold",
                category = GENERAL_FITNESS,
                description = "Hold an L-sit (legs straight, parallel to ground) as long as possible. Supported on floor, parallettes, or rings.",
                scoringType = BenchmarkScoringType.TIME
            )
        )
    }

    // MARK: - Category Order

    val categoryOrder: List<String> = listOf(
        CROSSFIT_WOD, STRENGTH, ENDURANCE, GYMNASTICS, GENERAL_FITNESS
    )

    // MARK: - Public API

    /**
     * Returns all predefined benchmarks.
     */
    fun getAllBenchmarks(): List<BenchmarkInfo> = predefined

    /**
     * Returns a benchmark by its ID.
     */
    fun getBenchmarkById(id: String): BenchmarkInfo? {
        return predefined.find { it.id == id }
    }

    /**
     * Returns benchmarks grouped by category in display order.
     */
    fun getGroupedByCategory(): List<BenchmarkCategoryGroup> {
        return categoryOrder.mapNotNull { cat ->
            val entries = predefined.filter { it.category == cat }
            if (entries.isEmpty()) null
            else BenchmarkCategoryGroup(category = cat, entries = entries)
        }
    }

    /**
     * Returns benchmarks in a specific category.
     */
    fun getByCategory(category: String): List<BenchmarkInfo> {
        return predefined.filter { it.category == category }
    }

    /**
     * Searches benchmarks by name (case-insensitive).
     */
    fun searchByName(query: String): List<BenchmarkInfo> {
        val lowerQuery = query.lowercase()
        return predefined.filter { it.name.lowercase().contains(lowerQuery) }
    }

    // MARK: - Rounds and Reps Encoding

    /**
     * Encodes rounds and reps into a single comparable value for scoring.
     * Formula: rounds * 10000 + reps (assuming reps < 10000)
     */
    fun encodeRoundsAndReps(rounds: Int, reps: Int): Double {
        return rounds * 10000.0 + reps
    }

    /**
     * Decodes a rounds and reps value back into a pair.
     */
    fun decodeRoundsAndReps(value: Double): Pair<Int, Int> {
        val rounds = (value / 10000).toInt()
        val reps = (value % 10000).toInt()
        return Pair(rounds, reps)
    }

    /**
     * Formats rounds and reps as a display string.
     */
    fun formatRoundsAndReps(rounds: Int, reps: Int): String {
        return if (reps == 0) {
            "$rounds rounds"
        } else {
            "$rounds + $reps"
        }
    }
}
