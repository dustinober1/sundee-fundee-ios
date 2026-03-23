package com.sundeefundee.domain.repository

import android.app.Activity
import com.android.billingclient.api.ProductDetails
import com.sundeefundee.domain.model.SubscriptionTier
import kotlinx.coroutines.flow.StateFlow

interface SubscriptionRepository {
    val currentTier: StateFlow<SubscriptionTier>
    val availableProducts: StateFlow<List<ProductDetails>>
    val purchaseInProgress: StateFlow<Boolean>
    val errorMessage: StateFlow<String?>
    
    suspend fun loadProducts()
    suspend fun purchase(product: ProductDetails, activity: Activity)
    suspend fun restorePurchases()
    fun refreshCurrentTier()
}
