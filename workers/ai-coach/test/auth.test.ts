import { describe, it, expect } from "vitest";
import { verifyJwt, createJwt } from "../src/auth";

const TEST_SECRET = "test-secret-key-for-unit-tests";

describe("verifyJwt", () => {
  it("accepts a valid token", async () => {
    const token = await createJwt({ sub: "user-123", tier: "plus", iat: nowSeconds() }, TEST_SECRET);
    const result = await verifyJwt(token, TEST_SECRET);
    expect(result).toEqual({ sub: "user-123", tier: "plus", iat: expect.any(Number) });
  });

  it("accepts premium tier", async () => {
    const token = await createJwt({ sub: "user-456", tier: "premium", iat: nowSeconds() }, TEST_SECRET);
    const result = await verifyJwt(token, TEST_SECRET);
    expect(result.tier).toBe("premium");
  });

  it("rejects expired token (iat > 5 minutes ago)", async () => {
    const token = await createJwt({ sub: "user-123", tier: "plus", iat: nowSeconds() - 301 }, TEST_SECRET);
    await expect(verifyJwt(token, TEST_SECRET)).rejects.toThrow("Token expired");
  });

  it("rejects token signed with wrong secret", async () => {
    const token = await createJwt({ sub: "user-123", tier: "plus", iat: nowSeconds() }, "wrong-secret");
    await expect(verifyJwt(token, TEST_SECRET)).rejects.toThrow("Invalid signature");
  });

  it("rejects token with missing sub", async () => {
    const token = await createJwt({ sub: "", tier: "plus", iat: nowSeconds() }, TEST_SECRET);
    await expect(verifyJwt(token, TEST_SECRET)).rejects.toThrow("Missing sub");
  });

  it("rejects token with free tier", async () => {
    const payload = { sub: "user-123", tier: "free" as any, iat: nowSeconds() };
    const token = await createJwt(payload, TEST_SECRET);
    await expect(verifyJwt(token, TEST_SECRET)).rejects.toThrow("Invalid tier");
  });

  it("rejects token with missing tier", async () => {
    const payload = { sub: "user-123", tier: "" as any, iat: nowSeconds() };
    const token = await createJwt(payload, TEST_SECRET);
    await expect(verifyJwt(token, TEST_SECRET)).rejects.toThrow("Invalid tier");
  });

  it("rejects malformed token", async () => {
    await expect(verifyJwt("not.a.valid.token", TEST_SECRET)).rejects.toThrow();
  });
});

function nowSeconds(): number {
  return Math.floor(Date.now() / 1000);
}
