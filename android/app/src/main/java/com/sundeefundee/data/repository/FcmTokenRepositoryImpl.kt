package com.sundeefundee.data.repository

import android.content.Context
import android.content.SharedPreferences
import com.google.firebase.firestore.FirebaseFirestore
import com.sundeefundee.domain.repository.AuthRepository
import com.sundeefundee.domain.repository.FcmTokenRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FcmTokenRepositoryImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val authRepository: AuthRepository
) : FcmTokenRepository {

    private val firestore = FirebaseFirestore.getInstance()
    private val prefs: SharedPreferences = context.getSharedPreferences(
        PREFS_NAME,
        Context.MODE_PRIVATE
    )

    override suspend fun saveToken(token: String): Result<Boolean> {
        return try {
            val userId = authRepository.getCurrentUserId()
                ?: return Result.failure(Exception("User not authenticated"))
            
            // Save to Firestore
            val userRef = firestore.collection("users").document(userId)
            userRef.update("fcmToken", token).await()
            
            // Cache locally
            prefs.edit().putString(KEY_FCM_TOKEN, token).apply()
            
            Result.success(true)
        } catch (e: Exception) {
            // If Firestore fails, at least save locally
            prefs.edit().putString(KEY_FCM_TOKEN, token).apply()
            Result.failure(e)
        }
    }

    override suspend fun getToken(): String? {
        // First check local cache
        val cachedToken = prefs.getString(KEY_FCM_TOKEN, null)
        if (cachedToken != null) {
            return cachedToken
        }
        
        // If not cached, try to get from Firestore
        return try {
            val userId = authRepository.getCurrentUserId() ?: return null
            val userRef = firestore.collection("users").document(userId)
            val snapshot = userRef.get().await()
            val token = snapshot.getString("fcmToken")
            
            // Cache the token
            token?.let { prefs.edit().putString(KEY_FCM_TOKEN, it).apply() }
            
            token
        } catch (e: Exception) {
            null
        }
    }

    override fun observeToken(): Flow<String?> = callbackFlow {
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key == KEY_FCM_TOKEN) {
                val token = prefs.getString(KEY_FCM_TOKEN, null)
                trySend(token)
            }
        }
        
        prefs.registerOnSharedPreferenceChangeListener(listener)
        
        // Emit current value
        trySend(prefs.getString(KEY_FCM_TOKEN, null))
        
        awaitClose {
            prefs.unregisterOnSharedPreferenceChangeListener(listener)
        }
    }

    override suspend fun deleteToken(): Result<Boolean> {
        return try {
            val userId = authRepository.getCurrentUserId()
                ?: return Result.failure(Exception("User not authenticated"))
            
            // Remove from Firestore
            val userRef = firestore.collection("users").document(userId)
            userRef.update("fcmToken", com.google.firebase.firestore.FieldValue.delete()).await()
            
            // Remove local cache
            prefs.edit().remove(KEY_FCM_TOKEN).apply()
            
            Result.success(true)
        } catch (e: Exception) {
            // If Firestore fails, at least remove locally
            prefs.edit().remove(KEY_FCM_TOKEN).apply()
            Result.failure(e)
        }
    }

    override suspend fun hasToken(): Boolean {
        return prefs.getString(KEY_FCM_TOKEN, null) != null
    }

    companion object {
        private const val PREFS_NAME = "fcm_prefs"
        private const val KEY_FCM_TOKEN = "fcm_token"
    }
}