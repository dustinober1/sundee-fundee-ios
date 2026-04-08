---
name: External Integrations
type: codebase-map
focus: tech
created: 2026-04-08
---

# External Integrations

**Analysis Date:** 2026-04-08

## Firebase

**Firebase Auth (Web):**
- Purpose: User authentication for the web app (sign-in, sign-up, session management)
- Providers: Google OAuth, Apple Sign-In, Email/Password
- Client SDK: `firebase` 12.11.0 (`firebase/auth` module)
- Admin SDK: `firebase-admin` 13.7.0 (`firebase-admin/auth` module)
- Client init: `web-app/src/lib/firebase.ts` - `getFirebaseAuth()` lazy singleton, dynamic imports required to avoid SSR failures
- Admin init: `web-app/src/lib/firebase-admin.ts` - `adminAuth` lazy proxy, service account credentials from env vars
- Auth context: `web-app/src/components/providers/auth-provider.tsx` - React context wrapping app, syncs ID tokens to session cookies
- Social auth helpers: `web-app/src/lib/social-auth.ts` - `signInWithGoogle()` with popup/redirect fallback; Apple Sign-In with name extraction
- Session cookie API: `web-app/src/app/api/auth/session/route.ts` - POST creates 13-day session cookie, DELETE clears it
- Middleware: `web-app/src/middleware.ts` - Checks `__session` cookie on protected routes
- Env vars: `NEXT_PUBLIC_FIREBASE_API_KEY`, `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`, `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
- Admin env vars: `FIREBASE_PROJECT_ID` (or `NEXT_PUBLIC_FIREBASE_PROJECT_ID`), `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`
- Firebase Console config: Apple Sign-In requires Team ID, Key ID, `.p8` private key, Services ID `com.sundeefundee.web` with authorized domains

**Cloud Firestore:**
- Purpose: Primary database for all user data, subscriptions, blog posts, exercise catalog, admin settings
- Client: Firebase Admin SDK (`firebase-admin/firestore`)
- Admin init: `web-app/src/lib/firebase-admin.ts` - `db` lazy proxy with `ignoreUndefinedProperties: true`
- Firestore helpers: `web-app/src/lib/firestore.ts` - `getAuthUser()`, `userCollection(uid, name)`, `userDoc(uid)`, re-exports `db`
- Admin helpers: `web-app/src/lib/admin-firestore.ts` - `adminCollection()`, `adminDoc()`, `allUsers()`, `userById()`, `userSubcollection()`
- Security rules: `web-app/firestore.rules` - Users can read/write own subcollections (`request.auth.uid == userId`); `benchmarkDefinitions` readable by all authenticated, writable only server-side
- Data model (all under `users/{uid}/`): `oneRepMaxes`, `completedWorkouts`, `enrolledPrograms`, `periodLogs`, `cycleSettings/default`, `benchmarkResults`, `subscription/current`, `generatedWorkoutRecords`, `aiUsage/{YYYY-MM-DD}`
- Top-level collections: `users`, `benchmarkDefinitions`, `blogPosts`, `exerciseCatalog`, `admins`, `adminSettings`

**Cloud Functions:**
- Purpose: Server-side callable function for AI workout generation
- Runtime: Node 20, us-central1, 512MiB memory, 120s timeout
- Entry point: `firebase/functions/src/index.ts` - `generateWorkoutFn` (2nd gen `onCall`)
- Admin SDK auto-init: `initializeApp()` without args (Cloud Functions default credentials)
- Deploy command: `cd firebase/functions && firebase deploy --only functions`

## Stripe

**Purpose:** Subscription billing (Plus and Premium tiers)

**SDK:** `stripe` 21.0.0 (server-side Node.js SDK)

**Client factory:** `web-app/src/lib/stripe.ts`
- `createStripeClient()` - Creates Stripe instance with `STRIPE_SECRET_KEY` env var
- `STRIPE_PRICES` - Maps tier+interval to price IDs (env var overrides with defaults hardcoded)
- `tierFromPriceId()` - Reverse lookup from Stripe price ID to "plus" or "premium"
- API version: `2026-03-25.dahlia`

**Price mapping** (in `web-app/src/lib/stripe.ts`):
- Plus monthly / annual: `STRIPE_PRICE_PLUS_MONTHLY` / `STRIPE_PRICE_PLUS_ANNUAL`
- Premium monthly / annual: `STRIPE_PRICE_PREMIUM_MONTHLY` / `STRIPE_PRICE_PREMIUM_ANNUAL`

**Checkout:** `web-app/src/app/api/stripe/checkout/route.ts`
- Creates Stripe checkout session with subscription mode
- Uses `client_reference_id` = user.uid for webhook correlation
- Metadata: `{ userId, tier, interval }`
- Success redirect: `/settings?session_id={CHECKOUT_SESSION_ID}`

**Webhooks:** `web-app/src/app/api/stripe/webhook/route.ts`
- Events handled: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `customer.subscription.created`
- Verifies signature with `STRIPE_WEBHOOK_SECRET`
- Upserts subscription to `users/{uid}/subscription/current` by userId (checkout) or stripeSubscriptionId (updates/deletes)
- Canceled/unpaid subscriptions reset tier to "free"

**Billing Portal:** `web-app/src/app/api/stripe/portal/route.ts`
- Creates Stripe billing portal session for customer self-service
- Return URL: `/settings`

**Subscription state management:** `web-app/src/lib/subscription-state.ts`
- `resolveEntitlement(uid)` - Determines effective tier, daily AI limits, grace periods
- `getSubscriptionRecord(uid)` - Reads from Firestore `subscription/current`
- `incrementDailyAIUsage(uid)` - Atomically increments daily counter
- `hasActivePaidAccess()` - Checks active/trialing status and grace periods (canceled + `currentPeriodEnd` not expired)
- Admin-configurable rate limits via `adminSettings/config` Firestore doc

**Subscription tier logic:** `web-app/src/lib/domain/subscription.ts`
- Defines feature gates, tracking limits, AI limits per tier
- Free: 5 lifts, 1 injury, 30-day history, 0 cloud AI/day
- Plus: unlimited lifts/injuries/history, 1 cloud AI/day
- Premium: unlimited all, 25 cloud AI/day

**Env vars:** `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`, `NEXT_PUBLIC_APP_URL`

## Vertex AI / Gemini

**Purpose:** AI-powered workout generation and blog post generation

**Two integration paths:**

**1. Cloud Functions (legacy):** `firebase/functions/src/ai.ts`
- SDK: `@google-cloud/vertexai` ^1.9.0
- Model: `gemini-flash-lite-latest`
- Region: us-central1
- Auth: Automatic (Cloud Functions default credentials)
- Callable via: `generateWorkoutFn` in `firebase/functions/src/index.ts`
- Rate limiting: Firestore-based daily counter (`firebase/functions/src/rate-limit.ts`)
  - Plus: 1/day, Premium: 10/day

**2. Web App API route (current):** `web-app/src/app/api/ai/generate/route.ts`
- SDK: `@google/genai` ^1.47.0
- Model config: `web-app/src/lib/ai-generation.ts` - `getAIModelConfig(tier)` returns model name, temperature, max tokens
- Auth: `GEMINI_API_KEY` env var
- Features: Equipment-based catalog filtering, user context enrichment (profile, maxes, recent workouts)
- Prompt building: `web-app/src/lib/ai-generation.ts` - `buildWorkoutPrompt()`, `buildWorkoutSystemInstruction()`
- Response parsing: `parseAIWorkoutResponse()` validates and returns structured workout
- Records: Saves request/response/metadata to `generatedWorkoutRecords` subcollection
- Rate limiting via `subscription-state.ts` with admin-configurable overrides

**3. Admin blog generation:** `web-app/src/app/api/admin/blog/generate/route.ts`
- SDK: `@google/genai`
- Model: `GEMINI_PREMIUM_MODEL` env var (default: `models/gemini-flash-lite-latest`)
- Auth: `GEMINI_API_KEY` env var
- Admin-only (requires `requireAdmin()` check)
- Returns structured blog post JSON (title, description, tags, HTML content)

**Env vars:** `GEMINI_API_KEY`, `GEMINI_PREMIUM_MODEL` (optional override)

## Apple CloudKit (iOS Only)

**Purpose:** Data persistence for the native iOS app (no Firebase dependency on iOS)

**Client:** `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/CloudKitClient.swift`
- Container: `iCloud.com.sundeefundee.app` (hardcoded in `DataClientFactory.swift` and `AuthViewModel.swift`)
- Database scope: Private (default)
- Protocol: `DataClientProtocol` - defines `fetch`, `save`, `delete` operations
- JSON encoding/decoding for record serialization (ISO 8601 dates)
- Thread-safe via `@unchecked Sendable` on actor

**Data layer architecture:**
- Protocol: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/DataClientProtocol.swift`
- Factory: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/DataClientFactory.swift` - Creates CloudKit or mock client
- Mock: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Mocks/MockCloudKitClient.swift` - For testing
- Local fallback: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Actors/LocalDataClient.swift` - Local storage
- Sync queue: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/SyncQueue/` - Offline mutation queue

