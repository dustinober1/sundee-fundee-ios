package com.sundeefundee.domain.repository

import com.sundeefundee.domain.model.User
import kotlinx.coroutines.flow.Flow

interface UserRepository {
    fun getUserById(id: String): Flow<User?>
    fun getUserByGoogleId(googleUserId: String): Flow<User?>
    suspend fun createUser(user: User)
    suspend fun updateUser(user: User)
    suspend fun deleteUser(user: User)
}
