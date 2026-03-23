package com.sundeefundee.domain.model

/**
 * Represents an overall readiness score calculated from various health metrics
 * 
 * @property overallScore Overall readiness score from 0-100
 * @property factors List of individual factors that contributed to the score
 * @property recommendation Text recommendation based on the score
 */
data class ReadinessScore(
    val overallScore: Int,
    val factors: List<ReadinessFactor>,
    val recommendation: String
) {
    companion object {
        const val MAX_SCORE = 100
        const val MIN_SCORE = 0
        
        fun empty(): ReadinessScore = ReadinessScore(
            overallScore = 0,
            factors = emptyList(),
            recommendation = "Unable to calculate readiness. Please ensure Health Connect permissions are granted."
        )
    }
}

/**
 * Represents an individual factor contributing to the readiness score
 * 
 * @property name Display name of the factor
 * @property score Individual score for this factor (0-100)
 * @property contribution Weighted contribution to overall score
 */
data class ReadinessFactor(
    val name: String,
    val score: Int,
    val contribution: Int
)

/**
 * Categories of readiness factors
 */
enum class ReadinessFactorType(val displayName: String, val weight: Int) {
    HEART_RATE_VARIABILITY("Heart Rate Variability", 25),
    RESTING_HEART_RATE("Resting Heart Rate", 20),
    RECENT_EXERCISE("Recent Exercise", 20),
    SLEEP_QUALITY("Sleep Quality", 15),
    CYCLE_PHASE("Menstrual Cycle Phase", 10),
    INJURY_STATUS("Injury Status", 10);
    
    companion object {
        fun fromName(name: String): ReadinessFactorType? {
            return entries.find { it.displayName == name }
        }
    }
}
