import type { Timestamp } from "firebase-admin/firestore";
import { adminDoc } from "./admin-firestore";
import { db } from "./firebase-admin";
import {
  dailyCloudAILimit,
  tierDisplayName,
  tierRank,
  tierValueProposition,
  type GatedFeature,
  canAccess,
} from "./domain";
import type { SubscriptionTier } from "./domain";

export type SubscriptionStatus =
  | "active"
  | "canceled"
  | "past_due"
  | "incomplete"
  | "trialing"
  | "unpaid";

export interface SubscriptionRecord {
  tier: SubscriptionTier;
  status: SubscriptionStatus;
  stripeCustomerId?: string;
  stripeSubscriptionId?: string;
  currentPeriodEnd: Date | null;
  cancelAtPeriodEnd: boolean;
  createdAt: Date | null;
  updatedAt: Date | null;
}

export interface AIUsageSnapshot {
  date: string;
  count: number;
  updatedAt: Date | null;
}

export interface ResolvedEntitlement {
  subscription: SubscriptionRecord;
  tier: SubscriptionTier;
  status: SubscriptionStatus;
  hasActivePaidAccess: boolean;
  dailyCloudLimit: number;
  generatedToday: number;
  remainingCloudGenerations: number;
  canUseCloudAI: boolean;
}

const DEFAULT_SUBSCRIPTION: SubscriptionRecord = {
  tier: "free",
  status: "canceled",
  currentPeriodEnd: null,
  cancelAtPeriodEnd: false,
  createdAt: null,
  updatedAt: null,
};

function toDate(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value === "object" && value !== null && "toDate" in value && typeof (value as Timestamp).toDate === "function") {
    return (value as Timestamp).toDate();
  }
  if (typeof value === "string" || typeof value === "number") {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  return null;
}

export function normalizeSubscriptionRecord(raw: unknown): SubscriptionRecord {
  const data = (raw ?? {}) as Record<string, unknown>;
  const tier = data.tier === "plus" || data.tier === "premium" ? data.tier : "free";
  const statusValues: SubscriptionStatus[] = [
    "active",
    "canceled",
    "past_due",
    "incomplete",
    "trialing",
    "unpaid",
  ];
  const status = statusValues.includes(data.status as SubscriptionStatus)
    ? (data.status as SubscriptionStatus)
    : tier === "free"
      ? "canceled"
      : "incomplete";

  return {
    tier,
    status,
    stripeCustomerId: typeof data.stripeCustomerId === "string" ? data.stripeCustomerId : undefined,
    stripeSubscriptionId: typeof data.stripeSubscriptionId === "string" ? data.stripeSubscriptionId : undefined,
    currentPeriodEnd: toDate(data.currentPeriodEnd),
    cancelAtPeriodEnd: data.cancelAtPeriodEnd === true,
    createdAt: toDate(data.createdAt),
    updatedAt: toDate(data.updatedAt),
  };
}

export function isSubscriptionInGracePeriod(subscription: SubscriptionRecord, now: Date = new Date()): boolean {
  if (!subscription.currentPeriodEnd) return false;
  if (subscription.currentPeriodEnd.getTime() <= now.getTime()) return false;
  return subscription.status === "canceled" || subscription.status === "past_due";
}

export function hasActivePaidAccess(subscription: SubscriptionRecord, now: Date = new Date()): boolean {
  if (tierRank(subscription.tier) < tierRank("plus")) return false;
  if (subscription.status === "active" || subscription.status === "trialing") return true;
  return isSubscriptionInGracePeriod(subscription, now);
}

export async function getRateLimitOverrides(): Promise<Partial<Record<SubscriptionTier, number>>> {
  try {
    const doc = await adminDoc("adminSettings", "config").get();
    if (!doc.exists) return {};
    const limits = doc.data()?.rateLimits as Record<string, unknown> | undefined;
    return {
      free: typeof limits?.free === "number" ? limits.free : undefined,
      plus: typeof limits?.plus === "number" ? limits.plus : undefined,
      premium: typeof limits?.premium === "number" ? limits.premium : undefined,
    };
  } catch {
    return {};
  }
}

export async function getDailyCloudLimitForTier(tier: SubscriptionTier): Promise<number> {
  const overrides = await getRateLimitOverrides();
  return overrides[tier] ?? dailyCloudAILimit(tier);
}

export async function getSubscriptionRecord(uid: string): Promise<SubscriptionRecord> {
  const doc = await db.collection("users").doc(uid).collection("subscription").doc("current").get();
  if (!doc.exists) return DEFAULT_SUBSCRIPTION;
  return normalizeSubscriptionRecord(doc.data());
}

export function getUsageDateKey(date: Date = new Date()): string {
  return date.toISOString().split("T")[0] ?? "";
}

export async function getDailyAIUsage(uid: string, date: Date = new Date()): Promise<AIUsageSnapshot> {
  const dateKey = getUsageDateKey(date);
  const usageDoc = await db.collection("users").doc(uid).collection("aiUsage").doc(dateKey).get();
  const data = usageDoc.data() as Record<string, unknown> | undefined;
  return {
    date: dateKey,
    count: typeof data?.count === "number" ? data.count : 0,
    updatedAt: toDate(data?.updatedAt),
  };
}

export async function incrementDailyAIUsage(uid: string, date: Date = new Date()): Promise<AIUsageSnapshot> {
  const snapshot = await getDailyAIUsage(uid, date);
  const nextCount = snapshot.count + 1;
  await db.collection("users").doc(uid).collection("aiUsage").doc(snapshot.date).set(
    {
      count: nextCount,
      updatedAt: new Date(),
    },
    { merge: true }
  );
  return { ...snapshot, count: nextCount, updatedAt: new Date() };
}

export async function resolveEntitlement(uid: string, date: Date = new Date()): Promise<ResolvedEntitlement> {
  const [subscription, usage] = await Promise.all([
    getSubscriptionRecord(uid),
    getDailyAIUsage(uid, date),
  ]);
  const paidAccess = hasActivePaidAccess(subscription, date);
  const effectiveTier: SubscriptionTier = paidAccess ? subscription.tier : "free";
  const limit = paidAccess ? await getDailyCloudLimitForTier(effectiveTier) : 0;
  const remaining = Math.max(0, limit - usage.count);

  return {
    subscription,
    tier: effectiveTier,
    status: subscription.status,
    hasActivePaidAccess: paidAccess,
    dailyCloudLimit: limit,
    generatedToday: usage.count,
    remainingCloudGenerations: remaining,
    canUseCloudAI: limit > 0 && usage.count < limit,
  };
}

export function serializeSubscriptionRecord(subscription: SubscriptionRecord) {
  return {
    ...subscription,
    currentPeriodEnd: subscription.currentPeriodEnd?.toISOString() ?? null,
    createdAt: subscription.createdAt?.toISOString() ?? null,
    updatedAt: subscription.updatedAt?.toISOString() ?? null,
  };
}

export function subscriptionMarketingCopy(tier: SubscriptionTier) {
  return {
    displayName: tierDisplayName(tier),
    valueProposition: tierValueProposition(tier),
  };
}

export function featureGateState(feature: GatedFeature, tier: SubscriptionTier) {
  return {
    feature,
    minimumTier: canAccess(feature, "plus") && !canAccess(feature, "free")
      ? "plus"
      : "premium",
    allowed: canAccess(feature, tier),
  };
}
