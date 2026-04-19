package com.sundeefundee.core.data.room

import com.sundeefundee.core.data.protocol.DataClient
import com.sundeefundee.core.data.protocol.Predicate
import com.sundeefundee.core.data.protocol.SortDescriptor
import com.sundeefundee.core.data.room.entity.*
import com.sundeefundee.core.model.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

// Room-backed DataClient for guest users — mirrors iOS LocalDataClient
@Singleton
class RoomDataClient @Inject constructor(
    private val db: SundeeFundeeDatabase
) : DataClient {

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    @Suppress("UNCHECKED_CAST")
    override suspend fun <T : Any> fetch(
        recordType: String,
        predicate: Predicate,
        sortDescriptors: List<SortDescriptor>?
    ): List<T> {
        val all = fetchAll<T>(recordType)
        // Room handles most filtering natively; for complex predicates,
        // we filter in-memory (mirrors iOS LocalDataClient approach)
        return all // Predicate filtering done at ViewModel level for now
    }

    @Suppress("UNCHECKED_CAST")
    override suspend fun <T : Any> fetchAll(
        recordType: String,
        sortDescriptors: List<SortDescriptor>?
    ): List<T> = when (recordType) {
        "Workout" -> db.workoutDao().getAll().map { it.toModel() } as List<T>
        "OneRepMaxRecord" -> db.oneRepMaxDao().getAll().map { it.toModel() } as List<T>
        "Challenge" -> db.challengeDao().getAll().map { it.toModel() } as List<T>
        "Injury" -> db.injuryDao().getAll().map { it.toModel() } as List<T>
        "DailyPainLog" -> db.painLogDao().getAll().map { it.toModel() } as List<T>
        "EnrolledProgram" -> db.enrolledProgramDao().getAll().map { it.toModel() } as List<T>
        "BenchmarkResult" -> db.benchmarkResultDao().getAll().map { it.toModel() } as List<T>
        "CycleSettings" -> listOfNotNull(db.cycleSettingsDao().get()?.toModel()) as List<T>
        "PeriodLogRecord" -> db.periodLogDao().getAll().map { it.toModel() } as List<T>
        "UserSettings" -> listOfNotNull(db.userSettingsDao().get()?.toModel()) as List<T>
        "RecoveryScore" -> db.recoveryScoreDao().getAll().map { it.toModel() } as List<T>
        "CelebrationEventRecord" -> db.celebrationDao().getAll().map { it.toModel() } as List<T>
        "CompletedWorkoutRecord" -> db.completedWorkoutDao().getAll().map { it.toModel() } as List<T>
        "CyclePhaseInfo" -> db.cyclePhaseInfoDao().getAll().map { it.toModel() } as List<T>
        else -> emptyList()
    }

    @Suppress("UNCHECKED_CAST")
    override suspend fun <T : Any> save(records: List<T>, recordType: String) {
        for (record in records) {
            save(record, recordType)
        }
    }

    @Suppress("UNCHECKED_CAST")
    override suspend fun <T : Any> save(record: T, recordType: String) {
        when (recordType) {
            "Workout" -> {
                val model = record as Workout
                db.workoutDao().insert(model.toEntity(json))
            }
            "OneRepMaxRecord" -> {
                val model = record as OneRepMaxRecord
                db.oneRepMaxDao().insert(model.toEntity())
            }
            "Challenge" -> {
                val model = record as Challenge
                db.challengeDao().insert(model.toEntity(json))
            }
            "Injury" -> {
                val model = record as Injury
                db.injuryDao().insert(InjuryEntity(
                    id = model.id,
                    locationIds = model.locationIds,
                    name = model.name,
                    recoveryPhase = model.recoveryPhase,
                    dateCreated = model.dateCreated,
                    phaseUpdated = model.phaseUpdated,
                    notes = model.notes
                ))
            }
            "DailyPainLog" -> {
                val model = record as DailyPainLog
                db.painLogDao().insert(PainLogEntity(
                    id = model.id,
                    locationIds = model.locationIds,
                    intensity = model.intensity,
                    painType = model.painType,
                    date = model.date,
                    notes = model.notes
                ))
            }
            "EnrolledProgram" -> {
                val model = record as EnrolledProgramRecord
                db.enrolledProgramDao().insert(EnrolledProgramEntity(
                    id = model.id, name = model.name, isActive = model.isActive
                ))
            }
            "BenchmarkResult" -> {
                val model = record as BenchmarkResult
                db.benchmarkResultDao().insert(BenchmarkResultEntity(
                    id = model.id,
                    benchmarkId = model.benchmarkId,
                    benchmarkName = model.benchmarkName,
                    score = model.score,
                    notes = model.notes,
                    date = model.date,
                    cyclePhase = model.cyclePhase
                ))
            }
            "CycleSettings" -> {
                val model = record as CycleSettings
                db.cycleSettingsDao().insert(CycleSettingsEntity(
                    id = model.id,
                    averageCycleLengthDays = model.averageCycleLengthDays,
                    averagePeriodLengthDays = model.averagePeriodLengthDays,
                    lutealPhaseLengthDays = model.lutealPhaseLengthDays
                ))
            }
            "PeriodLogRecord" -> {
                val model = record as PeriodLogRecord
                db.periodLogDao().insert(PeriodLogEntity(
                    id = model.id, startDate = model.startDate, endDate = model.endDate
                ))
            }
            "UserSettings" -> {
                val model = record as UserSettings
                db.userSettingsDao().insert(UserSettingsEntity(
                    id = model.id,
                    weightUnit = model.weightUnit.name,
                    experienceLevel = model.experienceLevel,
                    primaryGoal = model.primaryGoal,
                    cycleTrackingEnabled = model.cycleTrackingEnabled
                ))
            }
            "RecoveryScore" -> {
                val model = record as RecoveryScoreRecord
                db.recoveryScoreDao().insert(RecoveryScoreEntity(
                    id = model.id,
                    scoreDate = model.scoreDate,
                    totalScore = model.totalScore,
                    hrvSubScore = model.hrvSubScore,
                    sleepSubScore = model.sleepSubScore,
                    loadSubScore = model.loadSubScore,
                    cyclePhaseSubScore = model.cyclePhaseSubScore,
                    painSubScore = model.painSubScore,
                    presentInputCount = model.presentInputCount,
                    cyclePhaseRaw = model.cyclePhaseRaw,
                    recommendationRaw = model.recommendationRaw,
                    dateCreated = model.dateCreated
                ))
            }
            "CelebrationEventRecord" -> {
                val model = record as CelebrationEventRecord
                db.celebrationDao().insert(CelebrationEntity(
                    id = model.id, description = model.description, date = model.date
                ))
            }
            "CompletedWorkoutRecord" -> {
                val model = record as CompletedWorkoutRecord
                db.completedWorkoutDao().insert(CompletedWorkoutEntity(
                    id = model.id,
                    name = model.name,
                    date = model.date,
                    duration = model.duration,
                    exerciseNamesJson = json.encodeToString(model.exerciseNames),
                    isComplete = model.isComplete
                ))
            }
            "CyclePhaseInfo" -> {
                val model = record as CyclePhaseInfo
                db.cyclePhaseInfoDao().insert(CyclePhaseInfoEntity(
                    id = model.id,
                    phase = model.phase.name,
                    confidence = model.confidence,
                    startDate = model.startDate,
                    endDate = model.endDate
                ))
            }
        }
    }

    override suspend fun delete(recordIds: List<String>, recordType: String) {
        for (id in recordIds) {
            when (recordType) {
                "Workout" -> db.workoutDao().deleteById(id)
                "OneRepMaxRecord" -> db.oneRepMaxDao().deleteById(id)
                "Challenge" -> db.challengeDao().deleteById(id)
                "Injury" -> db.injuryDao().deleteById(id)
                "DailyPainLog" -> db.painLogDao().deleteById(id)
                "EnrolledProgram" -> db.enrolledProgramDao().deleteById(id)
                "BenchmarkResult" -> db.benchmarkResultDao().deleteById(id)
                "PeriodLogRecord" -> db.periodLogDao().deleteById(id)
            }
        }
    }

    override suspend fun deleteAllData() {
        db.workoutDao().deleteAll()
        db.oneRepMaxDao().deleteAll()
        db.challengeDao().deleteAll()
        db.injuryDao().deleteAll()
        db.painLogDao().deleteAll()
        db.enrolledProgramDao().deleteAll()
        db.programSessionDao().deleteAll()
        db.benchmarkResultDao().deleteAll()
        db.cycleSettingsDao().deleteAll()
        db.periodLogDao().deleteAll()
        db.userSettingsDao().deleteAll()
        db.recoveryScoreDao().deleteAll()
        db.celebrationDao().deleteAll()
        db.completedWorkoutDao().deleteAll()
        db.cyclePhaseInfoDao().deleteAll()
        db.syncQueueDao().deleteAll()
        db.coachProfileDao().deleteAll()
    }

    override suspend fun saveFromJSON(jsonRecords: List<String>, recordType: String) {
        for (jsonStr in jsonRecords) {
            try {
                when (recordType) {
                    "Workout" -> {
                        val model = json.decodeFromString<Workout>(jsonStr)
                        save(model, recordType)
                    }
                    "OneRepMaxRecord" -> {
                        val model = json.decodeFromString<OneRepMaxRecord>(jsonStr)
                        save(model, recordType)
                    }
                    "Challenge" -> {
                        val model = json.decodeFromString<Challenge>(jsonStr)
                        save(model, recordType)
                    }
                }
            } catch (_: Exception) { /* skip malformed records, mirrors iOS */ }
        }
    }
}

