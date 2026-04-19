package com.sundeefundee.core.domain.program

import kotlin.math.roundToInt

// MARK: - Exercise Value (Discriminated Union)

/**
 * A discriminated union for sets/reps values in program templates.
 */
sealed class ExerciseValue {
    data class Fixed(val value: Int) : ExerciseValue()
    data object Amrap : ExerciseValue()
    data class Range(val low: Int, val high: Int) : ExerciseValue()
    data class Text(val value: String) : ExerciseValue()

    val description: String
        get() = when (this) {
            is Fixed -> value.toString()
            is Amrap -> "AMRAP"
            is Range -> "$low\u2013$high"
            is Text -> value
        }
}

// MARK: - Program Template Types

/**
 * Available program templates with their default settings.
 */
enum class ProgramTemplate(
    val displayName: String,
    val defaultDurationWeeks: Int,
    val defaultSessionsPerWeek: Int
) {
    FIRST_MARGARITA("The First Margarita", 8, 3),
    STRENGTH("Strength", 4, 3),
    HYPERTROPHY("Hypertrophy", 6, 4),
    FULL_BODY("Full Body", 4, 3),
    LINEAR("Linear", 6, 3),
    DUP("Daily Undulating", 4, 3),
    BLOCK("Block", 9, 3);
}

// MARK: - Generated Program Types

data class GeneratedProgramExercise(
    val exercise: String,
    val sets: ExerciseValue,
    val reps: ExerciseValue,
    val percent1RM: Double?,
    val restMinutes: Double,
    val bodyweightOnly: Boolean
)

data class GeneratedProgramSession(
    val sessionId: String,
    val sessionName: String,
    val sessionType: String,
    val focus: String,
    val exercises: List<GeneratedProgramExercise>
)

data class GeneratedProgramWeek(
    val week: Int,
    val phaseId: String?,
    val sessions: List<GeneratedProgramSession>
)

data class GeneratedProgramPhase(
    val id: String,
    val name: String,
    val goal: String,
    val weekRange: List<Int>
)

data class GeneratedProgram(
    val id: String,
    val name: String,
    val category: String,
    val description: String,
    val durationWeeks: Int,
    val sessionsPerWeek: Int,
    val difficulty: String,
    val phases: List<GeneratedProgramPhase>,
    val weeks: List<GeneratedProgramWeek>
)

// MARK: - Program Generation

/**
 * Generate a program from a template.
 *
 * Hand-crafted programs (FIRST_MARGARITA) bypass the generic generation path.
 */
fun generateProgram(
    template: ProgramTemplate,
    name: String,
    durationWeeks: Int? = null,
    sessionsPerWeek: Int? = null
): GeneratedProgram {
    // Hand-crafted programs bypass the generic generation path
    if (template == ProgramTemplate.FIRST_MARGARITA) {
        return generateFirstMargaritaProgram()
    }

    val totalWeeks = durationWeeks ?: template.defaultDurationWeeks
    val totalSessions = sessionsPerWeek ?: template.defaultSessionsPerWeek

    val phases: List<GeneratedProgramPhase> =
        if (template == ProgramTemplate.BLOCK) blockPhases(totalWeeks) else emptyList()

    val weeks = (1..totalWeeks).map { weekNum ->
        val sessions = (1..totalSessions).map { dayNum ->
            buildSession(
                template = template,
                week = weekNum,
                day = dayNum,
                sessionsPerWeek = totalSessions,
                totalWeeks = totalWeeks
            )
        }
        val phaseId =
            if (template == ProgramTemplate.BLOCK) blockPhaseId(weekNum, totalWeeks) else null
        GeneratedProgramWeek(week = weekNum, phaseId = phaseId, sessions = sessions)
    }

    return GeneratedProgram(
        id = "template-${template.name.lowercase()}-${System.currentTimeMillis()}",
        name = name,
        category = "custom",
        description = "${template.displayName} program \u2014 $totalWeeks weeks, ${totalSessions}x/week",
        durationWeeks = totalWeeks,
        sessionsPerWeek = totalSessions,
        difficulty = "intermediate",
        phases = phases,
        weeks = weeks
    )
}

// MARK: - Private: Session Building

private fun buildSession(
    template: ProgramTemplate,
    week: Int,
    day: Int,
    sessionsPerWeek: Int,
    totalWeeks: Int
): GeneratedProgramSession {
    val focus = sessionFocus(template, day)
    val sessionName = buildSessionName(template, day, focus)
    val exercises = sessionExercises(template, focus, week, day, totalWeeks)

    return GeneratedProgramSession(
        sessionId = "w${week}d${day}",
        sessionName = sessionName,
        sessionType = "strength",
        focus = focus,
        exercises = exercises
    )
}

