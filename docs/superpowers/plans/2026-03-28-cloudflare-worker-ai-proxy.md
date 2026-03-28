# Cloudflare Worker AI Proxy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Cloudflare Worker that validates JWT auth, enforces daily rate limits via KV, and routes workout generation requests to Cloudflare Workers AI models based on subscription tier.

**Architecture:** Single Worker with four modules: JWT auth validation, KV-based rate limiting, Workers AI routing, and an entry point that chains them. Unit tested with Vitest, mocking the AI binding and KV store.

**Tech Stack:** TypeScript, Cloudflare Workers, Workers AI, KV, Vitest, Wrangler

---

## File Structure

```
workers/ai-coach/
├── src/
│   ├── index.ts        # Entry point, routing, CORS
│   ├── auth.ts         # JWT validation (HMAC-SHA256 via Web Crypto)
│   ├── rate-limit.ts   # KV-based daily rate limiting
│   ├── ai.ts           # Workers AI model routing and response parsing
│   └── types.ts        # Shared TypeScript types and Env interface
├── test/
│   ├── auth.test.ts
│   ├── rate-limit.test.ts
│   └── ai.test.ts
├── wrangler.toml
├── package.json
├── tsconfig.json
└── vitest.config.ts
```

---

### Task 1: Project Scaffolding

**Files:**
- Create: `workers/ai-coach/package.json`
- Create: `workers/ai-coach/tsconfig.json`
- Create: `workers/ai-coach/wrangler.toml`
- Create: `workers/ai-coach/vitest.config.ts`
- Create: `workers/ai-coach/src/types.ts`

- [ ] **Step 1: Create package.json**

```json
{
  "name": "ai-coach",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "devDependencies": {
    "@cloudflare/vitest-pool-workers": "^0.8.0",
    "@cloudflare/workers-types": "^4.20250327.0",
    "typescript": "^5.8.0",
    "vitest": "^3.1.0",
    "wrangler": "^4.14.0"
  }
}
```

- [ ] **Step 2: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ESNext"],
    "types": ["@cloudflare/workers-types", "@cloudflare/vitest-pool-workers"],
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*.ts", "test/**/*.ts"]
}
```

- [ ] **Step 3: Create wrangler.toml**

```toml
name = "ai-coach"
main = "src/index.ts"
compatibility_date = "2025-03-28"

[ai]
binding = "AI"

[[kv_namespaces]]
binding = "RATE_LIMIT"
id = "PLACEHOLDER_REPLACE_AFTER_KV_CREATE"

[vars]
ENVIRONMENT = "production"
```

Note: The KV namespace ID is a placeholder. After running `wrangler kv namespace create RATE_LIMIT`, replace the `id` value with the actual ID returned. The `JWT_SECRET` is set via `wrangler secret put JWT_SECRET` (never in this file).

- [ ] **Step 4: Create vitest.config.ts**

```typescript
import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: "./wrangler.toml" },
      },
    },
  },
});
```

- [ ] **Step 5: Create src/types.ts**

```typescript
export interface Env {
  AI: Ai;
  RATE_LIMIT: KVNamespace;
  JWT_SECRET: string;
}

export interface JwtPayload {
  sub: string;
  tier: "plus" | "premium";
  iat: number;
}

export interface WorkoutRequest {
  prompt: string;
  systemInstruction: string;
}

export interface Exercise {
  name: string;
  sets: number;
  reps: string;
  weightKg: number | null;
  restMinutes: number | null;
  notes: string | null;
  bodyweightOnly: boolean;
}

export interface WorkoutResponse {
  coachingSummary: string;
  exercises: Exercise[];
}

export interface ErrorResponse {
  error: string;
  message?: string;
  remaining?: number;
  resetsAt?: string;
}

export type Tier = "plus" | "premium";

export const TIER_LIMITS: Record<Tier, number> = {
  plus: 1,
  premium: 10,
};

