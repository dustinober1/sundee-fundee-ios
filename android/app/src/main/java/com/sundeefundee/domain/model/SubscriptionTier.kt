package com.sundeefundee.domain.model

enum class SubscriptionTier(val displayName: String, val rank: Int) {
    FREE("Free", 0),
    PLUS("Plus", 1),
    PREMIUM("Premium", 2);
    
    companion object {
        // Product IDs matching iOS App Store
        const val PLUS_MONTHLY = "com.sundeefundee.sub.plus.monthly"
        const val PLUS_ANNUAL = "com.sundeefundee.sub.plus.annual"
        const val PREMIUM_MONTHLY = "com.sundeefundee.sub.premium.monthly"
        const val PREMIUM_ANNUAL = "com.sundeefundee.sub.premium.annual"
        
        fun fromProductID(productId: String): SubscriptionTier = when {
            productId.contains("premium") -> PREMIUM
            productId.contains("plus") -> PLUS
            else -> FREE
        }
    }
}