private fun buildSessionName(template: ProgramTemplate, day: Int, focus: String): String {
    if (template == ProgramTemplate.DUP) {
        val labels = listOf("Heavy", "Moderate", "Volume", "Heavy", "Moderate")
        val label = labels[(day - 1) % labels.size]
        return "Day $day \u2014 $label"
    }
    val capitalised = focus.replaceFirstChar { it.uppercase() }
    return "Day $day \u2014 $capitalised Focus"
}

private fun sessionFocus(template: ProgramTemplate, day: Int): String {
    val idx = day - 1
    return when (template) {
        ProgramTemplate.FIRST_MARGARITA,
        ProgramTemplate.STRENGTH,
        ProgramTemplate.LINEAR,
        ProgramTemplate.BLOCK -> {
            val focuses = listOf("squat", "bench", "deadlift", "overhead press", "squat")
            focuses[idx % focuses.size]
        }
        ProgramTemplate.HYPERTROPHY -> {
            val focuses = listOf("upper", "lower", "push", "pull", "upper")
            focuses[idx % focuses.size]
        }
        ProgramTemplate.FULL_BODY -> {
            val focuses = listOf("full body a", "full body b", "full body c", "full body a", "full body b")
            focuses[idx % focuses.size]
        }
        ProgramTemplate.DUP -> "full body"
    }
}

// MARK: - Private: Exercise Selection

// Exercise tuple: (name, sets, reps, basePct1RM, restMinutes, bodyweightOnly)
private data class ExerciseTuple(
    val name: String,
    val sets: Int,
    val reps: Int,
    val basePct1RM: Double,
    val restMinutes: Double,
    val bodyweightOnly: Boolean
)

private fun sessionExercises(
    template: ProgramTemplate,
    focus: String,
    week: Int,
    day: Int,
    totalWeeks: Int
): List<GeneratedProgramExercise> {
    return when (template) {
        ProgramTemplate.FIRST_MARGARITA ->
            emptyList() // Hand-crafted; generateProgram short-circuits before reaching here
        ProgramTemplate.STRENGTH,
        ProgramTemplate.HYPERTROPHY,
        ProgramTemplate.FULL_BODY -> {
            val pool = exercisePool(template, focus)
            val progressionOffset = (week - 1) * 0.02
            pool.map { (name, sets, reps, basePct, rest, bw) ->
                GeneratedProgramExercise(
                    exercise = name,
                    sets = ExerciseValue.Fixed(sets),
                    reps = if (reps == 0) ExerciseValue.Text("hold") else ExerciseValue.Fixed(reps),
                    percent1RM = if (bw) null else basePct + progressionOffset,
                    restMinutes = rest,
                    bodyweightOnly = bw
                )
            }
        }
        ProgramTemplate.LINEAR -> linearExercises(focus, week, totalWeeks)
        ProgramTemplate.DUP -> dupExercises(day, week)
        ProgramTemplate.BLOCK -> blockExercises(focus, week, totalWeeks)
    }
}

private fun exercisePool(template: ProgramTemplate, focus: String): List<ExerciseTuple> {
    return when (template) {
        ProgramTemplate.STRENGTH -> strengthExercises(focus)
        ProgramTemplate.HYPERTROPHY -> hypertrophyExercises(focus)
        ProgramTemplate.FULL_BODY -> fullBodyExercises(focus)
        else -> emptyList()
    }
}

// MARK: - Strength Exercises

