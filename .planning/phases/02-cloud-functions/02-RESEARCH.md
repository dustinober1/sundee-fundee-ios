# Phase 2: Cloud Functions - Research

**Researched:** 2026-03-21
**Domain:** Firebase Cloud Functions v2 (TypeScript) — AI workout generation (Gemini) + Stripe Checkout + Stripe webhook entitlement write
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BACK-01 | Firebase Cloud Function generates AI workouts via Gemini SDK with user auth gating | v2 onCall with `request.auth` check; `@google/genai` SDK for Gemini; `defineSecret` for API key |
| BACK-02 | Stripe Checkout session created via Cloud Function with real price ID, success/cancel URLs | v2 onCall returning `{ url }` from `stripe.checkout.sessions.create()`; client calls `httpsCallable` then redirects |
| BACK-03 | Stripe webhook verifies signature via `rawBody`, writes `premiumEntitlement` field to Firestore | v2 onRequest with `request.rawBody`; `stripe.webhooks.constructEvent()`; Firebase Admin Firestore `.update()` |
</phase_requirements>

---

## Summary

Phase 2 wires up three Firebase Cloud Functions that currently do not exist in the project: an AI workout generator backed by Gemini, a Stripe Checkout session creator, and a Stripe webhook handler that writes subscription entitlements to Firestore. The client-side stubs are already fully built — `AIWorkoutConfig.tsx` has a `// TODO: Try Cloud Function first` comment, and `stripe-checkout.ts` already calls `httpsCallable(functions, 'createStripeCheckoutSession')` with the correct signature. All three functions need to be created from scratch in a new `functions/` directory at the project root.

The Firebase project ID is `sundee-fundee` (confirmed in `.firebaserc`). No `functions/` directory exists yet — the entire Firebase Functions scaffold needs to be initialized. The existing `firebase.json` only configures Hosting; a `"functions"` key must be added. Sensitive credentials (Stripe secret key, Stripe webhook secret, Gemini API key) must be stored in Cloud Secret Manager via `defineSecret()` — not `.env` files — as these run in a Node.js server environment.

The entitlement schema is already defined: the client reads `users/{uid}.premiumEntitlement.active` via `onSnapshot` in `useEntitlements.ts`. The webhook function only needs to write that field using Firebase Admin SDK's `.update()` syntax. The webhook identifies the user by looking up `customer.metadata.firebaseUID` on the Stripe customer — so the checkout session creator must store the Firebase UID in the Stripe customer's metadata at creation time.

**Primary recommendation:** Use Firebase Functions v2 TypeScript in a `functions/` directory at the project root. Three exports: `generateAIWorkout` (onCall), `createStripeCheckoutSession` (onCall), `stripeWebhook` (onRequest). Secrets via `defineSecret`. Test locally with Firebase Emulator Suite + Stripe CLI `stripe listen --forward-to`.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `firebase-functions` | ^6.x | Cloud Functions v2 runtime + types | Official Firebase SDK; `onCall`/`onRequest` v2 APIs |
| `firebase-admin` | ^12.x | Server-side Firestore + Auth access | Required for writing to Firestore from Functions |
| `@google/genai` | ^1.x | Gemini API SDK (replaces Cloudflare proxy) | Google's current GA SDK (reached GA May 2025); uses `ai.models.generateContent()` |
| `stripe` | ^17.x | Stripe Checkout + webhook verification | Official Stripe Node.js SDK; `stripe.webhooks.constructEvent()` for sig verification |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `firebase-functions/params` | (bundled) | `defineSecret()` for Cloud Secret Manager | All API keys — Stripe secret, webhook secret, Gemini API key |
| `firebase-functions/logger` | (bundled) | Structured logging | Replace `console.log` in all functions |
| TypeScript | ~5.x | Type safety for function code | Matches PWA tsconfig style |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@google/genai` | `@google-cloud/vertexai` | Vertex AI adds GCP IAM complexity; `@google/genai` with API key is simpler for a single-region function |
| `defineSecret()` | `.env` files | `.env` is not secure for production API keys; Secret Manager is the Firebase-recommended approach |
| Firebase Functions v2 | Firebase Functions v1 | v1 is legacy; v2 has better cold start, concurrency control, and TypeScript types |

**Installation (inside `functions/` directory):**
```bash
npm install firebase-functions firebase-admin @google/genai stripe
npm install --save-dev typescript @types/node
```

---

## Architecture Patterns

### Recommended Project Structure
```
functions/                    # New directory at project root
├── src/
│   ├── index.ts              # Exports all 3 functions
│   ├── generateAIWorkout.ts  # BACK-01: onCall Gemini AI generation
│   ├── createCheckoutSession.ts # BACK-02: onCall Stripe Checkout
│   └── stripeWebhook.ts      # BACK-03: onRequest webhook handler
├── package.json
├── tsconfig.json
└── .secret.local             # Local dev secrets (gitignored)
```

The `firebase.json` must be updated to add a `"functions"` block pointing to the `functions/` directory.

### Pattern 1: v2 onCall with Auth Gating
**What:** Server-enforced authentication check before executing any logic
**When to use:** Both BACK-01 (generateAIWorkout) and BACK-02 (createCheckoutSession)
**Example:**
```typescript
// Source: https://firebase.google.com/docs/functions/callable
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

