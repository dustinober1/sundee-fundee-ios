package com.sundeefundee.core.domain.coach

import com.sundeefundee.core.domain.intelligence.PlateauDetector
import com.sundeefundee.core.domain.intelligence.PlateauDetector.PlateauAlert
import com.sundeefundee.core.domain.intelligence.PlateauDetector.RateOfProgressAlert
import com.sundeefundee.core.domain.intelligence.ScheduleReshuffler
import com.sundeefundee.core.domain.intelligence.ScheduleReshuffler.PlannedSession
import com.sundeefundee.core.domain.intelligence.ScheduleReshuffler.ReshuffleResult
import com.sundeefundee.core.domain.intelligence.SubstitutionRanker
import com.sundeefundee.core.domain.intelligence.SubstitutionRanker.EquipmentContext
import com.sundeefundee.core.domain.intelligence.SubstitutionRanker.RankedSubstitution
import com.sundeefundee.core.domain.intelligence.WeeklyLoadAnalyzer
import com.sundeefundee.core.domain.intelligence.WeeklyLoadAnalyzer.LoadTrend
import com.sundeefundee.core.domain.intelligence.WeeklyLoadAnalyzer.WeeklySummary
import com.sundeefundee.core.domain.injury.Injury
import com.sundeefundee.core.domain.injury.InjuryAdaptationEngine
import com.sundeefundee.core.model.CyclePhase
import com.sundeefundee.core.model.CompletedWorkoutRecord
import java.time.Instant
import java.util.UUID
import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

// MARK: - Enums & Shared Types

/** Workout focus areas for training session generation. */
enum class WorkoutFocus(val rawValue: String) {
    UPPER_BODY("upper_body"),
    LOWER_BODY("lower_body"),
    FULL_BODY("full_body"),
    PUSH("push"),
    PULL("pull"),
    CORE("core"),
    CONDITIONING("conditioning");

    val displayName: String
        get() = rawValue.replace("_", " ")
}

/** User-reported energy level for workout generation. */
enum class EnergyLevel {
    LOW,
    MEDIUM,
    HIGH
}

/** Available equipment access level. */
enum class EquipmentAccess {
    FULL_GYM,
    HOME_DUMBBELLS,
    BODYWEIGHT_ONLY,
    OUTDOOR
}

/** Subscription tier for feature gating. */
enum class SubscriptionTier {
    FREE,
    PLUS,
    PREMIUM
}

// MARK: - Generated Exercise & Workout

/** A single exercise within a generated workout. */
data class GeneratedExercise(
    val id: String,
    val name: String,
    val sets: Int,
    val reps: String,
    val weightKg: Double? = null,
    val restMinutes: Double? = null,
    val notes: String? = null,
    val reasoning: String? = null,
    val bodyweightOnly: Boolean = false,
    val percentageOfMax: Double? = null
)

/** A complete generated workout from the coach. */
data class GeneratedWorkout(
    val id: String,
    val createdAt: Instant,
    val isFavorite: Boolean,
    val coachingSummary: String,
    val exercises: List<GeneratedExercise>,
    val questionnaire: QuestionnaireAnswers
)

/** User's questionnaire answers for workout generation. */
data class QuestionnaireAnswers(
    val timeMinutes: Int,
    val focus: WorkoutFocus,
    val energyLevel: EnergyLevel,
    val equipment: EquipmentAccess
)

/** A recorded 1RM for an exercise. */
data class ExerciseMax(
    val name: String,
    val weightKg: Double
)

// MARK: - CoachContext

/**
 * Compact context assembled from multiple data sources for the coach.
 *
 * Instead of passing raw full history, this holds rolling summaries
 * that fit within model context windows. Each field is optional
 * because not all data may be available for every user.
 */
