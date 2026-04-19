package com.sundeefundee.core.domain.cycle

import com.sundeefundee.core.model.CyclePhase
import com.sundeefundee.core.model.CycleSettings
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.DayOfWeek
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.plus
import kotlinx.datetime.toLocalDateTime

// Phase boundaries within a cycle (1-indexed day numbers)
data class PhaseBoundary(val start: Int, val end: Int)

// Result of cycle status calculation
data class CycleStatusResult(
    val currentPhase: CyclePhase,
    val cycleDay: Int,
    val daysUntilNextPhase: Int,
    val predictedNextPeriod: LocalDate,
    val phaseStartDate: LocalDate,
    val phaseEndDate: LocalDate
)

// Training recommendation for a cycle phase
data class PhaseRecommendation(
    val phase: CyclePhase,
    val title: String,
    val description: String,
    val trainingFocus: String,
    val intensityRecommendation: String,
    val exercisesToEmphasize: List<String>,
    val exercisesToAvoid: List<String>
)

// Calculate phase day boundaries for a given cycle settings
fun getPhaseBoundaries(settings: CycleSettings): Map<CyclePhase, PhaseBoundary> {
    val cycleLen = settings.averageCycleLengthDays
    val periodLen = settings.averagePeriodLengthDays
    val lutealLen = settings.lutealPhaseLengthDays

    val ovDay = cycleLen - lutealLen
    val ovStart = maxOf(periodLen + 2, ovDay - 2)
    val ovEnd = minOf(ovDay + 2, cycleLen - lutealLen + 2)

    return mapOf(
        CyclePhase.MENSTRUAL to PhaseBoundary(start = 1, end = periodLen),
        CyclePhase.FOLLICULAR to PhaseBoundary(start = periodLen + 1, end = ovStart - 1),
        CyclePhase.OVULATION to PhaseBoundary(start = ovStart, end = ovEnd),
        CyclePhase.LUTEAL to PhaseBoundary(start = ovEnd + 1, end = cycleLen)
    )
}

// Calculate current cycle status from period logs and settings
fun calculateCycleStatus(
    periodStartDates: List<Pair<LocalDate, LocalDate?>>,
    settings: CycleSettings,
    referenceDate: LocalDate
): CycleStatusResult? {
    if (periodStartDates.isEmpty()) return null

    val sorted = periodStartDates.sortedByDescending { it.first }

    var cycleStartDate: LocalDate? = null

    for ((pStart, pEnd) in sorted) {
        val effectiveEnd = when {
            pEnd != null -> pEnd
            referenceDate >= pStart -> referenceDate
            else -> pStart.plus(settings.averagePeriodLengthDays - 1, DateTimeUnit.DAY)
        }

        if (referenceDate >= pStart && referenceDate <= effectiveEnd) {
            cycleStartDate = pStart
            break
        }
        val nextExpected = pStart.plus(settings.averageCycleLengthDays, DateTimeUnit.DAY)
        if (referenceDate > effectiveEnd && referenceDate < nextExpected) {
            cycleStartDate = pStart
            break
        }
    }

    val cycleStart: LocalDate = cycleStartDate ?: run {
        val most = sorted.first().first
        val daysSince = (referenceDate.toEpochDays() - most.toEpochDays())
        val safeCycleLength = maxOf(1, settings.averageCycleLengthDays)
        val completed = daysSince / safeCycleLength
        most.plus(completed * safeCycleLength, DateTimeUnit.DAY)
    }

    val cycleDay = referenceDate.toEpochDays() - cycleStart.toEpochDays() + 1
    val boundaries = getPhaseBoundaries(settings)

    val phases = listOf(CyclePhase.MENSTRUAL, CyclePhase.FOLLICULAR, CyclePhase.OVULATION, CyclePhase.LUTEAL)
    var currentPhase = CyclePhase.FOLLICULAR
    var phaseStartDay = 1
    var phaseEndDay = settings.averageCycleLengthDays

    for (phase in phases) {
        val b = boundaries[phase]
        if (b != null && cycleDay >= b.start && cycleDay <= b.end) {
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
        CyclePhase.LUTEAL -> settings.averageCycleLengthDays - cycleDay + 1
    }

    return CycleStatusResult(
        currentPhase = currentPhase,
        cycleDay = cycleDay,
        daysUntilNextPhase = maxOf(0, daysUntilNext),
        predictedNextPeriod = cycleStart.plus(settings.averageCycleLengthDays, DateTimeUnit.DAY),
        phaseStartDate = cycleStart.plus(phaseStartDay - 1, DateTimeUnit.DAY),
        phaseEndDate = cycleStart.plus(phaseEndDay - 1, DateTimeUnit.DAY)
    )
}

// Get training recommendation for a cycle phase
fun getPhaseRecommendation(phase: CyclePhase): PhaseRecommendation = when (phase) {
    CyclePhase.MENSTRUAL -> PhaseRecommendation(
        phase = phase,
        title = "Shark Week",
        description = "Your period phase. Energy may be lower — you might feel more fatigued.",
        trainingFocus = "Recovery and light movement",
        intensityRecommendation = "low",
        exercisesToEmphasize = listOf("yoga", "walking", "light stretching"),
        exercisesToAvoid = listOf("heavy compound lifts", "max effort attempts")
    )
    CyclePhase.FOLLICULAR -> PhaseRecommendation(
        phase = phase,
        title = "Follicular Phase",
        description = "Energy and endurance begin to rise. Estrogen increases, supporting muscle growth.",
        trainingFocus = "Building strength and endurance",
        intensityRecommendation = "moderate",
        exercisesToEmphasize = listOf("compound movements", "strength training", "cardio"),
        exercisesToAvoid = emptyList()
    )
    CyclePhase.OVULATION -> PhaseRecommendation(
        phase = phase,
        title = "Ovulation Phase",
        description = "Peak estrogen and testosterone. Often the strongest phase for performance.",
        trainingFocus = "High-intensity training and PR attempts",
        intensityRecommendation = "peak",
        exercisesToEmphasize = listOf("max effort attempts", "heavy compound lifts", "power-focused workouts"),
        exercisesToAvoid = emptyList()
    )
    CyclePhase.LUTEAL -> PhaseRecommendation(
        phase = phase,
        title = "Luteal Phase",
        description = "Progesterone rises, which may affect recovery and energy. Focus on maintenance.",
        trainingFocus = "Maintenance and technique refinement",
        intensityRecommendation = "moderate",
        exercisesToEmphasize = listOf("technique work", "volume training", "recovery-focused sessions"),
        exercisesToAvoid = listOf("max effort attempts", "extremely heavy loads")
    )
}

// Get the phase for a specific cycle day
fun getPhaseForDay(cycleDay: Int, settings: CycleSettings): CyclePhase {
    val adjustedDay = ((cycleDay - 1) % settings.averageCycleLengthDays) + 1
    val boundaries = getPhaseBoundaries(settings)
    for ((phase, boundary) in boundaries) {
        if (adjustedDay in boundary.start..boundary.end) return phase
    }
    return CyclePhase.FOLLICULAR
}
