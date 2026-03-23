package com.sundeefundee.di

import android.content.Context
import com.sundeefundee.data.remote.GoogleSignInService
import com.sundeefundee.data.repository.AuthRepositoryImpl
import com.sundeefundee.domain.repository.AuthRepository
import com.sundeefundee.domain.repository.UserRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AuthModule {

    @Provides
    @Singleton
    fun provideGoogleSignInService(
        @ApplicationContext context: Context
    ): GoogleSignInService = GoogleSignInService(context)

    @Provides
    @Singleton
    fun provideAuthRepository(
        googleSignInService: GoogleSignInService,
        userRepository: UserRepository
    ): AuthRepository = AuthRepositoryImpl(googleSignInService, userRepository)
}
