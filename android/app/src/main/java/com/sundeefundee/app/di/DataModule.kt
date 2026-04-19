package com.sundeefundee.app.di

import android.content.Context
import androidx.room.Room
import com.sundeefundee.core.data.room.SundeeFundeeDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DataModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): SundeeFundeeDatabase {
        return Room.databaseBuilder(
            context,
            SundeeFundeeDatabase::class.java,
            "sundeefundee.db"
        ).build()
    }
}
