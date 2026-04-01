import { describe, it, expect } from "vitest";
import {
  tierDisplayName,
  tierValueProposition,
  tierRank,
  PLUS_FEATURES,
  PREMIUM_FEATURES,
  canAccess,
  minimumTierRequired,
  maxTrackedLifts,
  maxActiveInjuries,
  workoutHistoryDaysLimit,
  dailyCloudAILimit,
  canGenerateCloud,
  shouldShowSoftNudge,
  PREMIUM_SOFT_NUDGE_THRESHOLD,
  canViewExistingData,
  canCreateNew,
  canDeleteOwnData,
} from "../subscription";
import type { GatedFeature } from "../subscription";

// ---------------------------------------------------------------------------
// Tier metadata
// ---------------------------------------------------------------------------

describe("tierDisplayName", () => {
  it("free → 'Free'", () => {
    expect(tierDisplayName("free")).toBe("Free");
  });

  it("plus → 'Sundee Plus'", () => {
    expect(tierDisplayName("plus")).toBe("Sundee Plus");
  });

  it("premium → 'Sundee Premium'", () => {
    expect(tierDisplayName("premium")).toBe("Sundee Premium");
  });
});

describe("tierValueProposition", () => {
  it("free tier proposition", () => {
    expect(tierValueProposition("free")).toBe(
      "Unlimited on-device AI workouts"
    );
  });

  it("plus tier proposition", () => {
    expect(tierValueProposition("plus")).toBe(
      "Gemini-powered AI workouts and programming tools"
    );
  });

  it("premium tier proposition", () => {
    expect(tierValueProposition("premium")).toBe(
      "Personal AI coach with adaptive planning"
    );
  });
});

describe("tierRank", () => {
  it("free rank is 0", () => {
    expect(tierRank("free")).toBe(0);
  });

  it("plus rank is 1", () => {
    expect(tierRank("plus")).toBe(1);
  });

  it("premium rank is 2", () => {
    expect(tierRank("premium")).toBe(2);
  });

  it("plus rank > free rank", () => {
    expect(tierRank("plus")).toBeGreaterThan(tierRank("free"));
  });

  it("premium rank > plus rank", () => {
    expect(tierRank("premium")).toBeGreaterThan(tierRank("plus"));
  });
});

// ---------------------------------------------------------------------------
// Feature catalog counts
// ---------------------------------------------------------------------------

describe("feature catalogs", () => {
  it("PLUS_FEATURES contains 11 features", () => {
    expect(PLUS_FEATURES).toHaveLength(11);
  });

  it("PREMIUM_FEATURES contains 9 features", () => {
    expect(PREMIUM_FEATURES).toHaveLength(9);
  });

  it("total gated features is 20", () => {
    expect(PLUS_FEATURES.length + PREMIUM_FEATURES.length).toBe(20);
  });
});

// ---------------------------------------------------------------------------
// minimumTierRequired
// ---------------------------------------------------------------------------

describe("minimumTierRequired", () => {
  it("customBenchmarks requires plus", () => {
    expect(minimumTierRequired("customBenchmarks")).toBe("plus");
  });

  it("autoDeload requires plus", () => {
    expect(minimumTierRequired("autoDeload")).toBe("plus");
  });

  it("streaksAchievements requires plus", () => {
    expect(minimumTierRequired("streaksAchievements")).toBe("plus");
  });

  it("rehabSessions requires premium", () => {
    expect(minimumTierRequired("rehabSessions")).toBe("premium");
  });

  it("smartSubstitutions requires premium", () => {
    expect(minimumTierRequired("smartSubstitutions")).toBe("premium");
  });

  it("weeklyReports requires premium", () => {
    expect(minimumTierRequired("weeklyReports")).toBe("premium");
  });
});

// ---------------------------------------------------------------------------
// canAccess
// ---------------------------------------------------------------------------

describe("canAccess — Plus features", () => {
  const plusFeature: GatedFeature = "customBenchmarks";

  it("free cannot access plus feature", () => {
    expect(canAccess(plusFeature, "free")).toBe(false);
  });

  it("plus can access plus feature", () => {
    expect(canAccess(plusFeature, "plus")).toBe(true);
  });

  it("premium can access plus feature", () => {
    expect(canAccess(plusFeature, "premium")).toBe(true);
  });
});

describe("canAccess — Premium features", () => {
  const premiumFeature: GatedFeature = "rehabSessions";

  it("free cannot access premium feature", () => {
    expect(canAccess(premiumFeature, "free")).toBe(false);
  });

  it("plus cannot access premium feature", () => {
    expect(canAccess(premiumFeature, "plus")).toBe(false);
  });

  it("premium can access premium feature", () => {
    expect(canAccess(premiumFeature, "premium")).toBe(true);
  });
});

describe("canAccess — all plus features accessible at premium", () => {
  it("every plus feature is accessible at premium tier", () => {
    for (const feature of PLUS_FEATURES) {
      expect(canAccess(feature, "premium")).toBe(true);
    }
  });
});

