# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sundee Fundee is a web-based PWA for cycle-aware strength training. Next.js 16 + TypeScript + Tailwind CSS 4, deployed to Vercel with Firebase (Auth, Firestore, Cloud Functions).

## Commands

### Development
```bash
cd web-app
npm run dev              # Next.js dev server (http://localhost:3000)
```

### Build
```bash
cd web-app
npm run build            # Next.js production build (+ sitemap generation)
```

### Test
```bash
cd web-app
npm test                 # Run all tests (Vitest)
npm run test:watch       # Watch mode
npm run test:coverage    # Coverage report (domain layer only)
```

### Lint
```bash
cd web-app
npm run lint             # ESLint
```

### Cloud Functions
```bash
cd firebase/functions
npm run build            # Compile TypeScript
npm run deploy           # Deploy functions to Firebase
```

### Deploy
Vercel auto-deploys on push to `main`. Cloud Functions deployed separately:
```bash
firebase deploy --only functions
firebase deploy --only firestore:rules
```

## Architecture

```
Next.js App Router on Vercel (React 19 Server Components)
    ↓
API Routes (/api/auth/session, /api/stripe, /api/ai)
    ↓
Firebase Admin SDK (server-side auth + Firestore)
    ↓
Firebase Auth + Firestore (NoSQL)
    ↓
Cloud Functions (AI workout generation via Vertex AI)
    ↓
Domain/ (pure TypeScript, zero dependencies, 100% tested)
```

### Key Directories

- **`web-app/`** — Main application (Next.js PWA)
  - **`src/app/(auth)/`** — Sign in / sign up pages (Firebase Auth SDK)
  - **`src/app/(features)/`** — Protected routes: dashboard, workouts, programs, maxes, benchmarks, cycle, settings
  - **`src/app/(marketing)/`** — Public pages: blog, privacy, terms, support
  - **`src/app/api/`** — API routes: auth session, AI generation, Stripe webhooks
  - **`src/lib/firebase.ts`** — Firebase Client SDK initialization
  - **`src/lib/firebase-admin.ts`** — Firebase Admin SDK initialization (server-side)
  - **`src/lib/firestore.ts`** — Firestore helpers: `getAuthUser()`, `userCollection()`, `userDoc()`
  - **`src/lib/domain/`** — Pure business logic: weight calculations, cycle phases, injury adaptation, benchmark catalog, subscription tiers. No framework dependencies — fully unit tested.
  - **`src/lib/stripe.ts`** — Stripe price ID mapping
  - **`src/lib/blog.ts`** — MDX blog post parser
  - **`src/lib/theme.ts`** — Art Deco design tokens (cream/navy/orange)
  - **`src/components/`** — UI primitives (`button`, `card`, `input`) + layout (`bottom-nav`)
  - **`src/components/providers/auth-provider.tsx`** — Firebase Auth React context
  - **`content/blog/`** — MDX blog posts
- **`firebase/functions/`** — Cloud Functions for AI workout generation (Vertex AI Gemini)
  - **`src/index.ts`** — `generateWorkoutFn` callable function
  - **`src/ai.ts`** — Vertex AI Gemini integration
  - **`src/rate-limit.ts`** — Firestore-based daily rate limiting
- **`wod-dashboard/`** — Admin dashboard for WODs, programs, benchmarks
  - **`data/`** — Shared JSON data files (programs.json, wods.json, benchmarks.json)

### Auth & Routing

Firebase Auth with session cookies for server-side verification.

**Providers:** Google OAuth, Apple Sign-In, Email/Password.

**Social auth:** `src/lib/social-auth.ts` contains shared `signInWithGoogle()` and `signInWithApple()` helpers used by both sign-in and sign-up pages. `signInWithPopup` handles account creation and login automatically — no separate logic needed per page.

**Apple Sign-In quirks:** Apple only sends the user's name on the **first** authorization. `signInWithApple()` extracts the name from the Apple ID token and calls `updateProfile`. If a user revokes and re-authorizes, the name is sent again. Firebase Console requires the full OAuth code flow config (Team ID, Key ID, Private Key from `.p8` file) for web — the toggle alone is not enough.

**Client-side:** Firebase Client SDK (`firebase/auth`) handles sign-in flows via dynamic imports (required to avoid SSR pre-render failures). `AuthProvider` context wraps the app, syncs Firebase ID tokens to server-side session cookies via `/api/auth/session`. Use `getFirebaseAuth()` from `src/lib/firebase.ts` — never import `firebase/auth` at the top level of client components.

**Server-side:** Firebase Admin SDK verifies session cookies. `getAuthUser()` from `src/lib/firestore.ts` returns `{ uid, email, name }` or `null`.

