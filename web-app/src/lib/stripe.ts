import Stripe from "stripe";
import type { SubscriptionStatus, SubscriptionRecord } from "./subscription-state";
import type { SubscriptionTier } from "./domain";

const DEFAULT_STRIPE_PRICES = {
  plus: {
    monthly: "price_1TGMEmR3qTJLE6bbfrsZYIJt",
    annual: "price_1TGMEmR3qTJLE6bb2d7Xkocg",
  },
  premium: {
    monthly: "price_1TGMEnR3qTJLE6bbeooKfY0E",
    annual: "price_1TGMEoR3qTJLE6bbMW01HMya",
  },
} as const;

export const STRIPE_PRICES = {
  plus: {
    monthly: process.env.STRIPE_PRICE_PLUS_MONTHLY ?? DEFAULT_STRIPE_PRICES.plus.monthly,
    annual: process.env.STRIPE_PRICE_PLUS_ANNUAL ?? DEFAULT_STRIPE_PRICES.plus.annual,
  },
  premium: {
    monthly: process.env.STRIPE_PRICE_PREMIUM_MONTHLY ?? DEFAULT_STRIPE_PRICES.premium.monthly,
    annual: process.env.STRIPE_PRICE_PREMIUM_ANNUAL ?? DEFAULT_STRIPE_PRICES.premium.annual,
  },
} as const;

export function tierFromPriceId(priceId: string): "plus" | "premium" | null {
  for (const [tier, prices] of Object.entries(STRIPE_PRICES)) {
    if (prices.monthly === priceId || prices.annual === priceId) {
      return tier as "plus" | "premium";
    }
  }
  return null;
}

export function createStripeClient(): Stripe {
  return new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: "2026-03-25.dahlia" });
}

export function normalizeStripeStatus(status: string | null | undefined): SubscriptionStatus {
  switch (status) {
    case "active":
    case "trialing":
    case "past_due":
    case "incomplete":
    case "unpaid":
    case "canceled":
      return status;
    default:
      return "incomplete";
  }
}

export function subscriptionRecordFromStripe(
  tier: SubscriptionTier,
  input: {
    status: string | null | undefined;
    stripeCustomerId?: string | null;
    stripeSubscriptionId?: string | null;
    currentPeriodEnd?: number | null;
    cancelAtPeriodEnd?: boolean | null;
  }
): SubscriptionRecord {
  return {
    tier,
    status: normalizeStripeStatus(input.status),
    stripeCustomerId: input.stripeCustomerId ?? undefined,
    stripeSubscriptionId: input.stripeSubscriptionId ?? undefined,
    currentPeriodEnd: input.currentPeriodEnd ? new Date(input.currentPeriodEnd * 1000) : null,
    cancelAtPeriodEnd: input.cancelAtPeriodEnd === true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}
