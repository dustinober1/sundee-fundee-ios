# Cloudflare Worker AI Proxy Design

**Date:** 2026-03-28
**Status:** Approved

## Purpose

A new Cloudflare Worker (`ai-coach.sundeefundee.workers.dev`) that receives workout generation requests from the iOS app, validates the user's subscription tier via a signed JWT, routes to the appropriate Cloudflare Workers AI model, enforces server-side daily rate limits via KV, and returns the generated workout.

## Architecture

```
iOS App
  → POST /generate-workout (JWT in Authorization header)
  → ai-coach.sundeefundee.workers.dev
    → Validate JWT (shared secret, HMAC-SHA256)
    → Check daily rate limit (KV: userID:YYYY-MM-DD)
    → Route to Workers AI model based on tier:
        Plus  → @cf/qwen/qwen3-30b-a3b-fp8
        Premium → @cf/nvidia/nemotron-3-120b-a12b
    → Increment usage counter in KV
    → Return generated workout JSON
```

Separate from the existing `workout-proxy.sundeefundee.workers.dev` (Gemini proxy for WOD Dashboard). Different purposes, auth models, and rate limiting needs.

## Request/Response Contract

### Request

```
POST /generate-workout
Authorization: Bearer <JWT>
Content-Type: application/json
```

```json
{
  "prompt": "<workout generation prompt built by iOS app>",
  "systemInstruction": "<system prompt>"
}
```

### JWT

Payload: `{ "sub": "<userID>", "tier": "plus"|"premium", "iat": <timestamp> }`

Signed with HMAC-SHA256 using a shared secret stored as a Worker secret. `iat` must be within the last 5 minutes to prevent replay attacks.

### Success Response (200)

```json
{
  "coachingSummary": "...",
  "exercises": [
    {
      "name": "Back Squat",
      "sets": 4,
      "reps": "8",
      "weightKg": null,
      "restMinutes": 2,
      "notes": "Focus on depth",
      "bodyweightOnly": false
    }
  ]
}
```

### Error Responses

| Status | Meaning | Body |
|--------|---------|------|
| 401 | Invalid/expired JWT | `{ "error": "unauthorized", "message": "..." }` |
| 403 | Free tier (no cloud access) | `{ "error": "forbidden", "message": "Cloud AI requires Plus or Premium" }` |
| 429 | Daily rate limit exceeded | `{ "error": "rate_limited", "remaining": 0, "resetsAt": "<ISO 8601>" }` |
| 500 | Workers AI failure | `{ "error": "generation_failed", "message": "..." }` |

## Components

### 1. JWT Validation (`src/auth.ts`)

- Verify HMAC-SHA256 signature using Web Crypto API (native to Workers)
- Check `iat` is within last 5 minutes (prevents replay with stale tokens)
- Extract `sub` (userID) and `tier` from payload
- Reject if tier is `"free"` or missing

### 2. Rate Limiter (`src/rate-limit.ts`)

- KV key format: `usage:{userID}:{YYYY-MM-DD}`
- Read current count, compare against tier limit (Plus: 1, Premium: 10)
- If under limit, increment and proceed. If at/over, return 429.
- KV entries auto-expire after 48 hours (TTL) to avoid unbounded storage growth

### 3. AI Router (`src/ai.ts`)

- Maps tier to model ID: `plus` → `@cf/qwen/qwen3-30b-a3b-fp8`, `premium` → `@cf/nvidia/nemotron-3-120b-a12b`
- Calls Cloudflare Workers AI binding (`env.AI.run()`)
- Formats the prompt as the model expects (system + user messages)
- Parses the text response, strips markdown fences if present, returns JSON

### 4. Entry Point (`src/index.ts`)

- Single `POST /generate-workout` route
- Chains: CORS → JWT validation → rate limit check → AI generation → response
- Returns structured error responses with appropriate HTTP status codes

### 5. Configuration

- `wrangler.toml` — Worker name, KV namespace binding, AI binding, account ID
- Secrets (set via `wrangler secret put`): `JWT_SECRET`
- No secrets in code or version control

## File Structure

```
workers/ai-coach/
├── src/
│   ├── index.ts        # Entry point, routing, CORS
│   ├── auth.ts         # JWT validation
│   ├── rate-limit.ts   # KV-based daily rate limiting
│   ├── ai.ts           # Workers AI model routing and response parsing
│   └── types.ts        # Shared TypeScript types
├── test/
│   ├── auth.test.ts
│   ├── rate-limit.test.ts
│   └── ai.test.ts
├── wrangler.toml
├── package.json
├── tsconfig.json
└── vitest.config.ts
```

## Rate Limiting Details

| Tier | Daily Limit | Soft Nudge | KV TTL |
|------|------------|------------|--------|
| Free | 0 (rejected at JWT validation) | N/A | N/A |
| Plus | 1 | N/A | 48h |
| Premium | 10 | Client-side at 7 (not enforced server-side) | 48h |

Rate limit resets at midnight UTC. The 429 response includes `resetsAt` (next midnight UTC) so the iOS app can display time remaining.

## Security

- **JWT shared secret** stored as a Cloudflare Worker secret, never in code
- **5-minute JWT expiry** prevents replay attacks with captured tokens
- **Server-side rate limiting** as backstop against client-side tampering
- **No API keys in the iOS binary** — only the JWT signing secret, which is rotatable
- Threat model: low. Someone would need to reverse-engineer the app binary to extract the secret and spoof a tier. Rate limiting via KV provides a second layer regardless.

## Testing Strategy

**Unit tests** (Vitest):
- JWT validation: valid token, expired token, wrong secret, missing fields, free tier rejection
- Rate limiter: under limit, at limit, over limit, new day resets
- AI router: correct model selection per tier, response parsing, markdown fence stripping
- Error responses: correct HTTP status codes and body format

**Manual integration test:**
- `wrangler dev` for local development
- Curl with a test JWT to verify end-to-end flow

No automated E2E tests — Workers AI calls cost money and aren't mockable in CI. Unit tests mock the AI binding.

## Out of Scope

- iOS app changes (Sub-project 3: Cloud AI Workout Integration)
- StoreKit re-enablement (Sub-project 4)
- Analytics/usage dashboards
- The existing Gemini proxy worker (unchanged)
- User registration or account management