**Middleware** (`src/middleware.ts`) checks for `__session` cookie presence on protected routes:
- `/dashboard`, `/workouts`, `/programs`, `/maxes`, `/benchmarks`, `/cycle`, `/settings`

Marketing routes (`/blog`, `/privacy`, `/terms`, `/support`) and auth routes (`/sign-in`, `/sign-up`) are unprotected.

**Always use `user.uid`** for data ownership queries.

**Environment variables:**
- `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` — Admin SDK
- `NEXT_PUBLIC_FIREBASE_API_KEY` / `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` / `NEXT_PUBLIC_FIREBASE_PROJECT_ID` — Client SDK
- `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` — Stripe server-side
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` / `NEXT_PUBLIC_APP_URL` — Stripe client-side + redirects

**Apple Sign-In Firebase Config** (set in Firebase Console, not env vars): Services ID (`com.sundeefundee.web`), Apple Team ID, Key ID, and `.p8` private key. Apple Developer Services ID must have `sundee-fundee.firebaseapp.com` and `sundeefundee.com` as authorized domains with return URL `https://sundee-fundee.firebaseapp.com/__/auth/handler`.

### Database

Cloud Firestore (NoSQL). Access via Firebase Admin SDK in server actions and API routes.

**Data model:**
- **`users/{uid}`** — User profile: experienceLevel, primaryGoal, gender, weightUnit, cycleTrackingEnabled, onboardingComplete
- **`users/{uid}/oneRepMaxes/{id}`** — 1RM tracking
- **`users/{uid}/completedWorkouts/{id}`** — Workouts with sets array (denormalized)
- **`users/{uid}/enrolledPrograms/{id}`** — Program enrollment
- **`users/{uid}/periodLogs/{id}`** — Cycle period logs
- **`users/{uid}/cycleSettings/default`** — Cycle settings (single doc)
- **`users/{uid}/benchmarkResults/{id}`** — Benchmark results
- **`users/{uid}/subscription/current`** — Stripe subscription (single doc)
- **`users/{uid}/generatedWorkoutRecords/{id}`** — AI workout history
- **`users/{uid}/aiUsage/{YYYY-MM-DD}`** — Daily AI rate limit counter
- **`benchmarkDefinitions/{id}`** — Shared benchmark catalog (top-level)

**Security rules** in `web-app/firestore.rules`: User subcollections restricted to `request.auth.uid == userId`. benchmarkDefinitions readable by all authenticated users, writable only via Admin SDK.

**Data access pattern in server actions:**
```typescript
const user = await getAuthUser();
if (!user) return [];
const snapshot = await userCollection(user.uid, "collectionName").orderBy("date", "desc").get();
return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
```

### Offline / PWA

**Service worker:** Serwist (`src/app/sw.ts`) — precaching, runtime caching, navigation preload. Disabled in dev (conflicts with Turbopack). Compiles to `public/sw.js`.

**Manifest:** `public/manifest.json` — standalone display, portrait orientation, 192/512 icons.

### Subscriptions

Stripe integration with checkout sessions, webhooks, and customer portal.

**Price IDs** (in `src/lib/stripe.ts`):
- `price_plus_monthly` / `price_plus_annual`
- `price_premium_monthly` / `price_premium_annual`

**Tiers** (in `src/lib/domain/subscription.ts`):
- **Free** — 5 lifts, 1 injury, 30-day history, 0 cloud AI/day
- **Sundee Plus** — unlimited lifts/injuries/history, 1 cloud AI/day, custom benchmarks, pain trends
- **Sundee Premium** — unlimited all, 10 cloud AI/day, rehab sessions, AI coach memory, plateau detection

**Webhook events** (`src/app/api/stripe/webhook/route.ts`):
- `checkout.session.completed` — upsert subscription in `users/{uid}/subscription/current`
- `customer.subscription.updated` — update tier/status/expiry
- `customer.subscription.deleted` — mark canceled

**Portal** (`src/app/api/stripe/portal/route.ts`): Creates Stripe billing portal from user's `stripeCustomerId`.

### AI Workouts

**Cloud Function** (`firebase/functions/src/index.ts`) — `generateWorkoutFn` callable function. Uses Vertex AI Gemini Flash + Firestore rate limiting.

**Web-app API route** (`src/app/api/ai/generate/route.ts`): Authenticates user, checks subscription tier, rate limits, calls Vertex AI directly, saves record to Firestore.

