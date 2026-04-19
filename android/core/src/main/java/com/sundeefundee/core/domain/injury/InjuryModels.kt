package com.sundeefundee.core.domain.injury

import kotlinx.serialization.Serializable
import java.util.UUID

// MARK: - Body Region

/**
 * Body region for injury/pain tracking.
 */
@Serializable
data class BodyRegion(
    val id: String,
    val displayName: String,
    /** Maps to the injury engine's contraindication key */
    val engineKey: String
)

/**
 * All supported body regions (17 total).
 */
object BodyRegions {
    val allRegions: List<BodyRegion> = listOf(
        BodyRegion(id = "head", displayName = "Head", engineKey = "head"),
        BodyRegion(id = "neck", displayName = "Neck", engineKey = "neck"),
        BodyRegion(id = "shoulder_left", displayName = "Left Shoulder", engineKey = "shoulder"),
        BodyRegion(id = "shoulder_right", displayName = "Right Shoulder", engineKey = "shoulder"),
        BodyRegion(id = "chest", displayName = "Chest", engineKey = "chest"),
        BodyRegion(id = "upper_back", displayName = "Upper Back", engineKey = "back"),
        BodyRegion(id = "lower_back", displayName = "Lower Back", engineKey = "back"),
        BodyRegion(id = "elbow_left", displayName = "Left Elbow", engineKey = "elbow"),
        BodyRegion(id = "elbow_right", displayName = "Right Elbow", engineKey = "elbow"),
        BodyRegion(id = "wrist_left", displayName = "Left Wrist", engineKey = "wrist"),
        BodyRegion(id = "wrist_right", displayName = "Right Wrist", engineKey = "wrist"),
        BodyRegion(id = "hip_left", displayName = "Left Hip", engineKey = "hip"),
        BodyRegion(id = "hip_right", displayName = "Right Hip", engineKey = "hip"),
        BodyRegion(id = "knee_left", displayName = "Left Knee", engineKey = "knee"),
        BodyRegion(id = "knee_right", displayName = "Right Knee", engineKey = "knee"),
        BodyRegion(id = "ankle_left", displayName = "Left Ankle", engineKey = "ankle"),
        BodyRegion(id = "ankle_right", displayName = "Right Ankle", engineKey = "ankle"),
    )

    private val regionMap: Map<String, BodyRegion> = allRegions.associateBy { it.id }

    /** Find a region by ID */
    fun region(id: String): BodyRegion? = regionMap[id]

    /** Parse a comma-separated string of region IDs into BodyRegion objects */
    fun parseRegions(raw: String): List<BodyRegion> {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return emptyList()

        return trimmed
            .split(",")
            .map { it.trim() }
            .mapNotNull { region(it) }
    }

    /** Encode an array of BodyRegion objects to a comma-separated string of IDs */
    fun encodeRegions(regions: List<BodyRegion>): String =
        regions.joinToString(",") { it.id }
}

// MARK: - Recovery Phase

/**
 * Recovery phase for an injury (canonical ordering from acute to resolved).
 */
@Serializable
enum class RecoveryPhase(val displayName: String) {
    ACUTE("Acute"),
    REHAB("Rehab"),
    LIGHT_LOAD("Light Load"),
    RETURN_TO_PLAY("Return to Play"),
    RESOLVED("Resolved");

    /** Numeric value for ordering (lower = more severe) */
    val orderValue: Int get() = ordinal

    /** The next phase in the recovery progression, or null if already resolved */
    val next: RecoveryPhase? get() = entries.getOrNull(ordinal + 1)

    companion object {
        /** Comparison for sorting */
        fun compare(lhs: RecoveryPhase, rhs: RecoveryPhase): Int =
            lhs.orderValue.compareTo(rhs.orderValue)
    }
}

// MARK: - Pain Type

/**
 * Type/category of pain.
 */
@Serializable
enum class PainType(val displayName: String, val color: String) {
    ACUTE("Acute Pain", "red"),
    CHRONIC("Chronic Pain", "orange"),
    SORENESS("Soreness", "yellow"),
    STIFFNESS("Stiffness", "blue"),
    SHARP("Sharp Pain", "red"),
    DULL("Dull Ache", "green"),
    ACHING("Aching", "yellow"),
    OTHER("Other", "gray");
}

