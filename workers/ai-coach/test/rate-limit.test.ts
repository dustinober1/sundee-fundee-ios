import { describe, it, expect, vi, beforeEach } from "vitest";
import { checkRateLimit } from "../src/rate-limit";
import type { Tier } from "../src/types";

function createMockKV(store: Record<string, string> = {}) {
  return {
    get: vi.fn(async (key: string) => store[key] ?? null),
    put: vi.fn(async (key: string, value: string) => {
      store[key] = value;
    }),
  } as unknown as KVNamespace;
}

describe("checkRateLimit", () => {
  it("allows first request for plus user", async () => {
    const kv = createMockKV();
    const result = await checkRateLimit(kv, "user-1", "plus");
    expect(result.allowed).toBe(true);
    expect(result.remaining).toBe(0);
    expect(kv.put).toHaveBeenCalledWith(
      expect.stringContaining("usage:user-1:"),
      "1",
      expect.objectContaining({ expirationTtl: 172800 }),
    );
  });

  it("blocks second request for plus user", async () => {
    const kv = createMockKV();
    kv.get = vi.fn(async () => "1");
    const result = await checkRateLimit(kv, "user-1", "plus");
    expect(result.allowed).toBe(false);
    expect(result.remaining).toBe(0);
    expect(result.resetsAt).toBeDefined();
  });

  it("allows up to 10 requests for premium user", async () => {
    const kv = createMockKV();
    kv.get = vi.fn(async () => "9");
    const result = await checkRateLimit(kv, "user-2", "premium");
    expect(result.allowed).toBe(true);
    expect(result.remaining).toBe(0);
  });

  it("blocks 11th request for premium user", async () => {
    const kv = createMockKV();
    kv.get = vi.fn(async () => "10");
    const result = await checkRateLimit(kv, "user-2", "premium");
    expect(result.allowed).toBe(false);
    expect(result.remaining).toBe(0);
  });

  it("returns correct remaining count", async () => {
    const kv = createMockKV();
    kv.get = vi.fn(async () => "5");
    const result = await checkRateLimit(kv, "user-2", "premium");
    expect(result.allowed).toBe(true);
    expect(result.remaining).toBe(4);
  });

  it("uses date-keyed KV entries", async () => {
    const kv = createMockKV();
    await checkRateLimit(kv, "user-1", "plus");
    const today = new Date().toISOString().split("T")[0];
    expect(kv.get).toHaveBeenCalledWith(`usage:user-1:${today}`);
  });

  it("sets 48-hour TTL on KV entries", async () => {
    const kv = createMockKV();
    await checkRateLimit(kv, "user-1", "plus");
    expect(kv.put).toHaveBeenCalledWith(
      expect.any(String),
      "1",
      { expirationTtl: 172800 },
    );
  });

  it("resetsAt is next midnight UTC", async () => {
    const kv = createMockKV();
    kv.get = vi.fn(async () => "1");
    const result = await checkRateLimit(kv, "user-1", "plus");
    expect(result.resetsAt).toBeDefined();
    const resetDate = new Date(result.resetsAt!);
    expect(resetDate.getUTCHours()).toBe(0);
    expect(resetDate.getUTCMinutes()).toBe(0);
    expect(resetDate.getUTCSeconds()).toBe(0);
  });
});