data class CoachContext(
    // User Profile
    val cyclePhase: CyclePhase? = null,
    val cycleConfidence: Double? = null,
    val experienceLevel: String? = null,
    val primaryGoal: String? = null,
    val tier: SubscriptionTier = SubscriptionTier.FREE,

    // Training State
    val maxes: List<ExerciseMax> = emptyList(),
    val injuries: List<Injury> = emptyList(),
    val workoutsThisWeek: Int = 0,
    val weeklySummaries: List<WeeklySummary> = emptyList(),
    val trends: List<LoadTrend> = emptyList(),
    val plateaus: List<PlateauAlert> = emptyList(),
    val volumePlateaus: List<PlateauAlert> = emptyList(),
    val progressWarnings: List<RateOfProgressAlert> = emptyList(),

    // Equipment
    val equipment: EquipmentAccess = EquipmentAccess.FULL_GYM
)

// MARK: - Coach Service Protocol

/**
 * Defines the capabilities of the training coach.
 *
 * Implementations may use deterministic domain logic (fallback),
 * on-device AI, or cloud AI. The protocol is designed so that
 * deterministic services produce the decisions and AI services
 * explain/package them.
 */
interface CoachService {

    /** Generates a personalized workout based on context and preferences. */
    suspend fun generateWorkout(
        context: CoachContext,
        preferences: QuestionnaireAnswers
    ): CoachWorkoutResponse

    /** Returns training insights: plateaus, load trends, and recommendations. */
    suspend fun getInsights(context: CoachContext): CoachInsightsResponse

    /** Suggests substitute exercises for a given exercise. */
    suspend fun suggestSubstitutions(
        exercise: String,
        context: CoachContext
    ): CoachSubstitutionResponse

    /** Adapts the weekly plan based on missed/completed sessions. */
    suspend fun adaptWeeklyPlan(
        plan: List<PlannedSession>,
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int,
        context: CoachContext
    ): CoachPlanResponse
}

// MARK: - Response Types

/** Response from workout generation. */
data class CoachWorkoutResponse(
    val workout: GeneratedWorkout,
    val coachingSummary: String,
    val tips: List<String> = emptyList()
)

/** Response from training insights analysis. */
data class CoachInsightsResponse(
    val plateaus: List<PlateauAlert>,
    val trends: List<LoadTrend>,
    val summary: String,
    val priorityActions: List<String>
)

/** Response from exercise substitution suggestions. */
data class CoachSubstitutionResponse(
    val originalExercise: String,
    val substitutions: List<RankedSubstitution>,
    val explanation: String
)

/** Response from weekly plan adaptation. */
data class CoachPlanResponse(
    val result: ReshuffleResult,
    val explanation: String,
    val volumeWarning: String? = null
)

// MARK: - Coach Memory Models

/**
 * Persistent coaching profile that summarizes what the coach "knows"
 * about the user's training preferences and patterns.
 *
 * Updated incrementally after each workout and weekly recap.
 */
data class CoachProfile(
    var preferredSessionMinutes: Int = 45,
    var preferredFocusAreas: List<String> = emptyList(),
    var preferredEquipment: String = "full_gym",
    var favoriteExercises: List<String> = emptyList(),
    var avoidedExercises: List<String> = emptyList(),
    var avgWorkoutsPerWeek: Double = 0.0,
    var energyDistribution: EnergyDistribution = EnergyDistribution(),
    var totalWorkoutsObserved: Int = 0,
    var lastUpdated: Instant = Instant.now()
)

/** Tracks how often the user reports each energy level. */
data class EnergyDistribution(
    var lowCount: Int = 0,
    var mediumCount: Int = 0,
    var highCount: Int = 0
) {
    /** The most common energy level. */
    val dominant: EnergyLevel
        get() = when {
            highCount >= mediumCount && highCount >= lowCount -> EnergyLevel.HIGH
            lowCount >= mediumCount -> EnergyLevel.LOW
            else -> EnergyLevel.MEDIUM
        }

    val total: Int
        get() = lowCount + mediumCount + highCount
}

/** Records a substitution decision (accepted or rejected) for learning. */
data class AcceptedSubstitution(
    val originalExercise: String,
    val substituteExercise: String,
    val accepted: Boolean,
    val reason: String,
    val date: Instant = Instant.now()
)

