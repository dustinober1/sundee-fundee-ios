package com.sundeefundee.data.repository

import com.sundeefundee.data.local.UserDao
import com.sundeefundee.data.local.UserEntity
import com.sundeefundee.domain.model.User
import com.sundeefundee.domain.repository.UserRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class UserRepositoryImpl @Inject constructor(
    private val userDao: UserDao
) : UserRepository {

    override fun getUserById(id: String): Flow<User?> {
        return userDao.getUserById(id).map { entity ->
            entity?.toDomain()
        }
    }

    override fun getUserByGoogleId(googleUserId: String): Flow<User?> {
        return userDao.getUserByGoogleId(googleUserId).map { entity ->
            entity?.toDomain()
        }
    }

    override suspend fun createUser(user: User) {
        userDao.insert(user.toEntity())
    }

    override suspend fun updateUser(user: User) {
        userDao.update(user.toEntity())
    }

    override suspend fun deleteUser(user: User) {
        userDao.delete(user.toEntity())
    }

    private fun UserEntity.toDomain(): User {
        return User(
            id = id,
            name = name,
            experienceLevelRaw = experienceLevelRaw,
            primaryGoalRaw = primaryGoalRaw,
            genderRaw = genderRaw,
            weightUnitRaw = weightUnitRaw,
            googleUserID = googleUserID,
            cycleTrackingEnabled = cycleTrackingEnabled,
            onboardingComplete = onboardingComplete,
            createdAt = createdAt,
            profileUpdatedAt = profileUpdatedAt
        )
    }

    private fun User.toEntity(): UserEntity {
        return UserEntity(
            id = id,
            name = name,
            experienceLevelRaw = experienceLevelRaw,
            primaryGoalRaw = primaryGoalRaw,
            genderRaw = genderRaw,
            weightUnitRaw = weightUnitRaw,
            googleUserID = googleUserID,
            cycleTrackingEnabled = cycleTrackingEnabled,
            onboardingComplete = onboardingComplete,
            createdAt = createdAt,
            profileUpdatedAt = profileUpdatedAt
        )
    }
}
