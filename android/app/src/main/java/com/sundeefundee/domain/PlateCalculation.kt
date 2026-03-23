package com.sundeefundee.domain

/**
 * Represents an available plate with its weight and quantity.
 */
data class AvailablePlate(
    val weight: Double,
    val count: Int
) {
    val displayWeight: String
        get() = if (weight == weight.toLong().toDouble()) {
            "${weight.toLong()}kg"
        } else {
            "${weight}kg"
        }

    val displayString: String
        get() = "${count}×$displayWeight"
}

/**
 * Result of plate calculation showing plates per side.
 */
data class PlateResult(
    val plates: List<AvailablePlate>,
    val totalWeight: Double,
    val barWeight: Double
) {
    val isBarOnly: Boolean
        get() = plates.isEmpty()

    val description: String
        get() = if (isBarOnly) {
            "Bar only (${barWeight.toInt()}kg)"
        } else {
            plates.joinToString(" + ") { it.displayString } + " per side"
        }
}

/**
 * Pure functions for calculating plates needed for barbell loading.
 */
object PlateCalculation {

    const val STANDARD_BAR_KG = 20.0
    const val WOMEN_BAR_KG = 15.0

    private val defaultPlatesKg: List<Double> = listOf(25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25)

    /**
     * Returns the plates needed per side of the barbell.
     *
     * @param totalWeightKg Target total weight in kg
     * @param barWeightKg Weight of the barbell (defaults to standard 20kg)
     * @param availablePlates List of available plate weights (defaults to standard set)
     * @return List of AvailablePlate representing plates per side
     */
    fun calculatePlates(
        totalWeightKg: Double,
        barWeightKg: Double = STANDARD_BAR_KG,
        availablePlates: List<Double> = defaultPlatesKg
    ): List<AvailablePlate> {
        if (totalWeightKg <= barWeightKg) return emptyList()

        var remaining = (totalWeightKg - barWeightKg) / 2.0
        val breakdown = mutableListOf<AvailablePlate>()

        for (plate in availablePlates) {
            if (remaining < plate) continue
            val count = (remaining / plate).toInt()
            if (count > 0) {
                breakdown.add(AvailablePlate(weight = plate, count = count))
                remaining -= count * plate
            }
        }

        return breakdown
    }

    /**
     * Returns a PlateResult with full calculation details.
     */
    fun calculatePlatesWithResult(
        totalWeightKg: Double,
        barWeightKg: Double = STANDARD_BAR_KG,
        availablePlates: List<Double> = defaultPlatesKg
    ): PlateResult {
        val plates = calculatePlates(totalWeightKg, barWeightKg, availablePlates)
        val actualTotal = calculateActualTotal(plates, barWeightKg)
        return PlateResult(
            plates = plates,
            totalWeight = actualTotal,
            barWeight = barWeightKg
        )
    }

    /**
     * Calculates the actual total weight achieved with given plates.
     */
    fun calculateActualTotal(plates: List<AvailablePlate>, barWeightKg: Double): Double {
        val platesWeight = plates.sumOf { it.weight * it.count } * 2
        return barWeightKg + platesWeight
    }

    /**
     * Generates a human-readable description of the plate loading.
     *
     * @param totalWeightKg Target total weight in kg
     * @param barWeightKg Weight of the barbell (defaults to standard 20kg)
     * @return Human-readable string like "2×25kg + 1×5kg per side"
     */
    fun description(
        totalWeightKg: Double,
        barWeightKg: Double = STANDARD_BAR_KG
    ): String {
        val plates = calculatePlates(totalWeightKg, barWeightKg)
        if (plates.isEmpty()) {
            return "Bar only (${barWeightKg.toInt()}kg)"
        }

        return plates.joinToString(" + ") { it.displayString } + " per side"
    }

    /**
     * Checks if the target weight is achievable with available plates.
     */
    fun isAchievable(
        totalWeightKg: Double,
        barWeightKg: Double = STANDARD_BAR_KG,
        availablePlates: List<Double> = defaultPlatesKg
    ): Boolean {
        val plates = calculatePlates(totalWeightKg, barWeightKg, availablePlates)
        val actualTotal = calculateActualTotal(plates, barWeightKg)
        return kotlin.math.abs(actualTotal - totalWeightKg) < 0.01
    }

    /**
     * Gets the default available plates in order (heaviest to lightest).
     */
    fun getDefaultPlates(): List<Double> = defaultPlatesKg

    /**
     * Gets available plates for a standard gym (in lbs).
     */
    fun getDefaultPlatesLbs(): List<Double> = listOf(45.0, 35.0, 25.0, 10.0, 5.0, 2.5)

    /**
     * Calculates plates using imperial units (lbs).
     * Uses 45lb standard bar and common plate set.
     */
    fun calculatePlatesLbs(
        totalWeightLbs: Double,
        barWeightLbs: Double = 45.0,
        availablePlates: List<Double> = getDefaultPlatesLbs()
    ): List<AvailablePlate> {
        if (totalWeightLbs <= barWeightLbs) return emptyList()

        var remaining = (totalWeightLbs - barWeightLbs) / 2.0
        val breakdown = mutableListOf<AvailablePlate>()

        for (plate in availablePlates) {
            if (remaining < plate) continue
            val count = (remaining / plate).toInt()
            if (count > 0) {
                val displayWeight = if (plate == plate.toLong().toDouble()) {
                    plate.toLong().toDouble()
                } else {
                    plate
                }
                breakdown.add(AvailablePlate(weight = displayWeight, count = count))
                remaining -= count * plate
            }
        }

        return breakdown
    }
}
