package com.sundeefundee.core.auth

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

// Encrypted session storage — mirrors iOS KeychainHelper
@Singleton
class SessionManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        "sundee_fundee_session",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    companion object {
        private const val KEY_USER_ID = "user_id"
        private const val KEY_USER_EMAIL = "user_email"
        private const val KEY_USER_NAME = "user_name"
        private const val KEY_IS_GUEST = "is_guest"
        private const val KEY_ONBOARDING_COMPLETE = "onboarding_complete"
        const val GUEST_USER_ID = "guest_local"
    }

    var userId: String?
        get() = prefs.getString(KEY_USER_ID, null)
        set(value) = prefs.edit().putString(KEY_USER_ID, value).apply()

    var userEmail: String?
        get() = prefs.getString(KEY_USER_EMAIL, null)
        set(value) = prefs.edit().putString(KEY_USER_EMAIL, value).apply()

    var userName: String?
        get() = prefs.getString(KEY_USER_NAME, null)
        set(value) = prefs.edit().putString(KEY_USER_NAME, value).apply()

    var isGuest: Boolean
        get() = prefs.getBoolean(KEY_IS_GUEST, false)
        set(value) = prefs.edit().putBoolean(KEY_IS_GUEST, value).apply()

    var isOnboardingComplete: Boolean
        get() = prefs.getBoolean(KEY_ONBOARDING_COMPLETE, false)
        set(value) = prefs.edit().putBoolean(KEY_ONBOARDING_COMPLETE, value).apply()

    val isAuthenticated: Boolean
        get() = userId != null || isGuest

    fun saveSession(userId: String, email: String?, name: String?) {
        prefs.edit()
            .putString(KEY_USER_ID, userId)
            .putString(KEY_USER_EMAIL, email)
            .putString(KEY_USER_NAME, name)
            .putBoolean(KEY_IS_GUEST, false)
            .apply()
    }

    fun saveGuestSession() {
        prefs.edit()
            .putString(KEY_USER_ID, GUEST_USER_ID)
            .putBoolean(KEY_IS_GUEST, true)
            .apply()
    }

    fun clearSession() {
        prefs.edit().clear().apply()
    }
}
