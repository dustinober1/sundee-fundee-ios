package com.sundeefundee.core.domain.benchmark

import com.sundeefundee.core.model.CyclePhase
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDate
import kotlinx.datetime.plus

// MARK: - Cycle Phase Multiplier Helper

/// Helper for getting cycle phase multipliers
object CyclePhaseMultiplier {

    fun multiplierFor(phase: CyclePhase): Double = when (phase) {
        CyclePhase.MENSTRUAL -> 0.85
        CyclePhase.FOLLICULAR -> 1.0
        CyclePhase.OVULATION -> 1.05
        CyclePhase.LUTEAL -> 0.95
    }
}

// MARK: - Benchmark Readiness Calculator

/// Calculates benchmark readiness based on cycle phase and benchmark characteristics
object BenchmarkReadinessCalculator {

    /// Calculate benchmark readiness for a given phase and benchmark
    fun calculateReadiness(
        phase: CyclePhase?,
        benchmarkIntensity: BenchmarkIntensity?,
        movementTags: List<String>?
    ): BenchmarkReadiness {
        // No cycle data - return neutral
        if (phase == null) {
            return BenchmarkReadiness(
                tier = ReadinessTier.MODERATE,
                reason = "No cycle data available",
                recommendation = "Log your period to get personalized recommendations.",
                phaseMultiplier = 1.0,
                emoji = "\u26AA",
                color = "text-text-secondary"
            )
        }

        val intensity = benchmarkIntensity ?: BenchmarkIntensity.THREE
        val tags = movementTags ?: emptyList()
        val phaseMultiplier = CyclePhaseMultiplier.multiplierFor(phase)

        // Check for high-intensity tags
        val hasHeavyTag = tags.any { tag ->
            val lower = tag.lowercase()
            lower.contains("heavy") ||
                lower.contains("max") ||
                lower.contains("high volume")
        }

        val hasHighCardio = tags.any { tag ->
            val lower = tag.lowercase()
            lower.contains("cardio") ||
                lower.contains("sprint") ||
                lower.contains("high intensity")
        }

        // Determine tier based on phase + intensity
        return when (phase) {
            CyclePhase.MENSTRUAL -> {
                // Recovery phase - avoid high intensity
                if (intensity.value >= 4 || hasHeavyTag || hasHighCardio) {
                    BenchmarkReadiness(
                        tier = ReadinessTier.RECOVERY,
                        reason = "Shark Week — energy typically lower",
                        recommendation = "Consider saving this for later. Focus on light movement today.",
                        phaseMultiplier = phaseMultiplier,
                        emoji = "\uD83D\uDD34",
                        color = "text-warm-rose"
                    )
                } else {
                    BenchmarkReadiness(
                        tier = ReadinessTier.MODERATE,
                        reason = "Shark Week — listen to your body",
                        recommendation = "Light to moderate intensity is fine. Scale as needed.",
                        phaseMultiplier = phaseMultiplier,
                        emoji = "\uD83D\uDFE1",
                        color = "text-gold"
                    )
                }
            }

            CyclePhase.FOLLICULAR -> {
                if (intensity.value <= 3) {
                    BenchmarkReadiness(
                        tier = ReadinessTier.PEAK,
                        reason = "Follicular phase — great for building",
                        recommendation = "Your body is primed for strength and skill work. Go for it!",
                        phaseMultiplier = phaseMultiplier,
                        emoji = "\uD83D\uDFE2",
                        color = "text-green-600"
                    )
                } else if (intensity.value >= 4 || hasHeavyTag) {
                    BenchmarkReadiness(
                        tier = ReadinessTier.PEAK,
                        reason = "Follicular phase — strength window",
                        recommendation = "Estrogen is rising. Great time for PR attempts!",
                        phaseMultiplier = phaseMultiplier,
                        emoji = "\uD83D\uDFE2",
                        color = "text-green-600"
                    )
                } else {
                    BenchmarkReadiness(
                        tier = ReadinessTier.PEAK,
                        reason = "Follicular phase — energy building",
                        recommendation = "You're in a high-energy window. Make the most of it!",
                        phaseMultiplier = phaseMultiplier,
                        emoji = "\uD83D\uDFE2",
                        color = "text-green-600"
                    )
                }
            }

            CyclePhase.OVULATION -> {
                // Peak performance phase
                BenchmarkReadiness(
                    tier = ReadinessTier.PEAK,
                    reason = "Ovulation phase — peak performance window!",
                    recommendation = "Estrogen and testosterone peak. This is THE time for PRs and max effort.",
                    phaseMultiplier = phaseMultiplier,
                    emoji = "\uD83D\uDFE2",
                    color = "text-green-600"
                )
            }

            CyclePhase.LUTEAL -> {
                // Maintenance phase
                if (intensity.value >= 5 || hasHeavyTag) {
                    BenchmarkReadiness(
                        tier = ReadinessTier.RECOVERY,
                        reason = "Luteal phase — body preparing for Shark Week",
                        recommendation = "Consider saving max effort for your follicular phase.",
                        phaseMultiplier = phaseMultiplier,
                        emoji = "\uD83D\uDD34",
                        color = "text-warm-rose"
                    )
                } else if (intensity.value >= 4) {
                    BenchmarkReadiness(
                        tier = ReadinessTier.MODERATE,
                        reason = "Luteal phase — energy may be declining",
                        recommendation = "You can do this, but listen to your body. Scale if needed.",
                        phaseMultiplier = phaseMultiplier,
                        emoji = "\uD83D\uDFE1",
                        color = "text-gold"
                    )
                } else {
                    BenchmarkReadiness(
                        tier = ReadinessTier.MODERATE,
                        reason = "Luteal phase — maintenance mode",
                        recommendation = "Good for technique work and moderate intensity.",
                        phaseMultiplier = phaseMultiplier,
                        emoji = "\uD83D\uDFE1",
                        color = "text-gold"
                    )
                }
            }
        }
    }

    /// Get best days to attempt a benchmark based on cycle history.
    /// Ovulation window is typically days 12-16 of a 28-day cycle,
    /// adjusted based on actual cycle length (~45% into cycle).
    fun getBestAttemptWindow(
        averageCycleLength: Int,
        lastPeriodStart: LocalDate
    ): AttemptWindow {
        val ovulationDay = (averageCycleLength * 0.45).toInt()
        val windowStart = ovulationDay - 2
        val windowEnd = ovulationDay + 2

        val startDate = lastPeriodStart.plus(windowStart, DateTimeUnit.DAY)
        val endDate = lastPeriodStart.plus(windowEnd, DateTimeUnit.DAY)

        return AttemptWindow(
            startDate = startDate.toString(),
            endDate = endDate.toString(),
            reason = "Your ovulation window — estrogen and testosterone peak for maximum power output."
        )
    }
}
