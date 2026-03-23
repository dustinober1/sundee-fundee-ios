package com.sundeefundee.data.repository

import com.sundeefundee.data.local.EnrolledProgramDao
import com.sundeefundee.data.local.EnrolledProgramEntity
import com.sundeefundee.data.local.ProgramDao
import com.sundeefundee.data.local.ProgramEntity
import com.sundeefundee.domain.model.EnrolledProgram
import com.sundeefundee.domain.model.Program
import com.sundeefundee.domain.repository.ProgramRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class ProgramRepositoryImpl @Inject constructor(
    private val programDao: ProgramDao,
    private val enrolledProgramDao: EnrolledProgramDao
) : ProgramRepository {

    override fun getAllPrograms(): Flow<List<Program>> {
        return programDao.getAllPrograms().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getProgramById(id: String): Flow<Program?> {
        return programDao.getProgramById(id).map { entity ->
            entity?.toDomain()
        }
    }

    override fun getEnrollmentsForUser(userId: String): Flow<List<EnrolledProgram>> {
        return enrolledProgramDao.getEnrollmentsForUser(userId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getActiveEnrollment(userId: String): Flow<EnrolledProgram?> {
        return enrolledProgramDao.getActiveEnrollment(userId).map { entity ->
            entity?.toDomain()
        }
    }

    override suspend fun enrollInProgram(enrollment: EnrolledProgram) {
        enrolledProgramDao.insert(enrollment.toEntity())
    }

    override suspend fun updateEnrollment(enrollment: EnrolledProgram) {
        enrolledProgramDao.update(enrollment.toEntity())
    }

    override suspend fun seedProgramsFromBundle() {
        // Implementation would load programs from bundled JSON and insert them
        // This is a placeholder that would be implemented with actual data loading
    }

    private fun ProgramEntity.toDomain(): Program {
        return Program(
            id = id,
            name = name,
            programDescription = programDescription,
            difficultyLevelRaw = difficultyLevelRaw,
            estimatedDurationWeeks = estimatedDurationWeeks,
            targetAudience = targetAudience,
            createdAt = createdAt
        )
    }

    private fun EnrolledProgramEntity.toDomain(): EnrolledProgram {
        return EnrolledProgram(
            id = id,
            odUserID = odUserID,
            programId = programId,
            enrolledAt = enrolledAt,
            completedAt = completedAt,
            currentWeek = currentWeek,
            currentDay = currentDay
        )
    }

    private fun EnrolledProgram.toEntity(): EnrolledProgramEntity {
        return EnrolledProgramEntity(
            id = id,
            odUserID = odUserID,
            programId = programId,
            enrolledAt = enrolledAt,
            completedAt = completedAt,
            currentWeek = currentWeek,
            currentDay = currentDay
        )
    }
}
