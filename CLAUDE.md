# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sundee Fundee is a web-based PWA for cycle-aware strength training. Next.js 16 + TypeScript + Tailwind CSS 4, deployed to Cloudflare Pages with D1 (SQLite) and KV.

## Commands

### Development
```bash
cd web-app
npm run dev              # Next.js dev server (http://localhost:3000)
npm run preview          # Cloudflare local preview (wrangler dev)
```

### Build
```bash
cd web-app
npm run build            # Next.js production build (+ sitemap generation)
npm run build:cf         # OpenNext adapter build for Cloudflare Pages
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

### Database
```bash
cd web-app
npx drizzle-kit generate   # Generate migration from schema changes
npx drizzle-kit migrate    # Apply migrations
```

### Deploy
Cloudflare Pages auto-deploys on push to `main`. Manual deploy:
```bash
cd web-app
npm run build:cf && npm run deploy
```

## Architecture

```
Next.js App Router (React 19 Server Components)
    ↓
API Routes (/api/auth, /api/stripe, /api/ai)
    ↓
Service Layer (Auth.js, Stripe SDK, Drizzle ORM)
    ↓
Cloudflare D1 (SQLite) + KV (cache/sessions)
    ↓
Domain/ (pure TypeScript, zero dependencies, 100% tested)
```

### Key Directories

- **`web-app/`** — Main application (Next.js PWA)
  - **`src/app/(auth)/`** — Sign in / sign up pages
  - **`src/app/(features)/`** — Protected routes: dashboard, workouts, programs, maxes, benchmarks, cycle, settings
  - **`src/app/(marketing)/`** — Public pages: blog, privacy, terms, support
  - **`src/app/api/`** — API routes: auth, AI generation, Stripe webhooks
  - **`src/db/schema.ts`** — Drizzle ORM schema (19 tables)
  - **`src/lib/auth.ts`** — Auth.js configuration (Google + Apple providers)
  - **`src/lib/domain/`** — Pure business logic: weight calculations, cycle phases, injury adaptation, benchmark catalog, subscription tiers. No framework dependencies — fully unit tested.
  - **`src/lib/stripe.ts`** — Stripe price ID mapping
  - **`src/lib/blog.ts`** — MDX blog post parser
  - **`src/lib/theme.ts`** — Art Deco design tokens (cream/navy/orange)
  - **`src/components/`** — UI primitives (`button`, `card`, `input`) + layout (`bottom-nav`)
  - **`content/blog/`** — MDX blog posts
  - **`drizzle/`** — Database migrations
- **`wod-dashboard/`** — Admin dashboard for WODs, programs, benchmarks
  - **`data/`** — Shared JSON data files (programs.json, wods.json, benchmarks.json)
- **`workers/ai-coach/`** — Cloudflare Worker for AI workout generation (Cloudflare AI binding + KV rate limiting)
- **`functions/`** — Firebase Cloud Functions (legacy)

### Auth & Routing

Auth.js v5 (NextAuth beta) with JWT session strategy.

**Providers:** Google OAuth, Apple Sign-In, Credentials (stub).

**Middleware** (`src/middleware.ts`) protects all feature routes:
- `/dashboard`, `/workouts`, `/programs`, `/maxes`, `/benchmarks`, `/cycle`, `/settings`

Marketing routes (`/blog`, `/privacy`, `/terms`, `/support`) and auth routes (`/sign-in`, `/sign-up`) are unprotected.

**Session callback** embeds `user.id` into JWT token and `session.user.id`. Always use `session.user.id` for data ownership queries.

**Environment variables:**
- `AUTH_SECRET` — JWT signing secret (`openssl rand -base64 32`)
- `AUTH_GOOGLE_ID` / `AUTH_GOOGLE_SECRET` — Google OAuth
- `AUTH_APPLE_ID` / `AUTH_APPLE_SECRET` — Apple Sign-In

### Database

Cloudflare D1 (SQLite) via Drizzle ORM. Schema: `web-app/src/db/schema.ts`. Config: `web-app/drizzle.config.ts`.

**Cloudflare bindings** (defined in `wrangler.jsonc`):
- `DB: D1Database` — SQLite database
- `KV: KVNamespace` — Key-value cache

Accessed via `getCloudflareContext()` from `@opennextjs/cloudflare`. Types in `src/env.d.ts`.

**19 tables:**
- **Auth (Auth.js managed):** `users`, `accounts`, `sessions`, `verificationTokens`
- **Strength tracking:** `oneRepMaxes`, `personalRecords`, `liftMaxes`, `conditioningPrs`
- **Workouts:** `completedWorkouts`, `completedSets`
- **Programs:** `enrolledPrograms`, `enrollmentEvents`
- **Injuries:** `injuryProfiles`, `painLogs`
- **Cycle tracking:** `periodLogs`, `symptomLogs`, `cycleSettings`, `cycleAdaptationPreferences`
- **Benchmarks:** `benchmarkDefinitions`, `benchmarkResults`
- **AI & custom:** `generatedWorkoutRecords`, `customProgramRecords`
- **Subscriptions:** `subscriptions` (Stripe integration)

**`users` table extensions** beyond Auth.js defaults: `experienceLevel`, `primaryGoal`, `gender`, `weightUnit`, `cycleTrackingEnabled`, `onboardingComplete`.

**Enum-as-text convention:** Enums are stored as text columns in SQLite (same pattern as the former CloudKit requirement). Domain types use const objects, not TypeScript `enum`.

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
- `checkout.session.completed` — upsert subscription
- `customer.subscription.updated` — update tier/status/expiry
- `customer.subscription.deleted` — mark canceled

**Portal** (`src/app/api/stripe/portal/route.ts`): Creates Stripe billing portal from user's `stripeCustomerId`.

### AI Workouts

**Cloudflare Worker** (`workers/ai-coach/`) — endpoint at `workout-proxy.sundeefundee.workers.dev/generate-workout`. Uses Cloudflare AI binding + KV rate limiting + JWT auth.

**Web-app API route** (`src/app/api/ai/generate/route.ts`): Authenticates user, injects `userId`, proxies to worker.

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

AI generation routes (`src/app/api/generate/`) follow a shared pattern: accept parameters → build Gemini prompt → POST to Cloudflare Worker → strip markdown fences → parse and validate JSON → return typed response. Currently: `wod/`, `program/`, `benchmark/`.

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
- **Thread `session.user.id`** through all data-writing operations. Never hardcode empty strings.
- **Const objects for enums** — use `as const` objects, not TypeScript `enum`. Stored as text in D1.
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