/** A rolling weekly summary generated by the coach memory system. */
data class CoachWeeklySummary(
    val weekStartDate: java.time.LocalDate,
    val workoutsCompleted: Int,
    val totalMinutes: Int,
    val muscleGroupsHit: List<String>,
    val observations: List<String>,
    val recommendations: List<String>,
    val generatedAt: Instant = Instant.now()
)

/** Records an edit the user made to a generated workout. */
data class WorkoutEdit(
    val editType: EditType,
    val exerciseName: String,
    val replacementExercise: String? = null,
    val date: Instant = Instant.now()
) {
    enum class EditType {
        REMOVED_EXERCISE,
        SWAPPED_EXERCISE,
        CHANGED_WEIGHT,
        CHANGED_VOLUME
    }
}

// MARK: - Deterministic Coach Service

/**
 * Coach service that uses pure domain logic from Phase 2 services.
 *
 * This is the fallback for devices without on-device AI capabilities.
 * It provides the same structured responses but generates summaries
 * and explanations using template-based text rather than AI.
 *
 * The key principle: deterministic services make the decisions,
 * this service packages and explains them.
 */
class DeterministicCoachService(
    var coachProfile: CoachProfile? = null
) : CoachService {

    // MARK: - Generate Workout

    override suspend fun generateWorkout(
        context: CoachContext,
        preferences: QuestionnaireAnswers
    ): CoachWorkoutResponse {
        // Use existing domain logic to build exercises
        var exercises = buildExercisePlan(preferences = preferences, context = context)

        // Apply weights from maxes
        val energyMult = energyMultiplier(preferences.energyLevel)
        val cycleMult = aiCyclePhaseMultiplier(context.cyclePhase)
        var weighted = applyWeights(
            exercises = exercises,
            maxes = context.maxes,
            energyMult = energyMult,
            cycleMult = cycleMult
        )

        // Assign rest times
        val final = weighted.map { ex ->
            if (ex.restMinutes != null) ex
            else ex.copy(restMinutes = assignRestMinutes(ex.bodyweightOnly, ex.reps))
        }

        val summary = buildCoachingSummary(preferences = preferences, context = context)
        val tips = buildTips(context)

        val workout = GeneratedWorkout(
            id = UUID.randomUUID().toString(),
            createdAt = Instant.now(),
            isFavorite = false,
            coachingSummary = summary,
            exercises = final,
            questionnaire = preferences
        )

        return CoachWorkoutResponse(
            workout = workout,
            coachingSummary = summary,
            tips = tips
        )
    }

    // MARK: - Get Insights

    override suspend fun getInsights(context: CoachContext): CoachInsightsResponse {
        val plateaus = context.plateaus
        val trends = context.trends

        val actions = mutableListOf<String>()
        val summaryParts = mutableListOf<String>()

        // Strength plateaus
        if (plateaus.isNotEmpty()) {
            val names = plateaus.take(3).joinToString(", ") { it.exerciseName }
            summaryParts.add("${plateaus.size} lift(s) have stalled: $names.")
            for (p in plateaus.take(2)) {
                actions.add(p.recommendation)
            }
        }

        // Volume plateaus
        if (context.volumePlateaus.isNotEmpty()) {
            val volNames = context.volumePlateaus.take(2).joinToString(", ") { it.exerciseName }
            summaryParts.add("Volume has plateaued on $volNames.")
            for (p in context.volumePlateaus.take(1)) {
                actions.add(p.recommendation)
            }
        }

        // Progress slowdown warnings
        for (warning in context.progressWarnings.take(2)) {
            summaryParts.add(warning.message)
            actions.add(warning.message)
        }

        // Trends
        for (trend in trends) {
            summaryParts.add(trend.message)
            if (trend.severity == WeeklyLoadAnalyzer.TrendSeverity.WARNING) {
                actions.add(trend.message)
            }
        }

        if (summaryParts.isEmpty()) {
            summaryParts.add("Looking good -- keep up your current training rhythm.")
        }

        return CoachInsightsResponse(
            plateaus = plateaus,
            trends = trends,
            summary = summaryParts.joinToString(" "),
            priorityActions = actions
        )
    }

    // MARK: - Suggest Substitutions

    override suspend fun suggestSubstitutions(
        exercise: String,
        context: CoachContext
    ): CoachSubstitutionResponse {
        val equipmentContext: EquipmentContext = when (context.equipment) {
            EquipmentAccess.FULL_GYM -> EquipmentContext.FULL_GYM
            EquipmentAccess.HOME_DUMBBELLS -> EquipmentContext.HOME_DUMBBELLS
            EquipmentAccess.BODYWEIGHT_ONLY -> EquipmentContext.BODYWEIGHT_ONLY
            EquipmentAccess.OUTDOOR -> EquipmentContext.BODYWEIGHT_ONLY
        }

        val profile = coachProfile?.let { profile ->
            SubstitutionRanker.UserProfile(
                favoriteExercises = profile.favoriteExercises.toSet(),
                avoidedExercises = profile.avoidedExercises.toSet()
            )
        }

        val subs = SubstitutionRanker.rank(
            substitutesFor = exercise,
            injuries = context.injuries,
            equipment = equipmentContext,
            profile = profile
        )

        var explanation: String = if (context.injuries.isEmpty()) {
            "These alternatives target the same muscle groups as $exercise."
        } else {
            "These alternatives avoid movements that may aggravate your current injuries while targeting similar muscle groups."
        }

        if (context.equipment != EquipmentAccess.FULL_GYM) {
            explanation += " Filtered for your available equipment."
        }

        return CoachSubstitutionResponse(
            originalExercise = exercise,
            substitutions = subs,
            explanation = explanation
        )
    }

    // MARK: - Adapt Weekly Plan

    override suspend fun adaptWeeklyPlan(
        plan: List<PlannedSession>,
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int,
        context: CoachContext
    ): CoachPlanResponse {
        val result = ScheduleReshuffler.reshuffle(
            plan = plan,
            completedDays = completedDays,
            missedDays = missedDays,
            currentDay = currentDay
        )

        var explanation = result.summary
        var volumeWarning: String? = null

        // Check if the reshuffle packed too much into remaining days
        if (result.droppedSessions.isNotEmpty()) {
            explanation += " Consider adding these to next week's plan."
        }

        // Check for overreaching risk
        val warningTrends = context.trends.filter {
            it.type == WeeklyLoadAnalyzer.TrendType.OVERREACHING
        }
        if (warningTrends.isNotEmpty()) {
            volumeWarning = "You've been training at high volume recently. Consider dropping the extra session and focusing on recovery."
        }

        return CoachPlanResponse(
            result = result,
            explanation = explanation,
            volumeWarning = volumeWarning
        )
    }

    // MARK: - Private: Exercise Pool

    private data class PoolEntry(val name: String, val bodyweight: Boolean)

    private fun exercisePool(focus: WorkoutFocus): List<PoolEntry> {
        return when (focus) {
            WorkoutFocus.UPPER_BODY, WorkoutFocus.PUSH -> listOf(
                PoolEntry("Flat Barbell Bench Press", false),
                PoolEntry("Strict Press", false),
                PoolEntry("Dumbbell Incline Press", false),
                PoolEntry("Dips (Weighted)", false),
                PoolEntry("Close Grip Bench Press", false),
                PoolEntry("Face Pull", false),
                PoolEntry("Push-Up", true)
            )
            WorkoutFocus.PULL -> listOf(
                PoolEntry("Barbell Row", false),
                PoolEntry("Pull-Up", true),
                PoolEntry("Lat Pulldown", false),
                PoolEntry("Cable Row", false),
                PoolEntry("Dumbbell Row", false),
                PoolEntry("Bicep Curl (Barbell)", false),
                PoolEntry("Face Pull", false)
            )
            WorkoutFocus.LOWER_BODY -> listOf(
                PoolEntry("Back Squat", false),
                PoolEntry("Romanian Deadlift (No Straps)", false),
                PoolEntry("Leg Press", false),
                PoolEntry("Hip Thrust", false),
                PoolEntry("Leg Curl (Lying)", false),
                PoolEntry("Leg Extension", false),
                PoolEntry("Goblet Squat", false)
            )
            WorkoutFocus.FULL_BODY -> listOf(
                PoolEntry("Back Squat", false),
                PoolEntry("Flat Barbell Bench Press", false),
                PoolEntry("Barbell Row", false),
                PoolEntry("Strict Press", false),
                PoolEntry("Romanian Deadlift (No Straps)", false),
                PoolEntry("Pull-Up", true)
            )
            WorkoutFocus.CORE -> listOf(
                PoolEntry("Plank Hold", true),
                PoolEntry("V-up", true),
                PoolEntry("GHD Sit-up", true),
                PoolEntry("Toes-to-Bar", true),
                PoolEntry("Sit-Up", true),
                PoolEntry("L-Sit Hold", true)
            )
            WorkoutFocus.CONDITIONING -> listOf(
                PoolEntry("Burpee", true),
                PoolEntry("Kettlebell Swing", false),
                PoolEntry("Wall Ball", false),
                PoolEntry("Box Jump", true),
                PoolEntry("Thruster", false),
                PoolEntry("Air Squat", true),
                PoolEntry("Push-Up", true)
            )
        }
    }

    // MARK: - Private: Build Exercise Plan

    private fun buildExercisePlan(
        preferences: QuestionnaireAnswers,
        context: CoachContext
    ): List<GeneratedExercise> {
        val targetCount = max(3, preferences.timeMinutes / 10)
        var pool = exercisePool(preferences.focus)

        // Filter by equipment
        if (preferences.equipment == EquipmentAccess.BODYWEIGHT_ONLY) {
            pool = pool.filter { it.bodyweight }
            if (pool.isEmpty()) {
                pool = listOf(
                    PoolEntry("Push-Up", true),
                    PoolEntry("Air Squat", true),
                    PoolEntry("Burpee", true),
                    PoolEntry("Plank Hold", true)
                )
            }
        }

        // Filter by injuries
        if (context.injuries.isNotEmpty()) {
            pool = pool.filter { entry ->
                !InjuryAdaptationEngine.isContraindicated(
                    exerciseName = entry.name,
                    exerciseCategory = null,
                    injuries = context.injuries
                )
            }
        }

        val selected = pool.shuffled(Random).take(targetCount)
        val setsPerExercise = if (preferences.energyLevel == EnergyLevel.LOW) 3 else 4
        val reps = if (preferences.focus == WorkoutFocus.CONDITIONING) "12-15" else "6-8"

        return selected.mapIndexed { index, entry ->
            GeneratedExercise(
                id = UUID.randomUUID().toString(),
                name = entry.name,
                sets = setsPerExercise,
                reps = reps,
                reasoning = if (index == 0)
                    "Primary movement for ${preferences.focus.displayName}"
                else null,
                bodyweightOnly = entry.bodyweight
            )
        }
    }

    // MARK: - Private: Coaching Summary & Tips

    private fun buildCoachingSummary(
        preferences: QuestionnaireAnswers,
        context: CoachContext
    ): String {
        val parts = mutableListOf<String>()
        val focusName = preferences.focus.displayName
        parts.add("${preferences.timeMinutes}-minute $focusName session")

        context.cyclePhase?.let { phase ->
            val mult = aiCyclePhaseMultiplier(phase)
            when {
                mult < 1.0 -> parts.add("loads scaled to ${((mult * 100).toInt())}% for ${phase.displayName} phase")
                mult > 1.0 -> parts.add("peak phase -- push intensity to ${((mult * 100).toInt())}%")
            }
        }

        val eMult = energyMultiplier(preferences.energyLevel)
        when {
            eMult < 1.0 -> parts.add("adjusted for lower energy today")
            eMult > 1.0 -> parts.add("high energy -- weights bumped up")
        }

        if (context.injuries.isNotEmpty()) {
            parts.add("exercises filtered around ${context.injuries.size} active injury(s)")
        }

        return parts.joinToString(". ") + "."
    }

    private fun buildTips(context: CoachContext): List<String> {
        val tips = mutableListOf<String>()

        context.cyclePhase?.let { phase ->
            when (phase) {
                CyclePhase.MENSTRUAL ->
                    tips.add("Focus on movement quality over weight today. Listen to your body.")
                CyclePhase.FOLLICULAR ->
                    tips.add("Rising energy -- great time to push for progress on key lifts.")
                CyclePhase.OVULATION ->
                    tips.add("Peak strength window. Try for a PR if you're feeling it.")
                CyclePhase.LUTEAL ->
                    tips.add("You may feel warmer and more fatigued. Slightly longer rest periods can help.")
            }
        }

        if (context.plateaus.isNotEmpty()) {
            tips.add("Consider varying your rep scheme on stalled lifts this week.")
        }

        if (context.workoutsThisWeek >= 5) {
            tips.add("You've trained ${context.workoutsThisWeek} times this week. Recovery is productive too.")
        }

        return tips
    }
}

