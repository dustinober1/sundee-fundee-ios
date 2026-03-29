import type { SubscriptionTier } from "./types";

// ---------------------------------------------------------------------------
// Tier metadata
// ---------------------------------------------------------------------------

export function tierDisplayName(tier: SubscriptionTier): string {
  switch (tier) {
    case "free":    return "Free";
    case "plus":    return "Sundee Plus";
    case "premium": return "Sundee Premium";
  }
}

export function tierValueProposition(tier: SubscriptionTier): string {
  switch (tier) {
    case "free":    return "Unlimited on-device AI workouts";
    case "plus":    return "Cloud-powered AI workouts and programming tools";
    case "premium": return "Personal AI coach that learns and adapts";
  }
}

export function tierRank(tier: SubscriptionTier): number {
  switch (tier) {
    case "free":    return 0;
    case "plus":    return 1;
    case "premium": return 2;
  }
}

// ---------------------------------------------------------------------------
// Gated Features
// ---------------------------------------------------------------------------

/** Features that require at least a Plus subscription. */
export const PLUS_FEATURES = [
  "customBenchmarks",
  "painTrends",
  "effortTrends",
  "unlimitedLifts",
  "unlimitedInjuries",
  "unlimitedHistory",
  "programBuilder",
  "periodizationTemplates",
  "autoDeload",
  "advancedAnalytics",
  "streaksAchievements",
] as const;

/** Features that require at least a Premium subscription. */
export const PREMIUM_FEATURES = [
  "rehabSessions",
  "aiWorkoutHistory",
  "exportData",
  "aiCoachMemory",
  "mesocyclePlans",
  "progressiveOverload",
  "plateauDetection",
  "weeklyReports",
  "smartSubstitutions",
] as const;

export type GatedFeature =
  | (typeof PLUS_FEATURES)[number]
  | (typeof PREMIUM_FEATURES)[number];

const _plusFeatureSet = new Set<string>(PLUS_FEATURES);
const _premiumFeatureSet = new Set<string>(PREMIUM_FEATURES);

export function minimumTierRequired(feature: GatedFeature): SubscriptionTier {
  if (_plusFeatureSet.has(feature)) return "plus";
  if (_premiumFeatureSet.has(feature)) return "premium";
  return "free";
}

/**
 * Returns true when `tier` has access to `feature`.
 * Access is granted when the user's tier rank >= the minimum tier rank.
 */
export function canAccess(
  feature: GatedFeature,
  tier: SubscriptionTier
): boolean {
  return tierRank(tier) >= tierRank(minimumTierRequired(feature));
}

// ---------------------------------------------------------------------------
// Tracking Limits
// ---------------------------------------------------------------------------

/**
 * Maximum number of lifts the user may track, or null for unlimited.
 */
export function maxTrackedLifts(tier: SubscriptionTier): number | null {
  switch (tier) {
    case "free":    return 5;
    case "plus":    return null;
    case "premium": return null;
  }
}

/**
 * Maximum number of active injury profiles, or null for unlimited.
 */
export function maxActiveInjuries(tier: SubscriptionTier): number | null {
  switch (tier) {
    case "free":    return 1;
    case "plus":    return null;
    case "premium": return null;
  }
}

/**
 * Maximum workout history in days, or null for unlimited.
 */
export function workoutHistoryDaysLimit(tier: SubscriptionTier): number | null {
  switch (tier) {
    case "free":    return 30;
    case "plus":    return null;
    case "premium": return null;
  }
}

// ---------------------------------------------------------------------------
// AI Workout Limits
// ---------------------------------------------------------------------------

/** Maximum cloud AI generations per day. 0 means no cloud access. */
export function dailyCloudAILimit(tier: SubscriptionTier): number {
  switch (tier) {
    case "free":    return 0;
    case "plus":    return 1;
    case "premium": return 10;
  }
}

/** Whether the user can generate another cloud AI workout today. */
export function canGenerateCloud(
  tier: SubscriptionTier,
  generatedToday: number
): boolean {
  const limit = dailyCloudAILimit(tier);
  if (limit === 0) return false;
  return generatedToday < limit;
}

/** Soft nudge threshold for Premium users (show "try editing" message). */
export const PREMIUM_SOFT_NUDGE_THRESHOLD = 7;

/**
 * Whether to show a soft nudge to Premium users who have generated many
 * workouts today, suggesting they edit rather than regenerate.
 */
export function shouldShowSoftNudge(
  tier: SubscriptionTier,
  generatedToday: number
): boolean {
  return tier === "premium" && generatedToday >= PREMIUM_SOFT_NUDGE_THRESHOLD;
}

// ---------------------------------------------------------------------------
// Downgrade Policy
// ---------------------------------------------------------------------------

/**
 * Users always retain read access to data created during a higher tier.
 */
export function canViewExistingData(
  _feature: GatedFeature,
  _currentTier: SubscriptionTier
): boolean {
  return true;
}

/**
 * Creating new content for a feature requires the feature to be accessible
 * at the current tier.
 */
export function canCreateNew(
  feature: GatedFeature,
  currentTier: SubscriptionTier
): boolean {
  return canAccess(feature, currentTier);
}

/**
 * Users can always delete their own data regardless of subscription tier.
 */
export function canDeleteOwnData(_currentTier: SubscriptionTier): boolean {
  return true;
}