// Entity ↔ Model mappers

private fun WorkoutEntity.toModel(): Workout {
    val exercises = try { json.decodeFromString<List<Exercise>>(exercisesJson) } catch (_: Exception) { emptyList() }
    return Workout(id = id, date = date, name = name, exercises = exercises, notes = notes, duration = duration, completedAt = completedAt)
}

private fun Workout.toEntity(json: Json): WorkoutEntity = WorkoutEntity(
    id = id, date = date, name = name,
    exercisesJson = json.encodeToString(exercises),
    notes = notes, duration = duration, completedAt = completedAt
)

private fun OneRepMaxEntity.toModel() = OneRepMaxRecord(
    id = id, exerciseName = exerciseName, weight = weight,
    unit = try { WeightUnit.valueOf(unit) } catch (_: Exception) { WeightUnit.LBS }, date = date
)

private fun OneRepMaxRecord.toEntity() = OneRepMaxEntity(
    id = id, exerciseName = exerciseName, weight = weight, unit = unit.name, date = date
)

private fun ChallengeEntity.toModel(): Challenge {
    val tiers = try { json.decodeFromString<List<ChallengeTier>>(tiersJson) } catch (_: Exception) { emptyList() }
    return Challenge(
        id = id, type = try { ChallengeType.valueOf(type) } catch (_: Exception) { ChallengeType.CUSTOM },
        title = title, exerciseName = exerciseName, tiers = tiers,
        currentTierIndex = currentTierIndex, accumulatedVolumeLbs = accumulatedVolumeLbs,
        status = try { ChallengeStatus.valueOf(status) } catch (_: Exception) { ChallengeStatus.ACTIVE },
        challengeStartDate = challengeStartDate, challengeEndDate = challengeEndDate, dateCreated = dateCreated
    )
}

