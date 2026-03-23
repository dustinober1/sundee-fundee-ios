package com.sundeefundee.domain.model

enum class Feature {
    AI_WORKOUT_GENERATION,
    ADVANCED_ANALYTICS,
    UNLIMITED_PROGRAMS,
    PRIORITY_SUPPORT
}

object EntitlementChecker {
    fun hasAccess(tier: SubscriptionTier, feature: Feature): Boolean {
        return when (feature) {
            Feature.AI_WORKOUT_GENERATION -> tier.rank >= SubscriptionTier.PLUS.rank
            Feature.ADVANCED_ANALYTICS -> tier.rank >= SubscriptionTier.PLUS.rank
            Feature.UNLIMITED_PROGRAMS -> tier.rank >= SubscriptionTier.PREMIUM.rank
            Feature.PRIORITY_SUPPORT -> tier.rank >= SubscriptionTier.PREMIUM.rank
        }
    }
    
    fun getFeatureName(feature: Feature): String {
        return when (feature) {
            Feature.AI_WORKOUT_GENERATION -> "AI Workout Generation"
            Feature.ADVANCED_ANALYTICS -> "Advanced Analytics"
            Feature.UNLIMITED_PROGRAMS -> "Unlimited Programs"
            Feature.PRIORITY_SUPPORT -> "Priority Support"
        }
    }
    
    fun getFeatureDescription(feature: Feature): String {
        return when (feature) {
            Feature.AI_WORKOUT_GENERATION -> "Generate personalized workouts with AI"
            Feature.ADVANCED_ANALYTICS -> "Deep insights into your performance"
            Feature.UNLIMITED_PROGRAMS -> "Access to all training programs"
            Feature.PRIORITY_SUPPORT -> "Get help when you need it most"
        }
    }
    
    fun getRequiredTier(feature: Feature): SubscriptionTier {
        return when (feature) {
            Feature.AI_WORKOUT_GENERATION -> SubscriptionTier.PLUS
            Feature.ADVANCED_ANALYTICS -> SubscriptionTier.PLUS
            Feature.UNLIMITED_PROGRAMS -> SubscriptionTier.PREMIUM
            Feature.PRIORITY_SUPPORT -> SubscriptionTier.PREMIUM
        }
    }
}
