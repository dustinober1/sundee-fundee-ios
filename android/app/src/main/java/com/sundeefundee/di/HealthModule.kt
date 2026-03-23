package com.sundeefundee.di

import android.content.Context
import com.sundeefundee.data.remote.HealthConnectService
import com.sundeefundee.data.remote.HealthConnectServiceImpl
import com.sundeefundee.domain.repository.HealthRepository
import com.sundeefundee.domain.usecase.CalculateReadinessUseCase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for Health Connect dependencies.
 * 
 * Note: Health Connect may not be available on all devices or may not be installed.
 * This module handles the optional nature of Health Connect by returning null
 * when it's not available.
 */
@Module
@InstallIn(SingletonComponent::class)
object HealthModule {
    
    /**
     * Provides HealthConnectService instance.
     * 
     * Returns null if Health Connect is not available on the device
     * or if the Health Connect SDK is not installed.
     * 
     * @param context Application context
     * @return HealthConnectService instance or null
     */
    @Provides
    @Singleton
    fun provideHealthConnectService(
        @ApplicationContext context: Context
    ): HealthConnectService? {
        return try {
            HealthConnectServiceImpl(context)
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * Provides CalculateReadinessUseCase.
     * 
     * Takes optional HealthConnectService since Health Connect
     * may not be available on all devices.
     * 
     * @param healthConnectService Optional Health Connect service
     * @return CalculateReadinessUseCase instance
     */
    @Provides
    @Singleton
    fun provideCalculateReadinessUseCase(
        healthConnectService: HealthConnectService?
    ): CalculateReadinessUseCase {
        return CalculateReadinessUseCase(healthConnectService)
    }
}