export const TIER_MODELS: Record<Tier, string> = {
  plus: "@cf/qwen/qwen3-30b-a3b-fp8",
  premium: "@cf/nvidia/nemotron-3-120b-a12b",
};
```

- [ ] **Step 6: Install dependencies**

Run:
```bash
cd workers/ai-coach && npm install
```
Expected: `node_modules/` created, no errors

- [ ] **Step 7: Verify TypeScript compiles**

Run:
```bash
cd workers/ai-coach && npx tsc --noEmit
```
Expected: No errors (types.ts has no imports that need resolution beyond the installed types)

- [ ] **Step 8: Commit**

```bash
git add workers/ai-coach/package.json workers/ai-coach/tsconfig.json workers/ai-coach/wrangler.toml workers/ai-coach/vitest.config.ts workers/ai-coach/src/types.ts workers/ai-coach/package-lock.json
git commit -m "feat(ai-coach): scaffold Cloudflare Worker project with types"
```

---

### Task 2: JWT Authentication

**Files:**
- Create: `workers/ai-coach/src/auth.ts`
- Create: `workers/ai-coach/test/auth.test.ts`

- [ ] **Step 1: Write auth.test.ts**

```typescript
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd workers/ai-coach && npx vitest run test/auth.test.ts
```
Expected: FAIL — `auth.ts` doesn't exist yet

- [ ] **Step 3: Implement auth.ts**

```typescript
import type { JwtPayload } from "./types";

const MAX_AGE_SECONDS = 300; // 5 minutes

export async function verifyJwt(token: string, secret: string): Promise<JwtPayload> {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Malformed token");

  const [headerB64, payloadB64, signatureB64] = parts;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );

  const data = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const signature = base64UrlDecode(signatureB64);

  const valid = await crypto.subtle.verify("HMAC", key, signature, data);
  if (!valid) throw new Error("Invalid signature");

  const payload = JSON.parse(new TextDecoder().decode(base64UrlDecode(payloadB64)));

  if (!payload.sub) throw new Error("Missing sub");
  if (!payload.tier || (payload.tier !== "plus" && payload.tier !== "premium")) {
    throw new Error("Invalid tier");
  }

  const now = Math.floor(Date.now() / 1000);
  if (now - payload.iat > MAX_AGE_SECONDS) throw new Error("Token expired");

  return { sub: payload.sub, tier: payload.tier, iat: payload.iat };
}

export async function createJwt(payload: Record<string, unknown>, secret: string): Promise<string> {
  const header = { alg: "HS256", typ: "JWT" };
  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(payload));

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const data = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const signature = await crypto.subtle.sign("HMAC", key, data);

  return `${headerB64}.${payloadB64}.${base64UrlEncode(signature)}`;
}