// MARK: - Preference Learner

/**
 * Analyzes workout history, substitution decisions, and edits to learn
 * the user's training preferences over time.
 *
 * Pure domain logic -- no framework dependencies.
 * Call [learn] with historical data to produce an updated [CoachProfile].
 */
object PreferenceLearner {

    /**
     * Analyzes all available data and produces an updated CoachProfile.
     *
     * @param existingProfile The current profile (or a fresh default).
     * @param workouts Completed workouts (recent history).
     * @param edits Recorded workout edits.
     * @param substitutions Substitution accept/reject decisions.
     * @param questionnaires Past questionnaire answers.
     * @return An updated CoachProfile reflecting learned preferences.
     */
    fun learn(
        existingProfile: CoachProfile,
        workouts: List<CompletedWorkoutRecord>,
        edits: List<WorkoutEdit> = emptyList(),
        substitutions: List<AcceptedSubstitution> = emptyList(),
        questionnaires: List<QuestionnaireAnswers> = emptyList()
    ): CoachProfile {
        val profile = existingProfile.copy()

        // Session duration preference
        if (questionnaires.isNotEmpty()) {
            val avgMinutes = questionnaires.sumOf { it.timeMinutes } / questionnaires.size
            profile.preferredSessionMinutes = avgMinutes
        }

        // Focus area preferences
        if (questionnaires.isNotEmpty()) {
            profile.preferredFocusAreas = topFocusAreas(questionnaires)
        }

        // Equipment preference
        if (questionnaires.isNotEmpty()) {
            profile.preferredEquipment = dominantEquipment(questionnaires)
        }

        // Favorite exercises (most frequently appeared in workouts)
        profile.favoriteExercises = topExercises(workouts, limit = 10)

        // Avoided exercises (removed in edits or rejected in substitutions)
        profile.avoidedExercises = avoidedExercises(edits, substitutions)

        // Average workouts per week (rolling 4-week)
        profile.avgWorkoutsPerWeek = averageWeeklyWorkouts(workouts, weeks = 4)

        // Energy distribution
        if (questionnaires.isNotEmpty()) {
            profile.energyDistribution = buildEnergyDistribution(questionnaires)
        }

        profile.totalWorkoutsObserved = workouts.size
        profile.lastUpdated = Instant.now()

        return profile
    }