private fun strengthExercises(focus: String): List<ExerciseTuple> {
    return when (focus) {
        "squat" -> listOf(
            ExerciseTuple("Back Squat", 4, 5, 0.78, 3.0, false),
            ExerciseTuple("Front Squat", 3, 5, 0.68, 2.5, false),
            ExerciseTuple("Leg Press", 3, 8, 0.0, 2.0, false),
            ExerciseTuple("Walking Lunge", 3, 10, 0.0, 1.5, false),
            ExerciseTuple("Calf Raise", 3, 12, 0.0, 1.0, false)
        )
        "bench" -> listOf(
            ExerciseTuple("Bench Press", 4, 5, 0.78, 3.0, false),
            ExerciseTuple("Incline Dumbbell Press", 3, 8, 0.0, 2.0, false),
            ExerciseTuple("Barbell Row", 4, 5, 0.72, 2.5, false),
            ExerciseTuple("Dumbbell Lateral Raise", 3, 12, 0.0, 1.0, false),
            ExerciseTuple("Tricep Pushdown", 3, 10, 0.0, 1.0, false)
        )
        "deadlift" -> listOf(
            ExerciseTuple("Deadlift", 4, 5, 0.78, 3.0, false),
            ExerciseTuple("Romanian Deadlift", 3, 8, 0.65, 2.0, false),
            ExerciseTuple("Pull-Up", 3, 8, 0.0, 2.0, true),
            ExerciseTuple("Hip Thrust", 3, 10, 0.0, 1.5, false),
            ExerciseTuple("Plank", 3, 0, 0.0, 1.0, true)
        )
        else -> listOf(
            ExerciseTuple("Overhead Press", 4, 5, 0.72, 3.0, false),
            ExerciseTuple("Push Press", 3, 5, 0.68, 2.5, false),
            ExerciseTuple("Lateral Raise", 3, 12, 0.0, 1.0, false),
            ExerciseTuple("Face Pull", 3, 15, 0.0, 1.0, false),
            ExerciseTuple("Dip", 3, 8, 0.0, 1.5, true)
        )
    }
}

// MARK: - Hypertrophy Exercises

private fun hypertrophyExercises(focus: String): List<ExerciseTuple> {
    return when (focus) {
        "upper" -> listOf(
            ExerciseTuple("Bench Press", 4, 10, 0.65, 2.0, false),
            ExerciseTuple("Dumbbell Row", 4, 10, 0.0, 1.5, false),
            ExerciseTuple("Overhead Press", 3, 10, 0.62, 1.5, false),
            ExerciseTuple("Lat Pulldown", 3, 12, 0.0, 1.5, false),
            ExerciseTuple("Bicep Curl", 3, 12, 0.0, 1.0, false),
            ExerciseTuple("Tricep Extension", 3, 12, 0.0, 1.0, false)
        )
        "lower" -> listOf(
            ExerciseTuple("Back Squat", 4, 10, 0.65, 2.0, false),
            ExerciseTuple("Romanian Deadlift", 3, 10, 0.62, 2.0, false),
            ExerciseTuple("Leg Press", 3, 12, 0.0, 1.5, false),
            ExerciseTuple("Leg Curl", 3, 12, 0.0, 1.0, false),
            ExerciseTuple("Calf Raise", 4, 15, 0.0, 1.0, false),
            ExerciseTuple("Plank", 3, 0, 0.0, 1.0, true)
        )
        "push" -> listOf(
            ExerciseTuple("Incline Bench Press", 4, 10, 0.62, 2.0, false),
            ExerciseTuple("Dumbbell Fly", 3, 12, 0.0, 1.0, false),
            ExerciseTuple("Overhead Press", 3, 10, 0.60, 1.5, false),
            ExerciseTuple("Lateral Raise", 3, 15, 0.0, 1.0, false),
            ExerciseTuple("Tricep Pushdown", 3, 12, 0.0, 1.0, false)
        )
        else -> // pull
            listOf(
                ExerciseTuple("Barbell Row", 4, 10, 0.65, 2.0, false),
                ExerciseTuple("Pull-Up", 3, 8, 0.0, 2.0, true),
                ExerciseTuple("Face Pull", 3, 15, 0.0, 1.0, false),
                ExerciseTuple("Hammer Curl", 3, 12, 0.0, 1.0, false),
                ExerciseTuple("Shrug", 3, 12, 0.0, 1.0, false)
            )
    }
}

// MARK: - Full Body Exercises

private fun fullBodyExercises(focus: String): List<ExerciseTuple> {
    return when (focus) {
        "full body a" -> listOf(
            ExerciseTuple("Back Squat", 3, 8, 0.70, 2.5, false),
            ExerciseTuple("Bench Press", 3, 8, 0.70, 2.0, false),
            ExerciseTuple("Barbell Row", 3, 8, 0.68, 2.0, false),
            ExerciseTuple("Overhead Press", 3, 10, 0.62, 1.5, false),
            ExerciseTuple("Plank", 3, 0, 0.0, 1.0, true)
        )
        "full body b" -> listOf(
            ExerciseTuple("Deadlift", 3, 6, 0.75, 3.0, false),
            ExerciseTuple("Incline Dumbbell Press", 3, 10, 0.0, 1.5, false),
            ExerciseTuple("Pull-Up", 3, 8, 0.0, 2.0, true),
            ExerciseTuple("Walking Lunge", 3, 10, 0.0, 1.5, false),
            ExerciseTuple("Bicep Curl", 3, 12, 0.0, 1.0, false)
        )
        else -> // full body c
            listOf(
                ExerciseTuple("Front Squat", 3, 8, 0.65, 2.5, false),
                ExerciseTuple("Dumbbell Bench Press", 3, 10, 0.0, 1.5, false),
                ExerciseTuple("Seated Row", 3, 10, 0.0, 1.5, false),
                ExerciseTuple("Hip Thrust", 3, 10, 0.0, 1.5, false),
                ExerciseTuple("Lateral Raise", 3, 12, 0.0, 1.0, false)
            )
    }
}

