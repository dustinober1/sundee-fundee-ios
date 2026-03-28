import { TIER_LIMITS, type Tier } from "./types";

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetsAt?: string;
}

const KV_TTL_SECONDS = 172800; // 48 hours

export async function checkRateLimit(
  kv: KVNamespace,
  userID: string,
  tier: Tier,
): Promise<RateLimitResult> {
  const today = new Date().toISOString().split("T")[0];
  const key = `usage:${userID}:${today}`;
  const limit = TIER_LIMITS[tier];

  const currentStr = await kv.get(key);
  const current = currentStr ? parseInt(currentStr, 10) : 0;

  if (current >= limit) {
    return {
      allowed: false,
      remaining: 0,
      resetsAt: nextMidnightUTC(),
    };
  }

  await kv.put(key, String(current + 1), { expirationTtl: KV_TTL_SECONDS });

  return {
    allowed: true,
    remaining: limit - current - 1,
  };
}

function nextMidnightUTC(): string {
  const tomorrow = new Date();
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  tomorrow.setUTCHours(0, 0, 0, 0);
  return tomorrow.toISOString();
}
