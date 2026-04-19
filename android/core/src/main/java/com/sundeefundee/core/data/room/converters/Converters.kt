package com.sundeefundee.core.data.room.converters

import androidx.room.TypeConverter
import com.sundeefundee.core.model.CyclePhase
import com.sundeefundee.core.model.ChallengeStatus
import com.sundeefundee.core.model.ChallengeTier
import com.sundeefundee.core.model.ChallengeType
import com.sundeefundee.core.model.Exercise
import com.sundeefundee.core.model.ExerciseCategory
import com.sundeefundee.core.model.ExerciseSet
import com.sundeefundee.core.model.WeightUnit
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

// Room TypeConverters for complex types
class Converters {
    private val json = Json { ignoreUnknownKeys = true }

    // ExerciseSet list
    @TypeConverter
    fun fromExerciseSetList(value: List<ExerciseSet>): String = json.encodeToString(value)

    @TypeConverter
    fun toExerciseSetList(value: String): List<ExerciseSet> = try {
        json.decodeFromString(value)
    } catch (_: Exception) { emptyList() }

    // Exercise list
    @TypeConverter
    fun fromExerciseList(value: List<Exercise>): String = json.encodeToString(value)

    @TypeConverter
    fun toExerciseList(value: String): List<Exercise> = try {
        json.decodeFromString(value)
    } catch (_: Exception) { emptyList() }

    // ChallengeTier list
    @TypeConverter
    fun fromChallengeTierList(value: List<ChallengeTier>): String = json.encodeToString(value)

    @TypeConverter
    fun toChallengeTierList(value: String): List<ChallengeTier> = try {
        json.decodeFromString(value)
    } catch (_: Exception) { emptyList() }

    // String list
    @TypeConverter
    fun fromStringList(value: List<String>): String = json.encodeToString(value)

    @TypeConverter
    fun toStringList(value: String): List<String> = try {
        json.decodeFromString(value)
    } catch (_: Exception) { emptyList() }

    // Enums
    @TypeConverter
    fun fromWeightUnit(value: WeightUnit): String = value.name

    @TypeConverter
    fun toWeightUnit(value: String): WeightUnit = try {
        WeightUnit.valueOf(value)
    } catch (_: Exception) { WeightUnit.LBS }

    @TypeConverter
    fun fromExerciseCategory(value: ExerciseCategory): String = value.name

    @TypeConverter
    fun toExerciseCategory(value: String): ExerciseCategory = try {
        ExerciseCategory.valueOf(value)
    } catch (_: Exception) { ExerciseCategory.COMPOUND }

    @TypeConverter
    fun fromCyclePhase(value: CyclePhase): String = value.name

    @TypeConverter
    fun toCyclePhase(value: String): CyclePhase = try {
        CyclePhase.valueOf(value)
    } catch (_: Exception) { CyclePhase.FOLLICULAR }

    @TypeConverter
    fun fromChallengeType(value: ChallengeType): String = value.name

    @TypeConverter
    fun toChallengeType(value: String): ChallengeType = try {
        ChallengeType.valueOf(value)
    } catch (_: Exception) { ChallengeType.CUSTOM }

    @TypeConverter
    fun fromChallengeStatus(value: ChallengeStatus): String = value.name

    @TypeConverter
    fun toChallengeStatus(value: String): ChallengeStatus = try {
        ChallengeStatus.valueOf(value)
    } catch (_: Exception) { ChallengeStatus.ACTIVE }
}
