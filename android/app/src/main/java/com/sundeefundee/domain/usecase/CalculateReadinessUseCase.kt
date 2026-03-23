package com.sundeefundee.domain.usecase

import com.sundeefundee.data.remote.HealthConnectService
import com.sundeefundee.domain.model.HeartRateEntry
import com.sundeefundee.domain.model.ReadinessFactor
import com.sundeefundee.domain.model.ReadinessFactorType
import com.sundeefundee.domain.model.ReadinessScore
import javax.inject.Inject
import kotlin.math.abs

/**
 * Use case for calculating readiness score based on health metrics from Health Connect
 */
class CalculateReadinessUseCase @Inject constructor(
    private val healthConnectService: HealthConnectService?
) {
    
    /**
     * Calculate the readiness score based on available health data
     */
    suspend operator fun invoke(): ReadinessScore {
        // If Health Connect is not available, return empty score
        if (healthConnectService == null) {
            return ReadinessScore.empty()
        }
        
        val factors = mutableListOf<ReadinessFactor>()
        var totalScore = 0
        var totalWeight = 0
        
        // Calculate heart rate variability score
        val hrvScore = calculateHrvScore()
        factors.add(ReadinessFactor(
            name = ReadinessFactorType.HEART_RATE_VARIABILITY.displayName,
            score = hrvScore.first,
            contribution = hrvScore.second
        ))
        totalScore += hrvScore.second
        totalWeight += ReadinessFactorType.HEART_RATE_VARIABILITY.weight
        
        // Calculate resting heart rate score
        val rhrScore = calculateRestingHeartRateScore()
        factors.add(ReadinessFactor(
            name = ReadinessFactorType.RESTING_HEART_RATE.displayName,
            score = rhrScore.first,
            contribution = rhrScore.second
        ))
        totalScore += rhrScore.second
        totalWeight += ReadinessFactorType.RESTING_HEART_RATE.weight
        
        // Calculate recent exercise score
        val exerciseScore = calculateRecentExerciseScore()
        factors.add(ReadinessFactor(
            name = ReadinessFactorType.RECENT_EXERCISE.displayName,
            score = exerciseScore.first,
            contribution = exerciseScore.second
        ))
        totalScore += exerciseScore.second
        totalWeight += ReadinessFactorType.RECENT_EXERCISE.weight
        
        // Calculate overall score as percentage
        val overallScore = if (totalWeight > 0) {
            (totalScore * 100 / totalWeight).coerceIn(0, 100)
        } else {
            0
        }
        
        val recommendation = generateRecommendation(overallScore, factors)
        
        return ReadinessScore(
            overallScore = overallScore,
            factors = factors,
            recommendation = recommendation
        )
    }
    
    /**
     * Calculate HRV score from heart rate data
     * HRV is measured as the variation in time between heartbeats
     */
    private suspend fun calculateHrvScore(): Pair<Int, Int> {
        val now = System.currentTimeMillis()
        val oneDayAgo = now - (24 * 60 * 60 * 1000)
        
        return try {
            val heartRateResult = healthConnectService?.readHeartRate(oneDayAgo, now)
            val heartRates = heartRateResult?.getOrNull() ?: emptyList()
            
            if (heartRates.size < 10) {
                // Not enough data
                Pair(50, ReadinessFactorType.HEART_RATE_VARIABILITY.weight / 2)
            } else {
                // Calculate HRV as standard deviation of RR intervals
                val hrv = calculateHrvFromHeartRates(heartRates)
                // Score: higher HRV is better (typically 20-100ms is good)
                val score = when {
                    hrv < 20 -> 30
                    hrv < 40 -> 60
                    hrv < 60 -> 80
                    hrv < 80 -> 90
                    else -> 100
                }
                val contribution = (score * ReadinessFactorType.HEART_RATE_VARIABILITY.weight) / 100
                Pair(score, contribution)
            }
        } catch (e: Exception) {
            Pair(50, ReadinessFactorType.HEART_RATE_VARIABILITY.weight / 2)
        }
    }
    
    /**
     * Calculate HRV from a list of heart rate entries
     */
    private fun calculateHrvFromHeartRates(heartRates: List<HeartRateEntry>): Int {
        if (heartRates.size < 2) return 0
        
        // Convert BPM to RR intervals (ms between beats)
        val rrIntervals = heartRates.map { 60000.0 / it.beatsPerMinute }
        
        // Calculate standard deviation of RR intervals
        val mean = rrIntervals.average()
        val variance = rrIntervals.map { (it - mean) * (it - mean) }.average()
        val stdDev = kotlin.math.sqrt(variance)
        
        return stdDev.toInt()
    }
    
    /**
     * Calculate resting heart rate score
     * Lower resting HR generally indicates better cardiovascular fitness
     */
    private suspend fun calculateRestingHeartRateScore(): Pair<Int, Int> {
        val now = System.currentTimeMillis()
        val oneDayAgo = now - (24 * 60 * 60 * 1000)
        
        return try {
            val heartRateResult = healthConnectService?.readHeartRate(oneDayAgo, now)
            val heartRates = heartRateResult?.getOrNull() ?: emptyList()
            
            if (heartRates.isEmpty()) {
                Pair(50, ReadinessFactorType.RESTING_HEART_RATE.weight / 2)
            } else {
                // Find the minimum heart rate (likely resting)
                val restingHr = heartRates.minOfOrNull { it.beatsPerMinute } ?: 70
                
                // Score based on resting HR
                val score = when {
                    restingHr < 50 -> 100  // Athletes
                    restingHr < 60 -> 90
                    restingHr < 65 -> 80
                    restingHr < 70 -> 70
                    restingHr < 75 -> 60
                    restingHr < 80 -> 50
                    else -> 40
                }
                val contribution = (score * ReadinessFactorType.RESTING_HEART_RATE.weight) / 100
                Pair(score, contribution)
            }
        } catch (e: Exception) {
            Pair(50, ReadinessFactorType.RESTING_HEART_RATE.weight / 2)
        }
    }
    
    /**
     * Calculate recent exercise score based on workout history
     *适度运动有助于恢复，但过度训练会降低准备度
     */
    private suspend fun calculateRecentExerciseScore(): Pair<Int, Int> {
        val now = System.currentTimeMillis()
        val oneWeekAgo = now - (7 * 24 * 60 * 60 * 1000)
        
        return try {
            val exercisesResult = healthConnectService?.readExercises(oneWeekAgo, now)
            val exercises = exercisesResult?.getOrNull() ?: emptyList()
            
            val workoutCount = exercises.size
            val totalMinutes = exercises.sumOf { it.durationMinutes }
            
            // Ideal: 3-5 workouts per week, 30-90 minutes each
            val score = when {
                workoutCount == 0 -> 40  // No exercise
                workoutCount == 1 -> 60
                workoutCount == 2 -> 75
                workoutCount in 3..4 -> 90
                workoutCount in 5..6 -> 85
                workoutCount > 6 -> 70  // Potentially overtraining
                else -> 50
            }
            
            val contribution = (score * ReadinessFactorType.RECENT_EXERCISE.weight) / 100
            Pair(score, contribution)
        } catch (e: Exception) {
            Pair(50, ReadinessFactorType.RECENT_EXERCISE.weight / 2)
        }
    }
    
    /**
     * Generate a recommendation based on the overall score and factors
     */
    private fun generateRecommendation(overallScore: Int, factors: List<ReadinessFactor>): String {
        return when {
            overallScore >= 85 -> "Excellent readiness! Your body is well-recovered and ready for intense training."
            overallScore >= 70 -> "Good readiness. You can proceed with your planned workout."
            overallScore >= 50 -> "Moderate readiness. Consider a lighter workout or additional recovery."
            overallScore >= 30 -> "Low readiness. Focus on active recovery, mobility work, or rest."
            else -> "Poor readiness. Your body needs rest. Avoid strenuous exercise today."
        }
    }
}
