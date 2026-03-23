package com.sundeefundee.domain

import kotlin.math.roundToInt

/**
 * Result of a training session for weight progression logic.
 */
enum class SessionResult {
    FIRST,
    SUCCESS,
    FAILURE
}

/**
 * Available 1RM calculation formulas.
 */
enum class OneRepMaxFormula {
    EPLEY,
    BRZYCKI
}

/**
 * Pure functions for weight and rep calculations used in CrossFit/strength training.
 */
object WeightCalculations {

    /**
     * Rounds a weight to the nearest 5 units.
     */
    fun roundToNearestFive(value: Double): Double {
        return (value / 5.0).roundToInt() * 5.0
    }

    /**
     * Calculates target weight based on 1RM and percentage.
     */
    fun calculateTargetWeight(oneRepMax: Double, percentage: Double): Double {
        return roundToNearestFive(oneRepMax * percentage)
    }

    /**
     * Gets the next recommended weight based on session result.
     */
    fun getNextRecommendedWeight(
        currentWeight: Double,
        result: SessionResult,
        oneRepMax: Double
    ): Double {
        return when (result) {
            SessionResult.FIRST -> roundToNearestFive(oneRepMax * 0.7)
            SessionResult.SUCCESS -> roundToNearestFive(currentWeight + 5)
            SessionResult.FAILURE -> {
                val floor = roundToNearestFive(oneRepMax * 0.5)
                maxOf(roundToNearestFive(currentWeight - 5), floor)
            }
        }
    }

    /**
     * Determines if a set was successful based on actual vs prescribed values.
     */
    fun wasSetSuccessful(
        actualReps: Int,
        prescribedReps: Int,
        actualWeight: Double,
        prescribedWeight: Double?
    ): Boolean {
        val repsOk = actualReps >= prescribedReps
        val weightOk = prescribedWeight?.let { actualWeight >= it } ?: true
        return repsOk && weightOk
    }

    /**
     * Checks if a weight is a personal record compared to previous max.
     */
    fun isPersonalRecord(weight: Double, previousMax: Double?): Boolean {
        return previousMax?.let { weight > it } ?: true
    }

    /**
     * Calculates total volume load (weight × reps × sets).
     */
    fun calculateVolumeLoad(weight: Double, reps: Int, sets: Int): Double {
        return weight * reps * sets
    }

    /**
     * Detects if a plateau exists (less than 5 unit variation in last 3 weights).
     */
    fun detectPlateau(weights: List<Double>): Boolean {
        if (weights.size < 3) return false
        val last3 = weights.takeLast(3)
        return (last3.maxOrNull()!! - last3.minOrNull()!!) < 5.0
    }
}

/**
 * Epley formula for estimating 1RM.
 * Formula: weight × (1 + reps / 30)
 */
object EpleyFormula {

    /**
     * Estimates 1RM from a submaximal lift.
     * Only valid for reps > 1 (for reps == 1, the lift itself is the 1RM).
     */
    fun estimated1RM(weight: Double, reps: Int): Double {
        if (reps <= 1) return weight
        return weight * (1.0 + reps / 30.0)
    }

    /**
     * Checks if the new estimate is a PR vs the stored max.
     */
    fun isPR(newEstimate: Double, currentMax: Double?): Boolean {
        return currentMax?.let { newEstimate > it } ?: true
    }
}

/**
 * Brzycki formula for estimating 1RM.
 * Formula: weight × (36 / (37 - reps))
 */
object BrzyckiFormula {

    /**
     * Estimates 1RM using Brzycki formula.
     * Only valid for reps < 37.
     */
    fun estimated1RM(weight: Double, reps: Int): Double {
        if (reps <= 1) return weight
        if (reps >= 37) return weight * 2.0 // Approximate for very high reps
        return weight * (36.0 / (37.0 - reps))
    }
}

/**
 * Calculator for one-rep max using various formulas.
 */
object OneRepMaxCalculator {

    /**
     * Calculates 1RM using the specified formula.
     */
    fun calculate(weight: Double, reps: Int, formula: OneRepMaxFormula): Double {
        return when (formula) {
            OneRepMaxFormula.EPLEY -> EpleyFormula.estimated1RM(weight, reps)
            OneRepMaxFormula.BRZYCKI -> BrzyckiFormula.estimated1RM(weight, reps)
        }
    }

    /**
     * Calculates percentage of 1RM for a given weight.
     */
    fun calculatePercentageOf1RM(oneRepMax: Double, weight: Double): Double {
        return if (oneRepMax > 0) weight / oneRepMax else 0.0
    }

    /**
     * Gets weight for a target percentage of 1RM.
     */
    fun weightForPercentage(oneRepMax: Double, percentage: Double): Double {
        return WeightCalculations.roundToNearestFive(oneRepMax * percentage)
    }
}
