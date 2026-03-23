package com.sundeefundee.data.repository

import android.app.Activity
import com.android.billingclient.api.ProductDetails
import com.sundeefundee.data.remote.BillingService
import com.sundeefundee.domain.model.SubscriptionTier
import com.sundeefundee.domain.repository.SubscriptionRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SubscriptionRepositoryImpl @Inject constructor(
    private val billingService: BillingService
) : SubscriptionRepository {
    
    private val _currentTier = MutableStateFlow(SubscriptionTier.FREE)
    override val currentTier: StateFlow<SubscriptionTier> = _currentTier.asStateFlow()
    
    private val _availableProducts = MutableStateFlow<List<ProductDetails>>(emptyList())
    override val availableProducts: StateFlow<List<ProductDetails>> = _availableProducts.asStateFlow()
    
    private val _purchaseInProgress = MutableStateFlow(false)
    override val purchaseInProgress: StateFlow<Boolean> = _purchaseInProgress.asStateFlow()
    
    private val _errorMessage = MutableStateFlow<String?>(null)
    override val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()
    
    init {
        refreshCurrentTier()
    }
    
    override suspend fun loadProducts() {
        _errorMessage.value = null
        billingService.loadProducts()
            .onSuccess { products ->
                _availableProducts.value = products
            }
            .onFailure { error ->
                _errorMessage.value = error.message ?: "Failed to load subscription products"
            }
    }
    
    override suspend fun purchase(product: ProductDetails, activity: Activity) {
        _purchaseInProgress.value = true
        _errorMessage.value = null
        
        billingService.purchase(product, activity)
            .onSuccess { purchase ->
                // Update tier based on purchase
                val productId = purchase.products.firstOrNull() ?: ""
                _currentTier.value = SubscriptionTier.fromProductID(productId)
            }
            .onFailure { error ->
                _errorMessage.value = error.message ?: "Purchase failed"
            }
            .also {
                _purchaseInProgress.value = false
            }
    }
    
    override suspend fun restorePurchases() {
        _purchaseInProgress.value = true
        _errorMessage.value = null
        
        billingService.restorePurchases()
            .onSuccess { purchases ->
                if (purchases.isEmpty()) {
                    _currentTier.value = SubscriptionTier.FREE
                } else {
                    // Get the highest tier from active purchases
                    val highestTier = purchases
                        .flatMap { it.products }
                        .map { SubscriptionTier.fromProductID(it) }
                        .maxByOrNull { it.rank } ?: SubscriptionTier.FREE
                    _currentTier.value = highestTier
                }
            }
            .onFailure { error ->
                _errorMessage.value = error.message ?: "Failed to restore purchases"
            }
            .also {
                _purchaseInProgress.value = false
            }
    }
    
    override fun refreshCurrentTier() {
        // This would typically be called on app start or when user authenticates
        // For now, we default to FREE and update when purchases are restored
    }
}
