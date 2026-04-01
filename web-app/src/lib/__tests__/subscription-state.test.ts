import { describe, expect, it } from "vitest";
import {
  hasActivePaidAccess,
  isSubscriptionInGracePeriod,
  normalizeSubscriptionRecord,
} from "../subscription-state";

describe("normalizeSubscriptionRecord", () => {
  it("defaults missing data to a free canceled subscription", () => {
    const record = normalizeSubscriptionRecord(null);
    expect(record.tier).toBe("free");
    expect(record.status).toBe("canceled");
    expect(record.currentPeriodEnd).toBeNull();
  });

  it("preserves known tier and status values", () => {
    const record = normalizeSubscriptionRecord({
      tier: "plus",
      status: "active",
      currentPeriodEnd: "2026-04-15T00:00:00.000Z",
    });
    expect(record.tier).toBe("plus");
    expect(record.status).toBe("active");
    expect(record.currentPeriodEnd?.toISOString()).toBe("2026-04-15T00:00:00.000Z");
  });
});

describe("paid access evaluation", () => {
  const now = new Date("2026-03-31T12:00:00.000Z");

  it("treats active plus as paid", () => {
    expect(
      hasActivePaidAccess(
        normalizeSubscriptionRecord({
          tier: "plus",
          status: "active",
        }),
        now
      )
    ).toBe(true);
  });

  it("treats premium trialing as paid", () => {
    expect(
      hasActivePaidAccess(
        normalizeSubscriptionRecord({
          tier: "premium",
          status: "trialing",
        }),
        now
      )
    ).toBe(true);
  });

  it("treats canceled subscriptions with future period end as grace period", () => {
    const subscription = normalizeSubscriptionRecord({
      tier: "plus",
      status: "canceled",
      currentPeriodEnd: "2026-04-02T00:00:00.000Z",
    });
    expect(isSubscriptionInGracePeriod(subscription, now)).toBe(true);
    expect(hasActivePaidAccess(subscription, now)).toBe(true);
  });

  it("does not treat expired canceled subscriptions as paid", () => {
    expect(
      hasActivePaidAccess(
        normalizeSubscriptionRecord({
          tier: "plus",
          status: "canceled",
          currentPeriodEnd: "2026-03-01T00:00:00.000Z",
        }),
        now
      )
    ).toBe(false);
  });

  it("never treats free users as paid", () => {
    expect(
      hasActivePaidAccess(
        normalizeSubscriptionRecord({
          tier: "free",
          status: "active",
        }),
        now
      )
    ).toBe(false);
  });
});