private fun Challenge.toEntity(json: Json) = ChallengeEntity(
    id = id, type = type.name, title = title, exerciseName = exerciseName,
    tiersJson = json.encodeToString(tiers), currentTierIndex = currentTierIndex,
    accumulatedVolumeLbs = accumulatedVolumeLbs, status = status.name,
    challengeStartDate = challengeStartDate, challengeEndDate = challengeEndDate, dateCreated = dateCreated
)

private fun InjuryEntity.toModel() = Injury(
    id = id, locationIds = locationIds, name = name,
    recoveryPhase = recoveryPhase, dateCreated = dateCreated,
    phaseUpdated = phaseUpdated, notes = notes
)

private fun PainLogEntity.toModel() = DailyPainLog(
    id = id, locationIds = locationIds, intensity = intensity,
    painType = painType, date = date, notes = notes
)

private fun EnrolledProgramEntity.toModel() = EnrolledProgramRecord(id = id, name = name, isActive = isActive)

private fun BenchmarkResultEntity.toModel() = BenchmarkResult(
    id = id, benchmarkId = benchmarkId, benchmarkName = benchmarkName,
    score = score, notes = notes, date = date, cyclePhase = cyclePhase
)

private fun CycleSettingsEntity.toModel() = CycleSettings(
    id = id, averageCycleLengthDays = averageCycleLengthDays,
    averagePeriodLengthDays = averagePeriodLengthDays,
    lutealPhaseLengthDays = lutealPhaseLengthDays
)

private fun PeriodLogEntity.toModel() = PeriodLogRecord(id = id, startDate = startDate, endDate = endDate)

private fun UserSettingsEntity.toModel() = UserSettings(
    id = id, weightUnit = try { WeightUnit.valueOf(weightUnit) } catch (_: Exception) { WeightUnit.LBS },
    experienceLevel = experienceLevel, primaryGoal = primaryGoal,
    cycleTrackingEnabled = cycleTrackingEnabled
)

private fun RecoveryScoreEntity.toModel() = RecoveryScoreRecord(
    id = id, scoreDate = scoreDate, totalScore = totalScore,
    hrvSubScore = hrvSubScore, sleepSubScore = sleepSubScore, loadSubScore = loadSubScore,
    cyclePhaseSubScore = cyclePhaseSubScore, painSubScore = painSubScore,
    presentInputCount = presentInputCount, cyclePhaseRaw = cyclePhaseRaw,
    recommendationRaw = recommendationRaw, dateCreated = dateCreated
)

private fun CelebrationEntity.toModel() = CelebrationEventRecord(id = id, description = description, date = date)

private fun CompletedWorkoutEntity.toModel(): CompletedWorkoutRecord {
    val names = try { json.decodeFromString<List<String>>(exerciseNamesJson) } catch (_: Exception) { emptyList() }
    return CompletedWorkoutRecord(id = id, name = name, date = date, duration = duration, exerciseNames = names, isComplete = isComplete)
}

private fun CyclePhaseInfoEntity.toModel() = CyclePhaseInfo(
    phase = try { CyclePhase.valueOf(phase) } catch (_: Exception) { CyclePhase.FOLLICULAR },
    confidence = confidence, startDate = startDate, endDate = endDate,
    id = id
)

