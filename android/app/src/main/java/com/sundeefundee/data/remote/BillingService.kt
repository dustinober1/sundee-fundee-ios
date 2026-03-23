package com.sundeefundee.data.remote

import android.app.Activity
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase

interface BillingService {
    suspend fun loadProducts(): Result<List<ProductDetails>>
    suspend fun purchase(product: ProductDetails, activity: Activity): Result<Purchase>
    suspend fun getPurchases(): Result<List<Purchase>>
    suspend fun restorePurchases(): Result<List<Purchase>>
    fun getBillingClient(): BillingClient
}

/**
 * Simplified product representation for subscription products
 */
data class Product(
    val id: String,
    val title: String,
    val description: String,
    val price: String,
    val priceAmountMicros: Long,
    val priceCurrencyCode: String,
    val type: ProductType,
    val subscriptionPeriod: String? = null,
    val annualPrice: String? = null,
    val annualPriceAmountMicros: Long? = null,
    val annualSubscriptionPeriod: String? = null
)

enum class ProductType {
    SUBSCRIPTION
}