// MARK: - Linear Progression

private fun linearExercises(
    focus: String,
    week: Int,
    totalWeeks: Int
): List<GeneratedProgramExercise> {
    val progress = (week - 1).toDouble() / maxOf(totalWeeks - 1, 1).toDouble()
    val reps = (10.0 - progress * 7.0).roundToInt()
    val pct = 0.60 + progress * 0.28
    val sets = if (reps <= 3) 5 else 4
    val rest = if (reps <= 5) 3.0 else 2.0

    return linearPool(focus).map { (name, bw) ->
        GeneratedProgramExercise(
            exercise = name,
            sets = ExerciseValue.Fixed(sets),
            reps = ExerciseValue.Fixed(reps),
            percent1RM = if (bw) null else pct,
            restMinutes = rest,
            bodyweightOnly = bw
        )
    }
}

private fun linearPool(focus: String): List<Pair<String, Boolean>> {
    return when (focus) {
        "squat" -> listOf(
            "Back Squat" to false, "Front Squat" to false,
            "Leg Press" to false, "Walking Lunge" to false, "Calf Raise" to false
        )
        "bench" -> listOf(
            "Bench Press" to false, "Incline Dumbbell Press" to false,
            "Barbell Row" to false, "Lateral Raise" to false, "Tricep Pushdown" to false
        )
        "deadlift" -> listOf(
            "Deadlift" to false, "Romanian Deadlift" to false,
            "Pull-Up" to true, "Hip Thrust" to false, "Plank" to true
        )
        else -> listOf(
            "Overhead Press" to false, "Push Press" to false,
            "Lateral Raise" to false, "Face Pull" to false, "Dip" to true
        )
    }
}

// MARK: - Daily Undulating Periodization (DUP)

private fun dupExercises(day: Int, week: Int): List<GeneratedProgramExercise> {
    val weekOffset = (week - 1) * 0.02
    val dayIndex = (day - 1) % 3

    val reps: Int
    val basePct: Double
    val sets: Int
    val rest: Double
    when (dayIndex) {
        0 -> { reps = 3; basePct = 0.85; sets = 5; rest = 3.0 }
        1 -> { reps = 6; basePct = 0.72; sets = 4; rest = 2.0 }
        else -> { reps = 12; basePct = 0.60; sets = 3; rest = 1.5 }
    }

    val exercises: List<Pair<String, Boolean>> = listOf(
        "Back Squat" to false, "Bench Press" to false, "Deadlift" to false,
        "Overhead Press" to false, "Pull-Up" to true
    )

    return exercises.map { (name, bw) ->
        GeneratedProgramExercise(
            exercise = name,
            sets = ExerciseValue.Fixed(sets),
            reps = ExerciseValue.Fixed(reps),
            percent1RM = if (bw) null else basePct + weekOffset,
            restMinutes = rest,
            bodyweightOnly = bw
        )
    }
}

// MARK: - Block Periodization

private fun blockPhaseId(week: Int, totalWeeks: Int): String {
    val phaseLength = totalWeeks / 3
    return when {
        week <= phaseLength -> "accumulation"
        week <= phaseLength * 2 -> "intensification"
        else -> "peaking"
    }
}

private fun blockPhases(totalWeeks: Int): List<GeneratedProgramPhase> {
    val phaseLength = totalWeeks / 3
    return listOf(
        GeneratedProgramPhase(
            id = "accumulation",
            name = "Accumulation",
            goal = "Build work capacity with high volume, moderate intensity",
            weekRange = listOf(1, phaseLength)
        ),
        GeneratedProgramPhase(
            id = "intensification",
            name = "Intensification",
            goal = "Increase intensity, reduce volume",
            weekRange = listOf(phaseLength + 1, phaseLength * 2)
        ),
        GeneratedProgramPhase(
            id = "peaking",
            name = "Peaking",
            goal = "Peak strength with low volume, max intensity",
            weekRange = listOf(phaseLength * 2 + 1, totalWeeks)
        )
    )
}