const geminiKey = defineSecret('GEMINI_API_KEY');

export const generateAIWorkout = onCall(
  { secrets: [geminiKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated.');
    }
    const uid = request.auth.uid;
    const apiKey = geminiKey.value();
    // ... Gemini call
  }
);
```

### Pattern 2: v2 onRequest with rawBody for Stripe Webhooks
**What:** HTTP endpoint that receives raw request body for cryptographic signature verification
**When to use:** BACK-03 (stripeWebhook) — Stripe webhook handler
**Example:**
```typescript
// Source: https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/
import { onRequest } from 'firebase-functions/v2/https';
import Stripe from 'stripe';
import { defineSecret } from 'firebase-functions/params';
import { getFirestore } from 'firebase-admin/firestore';

const stripeKey = defineSecret('STRIPE_SECRET_KEY');
const webhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

export const stripeWebhook = onRequest(
  { secrets: [stripeKey, webhookSecret] },
  async (request, response) => {
    const sig = request.headers['stripe-signature'];
    if (!sig) { response.status(400).send('Missing signature'); return; }

    let event: Stripe.Event;
    try {
      const stripe = new Stripe(stripeKey.value());
      event = stripe.webhooks.constructEvent(
        request.rawBody,       // CRITICAL: must be rawBody, not body
        sig,
        webhookSecret.value()
      );
    } catch (err) {
      response.status(400).send(`Webhook Error: ${err}`);
      return;
    }

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session;
      const customerId = session.customer as string;
      const stripe = new Stripe(stripeKey.value());
      const customer = await stripe.customers.retrieve(customerId) as Stripe.Customer;
      const uid = customer.metadata?.firebaseUID;
      if (uid) {
        const db = getFirestore();
        await db.collection('users').doc(uid).update({
          'premiumEntitlement.active': true,
          'premiumEntitlement.stripeCustomerId': customerId,
          'premiumEntitlement.activatedAt': new Date().toISOString(),
        });
      }
    }
    response.json({ received: true });
  }
);
```

### Pattern 3: Stripe Checkout Session with Firebase UID in Metadata
**What:** Store Firebase UID in Stripe customer metadata so the webhook can look it up
**When to use:** BACK-02 — checkout session creation is the only place to wire the UID
**Example:**
```typescript
// Source: https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/
const customer = await stripe.customers.create({
  email: user.email,
  metadata: { firebaseUID: uid },  // KEY: webhook reads this back
});

const session = await stripe.checkout.sessions.create({
  customer: customer.id,
  line_items: [{ price: priceId, quantity: 1 }],
  mode: 'subscription',
  success_url: successUrl,
  cancel_url: cancelUrl,
});
return { url: session.url };
```

### Pattern 4: Gemini generateContent
**What:** Call Gemini with a prompt built from the `WorkoutGenerationContext` already defined in the domain layer
**When to use:** BACK-01 — AI workout generation
**Example:**
```typescript
// Source: https://github.com/googleapis/js-genai
import { GoogleGenAI } from '@google/genai';

