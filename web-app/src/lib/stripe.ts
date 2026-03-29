import Stripe from "stripe";

export const STRIPE_PRICES = {
  plus: {
    monthly: "price_plus_monthly",
    annual: "price_plus_annual",
  },
  premium: {
    monthly: "price_premium_monthly",
    annual: "price_premium_annual",
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

export function createStripeClient(secretKey: string): Stripe {
  return new Stripe(secretKey, { apiVersion: "2026-03-25.dahlia" });
}
