package com.sundeefundee.core.domain.exercise

import kotlin.math.round

/**
 * Epley 1RM formula: weight * (1 + reps / 30)
 */
fun epley1RM(weight: Double, reps: Int): Double = weight * (1.0 + reps / 30.0)

/**
 * Convert pounds to kilograms.
 */
fun lbsToKg(lbs: Double): Double = lbs / 2.20462

/**
 * Convert kilograms to pounds.
 */
fun kgToLbs(kg: Double): Double = kg * 2.20462

/**
 * Round a weight value to the nearest increment.
 * e.g. roundToNearest(137.5, 5.0) = 140.0
 */
fun roundToNearest(weight: Double, increment: Double): Double =
    round(weight / increment) * increment

/**
 * Map rep ranges to a default percentage of 1RM for AI-generated workouts.
 *   1-3  -> 0.85
 *   4-5  -> 0.80
 *   6-8  -> 0.70
 *   9-12 -> 0.65
 *   else -> 0.60
 */
fun aiDefaultPercentage(reps: Int): Double = when (reps) {
    in 1..3 -> 0.85
    in 4..5 -> 0.80
    in 6..8 -> 0.70
    in 9..12 -> 0.65
    else -> 0.60
}

/**
 * Assign rest time in minutes based on exercise type and rep range.
 *   bodyweight       -> 1.0
 *   1-5 reps         -> 2.5
 *   6-8 reps         -> 2.0
 *   9-12 reps        -> 1.5
 *   else             -> 1.0
 */
fun assignRestMinutes(bodyweight: Boolean, reps: Int): Double = when {
    bodyweight -> 1.0
    reps in 1..5 -> 2.5
    reps in 6..8 -> 2.0
    reps in 9..12 -> 1.5
    else -> 1.0
}