// ---------------------------------------------------------------------------
// Tracking Limits
// ---------------------------------------------------------------------------

describe("maxTrackedLifts", () => {
  it("free → 5", () => {
    expect(maxTrackedLifts("free")).toBe(5);
  });

  it("plus → null (unlimited)", () => {
    expect(maxTrackedLifts("plus")).toBeNull();
  });

  it("premium → null (unlimited)", () => {
    expect(maxTrackedLifts("premium")).toBeNull();
  });
});

describe("maxActiveInjuries", () => {
  it("free → 1", () => {
    expect(maxActiveInjuries("free")).toBe(1);
  });

  it("plus → null (unlimited)", () => {
    expect(maxActiveInjuries("plus")).toBeNull();
  });

  it("premium → null (unlimited)", () => {
    expect(maxActiveInjuries("premium")).toBeNull();
  });
});

describe("workoutHistoryDaysLimit", () => {
  it("free → 30", () => {
    expect(workoutHistoryDaysLimit("free")).toBe(30);
  });

  it("plus → null (unlimited)", () => {
    expect(workoutHistoryDaysLimit("plus")).toBeNull();
  });

  it("premium → null (unlimited)", () => {
    expect(workoutHistoryDaysLimit("premium")).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// AI Workout Limits
// ---------------------------------------------------------------------------

describe("dailyCloudAILimit", () => {
  it("free → 0", () => {
    expect(dailyCloudAILimit("free")).toBe(0);
  });

  it("plus → 1", () => {
    expect(dailyCloudAILimit("plus")).toBe(1);
  });

  it("premium → 10", () => {
    expect(dailyCloudAILimit("premium")).toBe(10);
  });
});

describe("canGenerateCloud", () => {
  it("free user cannot generate cloud workouts", () => {
    expect(canGenerateCloud("free", 0)).toBe(false);
  });

  it("plus user can generate when generatedToday = 0", () => {
    expect(canGenerateCloud("plus", 0)).toBe(true);
  });

  it("plus user cannot generate when generatedToday = 1 (limit reached)", () => {
    expect(canGenerateCloud("plus", 1)).toBe(false);
  });

  it("premium user can generate when generatedToday = 9", () => {
    expect(canGenerateCloud("premium", 9)).toBe(true);
  });

  it("premium user cannot generate when generatedToday = 10 (limit reached)", () => {
    expect(canGenerateCloud("premium", 10)).toBe(false);
  });

  it("premium user cannot generate when generatedToday > limit", () => {
    expect(canGenerateCloud("premium", 15)).toBe(false);
  });
});

describe("shouldShowSoftNudge", () => {
  it("PREMIUM_SOFT_NUDGE_THRESHOLD is 7", () => {
    expect(PREMIUM_SOFT_NUDGE_THRESHOLD).toBe(7);
  });

  it("no nudge for free tier", () => {
    expect(shouldShowSoftNudge("free", 10)).toBe(false);
  });

  it("no nudge for plus tier", () => {
    expect(shouldShowSoftNudge("plus", 10)).toBe(false);
  });

  it("no nudge for premium below threshold", () => {
    expect(shouldShowSoftNudge("premium", 6)).toBe(false);
  });

  it("nudge for premium at exactly threshold", () => {
    expect(shouldShowSoftNudge("premium", 7)).toBe(true);
  });

  it("nudge for premium above threshold", () => {
    expect(shouldShowSoftNudge("premium", 15)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Downgrade Policy
// ---------------------------------------------------------------------------

describe("canViewExistingData", () => {
  it("free tier can view existing data for any feature", () => {
    expect(canViewExistingData("rehabSessions", "free")).toBe(true);
  });

  it("plus tier can view existing data for premium features", () => {
    expect(canViewExistingData("aiCoachMemory", "plus")).toBe(true);
  });

  it("premium tier can view existing data", () => {
    expect(canViewExistingData("weeklyReports", "premium")).toBe(true);
  });
});

describe("canCreateNew", () => {
  it("free cannot create for plus-gated feature", () => {
    expect(canCreateNew("customBenchmarks", "free")).toBe(false);
  });

  it("plus can create for plus-gated feature", () => {
    expect(canCreateNew("customBenchmarks", "plus")).toBe(true);
  });

  it("plus cannot create for premium-gated feature", () => {
    expect(canCreateNew("rehabSessions", "plus")).toBe(false);
  });

  it("premium can create for premium-gated feature", () => {
    expect(canCreateNew("rehabSessions", "premium")).toBe(true);
  });
});

describe("canDeleteOwnData", () => {
  it("free tier can delete own data", () => {
    expect(canDeleteOwnData("free")).toBe(true);
  });

  it("plus tier can delete own data", () => {
    expect(canDeleteOwnData("plus")).toBe(true);
  });

  it("premium tier can delete own data", () => {
    expect(canDeleteOwnData("premium")).toBe(true);
  });
});
