package com.sundeefundee.domain.repository

import kotlinx.coroutines.flow.Flow

interface FcmTokenRepository {
    /**
     * Save the FCM token to the backend.
     * @param token The FCM registration token
     * @return Result indicating success or failure
     */
    suspend fun saveToken(token: String): Result<Boolean>
    
    /**
     * Get the current cached FCM token.
     * @return The token if available, null otherwise
     */
    suspend fun getToken(): String?
    
    /**
     * Observe changes to the FCM token.
     * Emits the token whenever it changes.
     */
    fun observeToken(): Flow<String?>
    
    /**
     * Delete the stored token (e.g., on logout).
     */
    suspend fun deleteToken(): Result<Boolean>
    
    /**
     * Check if a token exists and is valid.
     */
    suspend fun hasToken(): Boolean
}