private fun blockExercises(
    focus: String,
    week: Int,
    totalWeeks: Int
): List<GeneratedProgramExercise> {
    val phaseLength = totalWeeks / 3

    val reps: Int
    val basePct: Double
    val sets: Int
    val rest: Double

    when {
        week <= phaseLength -> {
            val weekInPhase = week - 1
            reps = 10; basePct = 0.60 + weekInPhase * 0.02; sets = 4; rest = 1.5
        }
        week <= phaseLength * 2 -> {
            val weekInPhase = week - phaseLength - 1
            reps = 5; basePct = 0.75 + weekInPhase * 0.02; sets = 4; rest = 2.5
        }
        else -> {
            val weekInPhase = week - phaseLength * 2 - 1
            reps = 2; basePct = 0.85 + weekInPhase * 0.02; sets = 5; rest = 3.0
        }
    }

    return blockPool(focus).map { (name, bw) ->
        GeneratedProgramExercise(
            exercise = name,
            sets = ExerciseValue.Fixed(sets),
            reps = ExerciseValue.Fixed(reps),
            percent1RM = if (bw) null else basePct,
            restMinutes = rest,
            bodyweightOnly = bw
        )
    }
}

private fun blockPool(focus: String): List<Pair<String, Boolean>> {
    return when (focus) {
        "squat" -> listOf(
            "Back Squat" to false, "Front Squat" to false,
            "Leg Press" to false, "Walking Lunge" to false, "Calf Raise" to false
        )
        "bench" -> listOf(
            "Bench Press" to false, "Incline Dumbbell Press" to false,
            "Barbell Row" to false, "Lateral Raise" to false, "Tricep Pushdown" to false
        )
        "deadlift" -> listOf(
            "Deadlift" to false, "Romanian Deadlift" to false,
            "Pull-Up" to true, "Hip Thrust" to false, "Plank" to true
        )
        else -> listOf(
            "Overhead Press" to false, "Push Press" to false,
            "Lateral Raise" to false, "Face Pull" to false, "Dip" to true
        )
    }
}

// MARK: - The First Margarita: 8-Week Strength Program
//
// A featured, hand-crafted advanced strength program focused on developing
// raw strength in power lifts (Squat, Bench, Deadlift) and foundational
// Olympic lifts. Three phases: Accumulation (Weeks 1-4), Intensification
// (Weeks 5-7), Deload & Testing (Week 8).

private fun generateFirstMargaritaProgram(): GeneratedProgram {
    val phases = listOf(
        GeneratedProgramPhase(
            id = "accumulation",
            name = "Strength Accumulation",
            goal = "Build work capacity and technical proficiency at moderate intensity (75\u201385% 1RM)",
            weekRange = listOf(1, 4)
        ),
        GeneratedProgramPhase(
            id = "intensification",
            name = "Strength Intensification",
            goal = "Increase intensity and decrease volume to peak strength capacity (85\u201395% 1RM)",
            weekRange = listOf(5, 7)
        ),
        GeneratedProgramPhase(
            id = "deload",
            name = "Deload & Testing",
            goal = "Reduce fatigue and test new maximal lifts",
            weekRange = listOf(8, 8)
        )
    )

    return GeneratedProgram(
        id = "sundee-first-margarita",
        name = "The First Margarita",
        category = "Strength",
        description = "Focused on developing raw strength in power lifts (Squat, Bench, Deadlift) and foundational Olympic lifts. Three phases: Accumulation, Intensification, and Deload & Testing.",
        durationWeeks = 8,
        sessionsPerWeek = 3,
        difficulty = "Advanced",
        phases = phases,
        weeks = listOf(
            fmWeek1(), fmWeek2(), fmWeek3(), fmWeek4(),
            fmWeek5(), fmWeek6(), fmWeek7(),
            fmWeek8()
        )
    )
}

// MARK: - First Margarita Helpers

private fun fmEx(
    name: String,
    sets: Int,
    reps: Int,
    pct: Double? = null,
    rest: Double = 2.0,
    bw: Boolean = false
): GeneratedProgramExercise {
    return GeneratedProgramExercise(
        exercise = name,
        sets = ExerciseValue.Fixed(sets),
        reps = ExerciseValue.Fixed(reps),
        percent1RM = pct,
        restMinutes = rest,
        bodyweightOnly = bw
    )
}

private fun fmSession(
    week: Int,
    day: Int,
    name: String,
    focus: String,
    exercises: List<GeneratedProgramExercise>
): GeneratedProgramSession {
    return GeneratedProgramSession(
        sessionId = "w${week}d${day}",
        sessionName = name,
        sessionType = "strength",
        focus = focus,
        exercises = exercises
    )
}