**WOD Dashboard CloudKit (Server-to-Server):**
- Purpose: Admin dashboard writes programs/WODs/benchmarks to CloudKit from web
- Auth: ECDSA server-to-server (no user sign-in)
- Private key: `wod-dashboard/cloudkit-server.pem` (gitignored)
- Signature: `sha256(date:base64(sha256(body)):subpath)` signed with EC P-256
- Required headers: `X-Apple-CloudKit-Request-KeyID`, `X-Apple-CloudKit-Request-ISO8601Date`, `X-Apple-CloudKit-Request-SignatureV1`
- Note: WOD dashboard directory not present in current repo (referenced in CLAUDE.md)

## Apple Sign-In (iOS)

**Purpose:** Authentication for native iOS app (no Firebase)

- Implementation: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift`
- Session storage: Keychain
- Guest mode: `continueAsGuest()` sets `isGuest = true`, `userID = "guest_local"`, skips CloudKit
- CloudKit writes gated on `!authViewModel.isGuest`

## Serwist (PWA Service Worker)

**Purpose:** Offline support, precaching, runtime caching for web app

**SDK:** `@serwist/next` 9.5.7, `serwist` 9.5.7

**Config:** `web-app/next.config.ts` - `withSerwistInit()` wrapping Next.js config
- Source: `web-app/src/app/sw.ts`
- Output: `public/sw.js`
- Disabled in development (conflicts with Turbopack)
- Auth routes bypass cache via `NetworkOnly` strategy (`/sign-in`, `/sign-up`, `/api/auth/*`, `/__/auth/*`)
- Uses `defaultCache` from `@serwist/next/worker`

**PWA Manifest:** `web-app/public/manifest.json`
- Display: standalone, portrait orientation
- Icons: 192x192 and 512x512 PNG (maskable)
- Theme: cream background, navy theme color

## Blog / Content System

**Purpose:** Blog post storage and rendering

**Storage:** Firestore `blogPosts` collection (not MDX files as previously configured)
- Reader: `web-app/src/lib/blog.ts` - `getAllPosts()` (published, sorted by date desc), `getPostBySlug()` (cached)
- Admin writer: `web-app/src/app/api/admin/blog/route.ts` - CRUD operations on blog posts
- AI generator: `web-app/src/app/api/admin/blog/generate/route.ts` - Uses Vertex AI to generate blog content

**Historical MDX system (may still be present):**
- `gray-matter` 4.0.3 for YAML frontmatter
- `next-mdx-remote` for rendering (if still installed)

## Monitoring & Observability

**Error Tracking:** None (no Sentry, DataDog, or similar)

**Logs:**
- Server-side: `console.error()` with structured context (e.g., `[ai/generate] Error:`, `[auth/session] Failed to create session cookie`)
- Cloud Functions: Standard Cloud Functions logging (default)
- Client-side: `console.error()` in `AuthProvider` for session sync failures

## CI/CD & Deployment

**Hosting:**
- Web app: Vercel (manual deploy via `vercel deploy --prod`)
- Cloud Functions: Google Cloud (manual deploy via `firebase deploy --only functions`)
- Firestore rules: manual deploy via `firebase deploy --only firestore:rules`
- iOS app: Apple App Store (manual via Xcode/App Store Connect)

**CI Pipeline:** None (no GitHub Actions or similar)

## Environment Configuration

**Required env vars (web app):**
- `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` - Firebase Admin SDK
- `NEXT_PUBLIC_FIREBASE_API_KEY` / `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` / `NEXT_PUBLIC_FIREBASE_PROJECT_ID` - Firebase Client SDK
- `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` - Stripe server-side
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` / `NEXT_PUBLIC_APP_URL` - Stripe client-side + redirects
- `GEMINI_API_KEY` - Vertex AI (web app API route)
- `GEMINI_PREMIUM_MODEL` - Optional model override for admin blog generation

**Required env vars (Cloud Functions):**
- Auto-configured via Cloud Functions default credentials
- `GCLOUD_PROJECT` or `GOOGLE_CLOUD_PROJECT` - Project ID for Vertex AI

**Required env vars (Stripe price overrides, optional):**
- `STRIPE_PRICE_PLUS_MONTHLY` / `STRIPE_PRICE_PLUS_ANNUAL`
- `STRIPE_PRICE_PREMIUM_MONTHLY` / `STRIPE_PRICE_PREMIUM_ANNUAL`

**Secrets location:**
- Vercel environment variables (production)
- Firebase Cloud Functions environment (production)
- `.env` files not present in repo (correctly gitignored)

## Sitemap & SEO

**Tool:** `next-sitemap` 4.2.3

**Config:** `web-app/next-sitemap.config.js`
- Site URL: `https://sundeefundee.com`
- Generates `robots.txt`
- Excludes: `/api/*`, `/admin/*`, all protected feature routes (`/dashboard`, `/workouts/*`, `/programs/*`, `/maxes`, `/benchmarks/*`, `/cycle`, `/settings`)
- Runs on `postbuild` step

## Admin System

**Purpose:** Internal admin dashboard for user management, content, and monitoring

**Auth:** `web-app/src/lib/admin-auth.ts`
- `requireAdmin()` - Verifies user is authenticated AND listed in `admins` Firestore collection
- `isAdmin(uid)` - Checks `admins/{uid}` document existence

**Admin API routes:** `web-app/src/app/api/admin/`
- User management: `/admin/users/`, `/admin/users/[uid]/`
- Blog CRUD + AI generation: `/admin/blog/`, `/admin/blog/generate/`, `/admin/blog/[slug]`
- Exercise catalog: `/admin/catalog/`, `/admin/catalog/[id]`
- WODs: `/admin/wods/`, `/admin/wods/[id]`
- Programs: `/admin/programs/`, `/admin/programs/[id]`
- Benchmarks: `/admin/benchmarks/`, `/admin/benchmarks/[id]`
- AI prompt management: `/admin/ai/prompts/`, `/admin/ai/prompts/[id]`, `/admin/ai/generations/`
- Settings: `/admin/settings/`, `/admin/settings/admins/`
- Data export/import: `/admin/export/[collection]`, `/admin/import/[collection]`
- Subscriptions: `/admin/subscriptions/`
- Stats: `/admin/stats/`
- Support tickets: `/admin/support/`, `/admin/support/[slug]`

## Webhooks & Callbacks

**Incoming:**
- Stripe webhook: `POST /api/stripe/webhook` - Handles checkout, subscription lifecycle events
- Firebase Auth rewrite: `/__/auth/*` proxied to `sundee-fundee.firebaseapp.com` (for Auth iframe)

**Outgoing:**
- Stripe checkout sessions (client-side redirect)
- Stripe billing portal (client-side redirect)

---

*Integration audit: 2026-04-08*