const ai = new GoogleGenAI({ apiKey: geminiKey.value() });
const response = await ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: buildWorkoutPrompt(context),  // use domain-layer prompt builder
  config: {
    systemInstruction: WORKOUT_SYSTEM_PROMPT,
  },
});
const text = response.text;
// parse text into GeneratedWorkout shape
```

### Pattern 5: firebase.json Functions Configuration
**What:** Add `"functions"` key to `firebase.json` with predeploy build hook
**When to use:** Required before any function can be deployed
**Example:**
```json
{
  "hosting": { "...existing config..." },
  "functions": {
    "source": "functions",
    "predeploy": "npm --prefix functions run build"
  }
}
```

### Anti-Patterns to Avoid
- **Using `request.body` instead of `request.rawBody` in the webhook:** Stripe signature verification will always fail because JSON parsing mutates the body bytes. The `request.rawBody` property (typed as `Buffer`) is set by Firebase Functions before body parsing.
- **Storing Stripe secret key or Gemini API key in `.env` files:** These run server-side but `.env` files are not encrypted at rest in Cloud Functions. Use `defineSecret()` backed by Cloud Secret Manager.
- **Creating a new Stripe customer on every checkout call:** Check if `users/{uid}.premiumEntitlement.stripeCustomerId` already exists and reuse it — prevents duplicate customers in Stripe dashboard.
- **Returning full Gemini response text to the client raw:** Parse it server-side into the `GeneratedWorkout` shape before returning. The prompt format from the Cloudflare worker is already defined — reuse it.
- **Initializing Firebase Admin multiple times:** Call `initializeApp()` once in `index.ts` or guard with `if (!getApps().length)`. Multiple initializations throw in Functions.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stripe signature verification | Custom HMAC comparison | `stripe.webhooks.constructEvent()` | Handles timing attacks, encoding edge cases, header parsing |
| Secrets at runtime | Reading `.env` in functions | `defineSecret()` from `firebase-functions/params` | Cloud Secret Manager encrypts at rest; automatic rotation support |
| Auth token verification in onCall | Manual JWT decode | Firebase Functions v2 `request.auth` | Automatically verified by the Functions runtime before handler runs |
| Firestore Admin writes | Client SDK from server | `firebase-admin/firestore` `.update()` | Admin SDK bypasses security rules; correct for server-side entitlement writes |
| Gemini prompt response parsing | Ad-hoc string splitting | Structured JSON mode or explicit JSON extraction | Gemini can return malformed JSON; need robust parsing with fallback |

**Key insight:** The entire client-side flow (`stripe-checkout.ts`, `useEntitlements.ts`, `AIWorkoutConfig.tsx`) is already wired correctly — only the server side (the functions themselves) is missing. This phase is pure backend work.

---

## Common Pitfalls

### Pitfall 1: rawBody vs body in Stripe Webhook
**What goes wrong:** `stripe.webhooks.constructEvent()` throws "No signatures found matching the expected signature for payload" even with the correct secret.
**Why it happens:** Express body-parser (which Firebase Functions uses internally) mutates the raw bytes. The parsed `request.body` is no longer byte-identical to what Stripe signed.
**How to avoid:** Always use `request.rawBody` (a `Buffer`) — not `request.body` — as the first argument to `constructEvent()`. Firebase Functions v2's `onRequest` exposes `rawBody` on the request object typed correctly.
**Warning signs:** Webhook returns 400 with signature mismatch errors in Firebase Functions logs.

### Pitfall 2: Missing Firebase UID in Stripe Customer Metadata
**What goes wrong:** Webhook fires for `checkout.session.completed`, but the function cannot find which Firestore user to update.
**Why it happens:** The checkout session links to a Stripe customer, and the customer needs a way to map back to Firebase. If `metadata.firebaseUID` was not set at customer creation time, the webhook has no lookup path.
**How to avoid:** In `createCheckoutSession`, always create/retrieve the Stripe customer with `metadata: { firebaseUID: uid }` before creating the session.
**Warning signs:** Webhook handler logs "No Firebase UID found in customer metadata" and entitlement is never set.

### Pitfall 3: Functions Not Added to firebase.json
**What goes wrong:** `firebase deploy` deploys hosting only; Cloud Functions are never deployed.
**Why it happens:** `firebase.json` currently has no `"functions"` key.
**How to avoid:** Add `"functions": { "source": "functions", "predeploy": "npm --prefix functions run build" }` to `firebase.json` before deploying.
**Warning signs:** `firebase deploy` output mentions no functions deployed; `httpsCallable` calls fail with network errors.

### Pitfall 4: Functions Directory Has No tsconfig.json
**What goes wrong:** TypeScript compilation fails or `npm run build` in functions produces wrong output path.
**Why it happens:** Functions TypeScript needs its own `tsconfig.json` with `"outDir": "./lib"` and `"module": "commonjs"` — different from the PWA's ESM tsconfig.
**How to avoid:** Create `functions/tsconfig.json` with `{ "compilerOptions": { "module": "commonjs", "noImplicitReturns": true, "outDir": "lib", "sourceMap": true, "strict": true, "target": "es2017" }, "include": ["src"] }`.
**Warning signs:** `tsc` errors about module resolution or missing `lib/` directory.

### Pitfall 5: Gemini Response Parsing Failure
**What goes wrong:** Gemini returns a workout that can't be parsed into the `GeneratedWorkout` shape, causing the Cloud Function to throw and the client to fall back to offline generation silently.
**Why it happens:** LLMs don't always return perfectly structured JSON. The Cloudflare proxy already solved this — the prompt format that works is known.
**How to avoid:** Port the same prompt structure from the Cloudflare worker (`workout-proxy.sundeefundee.workers.dev/generate-workout`). Wrap the JSON parse in try/catch and return a clear error so the client can fall back gracefully.
**Warning signs:** `generateAIWorkout` function throws JSON parse errors in logs.

### Pitfall 6: Cold Start on Checkout Session Call
**What goes wrong:** First-time `createStripeCheckoutSession` call takes 3-5 seconds, causing a slow UX moment before the Stripe redirect.
**Why it happens:** Firebase Functions v2 cold starts for Node.js. The Stripe SDK initialization is synchronous but the function container may not be warm.
**How to avoid:** Set `minInstances: 1` on the checkout function to keep one container warm, or accept the latency for v1 launch (it only happens once per cold start period).

---

## Code Examples

### functions/tsconfig.json
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "moduleResolution": "node",
    "noImplicitReturns": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017",
    "esModuleInterop": true
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

### functions/src/index.ts
```typescript
import * as admin from 'firebase-admin';