// MARK: - Pain Level

/**
 * Pain level category for display.
 */
@Serializable
enum class PainLevel(val displayName: String, val color: String) {
    NONE("No Pain", "green"),
    MILD("Mild", "yellow"),
    MODERATE("Moderate", "orange"),
    SEVERE("Severe", "red"),
    EXTREME("Extreme", "purple");

    companion object {
        /** Get pain level from intensity (1-10 scale) */
        fun from(intensity: Int): PainLevel = when (intensity) {
            0 -> NONE
            in 1..3 -> MILD
            in 4..6 -> MODERATE
            in 7..8 -> SEVERE
            in 9..10 -> EXTREME
            else -> MODERATE
        }
    }
}

// MARK: - Injury

/**
 * An injury or chronic condition being tracked.
 */
@Serializable
data class Injury(
    val id: String = UUID.randomUUID().toString(),
    /** Body regions affected (comma-separated IDs) */
    val locationIds: String,
    /** Name/description of the injury */
    val name: String,
    /** Current recovery phase */
    val recoveryPhase: RecoveryPhase,
    /** When the injury was logged (epoch millis) */
    val dateCreated: Long = System.currentTimeMillis(),
    /** When the recovery phase was last updated (epoch millis) */
    val phaseUpdated: Long = System.currentTimeMillis(),
    /** Additional notes */
    val notes: String? = null
) {
    /** Parse body regions from location IDs */
    val bodyRegions: List<BodyRegion>
        get() = BodyRegions.parseRegions(locationIds)
}

// MARK: - Daily Pain Log

/**
 * A pain log entry for tracking day-to-day pain levels.
 */
@Serializable
data class DailyPainLog(
    val id: String = UUID.randomUUID().toString(),
    /** Body regions experiencing pain (comma-separated IDs) */
    val locationIds: String,
    /** Pain intensity (1-10 scale) */
    val intensity: Int,
    /** Pain type/category */
    val painType: PainType,
    /** When the pain was logged (epoch millis) */
    val date: Long = System.currentTimeMillis(),
    /** Additional context */
    val notes: String? = null
) {
    /** Parse body regions from location IDs */
    val bodyRegions: List<BodyRegion>
        get() = BodyRegions.parseRegions(locationIds)

    /** Validate pain intensity is in valid range */
    val isValidIntensity: Boolean
        get() = intensity in 1..10
}

// MARK: - Pain Log (for trend analysis)

/**
 * A pain level log entry used for trend analysis.
 */
@Serializable
data class PainLog(
    val injuryId: String,
    val painLevel: Int,  // 0-10
    val recordedAt: Long  // epoch millis
)

// MARK: - Pain Trend Result

/**
 * Result of pain trend analysis.
 */
data class TrendResult(
    val trailingAverage: Double,
    val isImproving: Boolean,
    val latestPainLevel: Int?,
    val readingCount: Int
)

// MARK: - Transition Suggestion

/**
 * Suggestion to advance an injury to the next recovery phase.
 */
data class TransitionSuggestion(
    val injuryId: String,
    val currentPhase: RecoveryPhase,
    val suggestedPhase: RecoveryPhase
)

// MARK: - Load Multipliers

/**
 * Load multipliers for injury adaptation.
 */
data class LoadMultipliers(
    val load: Double,
    val sets: Double,
    val reps: Double
)

/** Load multipliers per recovery phase */
val LOAD_MULTIPLIERS: Map<RecoveryPhase, LoadMultipliers> = mapOf(
    RecoveryPhase.ACUTE to LoadMultipliers(load = 0.0, sets = 0.0, reps = 0.0),
    RecoveryPhase.REHAB to LoadMultipliers(load = 0.30, sets = 0.50, reps = 0.70),
    RecoveryPhase.LIGHT_LOAD to LoadMultipliers(load = 0.50, sets = 0.75, reps = 0.85),
    RecoveryPhase.RETURN_TO_PLAY to LoadMultipliers(load = 0.80, sets = 0.90, reps = 1.0),
    RecoveryPhase.RESOLVED to LoadMultipliers(load = 1.0, sets = 1.0, reps = 1.0),
)
