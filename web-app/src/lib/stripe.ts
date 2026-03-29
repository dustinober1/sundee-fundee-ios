import Stripe from "stripe";

export const STRIPE_PRICES = {
  plus: {
    monthly: "price_1TGMEmR3qTJLE6bbfrsZYIJt",
    annual: "price_1TGMEmR3qTJLE6bb2d7Xkocg",
  },
  premium: {
    monthly: "price_1TGMEnR3qTJLE6bbeooKfY0E",
    annual: "price_1TGMEoR3qTJLE6bbMW01HMya",
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
