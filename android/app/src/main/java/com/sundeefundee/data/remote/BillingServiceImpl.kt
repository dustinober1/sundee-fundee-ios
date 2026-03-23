package com.sundeefundee.data.remote

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.ProductDetailsResponseListener
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchaseHistoryResponseListener
import com.android.billingclient.api.PurchasesResponseListener
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.sundeefundee.domain.model.SubscriptionTier
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

@Singleton
class BillingServiceImpl @Inject constructor(
    private val context: Context
) : BillingService, PurchasesUpdatedListener {
    
    private var billingClient: BillingClient? = null
    
    private val productIds = listOf(
        SubscriptionTier.PLUS_MONTHLY,
        SubscriptionTier.PLUS_ANNUAL,
        SubscriptionTier.PREMIUM_MONTHLY,
        SubscriptionTier.PREMIUM_ANNUAL
    )
    
    init {
        billingClient = createBillingClient()
    }
    
    private fun createBillingClient(): BillingClient {
        return BillingClient.newBuilder(context)
            .setListener(this)
            .enablePendingPurchases()
            .build()
    }
    
    override fun getBillingClient(): BillingClient {
        return billingClient ?: throw IllegalStateException("BillingClient not initialized")
    }
    
    override suspend fun loadProducts(): Result<List<ProductDetails>> = suspendCancellableCoroutine { continuation ->
        ensureBillingClientConnected { connected ->
            if (!connected) {
                continuation.resume(Result.failure(Exception("Failed to connect to Google Play")))
                return@suspendCancellableCoroutine
            }
            
            val productDetailsParams = QueryProductDetailsParams.newBuilder()
                .setProductList(
                    productIds.map { productId ->
                        QueryProductDetailsParams.Product.newBuilder()
                            .setProductId(productId)
                            .setProductType(BillingClient.ProductType.SUBS)
                            .build()
                    }
                )
                .build()
            
            billingClient?.queryProductDetailsAsync(
                productDetailsParams,
                object : ProductDetailsResponseListener {
                    override fun onProductDetailsResponse(
                        billingResult: BillingResult,
                        productDetailsList: MutableList<ProductDetails>
                    ) {
                        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                            continuation.resume(Result.success(productDetailsList))
                        } else {
                            continuation.resume(
                                Result.failure(
                                    Exception("Failed to load products: ${billingResult.debugMessage}")
                                )
                            )
                        }
                    }
                }
            )
        }
    }
    
    override suspend fun purchase(
        product: ProductDetails,
        activity: Activity
    ): Result<Purchase> = suspendCancellableCoroutine { continuation ->
        ensureBillingClientConnected { connected ->
            if (!connected) {
                continuation.resume(Result.failure(Exception("Failed to connect to Google Play")))
                return@suspendCancellableCoroutine
            }
            
            val productDetailsParamsList = listOf(
                BillingFlowParams.ProductDetailsParams.newBuilder()
                    .setProductDetails(product)
                    .build()
            )
            
            val billingFlowParams = BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(productDetailsParamsList)
                .build()
            
            val billingResult = billingClient?.launchBillingFlow(activity, billingFlowParams)
            
            if (billingResult == null) {
                continuation.resume(Result.failure(Exception("Failed to launch billing flow")))
                return@suspendCancellableCoroutine
            }
            
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                continuation.resume(
                    Result.failure(Exception("Billing flow failed: ${billingResult.debugMessage}"))
                )
            }
            // The actual result will come through onPurchasesUpdated
        }
    }
    
    override suspend fun getPurchases(): Result<List<Purchase>> = suspendCancellableCoroutine { continuation ->
        ensureBillingClientConnected { connected ->
            if (!connected) {
                continuation.resume(Result.failure(Exception("Failed to connect to Google Play")))
                return@suspendCancellableCoroutine
            }
            
            billingClient?.queryPurchasesAsync(
                QueryPurchasesParams.newBuilder()
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build(),
                object : PurchasesResponseListener {
                    override fun onQueryPurchasesResponse(
                        billingResult: BillingResult,
                        purchases: MutableList<Purchase>
                    ) {
                        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                            continuation.resume(Result.success(purchases))
                        } else {
                            continuation.resume(
                                Result.failure(
                                    Exception("Failed to get purchases: ${billingResult.debugMessage}")
                                )
                            )
                        }
                    }
                }
            )
        }
    }
    
    override suspend fun restorePurchases(): Result<List<Purchase>> = getPurchases()
    
    private fun ensureBillingClientConnected(onConnected: (Boolean) -> Unit) {
        val client = billingClient
        if (client == null) {
            onConnected(false)
            return
        }
        
        if (client.isReady) {
            onConnected(true)
            return
        }
        
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                onConnected(billingResult.responseCode == BillingClient.BillingResponseCode.OK)
            }
            
            override fun onBillingServiceDisconnected() {
                onConnected(false)
            }
        })
    }
    
    override fun onPurchasesUpdated(
        billingResult: BillingResult,
        purchases: MutableList<Purchase>?
    ) {
        // This is called from the BillingClient listener
        // In a real implementation, you would use a Flow or callback to communicate results
        // For now, we handle acknowledge here
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            purchases.forEach { purchase ->
                if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED && !purchase.isAcknowledged) {
                    acknowledgePurchase(purchase)
                }
            }
        }
    }
    
    private fun acknowledgePurchase(purchase: Purchase) {
        val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()
        
        billingClient?.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
            if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                // Log error but don't fail - the purchase is still valid
            }
        }
    }
    
    /**
     * Convert ProductDetails to our simplified Product model
     */
    fun convertToProduct(productDetails: ProductDetails): Product {
        val subscriptionOfferDetails = productDetails.subscriptionOfferDetails?.firstOrNull()
        
        return Product(
            id = productDetails.productId,
            title = productDetails.title,
            description = productDetails.description,
            price = subscriptionOfferDetails?.formattedPrice ?: "N/A",
            priceAmountMicros = subscriptionOfferDetails?.pricingPhases?.pricingPhase?.firstOrNull()?.priceAmountMicros ?: 0,
            priceCurrencyCode = subscriptionOfferDetails?.pricingPhases?.pricingPhase?.firstOrNull()?.priceCurrencyCode ?: "USD",
            type = ProductType.SUBSCRIPTION,
            subscriptionPeriod = subscriptionOfferDetails?.subscriptionPeriod,
            annualPrice = null, // Would need to parse from annual offer if available
            annualPriceAmountMicros = null,
            annualSubscriptionPeriod = null
        )
    }
}