// Initialize once — guard prevents duplicate init
if (!admin.apps.length) {
  admin.initializeApp();
}

export { generateAIWorkout } from './generateAIWorkout';
export { createStripeCheckoutSession } from './createCheckoutSession';
export { stripeWebhook } from './stripeWebhook';
```

### Secret definitions (reused across files)
```typescript
// Source: https://firebase.google.com/docs/functions/config-env
import { defineSecret } from 'firebase-functions/params';

export const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
export const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
export const geminiApiKey = defineSecret('GEMINI_API_KEY');
```

### functions/.secret.local (local emulator, gitignored)
```
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
GEMINI_API_KEY=AIza...
```

### Deploying secrets to Cloud Secret Manager
```bash
# Run once per secret — Firebase CLI handles the rest
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase functions:secrets:set GEMINI_API_KEY
```

### Local development workflow
```bash
# Terminal 1: start emulator with functions
cd /path/to/project && firebase emulators:start --only functions,firestore

# Terminal 2: forward Stripe events to emulator
stripe listen --forward-to http://localhost:5001/sundee-fundee/us-central1/stripeWebhook
# Stripe CLI prints a whsec_ secret — put it in .secret.local as STRIPE_WEBHOOK_SECRET

# Terminal 3: trigger test checkout event
stripe trigger checkout.session.completed
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `@google/generative-ai` (legacy SDK) | `@google/genai` (GA SDK) | May 2025 | New SDK is stable, maintained, and recommended for production |
| Functions v1 `(data, context)` params | Functions v2 single `(request)` param | 2023 | v2 is now standard; v1 is legacy |
| `.env` files for secrets | `defineSecret()` + Cloud Secret Manager | 2022+ | Encrypted at rest, no plaintext keys in deployment artifacts |
| Stripe API version default | Must specify `apiVersion: "2025-01-27.acacia"` | Jan 2025 | Stripe SDKs now require explicit API version |

**Deprecated/outdated:**
- `functions.config()` (v1 env): Replaced by `defineSecret()` and `defineString()` params in v2
- Cloudflare worker proxy at `workout-proxy.sundeefundee.workers.dev`: Being replaced by BACK-01

---

## Open Questions

1. **Gemini prompt format from the Cloudflare worker**
   - What we know: The existing worker uses `contents`, `systemInstruction`, `generationConfig` (Gemini native format). The domain layer has `WorkoutGenerationContext` and `offline-workout-generator.ts` as a reference for the expected output shape.
   - What's unclear: The exact prompt text and response JSON schema used by the Cloudflare worker — not visible in the PWA source. The Cloud Function prompt will need to be written or the worker endpoint queried to reverse-engineer it.
   - Recommendation: Write the Gemini prompt using `WorkoutGenerationContext` fields as inputs, targeting `GeneratedWorkout` as the JSON schema. Use `responseMimeType: 'application/json'` in `generationConfig` if available with `@google/genai`.