    /**
     * Generates a weekly summary from completed workouts.
     *
     * @param workouts All completed workout records.
     * @param weekStart The Monday of the week to summarize.
     * @param profile The current coach profile (for context).
     * @return A weekly summary, or null if no workouts in that week.
     */
    fun generateWeeklySummary(
        workouts: List<CompletedWorkoutRecord>,
        weekStart: java.time.LocalDate,
        profile: CoachProfile
    ): CoachWeeklySummary? {
        val weekEnd = weekStart.plusDays(7)

        val weekWorkouts = workouts.filter { workout ->
            val workoutDate = java.time.LocalDate.parse(workout.date.substring(0, 10))
            !workoutDate.isBefore(weekStart) && workoutDate.isBefore(weekEnd)
        }
        if (weekWorkouts.isEmpty()) return null

        val totalMinutes = weekWorkouts.mapNotNull { it.duration }.sum()
        val allExercises = weekWorkouts.flatMap { it.exerciseNames }
        val muscleGroups = allExercises
            .mapNotNull { WeeklyLoadAnalyzer.classifyMuscleGroup(it) }
            .toSet()
            .sorted()

        // Build observations
        val observations = mutableListOf<String>()

        val majorGroups = setOf("Lower", "Upper Push", "Upper Pull", "Core")
        val missing = majorGroups - muscleGroups.toSet()
        if (missing.isNotEmpty()) {
            observations.add("Missed ${missing.sorted().joinToString(", ")} this week.")
        }

        if (weekWorkouts.size >= 5) {
            observations.add("High frequency week -- ${weekWorkouts.size} sessions.")
        } else if (weekWorkouts.size <= 1) {
            observations.add("Light week -- only ${weekWorkouts.size} session(s).")
        }

        // Build recommendations
        val recommendations = mutableListOf<String>()

        if (missing.isNotEmpty()) {
            recommendations.add("Try to hit ${missing.sorted().firstOrNull() ?: "missing groups"} early next week.")
        }

        if (weekWorkouts.size >= 6) {
            recommendations.add("Consider a lighter week to recover.")
        }

        val avgRounded = profile.avgWorkoutsPerWeek.toInt()
        if (weekWorkouts.size < avgRounded - 1 && profile.avgWorkoutsPerWeek > 0) {
            recommendations.add("Below your usual $avgRounded sessions/week -- try to get back on track.")
        }

        if (recommendations.isEmpty()) {
            recommendations.add("Solid week. Keep the momentum going.")
        }

        return CoachWeeklySummary(
            weekStartDate = weekStart,
            workoutsCompleted = weekWorkouts.size,
            totalMinutes = totalMinutes,
            muscleGroupsHit = muscleGroups,
            observations = observations,
            recommendations = recommendations
        )
    }

