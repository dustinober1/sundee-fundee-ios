package com.sundeefundee.core.data.supabase

// Supabase table name constants — mirrors CloudKit record types
object SupabaseSchema {
    const val WORKOUTS = "workouts"
    const val ONE_REP_MAX_RECORDS = "one_rep_max_records"
    const val CHALLENGES = "challenges"
    const val INJURIES = "injuries"
    const val DAILY_PAIN_LOGS = "daily_pain_logs"
    const val ENROLLED_PROGRAMS = "enrolled_programs"
    const val PROGRAM_SESSION_RECORDS = "program_session_records"
    const val BENCHMARK_RESULTS = "benchmark_results"
    const val CYCLE_SETTINGS = "cycle_settings"
    const val PERIOD_LOG_RECORDS = "period_log_records"
    const val USER_DATA = "user_data"
    const val USER_SETTINGS = "user_settings"
    const val CYCLE_PHASE_INFO = "cycle_phase_info"
    const val CELEBRATION_EVENTS = "celebration_events"
    const val RECOVERY_SCORE_RECORDS = "recovery_score_records"
    const val COMPLETED_WORKOUT_RECORDS = "completed_workout_records"
    const val COACH_PROFILES = "coach_profiles"
    const val WORKOUT_EDITS = "workout_edits"
    const val ACCEPTED_SUBSTITUTIONS = "accepted_substitutions"
    const val COACH_WEEKLY_SUMMARIES = "coach_weekly_summaries"

    // Maps iOS record type strings to Supabase table names
    val recordTypeToTable = mapOf(
        "Workout" to WORKOUTS,
        "OneRepMaxRecord" to ONE_REP_MAX_RECORDS,
        "Challenge" to CHALLENGES,
        "Injury" to INJURIES,
        "DailyPainLog" to DAILY_PAIN_LOGS,
        "EnrolledProgram" to ENROLLED_PROGRAMS,
        "ProgramSessionRecord" to PROGRAM_SESSION_RECORDS,
        "BenchmarkResult" to BENCHMARK_RESULTS,
        "CycleSettings" to CYCLE_SETTINGS,
        "PeriodLogRecord" to PERIOD_LOG_RECORDS,
        "UserData" to USER_DATA,
        "UserSettings" to USER_SETTINGS,
        "CyclePhaseInfo" to CYCLE_PHASE_INFO,
        "CelebrationEventRecord" to CELEBRATION_EVENTS,
        "RecoveryScore" to RECOVERY_SCORE_RECORDS,
        "CompletedWorkoutRecord" to COMPLETED_WORKOUT_RECORDS,
        "CoachProfile" to COACH_PROFILES,
        "WorkoutEdit" to WORKOUT_EDITS,
        "AcceptedSubstitution" to ACCEPTED_SUBSTITUTIONS,
        "CoachWeeklySummary" to COACH_WEEKLY_SUMMARIES,
    )
}
