package com.sundeefundee.ui.features.subscription

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.android.billingclient.api.ProductDetails
import com.sundeefundee.domain.model.SubscriptionTier
import com.sundeefundee.domain.repository.SubscriptionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SubscriptionViewModel @Inject constructor(
    private val subscriptionRepository: SubscriptionRepository
) : ViewModel() {
    
    val currentTier = subscriptionRepository.currentTier
    val availableProducts = subscriptionRepository.availableProducts
    val purchaseInProgress = subscriptionRepository.purchaseInProgress
    val errorMessage = subscriptionRepository.errorMessage
    
    private val _showPaywall = MutableStateFlow(false)
    val showPaywall: StateFlow<Boolean> = _showPaywall.asStateFlow()
    
    private val _selectedBillingPeriod = MutableStateFlow(BillingPeriod.MONTHLY)
    val selectedBillingPeriod: StateFlow<BillingPeriod> = _selectedBillingPeriod.asStateFlow()
    
    val plusProducts: StateFlow<List<ProductDetails>> = availableProducts
        .map { products -> products.filter { it.productId.contains("plus") } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    
    val premiumProducts: StateFlow<List<ProductDetails>> = availableProducts
        .map { products -> products.filter { it.productId.contains("premium") } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    
    fun loadProducts() {
        viewModelScope.launch {
            subscriptionRepository.loadProducts()
        }
    }
    
    fun purchase(product: ProductDetails, activity: Activity) {
        viewModelScope.launch {
            subscriptionRepository.purchase(product, activity)
        }
    }
    
    fun restorePurchases() {
        viewModelScope.launch {
            subscriptionRepository.restorePurchases()
        }
    }
    
    fun selectBillingPeriod(period: BillingPeriod) {
        _selectedBillingPeriod.value = period
    }
    
    fun showPaywall() {
        _showPaywall.value = true
    }
    
    fun dismissPaywall() {
        _showPaywall.value = false
    }
    
    fun clearError() {
        // Error is cleared when repository state changes
    }
    
    fun getPlusProducts(): List<ProductDetails> {
        return availableProducts.value.filter { it.productId.contains("plus") }
    }
    
    fun getPremiumProducts(): List<ProductDetails> {
        return availableProducts.value.filter { it.productId.contains("premium") }
    }
    
    fun getSelectedPlusProduct(): ProductDetails? {
        val period = _selectedBillingPeriod.value
        return plusProducts.value.find {
            when (period) {
                BillingPeriod.MONTHLY -> it.productId.contains("monthly")
                BillingPeriod.ANNUAL -> it.productId.contains("annual")
            }
        }
    }
    
    fun getSelectedPremiumProduct(): ProductDetails? {
        val period = _selectedBillingPeriod.value
        return premiumProducts.value.find {
            when (period) {
                BillingPeriod.MONTHLY -> it.productId.contains("monthly")
                BillingPeriod.ANNUAL -> it.productId.contains("annual")
            }
        }
    }
}

enum class BillingPeriod {
    MONTHLY,
    ANNUAL
}
