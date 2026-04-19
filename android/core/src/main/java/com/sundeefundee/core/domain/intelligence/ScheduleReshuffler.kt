package com.sundeefundee.core.domain.intelligence

/**
 * Redistributes missed workout sessions across remaining available days.
 *
 * Given a weekly plan and the days already completed or missed,
 * the reshuffler moves uncompleted sessions to available slots
 * without exceeding volume thresholds.
 *
 * Pure domain logic -- no framework dependencies.
 */
object ScheduleReshuffler {

    // MARK: - Types

    /** Priority level for sessions -- determines drop order when capacity is limited. */
    enum class SessionPriority(val value: Int) : Comparable<SessionPriority> {
        /** Conditioning/cardio -- dropped first. */
        CONDITIONING(0),
        /** Accessory/isolation work -- dropped second. */
        ACCESSORY(1),
        /** Major compound lifts -- dropped last. */
        COMPOUND(2);

        override fun compareTo(other: SessionPriority): Int =
            this.value.compareTo(other.value)
    }

    /** A planned session in the weekly schedule. */
    data class PlannedSession(
        /** The day of the week (1 = Monday, 7 = Sunday). */
        val dayOfWeek: Int,
        /** Session name or identifier. */
        val sessionName: String,
        /** Primary focus of the session. */
        val focus: String,
        /** Estimated duration in minutes. */
        val estimatedMinutes: Int,
        /** Priority level (compound > accessory > conditioning).
         * Defaults to [SessionPriority.ACCESSORY] for backward compatibility. */
        val priority: SessionPriority = SessionPriority.ACCESSORY
    )

    /** The result of a reshuffle operation. */
    data class ReshuffleResult(
        /** The redistributed schedule (sessions mapped to new days). */
        val rescheduledSessions: List<PlannedSession>,
        /** Sessions that couldn't be fit into the remaining week. */
        val droppedSessions: List<PlannedSession>,
        /** Human-readable explanation of what changed. */
        val summary: String
    )

    // MARK: - Configuration

    /** Maximum sessions per day after reshuffling. */
    const val MAX_SESSIONS_PER_DAY = 2

    /** Maximum total minutes per day after reshuffling. */
    const val MAX_MINUTES_PER_DAY = 120

    // MARK: - Reshuffling

    /**
     * Reshuffles missed sessions into available days.
     *
     * @param plan The original weekly plan.
     * @param completedDays Days of the week (1-7) where sessions were completed.
     * @param missedDays Days of the week (1-7) where sessions were missed.
     * @param currentDay The current day of the week (1-7).
     * @return A reshuffle result with the new schedule and any dropped sessions.
     */
    fun reshuffle(
        plan: List<PlannedSession>,
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int
    ): ReshuffleResult {
        // Identify missed sessions
        val missed = plan.filter { missedDays.contains(it.dayOfWeek) }

        if (missed.isEmpty()) {
            return ReshuffleResult(
                rescheduledSessions = plan.filter { it.dayOfWeek >= currentDay },
                droppedSessions = emptyList(),
                summary = "No missed sessions to reschedule."
            )
        }

        // Find available future days (not yet completed, not yet missed, >= current day)
        val usedDays = completedDays + missedDays
        val futureDays = (currentDay..7).filter { !usedDays.contains(it) }

        // Sessions already planned for future days
        val futurePlanned = plan.filter { futureDays.contains(it.dayOfWeek) }

        // Build a capacity map for each future day
        data class DayLoad(var count: Int, var minutes: Int)

        val dayLoad = mutableMapOf<Int, DayLoad>()
        for (day in futureDays) {
            val existingSessions = futurePlanned.filter { it.dayOfWeek == day }
            dayLoad[day] = DayLoad(
                count = existingSessions.size,
                minutes = existingSessions.sumOf { it.estimatedMinutes }
            )
        }

        val rescheduled = futurePlanned.toMutableList()
        val dropped = mutableListOf<PlannedSession>()

        // Sort missed sessions by priority descending (compound first, conditioning last)
        // so that high-priority sessions get placed first and are dropped last.
        val missedByPriority = missed.sortedByDescending { it.priority }

        // Try to place each missed session into the best available day
        // Prefer days with the same focus, then days with the most remaining capacity
        for (session in missedByPriority) {
            var bestDay: Int? = null
            var bestScore = -1

            for (day in futureDays) {
                val load = dayLoad[day] ?: continue

                // Check capacity
                if (load.count >= MAX_SESSIONS_PER_DAY) continue
                if (load.minutes + session.estimatedMinutes > MAX_MINUTES_PER_DAY) continue

                // Score: prefer same-focus days, then emptier days
                var score = 100 - load.count * 30 - load.minutes
                val sameFocus = futurePlanned.any {
                    it.dayOfWeek == day && it.focus == session.focus
                }
                if (sameFocus) score += 50

                if (score > bestScore) {
                    bestScore = score
                    bestDay = day
                }
            }

            val targetDay = bestDay
            if (targetDay != null) {
                val moved = PlannedSession(
                    dayOfWeek = targetDay,
                    sessionName = session.sessionName,
                    focus = session.focus,
                    estimatedMinutes = session.estimatedMinutes,
                    priority = session.priority
                )
                rescheduled.add(moved)
                dayLoad[targetDay]?.let {
                    it.count++
                    it.minutes += session.estimatedMinutes
                }
            } else {
                dropped.add(session)
            }
        }

        // Sort by day
        val sortedRescheduled = rescheduled.sortedBy { it.dayOfWeek }

        val rescheduledNames = rescheduled
            .filter { s -> missed.any { it.sessionName == s.sessionName } }

        val summary = buildSummary(
            missed = missed,
            rescheduled = rescheduledNames,
            dropped = dropped
        )

        return ReshuffleResult(
            rescheduledSessions = sortedRescheduled,
            droppedSessions = dropped,
            summary = summary
        )
    }

    // MARK: - Private

    private fun buildSummary(
        missed: List<PlannedSession>,
        rescheduled: List<PlannedSession>,
        dropped: List<PlannedSession>
    ): String {
        val parts = mutableListOf<String>()

        if (rescheduled.isNotEmpty()) {
            val names = rescheduled.joinToString(", ") { it.sessionName }
            parts.add("Moved ${rescheduled.size} session(s) ($names) to later this week.")
        }

        if (dropped.isNotEmpty()) {
            val keptNames = rescheduled.map { it.sessionName }
            val droppedNames = dropped.joinToString(", ") { it.sessionName }

            val lowestRescheduledPriority = rescheduled.minOfOrNull { it.priority }
            val hasLowerPriorityDropped = dropped.any { session ->
                lowestRescheduledPriority?.let { session.priority < it } == true
            }

            if (keptNames.isNotEmpty() && hasLowerPriorityDropped) {
                val keptStr = keptNames.joinToString(", ")
                parts.add(
                    "Kept higher-priority session(s) ($keptStr) and dropped $droppedNames due to limited availability."
                )
            } else {
                parts.add(
                    "Couldn't fit ${dropped.size} session(s) ($droppedNames) -- consider a longer session or adding them next week."
                )
            }
        }

        return if (parts.isEmpty()) "Schedule unchanged." else parts.joinToString(" ")
    }
}
