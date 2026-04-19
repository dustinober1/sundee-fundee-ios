package com.sundeefundee.app.di

import com.sundeefundee.core.data.protocol.DataClient
import com.sundeefundee.core.data.protocol.HealthClient
import com.sundeefundee.core.data.room.RoomDataClient
import com.sundeefundee.core.data.healthconnect.HealthConnectClientWrapper
import com.sundeefundee.core.data.supabase.SupabaseDataClient
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class DataModule {

    // Default binding is Room (guest mode). Supabase binding is swapped at runtime
    // when user signs in via DataClientFactory.
    // TODO: Bind SupabaseDataClient when Supabase is configured.
}