// MARK: - Phase 1: Strength Accumulation (Weeks 1-4)

private fun fmWeek1(): GeneratedProgramWeek {
    return GeneratedProgramWeek(week = 1, phaseId = "accumulation", sessions = listOf(
        // Day 1 - Squat Focus & Pulling Power
        fmSession(1, 1, name = "Day 1 \u2014 Squat Focus & Pulling Power", focus = "squat", listOf(
            fmEx("Back Squat", sets = 3, reps = 5, pct = 0.78, rest = 3.0),
            fmEx("Romanian Deadlift", sets = 2, reps = 8, rest = 2.5),
            fmEx("Overhead Press", sets = 2, reps = 5, rest = 2.5),
            fmEx("Barbell Row", sets = 2, reps = 8, rest = 1.5)
        )),
        // Day 2 - Bench Focus & Olympic Pulls
        fmSession(1, 2, name = "Day 2 \u2014 Bench Focus & Olympic Pulls", focus = "bench", listOf(
            fmEx("Bench Press", sets = 3, reps = 5, pct = 0.77, rest = 3.0),
            fmEx("Snatch Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Close Grip Bench Press", sets = 2, reps = 8, rest = 2.0),
            fmEx("Dumbbell Row", sets = 2, reps = 8, rest = 1.5)
        )),
        // Day 3 - Deadlift Focus & Accessory
        fmSession(1, 3, name = "Day 3 \u2014 Deadlift Focus & Accessory", focus = "deadlift", listOf(
            fmEx("Deadlift", sets = 4, reps = 5, pct = 0.75, rest = 3.0),
            fmEx("Clean Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Pause Squat", sets = 2, reps = 5, rest = 2.5),
            fmEx("Face Pull", sets = 1, reps = 15, rest = 1.0)
        ))
    ))
}

private fun fmWeek2(): GeneratedProgramWeek {
    return GeneratedProgramWeek(week = 2, phaseId = "accumulation", sessions = listOf(
        fmSession(2, 1, name = "Day 1 \u2014 Squat Focus & Pulling Power", focus = "squat", listOf(
            fmEx("Back Squat", sets = 3, reps = 5, pct = 0.80, rest = 3.0),
            fmEx("Deficit Deadlift", sets = 2, reps = 5, rest = 2.5),
            fmEx("Overhead Press", sets = 2, reps = 5, pct = 0.75, rest = 2.5),
            fmEx("Pendlay Row", sets = 2, reps = 5, rest = 1.5)
        )),
        fmSession(2, 2, name = "Day 2 \u2014 Bench Focus & Olympic Pulls", focus = "bench", listOf(
            fmEx("Bench Press", sets = 3, reps = 5, pct = 0.80, rest = 3.0),
            fmEx("Snatch High Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Spoto Press", sets = 2, reps = 5, rest = 2.0),
            fmEx("Pull-Up", sets = 2, reps = 8, rest = 2.0, bw = true)
        )),
        fmSession(2, 3, name = "Day 3 \u2014 Deadlift Focus & Accessory", focus = "deadlift", listOf(
            fmEx("Deadlift", sets = 4, reps = 5, pct = 0.78, rest = 3.0),
            fmEx("Hang Clean", sets = 3, reps = 3, rest = 2.0),
            fmEx("Front Squat", sets = 2, reps = 5, rest = 2.5),
            fmEx("Nordic Curl", sets = 2, reps = 8, rest = 1.5, bw = true)
        ))
    ))
}

private fun fmWeek3(): GeneratedProgramWeek {
    return GeneratedProgramWeek(week = 3, phaseId = "accumulation", sessions = listOf(
        fmSession(3, 1, name = "Day 1 \u2014 Squat Focus & Pulling Power", focus = "squat", listOf(
            fmEx("Back Squat", sets = 3, reps = 5, pct = 0.80, rest = 3.0),
            fmEx("Block Pull", sets = 2, reps = 5, rest = 2.5),
            fmEx("Overhead Press", sets = 2, reps = 5, pct = 0.78, rest = 2.5),
            fmEx("Meadows Row", sets = 2, reps = 8, rest = 1.5)
        )),
        fmSession(3, 2, name = "Day 2 \u2014 Bench Focus & Olympic Pulls", focus = "bench", listOf(
            fmEx("Bench Press", sets = 3, reps = 5, pct = 0.80, rest = 3.0),
            fmEx("Snatch Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Board Press", sets = 2, reps = 5, rest = 2.0),
            fmEx("Incline Dumbbell Press", sets = 2, reps = 8, rest = 1.5)
        )),
        fmSession(3, 3, name = "Day 3 \u2014 Deadlift Focus & Accessory", focus = "deadlift", listOf(
            fmEx("Deadlift", sets = 4, reps = 5, pct = 0.82, rest = 3.0),
            fmEx("Jerk Practice", sets = 2, reps = 3, rest = 2.0),
            fmEx("Pause Squat", sets = 3, reps = 5, rest = 2.5),
            fmEx("Farmer's Carry", sets = 2, reps = 1, rest = 1.5)
        ))
    ))
}

