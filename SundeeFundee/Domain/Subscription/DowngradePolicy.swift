import Foundation

/// Pure-logic downgrade behavior rules. No framework dependencies.
/// Policy: users retain read-only access to all data created during a paid subscription.
/// Only creation of new premium content is blocked on downgrade.
enum DowngradePolicy {

    /// Whether a downgraded user can still view data created during a higher tier.
    /// All existing data remains visible regardless of current tier.
    static func canViewExistingData(feature: GatedFeature, currentTier: SubscriptionTier) -> Bool {
        true
    }

    /// Whether the user can create new content for a given feature at their current tier.
    static func canCreateNew(feature: GatedFeature, currentTier: SubscriptionTier) -> Bool {
        FeatureEntitlement.canAccess(feature: feature, tier: currentTier)
    }

    /// Users can always delete their own data regardless of tier.
    static func canDeleteOwnData(currentTier: SubscriptionTier) -> Bool {
        true
    }
}