    // MARK: - Private Helpers

    private fun topFocusAreas(questionnaires: List<QuestionnaireAnswers>): List<String> {
        val counts = mutableMapOf<String, Int>()
        for (q in questionnaires) {
            counts[q.focus.rawValue] = (counts[q.focus.rawValue] ?: 0) + 1
        }
        return counts.entries
            .sortedByDescending { it.value }
            .map { it.key }
    }

    private fun dominantEquipment(questionnaires: List<QuestionnaireAnswers>): String {
        val counts = mutableMapOf<String, Int>()
        for (q in questionnaires) {
            val key = q.equipment.name.lowercase()
            counts[key] = (counts[key] ?: 0) + 1
        }
        return counts.maxByOrNull { it.value }?.key ?: "full_gym"
    }

    private fun topExercises(
        workouts: List<CompletedWorkoutRecord>,
        limit: Int
    ): List<String> {
        val counts = mutableMapOf<String, Int>()
        for (w in workouts) {
            for (name in w.exerciseNames) {
                counts[name] = (counts[name] ?: 0) + 1
            }
        }
        return counts.entries
            .sortedByDescending { it.value }
            .take(limit)
            .map { it.key }
    }

    private fun avoidedExercises(
        edits: List<WorkoutEdit>,
        substitutions: List<AcceptedSubstitution>
    ): List<String> {
        val avoidCounts = mutableMapOf<String, Int>()

        // Exercises removed in edits
        for (edit in edits) {
            if (edit.editType == WorkoutEdit.EditType.REMOVED_EXERCISE) {
                avoidCounts[edit.exerciseName] = (avoidCounts[edit.exerciseName] ?: 0) + 1
            }
        }

        // Exercises swapped away from
        for (edit in edits) {
            if (edit.editType == WorkoutEdit.EditType.SWAPPED_EXERCISE) {
                avoidCounts[edit.exerciseName] = (avoidCounts[edit.exerciseName] ?: 0) + 1
            }
        }

        // Substitutions where the user accepted moving AWAY from an exercise
        for (sub in substitutions) {
            if (sub.accepted) {
                avoidCounts[sub.originalExercise] = (avoidCounts[sub.originalExercise] ?: 0) + 1
            }
        }

        // Only flag exercises avoided 2+ times
        return avoidCounts.entries
            .filter { it.value >= 2 }
            .sortedByDescending { it.value }
            .map { it.key }
    }