private fun fmWeek4(): GeneratedProgramWeek {
    return GeneratedProgramWeek(week = 4, phaseId = "accumulation", sessions = listOf(
        fmSession(4, 1, name = "Day 1 \u2014 Squat Focus & Pulling Power", focus = "squat", listOf(
            fmEx("Back Squat", sets = 3, reps = 5, pct = 0.82, rest = 3.0),
            fmEx("Romanian Deadlift", sets = 2, reps = 8, rest = 2.5),
            fmEx("Overhead Press", sets = 3, reps = 5, pct = 0.80, rest = 2.5),
            fmEx("Barbell Row", sets = 2, reps = 8, rest = 1.5)
        )),
        fmSession(4, 2, name = "Day 2 \u2014 Bench Focus & Olympic Pulls", focus = "bench", listOf(
            fmEx("Bench Press", sets = 3, reps = 5, pct = 0.82, rest = 3.0),
            fmEx("Snatch Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Dumbbell Bench Press", sets = 2, reps = 8, rest = 2.0),
            fmEx("Face Pull", sets = 1, reps = 15, rest = 1.0)
        )),
        fmSession(4, 3, name = "Day 3 \u2014 Deadlift Focus & Accessory", focus = "deadlift", listOf(
            fmEx("Deadlift", sets = 4, reps = 5, pct = 0.80, rest = 3.0),
            fmEx("Clean Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Front Squat", sets = 2, reps = 5, rest = 2.5),
            fmEx("Glute Ham Raise", sets = 2, reps = 8, rest = 1.5)
        ))
    ))
}

// MARK: - Phase 2: Strength Intensification (Weeks 5-7)

private fun fmWeek5(): GeneratedProgramWeek {
    return GeneratedProgramWeek(week = 5, phaseId = "intensification", sessions = listOf(
        fmSession(5, 1, name = "Day 1 \u2014 Squat Focus & Pulling Power", focus = "squat", listOf(
            fmEx("Back Squat", sets = 4, reps = 3, pct = 0.85, rest = 3.0),
            fmEx("Pause Deadlift", sets = 3, reps = 3, rest = 3.0),
            fmEx("Overhead Press", sets = 3, reps = 3, pct = 0.82, rest = 2.5),
            fmEx("Barbell Row", sets = 2, reps = 5, rest = 2.0)
        )),
        fmSession(5, 2, name = "Day 2 \u2014 Bench Focus & Olympic Pulls", focus = "bench", listOf(
            fmEx("Bench Press", sets = 4, reps = 3, pct = 0.85, rest = 3.0),
            fmEx("Snatch Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Close Grip Bench Press", sets = 2, reps = 3, rest = 2.5),
            fmEx("Pull-Up", sets = 2, reps = 5, rest = 2.0, bw = true)
        )),
        fmSession(5, 3, name = "Day 3 \u2014 Deadlift Focus & Accessory", focus = "deadlift", listOf(
            fmEx("Deadlift", sets = 4, reps = 3, pct = 0.85, rest = 3.0),
            fmEx("Clean", sets = 3, reps = 2, rest = 2.0),
            fmEx("Back Squat", sets = 2, reps = 3, pct = 0.65, rest = 1.5), // Speed work
            fmEx("Ab Rollout", sets = 1, reps = 10, rest = 1.0, bw = true)
        ))
    ))
}