2. **Stripe Idempotency for Checkout Session**
   - What we know: Serverless functions can execute multiple times for one user action.
   - What's unclear: Whether an idempotency key is needed on `checkout.sessions.create()` for this use case.
   - Recommendation: Pass `idempotencyKey: uid + '-' + Date.now()` as the third argument to Stripe API calls as a best practice, especially for checkout session creation.

3. **CORS configuration for Cloud Functions**
   - What we know: `httpsCallable` from the Firebase JS SDK handles CORS automatically for `onCall` functions when called from a Firebase-authenticated app.
   - What's unclear: Whether any explicit CORS config is needed for the `stripeWebhook` `onRequest` endpoint (called only by Stripe servers, not browsers).
   - Recommendation: No CORS needed on the webhook — it is server-to-server. The `onCall` functions handle CORS automatically.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest 4.x |
| Config file | `pwa/vitest.config.ts` |
| Quick run command | `cd pwa && npx vitest run src/domain/__tests__/ai-workout.test.ts` |
| Full suite command | `cd pwa && npx vitest run` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BACK-01 | AI workout generation function auth-gates unauthenticated calls | unit (function logic) | `cd pwa && npx vitest run src/domain/__tests__/ai-workout.test.ts` | ✅ (domain tests exist; function integration test = Wave 0) |
| BACK-01 | `generateOfflineWorkout` returns valid `GeneratedWorkout` shape | unit | `cd pwa && npx vitest run src/domain/__tests__/ai-workout.test.ts` | ✅ |
| BACK-02 | `redirectToCheckout` calls `httpsCallable` correctly | unit | `cd pwa && npx vitest run` | ✅ (manual smoke via emulator) |
| BACK-03 | Webhook writes `premiumEntitlement.active = true` to Firestore | integration (emulator) | `stripe trigger checkout.session.completed` against emulator | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd pwa && npx vitest run src/domain/__tests__/ai-workout.test.ts`
- **Per wave merge:** `cd pwa && npx vitest run`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `pwa/src/entitlements/__tests__/stripe-checkout.test.ts` — unit test for `redirectToCheckout` calling `httpsCallable` (covers BACK-02 client side)
- [ ] Emulator-based integration test for webhook entitlement write (covers BACK-03 E2E) — manual verification acceptable for phase gate

*(The existing `pwa/src/domain/__tests__/ai-workout.test.ts` covers domain logic for BACK-01; the Cloud Function itself is server-side and tested via emulator smoke test, not Vitest.)*

---

## Sources

### Primary (HIGH confidence)
- [firebase.google.com/docs/functions/callable](https://firebase.google.com/docs/functions/callable) — v2 onCall TypeScript auth pattern, `HttpsError` codes
- [firebase.google.com/docs/functions/config-env](https://firebase.google.com/docs/functions/config-env) — `defineSecret()` usage and `.secret.local` for emulator
- [github.com/googleapis/js-genai](https://github.com/googleapis/js-genai) — `@google/genai` package, `generateContent` API, system instructions
- [docs.stripe.com/webhooks/signature](https://docs.stripe.com/webhooks/signature) — Stripe signature verification requirements

### Secondary (MEDIUM confidence)
- [aronschueler.de — Implementing Stripe Subscriptions (March 2025)](https://aronschueler.de/blog/2025/03/17/implementing-stripe-subscriptions-with-firebase-cloud-functions-and-firestore/) — complete working code for checkout session + webhook + Firestore write pattern; verified against official Stripe and Firebase docs
- [firebase.google.com/docs/functions/typescript](https://firebase.google.com/docs/functions/typescript) — functions directory structure, tsconfig.json, `lib/` output convention

### Tertiary (LOW confidence)
- [bitesite.ca — Raw Body for Stripe Webhooks](https://www.bitesite.ca/blog/raw-body-for-stripe-webhooks-using-firebase-cloud-functions) — rawBody TypeScript augmentation patterns; verified concept against Firebase GitHub issues

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `firebase-functions` v2, `firebase-admin`, `stripe`, `@google/genai` are all official packages with current documentation
- Architecture: HIGH — onCall/onRequest patterns are canonical Firebase v2 patterns; rawBody requirement is documented in Stripe and Firebase sources
- Pitfalls: HIGH — rawBody vs body is a well-documented, commonly-hit issue with multiple official sources; UID-in-metadata pattern confirmed in 2025 implementation guide

**Research date:** 2026-03-21
**Valid until:** 2026-09-21 (stable APIs — Firebase Functions v2 and Stripe Checkout are mature)