    private fun averageWeeklyWorkouts(
        workouts: List<CompletedWorkoutRecord>,
        weeks: Int
    ): Double {
        val cutoff = java.time.Instant.now().minusSeconds(weeks.toLong() * 7 * 24 * 60 * 60)
        val recent = workouts.filter { workout ->
            try {
                Instant.parse(workout.date.substring(0, 24)).isAfter(cutoff)
            } catch (e: Exception) {
                false
            }
        }
        return recent.size.toDouble() / weeks
    }

    private fun buildEnergyDistribution(
        questionnaires: List<QuestionnaireAnswers>
    ): EnergyDistribution {
        val dist = EnergyDistribution()
        for (q in questionnaires) {
            when (q.energyLevel) {
                EnergyLevel.LOW -> dist.lowCount++
                EnergyLevel.MEDIUM -> dist.mediumCount++
                EnergyLevel.HIGH -> dist.highCount++
            }
        }
        return dist
    }
}

// MARK: - Weight & Multiplier Helpers

/** Maps rep count string to default percentage of 1RM. */
fun aiDefaultPercentage(reps: String): Double {
    val repCount = reps.split("-").firstOrNull()?.toIntOrNull() ?: 10
    return when (repCount) {
        in 1..3 -> 0.85
        in 4..5 -> 0.80
        in 6..8 -> 0.70
        in 9..12 -> 0.65
        else -> 0.60
    }
}