private fun fmWeek6(): GeneratedProgramWeek {
    return GeneratedProgramWeek(week = 6, phaseId = "intensification", sessions = listOf(
        fmSession(6, 1, name = "Day 1 \u2014 Squat Focus & Pulling Power", focus = "squat", listOf(
            fmEx("Back Squat", sets = 4, reps = 2, pct = 0.88, rest = 3.5),
            fmEx("Deficit Deadlift", sets = 3, reps = 3, rest = 3.0),
            fmEx("Overhead Press", sets = 3, reps = 3, pct = 0.85, rest = 2.5),
            fmEx("Pendlay Row", sets = 2, reps = 5, rest = 2.0)
        )),
        fmSession(6, 2, name = "Day 2 \u2014 Bench Focus & Olympic Pulls", focus = "bench", listOf(
            fmEx("Bench Press", sets = 4, reps = 2, pct = 0.88, rest = 3.5),
            fmEx("Snatch High Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Spoto Press", sets = 3, reps = 3, rest = 2.5),
            fmEx("Dumbbell Row", sets = 2, reps = 5, rest = 2.0)
        )),
        fmSession(6, 3, name = "Day 3 \u2014 Deadlift Focus & Accessory", focus = "deadlift", listOf(
            fmEx("Deadlift", sets = 5, reps = 2, pct = 0.88, rest = 3.5),
            fmEx("Clean Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Pause Squat", sets = 3, reps = 2, rest = 3.0),
            fmEx("Face Pull", sets = 1, reps = 15, rest = 1.0)
        ))
    ))
}

private fun fmWeek7(): GeneratedProgramWeek {
    return GeneratedProgramWeek(week = 7, phaseId = "intensification", sessions = listOf(
        fmSession(7, 1, name = "Day 1 \u2014 Squat Focus & Pulling Power", focus = "squat", listOf(
            fmEx("Back Squat", sets = 4, reps = 2, pct = 0.90, rest = 3.5),
            fmEx("Romanian Deadlift", sets = 3, reps = 5, rest = 2.5),
            fmEx("Overhead Press", sets = 3, reps = 3, pct = 0.87, rest = 2.5),
            fmEx("Barbell Row", sets = 2, reps = 5, rest = 2.0)
        )),
        fmSession(7, 2, name = "Day 2 \u2014 Bench Focus & Olympic Pulls", focus = "bench", listOf(
            fmEx("Bench Press", sets = 4, reps = 2, pct = 0.90, rest = 3.5),
            fmEx("Snatch Pull", sets = 3, reps = 3, rest = 2.0),
            fmEx("Board Press", sets = 3, reps = 3, rest = 2.5),
            fmEx("Pull-Up", sets = 2, reps = 5, rest = 2.0, bw = true)
        )),
        fmSession(7, 3, name = "Day 3 \u2014 Deadlift Focus & Accessory", focus = "deadlift", listOf(
            fmEx("Deadlift", sets = 5, reps = 2, pct = 0.90, rest = 3.5),
            fmEx("Hang Clean", sets = 3, reps = 1, rest = 2.5),
            fmEx("Front Squat", sets = 3, reps = 3, rest = 2.5),
            fmEx("Grip Work", sets = 2, reps = 1, rest = 1.5)
        ))
    ))
}

// MARK: - Phase 3: Deload & Testing (Week 8)

private fun fmWeek8(): GeneratedProgramWeek {
    return GeneratedProgramWeek(week = 8, phaseId = "deload", sessions = listOf(
        // Day 1 - Light Squat & Technique
        fmSession(8, 1, name = "Day 1 \u2014 Light Squat & Technique", focus = "squat", listOf(
            fmEx("Back Squat", sets = 2, reps = 5, pct = 0.60, rest = 2.0),
            fmEx("Romanian Deadlift", sets = 2, reps = 8, rest = 2.0),
            fmEx("Overhead Press", sets = 2, reps = 5, pct = 0.55, rest = 2.0),
            fmEx("Face Pull", sets = 1, reps = 15, rest = 1.0)
        )),
        // Day 2 - Light Bench & Technique
        fmSession(8, 2, name = "Day 2 \u2014 Light Bench & Technique", focus = "bench", listOf(
            fmEx("Bench Press", sets = 2, reps = 5, pct = 0.60, rest = 2.0),
            fmEx("Snatch Pull", sets = 2, reps = 3, rest = 2.0),
            fmEx("Close Grip Bench Press", sets = 2, reps = 8, rest = 2.0),
            fmEx("Band Pull-Apart", sets = 1, reps = 15, rest = 1.0, bw = true)
        )),
        // Day 3 - Testing Day (Max Effort)
        fmSession(8, 3, name = "Day 3 \u2014 Testing Day (Max Effort)", focus = "testing", listOf(
            fmEx("Back Squat", sets = 5, reps = 1, rest = 4.0),
            fmEx("Bench Press", sets = 5, reps = 1, rest = 4.0),
            fmEx("Deadlift", sets = 6, reps = 1, rest = 4.0)
        ))
    ))
}
