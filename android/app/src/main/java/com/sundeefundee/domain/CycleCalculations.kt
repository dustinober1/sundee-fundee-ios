package com.sundeefundee.domain

import com.sundeefundee.domain.model.CycleSettings
import com.sundeefundee.domain.model.PeriodLog
import java.util.Calendar

/**
 * Result of cycle status calculation.
 */
data class CycleStatusResult(
    val currentPhase: CyclePhase,
    val cycleDay: Int,
    val daysUntilNextPhase: Int,
    val predictedNextPeriod: Long,
    val phaseStartDate: Long,
    val phaseEndDate: Long
)

/**
 * Defines the day range boundaries for a cycle phase.
 */
data class PhaseBoundary(
    val start: Int,
    val end: Int
)

/**
 * Training recommendations for a specific cycle phase.
 */
data class PhaseRecommendation(
    val phase: CyclePhase,
    val title: String,
    val description: String,
    val trainingFocus: String,
    val intensityRecommendation: String,
    val exercisesToEmphasize: List<String>,
    val exercisesToAvoid: List<String>
)

/**
 * Pure functions for menstrual cycle calculations.
 */
object CycleCalculations {

    // Phase day ranges as percentages of cycle length
    // These are defaults that can be overridden by settings
    private const val DEFAULT_LUTEAL_PHASE_LENGTH = 14
    private const val OVULATION_BUFFER_DAYS = 2

    /**
     * Calculates the current cycle status based on period logs and settings.
     * Returns null if no period logs are available.
     *
     * @param periodLogs List of period logs, newest first recommended
     * @param settings Cycle settings including average cycle/period lengths
     * @param referenceDate Reference date for calculation (defaults to now)
     * @return CycleStatusResult or null if insufficient data
     */
    fun calculateCycleStatus(
        periodLogs: List<PeriodLog>,
        settings: CycleSettings,
        referenceDate: Long = System.currentTimeMillis()
    ): CycleStatusResult? {
        if (periodLogs.isEmpty()) return null

        val ref = startOfDay(referenceDate)
        val sorted = periodLogs.sortedByDescending { it.startDate }

        var cycleStartDate: Long? = null

        // Check if reference date falls within a known period
        for (period in sorted) {
            val pStart = startOfDay(period.startDate)
            val pEnd = period.endDate?.let { startOfDay(it) }
                ?: addDays(pStart, settings.averagePeriodLength - 1)

            if (isWithin(ref, start = pStart, end = pEnd)) {
                cycleStartDate = pStart
                break
            }

            val nextExpected = addDays(pStart, settings.averageCycleLength)
            if (ref > pEnd && ref < nextExpected) {
                cycleStartDate = pStart
                break
            }
        }

        // Calculate cycle start if not found
        val cycleStart: Long = if (cycleStartDate != null) {
            cycleStartDate
        } else {
            val mostRecent = sorted.first()
            var start = startOfDay(mostRecent.startDate)
            val daysSince = daysBetween(start, ref)
            val safeCycleLength = maxOf(1, settings.averageCycleLength)
            val completed = daysSince / safeCycleLength
            start = addDays(start, completed * safeCycleLength)
            start
        }

        val cycleDay = daysBetween(cycleStart, ref) + 1
        val boundaries = getPhaseBoundaries(settings)

        var currentPhase = CyclePhase.FOLLICULAR
        var phaseStartDay = 1
        var phaseEndDay = settings.averageCycleLength

        for (phase in CyclePhase.entries) {
            val b = boundaries[phase] ?: continue
            if (cycleDay >= b.start && cycleDay <= b.end) {
                currentPhase = phase
                phaseStartDay = b.start
                phaseEndDay = b.end
                break
            }
        }

        val daysUntilNext = when (currentPhase) {
            CyclePhase.MENSTRUAL -> (boundaries[CyclePhase.FOLLICULAR]?.start ?: cycleDay) - cycleDay
            CyclePhase.FOLLICULAR -> (boundaries[CyclePhase.OVULATION]?.start ?: cycleDay) - cycleDay
            CyclePhase.OVULATION -> (boundaries[CyclePhase.LUTEAL]?.start ?: cycleDay) - cycleDay
            CyclePhase.LUTEAL -> settings.averageCycleLength - cycleDay + 1
        }

        return CycleStatusResult(
            currentPhase = currentPhase,
            cycleDay = cycleDay,
            daysUntilNextPhase = maxOf(0, daysUntilNext),
            predictedNextPeriod = addDays(cycleStart, settings.averageCycleLength),
            phaseStartDate = addDays(cycleStart, phaseStartDay - 1),
            phaseEndDate = addDays(cycleStart, phaseEndDay - 1)
        )
    }

