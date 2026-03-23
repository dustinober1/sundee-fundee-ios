package com.sundeefundee.domain.repository

import com.sundeefundee.domain.model.EnrolledProgram
import com.sundeefundee.domain.model.Program
import kotlinx.coroutines.flow.Flow

interface ProgramRepository {
    fun getAllPrograms(): Flow<List<Program>>
    fun getProgramById(id: String): Flow<Program?>
    fun getEnrollmentsForUser(userId: String): Flow<List<EnrolledProgram>>
    fun getActiveEnrollment(userId: String): Flow<EnrolledProgram?>
    suspend fun enrollInProgram(enrollment: EnrolledProgram)
    suspend fun updateEnrollment(enrollment: EnrolledProgram)
    suspend fun seedProgramsFromBundle()
}