**Domain logic** (`src/lib/domain/ai-workout.ts`):
- `energyMultiplier(level)` — low: 0.85, medium: 1.0, high: 1.05
- `cyclePhaseMultiplier(phase)` — applies phase-specific load adjustments
- `defaultPercentage(reps)` — maps rep count to %1RM (1–3: 85%, 6–8: 70%, 9–12: 65%)
- `assignRestMinutes(bodyweight, reps)` — heavy: 2.5min, light: 1.5min
- `applyWeights(exercises, maxes, energyMult, cycleMult)` — calculates prescribed weights from 1RM
- `findMatchingMax(exerciseName, maxes)` — fuzzy match exercise to user's 1RM data

### Blog / SEO

**Content:** MDX files in `content/blog/*.mdx`. Parsed with `gray-matter` (YAML frontmatter), rendered with `next-mdx-remote`.

**Frontmatter format:**
```yaml
---
title: "Post Title"
description: "Brief description"
date: "2026-03-29"
author: "Author Name"
tags: ["training", "cycle"]
image: "/optional-image.jpg"
---
```

**Routes:** `/blog` (list, sorted by date desc), `/blog/[slug]` (individual post).

**Sitemap** (`next-sitemap.config.js`): Generated on `npm run build`. Site URL: `https://sundeefundee.com`. Excludes `/api/*` and all protected feature routes.

### Testing

- **Framework:** Vitest with v8 coverage provider
- **Coverage scope:** `src/lib/domain/**` only (pure business logic)
- **Convention:** Tests in `src/lib/domain/__tests__/`. One test file per domain module.
- **Pattern:** Pure function unit tests — no mocking needed. Helper factories at top of each file (e.g., `makeProgram()`, `makeInjury()`).
- **When adding new domain types or functions**, add corresponding tests. Maintain full coverage of the domain layer.
- **Never ignore pre-existing failures.** If test runs, builds, or CI surface issues that predate your changes, investigate and resolve them.

### WOD Dashboard Patterns

When adding a new entity type to the dashboard (`wod-dashboard/`):
1. Add type to `src/lib/types.ts`
2. Add path to `src/lib/paths.ts`
3. Create API route at `src/app/api/<entity>/route.ts` (GET/PATCH/DELETE, uses `readJSONFile`/`writeJSONFile`)
4. Add CloudKit save function to `src/lib/cloudkit.ts`
5. Update `src/app/api/cloudkit/publish/route.ts` to support the new type
6. Create list + editor components in `src/components/`
7. Create page at `src/app/<entity>/page.tsx` (two-panel split-view)
8. Add nav link to `src/components/sidebar.tsx`

JSON data files live in `wod-dashboard/data/` (programs.json, wods.json, benchmarks.json).

### CloudKit Server-to-Server Auth

The WOD Dashboard uses ECDSA server-to-server authentication (no user sign-in needed). Keys:
- Private key: `wod-dashboard/cloudkit-server.pem` (gitignored)
- Key IDs are environment-scoped: development and production keys are separate
- Signature format: `sha256(date:base64(sha256(body)):subpath)` signed with EC P-256
- Required headers: `X-Apple-CloudKit-Request-KeyID`, `X-Apple-CloudKit-Request-ISO8601Date`, `X-Apple-CloudKit-Request-SignatureV1`

### Coding Conventions

- **Benchmark `roundsAndReps` scoring** encodes as `rounds * 10000 + reps` in a single number. Higher is better. Decode: `rounds = Math.floor(value / 10000)`, `reps = value % 10000`.
- **Disable buttons for invalid input** rather than silently failing on save.
- **Thread `user.uid`** through all data-writing operations. Never hardcode empty strings.
- **Const objects for enums** — use `as const` objects, not TypeScript `enum`. Stored as text fields in Firestore.
- **Discriminated unions** for flexible types (e.g., `ExerciseValue` with `type` field: `fixed`, `amrap`, `range`, `text`).
- **Multiplier-based adaptation** — cycle phase, recovery phase, and energy level compose multiplicatively on base weights.
- **Domain functions are pure** — no side effects, no framework imports. Accept data, return data.
- **Art Deco theme:** cream `#f4f0df`, navy `#0d1a40`, orange `#f27319`. Fonts: Playfair Display (headings), Inter (body), JetBrains Mono (mono).

### Navigation

Bottom nav (`src/components/layout/bottom-nav.tsx`) has 5 tabs:
1. Dashboard (`/dashboard`)
2. Programs (`/programs`)
3. Workouts (`/workouts`)
4. Maxes (`/maxes`)
5. Settings (`/settings`)

Features layout (`src/app/(features)/layout.tsx`) renders `<BottomNav />` with `max-w-lg` container and `pb-16` bottom padding.