    /**
     * Gets phase boundaries based on cycle settings.
     */
    fun getPhaseBoundaries(settings: CycleSettings): Map<CyclePhase, PhaseBoundary> {
        val cycleLen = settings.averageCycleLength
        val periodLen = settings.averagePeriodLength
        val lutealLen = DEFAULT_LUTEAL_PHASE_LENGTH

        val ovDay = cycleLen - lutealLen
        val ovStart = maxOf(periodLen + 2, ovDay - OVULATION_BUFFER_DAYS)
        val ovEnd = minOf(ovDay + OVULATION_BUFFER_DAYS, cycleLen - lutealLen + OVULATION_BUFFER_DAYS)

        return mapOf(
            CyclePhase.MENSTRUAL to PhaseBoundary(start = 1, end = periodLen),
            CyclePhase.FOLLICULAR to PhaseBoundary(start = periodLen + 1, end = ovStart - 1),
            CyclePhase.OVULATION to PhaseBoundary(start = ovStart, end = ovEnd),
            CyclePhase.LUTEAL to PhaseBoundary(start = ovEnd + 1, end = cycleLen)
        )
    }

    /**
     * Gets training recommendations for a specific phase.
     */
    fun getPhaseRecommendation(phase: CyclePhase): PhaseRecommendation {
        return when (phase) {
            CyclePhase.MENSTRUAL -> PhaseRecommendation(
                phase = CyclePhase.MENSTRUAL,
                title = "Menstrual Phase",
                description = "Your period phase. Energy may be lower — you might feel more fatigued.",
                trainingFocus = "Recovery and light movement",
                intensityRecommendation = "low",
                exercisesToEmphasize = listOf("yoga", "walking", "light stretching"),
                exercisesToAvoid = listOf("heavy compound lifts", "max effort attempts")
            )
            CyclePhase.FOLLICULAR -> PhaseRecommendation(
                phase = CyclePhase.FOLLICULAR,
                title = "Follicular Phase",
                description = "Energy and endurance begin to rise. Estrogen increases, supporting muscle growth.",
                trainingFocus = "Building strength and endurance",
                intensityRecommendation = "moderate",
                exercisesToEmphasize = listOf("compound movements", "strength training", "cardio"),
                exercisesToAvoid = emptyList()
            )
            CyclePhase.OVULATION -> PhaseRecommendation(
                phase = CyclePhase.OVULATION,
                title = "Ovulation Phase",
                description = "Peak estrogen and testosterone. Often the strongest phase for performance.",
                trainingFocus = "High-intensity training and PR attempts",
                intensityRecommendation = "peak",
                exercisesToEmphasize = listOf("max effort attempts", "heavy compound lifts", "power-focused workouts"),
                exercisesToAvoid = emptyList()
            )
            CyclePhase.LUTEAL -> PhaseRecommendation(
                phase = CyclePhase.LUTEAL,
                title = "Luteal Phase",
                description = "Progesterone rises, which may affect recovery and energy. Focus on maintenance.",
                trainingFocus = "Maintenance and technique refinement",
                intensityRecommendation = "moderate",
                exercisesToEmphasize = listOf("technique work", "volume training", "recovery-focused sessions"),
                exercisesToAvoid = listOf("max effort attempts", "extremely heavy loads")
            )
        }
    }

    // MARK: - Date helpers

    private fun startOfDay(timestamp: Long): Long {
        return Calendar.getInstance().apply {
            timeInMillis = timestamp
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    private fun addDays(timestamp: Long, days: Int): Long {
        return Calendar.getInstance().apply {
            timeInMillis = startOfDay(timestamp)
            add(Calendar.DAY_OF_YEAR, days)
        }.timeInMillis
    }

    private fun daysBetween(from: Long, to: Long): Int {
        val fromDay = startOfDay(from)
        val toDay = startOfDay(to)
        val diff = toDay - fromDay
        return (diff / (24 * 60 * 60 * 1000)).toInt()
    }

    private fun isWithin(target: Long, start: Long, end: Long): Boolean {
        return target >= start && target <= end
    }
}