/** Assigns rest time based on bodyweight flag and rep count. */
fun assignRestMinutes(bodyweight: Boolean, reps: String): Double {
    if (bodyweight) return 1.0
    val repCount = reps.split("-").firstOrNull()?.toIntOrNull() ?: 10
    return when (repCount) {
        in 1..5 -> 2.5
        in 6..8 -> 2.0
        in 9..12 -> 1.5
        else -> 1.0
    }
}

/** Get energy level multiplier. */
fun energyMultiplier(level: EnergyLevel): Double {
    return when (level) {
        EnergyLevel.LOW -> 0.85
        EnergyLevel.MEDIUM -> 1.0
        EnergyLevel.HIGH -> 1.05
    }
}

/** Get cycle phase multiplier for workout generation. */
fun aiCyclePhaseMultiplier(phase: CyclePhase?): Double {
    return when (phase) {
        CyclePhase.FOLLICULAR -> 1.0
        CyclePhase.OVULATION -> 1.05
        CyclePhase.LUTEAL -> 0.85
        CyclePhase.MENSTRUAL -> 0.90
        null -> 1.0
    }
}

/** Apply weights to exercises based on user's maxes. */
fun applyWeights(
    exercises: List<GeneratedExercise>,
    maxes: List<ExerciseMax>,
    energyMult: Double,
    cycleMult: Double
): List<GeneratedExercise> {
    return exercises.map { ex ->
        if (ex.bodyweightOnly) return@map ex
        val matched = findMatchingMax(ex.name, maxes) ?: return@map ex

        val pct = aiDefaultPercentage(ex.reps)
        val raw = matched.weightKg * pct * energyMult * cycleMult
        val rounded = (raw / 5.0 + 0.5).toInt() * 5.0

        val effectivePct = pct * energyMult * cycleMult

        ex.copy(
            weightKg = rounded,
            percentageOfMax = effectivePct
        )
    }
}

/** Fuzzy match an exercise name to a user's max. */
fun findMatchingMax(exerciseName: String, maxes: List<ExerciseMax>): ExerciseMax? {
    val lower = exerciseName.lowercase()
    // Exact match first
    maxes.firstOrNull { it.name.lowercase() == lower }?.let { return it }
    // Fuzzy: containment match
    return maxes.firstOrNull { m ->
        m.name.lowercase().contains(lower) || lower.contains(m.name.lowercase())
    }
}

/** Estimates total workout duration in minutes. */
fun totalEstimatedMinutes(exercises: List<GeneratedExercise>): Int {
    val total = exercises.sumOf { ex ->
        val rest = ex.restMinutes ?: 1.5
        ex.sets * (rest + 0.5)
    }
    return max(1, total.toInt())
}
