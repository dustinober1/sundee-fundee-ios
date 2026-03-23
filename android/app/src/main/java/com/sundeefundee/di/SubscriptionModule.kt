package com.sundeefundee.di

import android.content.Context
import com.sundeefundee.data.remote.BillingService
import com.sundeefundee.data.remote.BillingServiceImpl
import com.sundeefundee.data.repository.SubscriptionRepositoryImpl
import com.sundeefundee.domain.repository.SubscriptionRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object SubscriptionModule {
    
    @Provides
    @Singleton
    fun provideBillingService(
        @ApplicationContext context: Context
    ): BillingService = BillingServiceImpl(context)
    
    @Provides
    @Singleton
    fun provideSubscriptionRepository(
        billingService: BillingService
    ): SubscriptionRepository = SubscriptionRepositoryImpl(billingService)
}