function base64UrlEncode(input: string | ArrayBuffer): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : new Uint8Array(input);
  const binString = Array.from(bytes, (b) => String.fromCodePoint(b)).join("");
  return btoa(binString).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlDecode(input: string): Uint8Array {
  const padded = input.replace(/-/g, "+").replace(/_/g, "/");
  const binString = atob(padded);
  return Uint8Array.from(binString, (c) => c.codePointAt(0)!);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd workers/ai-coach && npx vitest run test/auth.test.ts
```
Expected: 8 tests PASS

- [ ] **Step 5: Commit**

```bash
git add workers/ai-coach/src/auth.ts workers/ai-coach/test/auth.test.ts
git commit -m "feat(ai-coach): add JWT authentication with HMAC-SHA256"
```

---

### Task 3: Rate Limiter

**Files:**
- Create: `workers/ai-coach/src/rate-limit.ts`
- Create: `workers/ai-coach/test/rate-limit.test.ts`

- [ ] **Step 1: Write rate-limit.test.ts**

```typescript
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd workers/ai-coach && npx vitest run test/rate-limit.test.ts
```
Expected: FAIL — `rate-limit.ts` doesn't exist yet

- [ ] **Step 3: Implement rate-limit.ts**

```typescript
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd workers/ai-coach && npx vitest run test/rate-limit.test.ts
```
Expected: 8 tests PASS

- [ ] **Step 5: Commit**

```bash
git add workers/ai-coach/src/rate-limit.ts workers/ai-coach/test/rate-limit.test.ts
git commit -m "feat(ai-coach): add KV-based daily rate limiting"
```

---

### Task 4: AI Router

**Files:**
- Create: `workers/ai-coach/src/ai.ts`
- Create: `workers/ai-coach/test/ai.test.ts`

- [ ] **Step 1: Write ai.test.ts**

```typescript
import { describe, it, expect, vi } from "vitest";
import { generateWorkout } from "../src/ai";
import type { Tier } from "../src/types";

function createMockAI(responseText: string) {
  return {
    run: vi.fn(async () => ({ response: responseText })),
  } as unknown as Ai;
}

const VALID_RESPONSE = JSON.stringify({
  coachingSummary: "Great upper body session.",
  exercises: [
    {
      name: "Bench Press",
      sets: 4,
      reps: "8",
      weightKg: null,
      restMinutes: 2,
      notes: "Control the eccentric",
      bodyweightOnly: false,
    },
  ],
});

describe("generateWorkout", () => {
  it("routes plus tier to qwen model", async () => {
    const ai = createMockAI(VALID_RESPONSE);
    await generateWorkout(ai, "plus", "Build a workout", "You are a coach");
    expect(ai.run).toHaveBeenCalledWith(
      "@cf/qwen/qwen3-30b-a3b-fp8",
      expect.objectContaining({
        messages: [
          { role: "system", content: "You are a coach" },
          { role: "user", content: "Build a workout" },
        ],
      }),
    );
  });

  it("routes premium tier to nemotron model", async () => {
    const ai = createMockAI(VALID_RESPONSE);
    await generateWorkout(ai, "premium", "Build a workout", "You are a coach");
    expect(ai.run).toHaveBeenCalledWith(
      "@cf/nvidia/nemotron-3-120b-a12b",
      expect.any(Object),
    );
  });

  it("parses valid JSON response", async () => {
    const ai = createMockAI(VALID_RESPONSE);
    const result = await generateWorkout(ai, "plus", "prompt", "system");
    expect(result.coachingSummary).toBe("Great upper body session.");
    expect(result.exercises).toHaveLength(1);
    expect(result.exercises[0].name).toBe("Bench Press");
  });

  it("strips markdown code fences from response", async () => {
    const wrapped = "```json\n" + VALID_RESPONSE + "\n```";
    const ai = createMockAI(wrapped);
    const result = await generateWorkout(ai, "plus", "prompt", "system");
    expect(result.coachingSummary).toBe("Great upper body session.");
  });

  it("throws on unparseable response", async () => {
    const ai = createMockAI("This is not JSON at all");
    await expect(generateWorkout(ai, "plus", "prompt", "system")).rejects.toThrow("Failed to parse");
  });

  it("throws on missing coachingSummary", async () => {
    const bad = JSON.stringify({ exercises: [] });
    const ai = createMockAI(bad);
    await expect(generateWorkout(ai, "plus", "prompt", "system")).rejects.toThrow("Invalid response");
  });

  it("throws on missing exercises array", async () => {
    const bad = JSON.stringify({ coachingSummary: "Hi" });
    const ai = createMockAI(bad);
    await expect(generateWorkout(ai, "plus", "prompt", "system")).rejects.toThrow("Invalid response");
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd workers/ai-coach && npx vitest run test/ai.test.ts
```
Expected: FAIL — `ai.ts` doesn't exist yet

- [ ] **Step 3: Implement ai.ts**

```typescript
import { TIER_MODELS, type Tier, type WorkoutResponse } from "./types";

export async function generateWorkout(
  ai: Ai,
  tier: Tier,
  prompt: string,
  systemInstruction: string,
): Promise<WorkoutResponse> {
  const model = TIER_MODELS[tier];

  const result = await ai.run(model, {
    messages: [
      { role: "system", content: systemInstruction },
      { role: "user", content: prompt },
    ],
  });

  const raw = (result as { response: string }).response;
  const cleaned = stripMarkdownFences(raw);

  let parsed: unknown;
  try {
    parsed = JSON.parse(cleaned);
  } catch {
    throw new Error("Failed to parse AI response as JSON");
  }

  if (!isValidWorkoutResponse(parsed)) {
    throw new Error("Invalid response structure from AI");
  }

  return parsed;
}

function stripMarkdownFences(text: string): string {
  const trimmed = text.trim();
  if (trimmed.startsWith("```")) {
    const lines = trimmed.split("\n");
    lines.shift(); // remove opening fence
    if (lines[lines.length - 1]?.trim() === "```") {
      lines.pop(); // remove closing fence
    }
    return lines.join("\n");
  }
  return trimmed;
}

function isValidWorkoutResponse(data: unknown): data is WorkoutResponse {
  if (typeof data !== "object" || data === null) return false;
  const obj = data as Record<string, unknown>;
  return typeof obj.coachingSummary === "string" && Array.isArray(obj.exercises);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd workers/ai-coach && npx vitest run test/ai.test.ts
```
Expected: 7 tests PASS

- [ ] **Step 5: Commit**

```bash
git add workers/ai-coach/src/ai.ts workers/ai-coach/test/ai.test.ts
git commit -m "feat(ai-coach): add Workers AI routing with model selection per tier"
```

---

### Task 5: Entry Point and Request Handler

**Files:**
- Create: `workers/ai-coach/src/index.ts`

- [ ] **Step 1: Implement index.ts**

```typescript
import type { Env, WorkoutRequest, ErrorResponse } from "./types";
import { verifyJwt } from "./auth";
import { checkRateLimit } from "./rate-limit";
import { generateWorkout } from "./ai";

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}

function errorResponse(error: string, message: string, status: number, extra?: Partial<ErrorResponse>): Response {
  return jsonResponse({ error, message, ...extra }, status);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const url = new URL(request.url);

    if (request.method !== "POST" || url.pathname !== "/generate-workout") {
      return errorResponse("not_found", "POST /generate-workout is the only endpoint", 404);
    }

    // 1. Authenticate
    const authHeader = request.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return errorResponse("unauthorized", "Missing Authorization header", 401);
    }

    const token = authHeader.slice(7);
    let jwt;
    try {
      jwt = await verifyJwt(token, env.JWT_SECRET);
    } catch (err) {
      return errorResponse("unauthorized", (err as Error).message, 401);
    }

    // 2. Rate limit
    const rateResult = await checkRateLimit(env.RATE_LIMIT, jwt.sub, jwt.tier);
    if (!rateResult.allowed) {
      return errorResponse("rate_limited", "Daily limit exceeded", 429, {
        remaining: 0,
        resetsAt: rateResult.resetsAt,
      });
    }

    // 3. Parse request body
    let body: WorkoutRequest;
    try {
      body = await request.json() as WorkoutRequest;
    } catch {
      return errorResponse("bad_request", "Invalid JSON body", 400);
    }

    if (!body.prompt || !body.systemInstruction) {
      return errorResponse("bad_request", "Missing prompt or systemInstruction", 400);
    }

    // 4. Generate workout
    try {
      const workout = await generateWorkout(env.AI, jwt.tier, body.prompt, body.systemInstruction);
      return jsonResponse(workout, 200);
    } catch (err) {
      return errorResponse("generation_failed", (err as Error).message, 500);
    }
  },
} satisfies ExportedHandler<Env>;
```

- [ ] **Step 2: Verify TypeScript compiles**

Run:
```bash
cd workers/ai-coach && npx tsc --noEmit
```
Expected: No errors

- [ ] **Step 3: Run all tests**

Run:
```bash
cd workers/ai-coach && npx vitest run
```
Expected: All tests pass (auth: 8, rate-limit: 8, ai: 7 = 23 total)

- [ ] **Step 4: Commit**

```bash
git add workers/ai-coach/src/index.ts
git commit -m "feat(ai-coach): add entry point with auth, rate limiting, and AI generation chain"
```

---

### Task 6: Update TODO and Final Verification

**Files:**
- Modify: `docs/TODO.md`

- [ ] **Step 1: Run full test suite one more time**

Run:
```bash
cd workers/ai-coach && npx vitest run
```
Expected: 23 tests PASS

- [ ] **Step 2: Verify TypeScript compiles clean**

Run:
```bash
cd workers/ai-coach && npx tsc --noEmit
```
Expected: No errors

- [ ] **Step 3: Update TODO.md**

In `docs/TODO.md`, change:
```markdown
- [ ] **Cloudflare Worker AI Proxy** — Route cloud AI requests through the existing worker using Cloudflare Workers AI (`@cf/nvidia/nemotron-3-120b-a12b`), server-side rate limiting via KV store, entitlement validation
```
to:
```markdown
- [x] **Cloudflare Worker AI Proxy** — Built `workers/ai-coach/` with JWT auth, KV rate limiting, and Workers AI routing (Qwen for Plus, Nemotron for Premium). Deploy with `cd workers/ai-coach && wrangler deploy`.
```

- [ ] **Step 4: Commit**

```bash
git add docs/TODO.md
git commit -m "docs: mark Cloudflare Worker AI Proxy as complete"
```
