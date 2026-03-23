package com.sundeefundee.di

import android.content.Context
import com.sundeefundee.data.remote.NotificationService
import com.sundeefundee.data.remote.NotificationServiceImpl
import com.sundeefundee.data.remote.WorkoutReminderScheduler
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NotificationModule {

    @Provides
    @Singleton
    fun provideNotificationService(
        @ApplicationContext context: Context
    ): NotificationService = NotificationServiceImpl(context)

    @Provides
    @Singleton
    fun provideWorkoutReminderScheduler(
        @ApplicationContext context: Context
    ): WorkoutReminderScheduler = WorkoutReminderScheduler(context)
}