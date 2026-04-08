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
No CI/CD pipeline in GitHub. Web app is deployed manually via `vercel deploy --prod`. Cloud Functions deployed separately:
```bash
cd web-app
vercel deploy --prod       # Deploy web app to Vercel
cd ../firebase/functions
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

## iOS App (Native SwiftUI)

Two directories for the native app:
- **`SundeeFundee/`** — Swift Package (`SundeeFundeeKit`): all domain logic, views, viewmodels, auth, CloudKit
- **`SundeeFundeeApp/`** — Xcode project that imports the package; entry point: `SundeeFundeeApp/SundeeFundee/App.swift`

### Key Files

- **`SundeeFundeeKit/UI/App/SundeeFundeeApp.swift`** — `AuthView`, `MainTabView`, `ThemeViewModel` (all in one file)
- **`SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift`** — auth state; `isGuest` flag for guest/test mode
- **`SundeeFundeeKit/UI/Theme/AppTheme.swift`** — `AppTheme.*` tokens + `.artDecoBackground()` modifier

### Auth

- Apple Sign In only (no Firebase); session stored in Keychain; user data saved to CloudKit
- Guest mode: `authViewModel.continueAsGuest()` sets `isGuest = true`, `userID = "guest_local"`, skips CloudKit
- Gate CloudKit writes on `!authViewModel.isGuest`

### Patterns

- Simulator screenshots showing a cream card on white = `AuthView` (not the web app sign-in page)
- SwiftUI views need `.frame(maxWidth: .infinity, maxHeight: .infinity)` before `.artDecoBackground()` to fill screen

### App Store Requirements

- **Privacy Manifest** (`PrivacyInfo.xcprivacy`) is required — declares API usage (UserDefaults CA92.1) and collected data types (HealthKit, Fitness, UserID)
- **UIRequiredDeviceCapabilities** must be `arm64`, not `armv7` (deprecated, causes rejection)
- **Code signing** should be `CODE_SIGN_STYLE = Automatic` — don't hardcode `iPhone Developer`
- **App icon**: Single 1024x1024 universal icon is sufficient for modern Xcode (auto-generates all sizes)
- **Screenshot dimensions**: iPhone 6.5" = 1284x2778, iPad 12.9" = 2048x2732 (not 1290x2796)
- **Subscription apps** must include Terms of Use + Privacy Policy links in the App Store description
- **Privacy Policy URL** is set in App Store Connect > Distribution > App Privacy (not in the version page)
- **App Review notes** should include steps to find IAP if the purchase flow isn't on the main screen

### iOS Simulator UI Automation Quirks

- SwiftUI `Toggle` (AXSwitch) doesn't respond to `tap` by label — use `touch` with coordinates on the switch knob
- Tab bar items on iPhone may not expose individual children in accessibility — use coordinate taps
- iPad has "Next Page" button in tab bar overflow when there are more than ~5 tabs
- Guest mode requires completing onboarding flow before reaching main app screens

### App Store Marketing Screenshots

- Raw simulator screenshots saved to `screenshots/`
- Enhanced marketing images (with navy background + headline) generated via `scripts/generate_appstore_marketing.py` (Pillow)
- iPhone output: `screenshots/appstore/` (1284x2778)
- iPad output: `screenshots/appstore_ipad/` (2048x2732)
- Art Deco theme: navy `#0d1a40` background, cream `#f4f0df` headlines

## Git Workflow

- **Commit each file separately** — stage and commit one file at a time rather than bundling changes together

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Sundee Fundee — Repo Cleanup**

Sundee Fundee is a cycle-aware strength training app for iPhone. The PWA (Next.js web app) is being retired in favor of the native iOS app. This project cleans up the repository to contain only the Apple-native codebase — the Swift Package (SundeeFundeeKit) and Xcode project (SundeeFundeeApp) — by archiving all other files into a zip and removing them.

**Core Value:** A clean, iOS-only repository with no web app remnants, updated docs reflecting the native-only direction.

### Constraints

- **Preserve:** Only `SundeeFundee/` and `SundeeFundeeApp/` directories remain
- **Backup:** All removed files must be zipped first before deletion
- **No data loss:** The zip serves as the archive of all web/Firebase/backend code
- **Build integrity:** Xcode project must still build after cleanup
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- TypeScript 5.x - Web app (`web-app/`), Cloud Functions (`firebase/functions/`), domain logic, API routes, React components
- Swift 6.0 (strict concurrency) - iOS app (`SundeeFundee/` Swift Package, `SundeeFundeeApp/` Xcode project)
- JavaScript (ESM) - PostCSS config, ESLint config, next-sitemap config
- Python 3 - Marketing screenshot generation scripts (`scripts/generate_appstore_marketing.py`, `scripts/generate_ipad_marketing.py`)
- MDX - Blog content (`content/blog/`)
- CSS (Tailwind) - Styling via `@tailwindcss/postcss` v4
## Runtime
- Node.js 25.x (development machine: v25.9.0)
- Cloud Functions require Node 20 (`firebase/functions/package.json` engines field)
- iOS: deployment target iOS 18.0, requires arm64
- Swift 6.3 toolchain (swiftlang-6.3.0.123.5)
- npm 11.x (web app and Cloud Functions; lockfiles present at `web-app/package-lock.json` and `firebase/functions/package-lock.json`)
- Swift Package Manager (iOS; `SundeeFundee/Package.swift`)
## Frameworks
- Next.js 16.2.1 - Web app framework (App Router, React Server Components, Turbopack in dev)
- React 19.2.4 - UI library
- SwiftUI - iOS native UI (`SundeeFundeeKit/UI/` views)
- Firebase Functions 6.3.0 - Cloud Functions runtime (2nd gen, `onCall`)
- Vitest 4.1.2 - Unit testing framework (web app domain layer)
- Vitest coverage-v8 4.1.2 - Coverage provider
- XCTest - iOS unit tests (`SundeeFundeeKitTests` target)
- Turbopack - Dev bundler (enabled via `turbopack: {}` in `web-app/next.config.ts`)
- TypeScript 5.x - Type checking (web app target ES2018, functions target ES2022)
- ESLint 9.x with `eslint-config-next` - Linting (config: `web-app/eslint.config.mjs`)
- Tailwind CSS 4 via `@tailwindcss/postcss` - Styling (config: `web-app/postcss.config.mjs`)
- Serwist 9.5.7 - PWA service worker generation (config: `web-app/next.config.ts`)
- XcodeGen (`project.yml`) - Xcode project generation for iOS app
- Xcode 16.0+ - iOS build tool
## Key Dependencies
- `firebase` 12.11.0 - Client SDK: Auth, Firestore (web app)
- `firebase-admin` 13.7.0 - Admin SDK: server-side Auth verification, Firestore access (web app API routes and Cloud Functions)
- `stripe` 21.0.1 - Payment processing: checkout sessions, webhooks, billing portal
- `@google/genai` ^1.47.0 - Vertex AI Gemini client for web app AI workout generation
- `@google-cloud/vertexai` ^1.9.0 - Vertex AI Gemini client for Cloud Functions
- `next` 16.2.1 - Core framework
- `@serwist/next` 9.5.7 - PWA service worker integration with Next.js
- `next-sitemap` 4.2.3 - Sitemap and robots.txt generation on build
- `gray-matter` 4.0.3 - MDX/YAML frontmatter parsing (blog posts)
- `sanitize-html` 2.17.2 - HTML sanitization
- `@tiptap/*` 3.21.0 - Rich text editor (code-block, image, link, placeholder extensions)
- `tsx` 4.21.0 - TypeScript execution helper
- `@types/node` 20.x, `@types/react` 19.x, `@types/react-dom` 19.x - Type definitions
## Configuration
- Path alias: `@/*` maps to `./src/*` (TypeScript and Vitest)
- TypeScript strict mode enabled in all projects
- Swift strict concurrency: `SWIFT_STRICT_CONCURRENCY: complete`
- ESLint: core-web-vitals + typescript configs from `eslint-config-next`
- Turbopack enabled in dev mode; Serwist disabled in dev (webpack/Turbopack conflict)
- `web-app/next.config.ts` - Next.js config with Serwist PWA, Firebase Auth rewrites, security headers
- `web-app/tsconfig.json` - TypeScript config (ES2018 target, bundler module resolution)
- `firebase/functions/tsconfig.json` - Functions TypeScript config (ES2022 target, commonjs output to `lib/`)
- `web-app/vitest.config.ts` - Test config (globals, node environment, v8 coverage on `src/lib/domain/**`)
- `web-app/postcss.config.mjs` - PostCSS with `@tailwindcss/postcss`
- `web-app/next-sitemap.config.js` - Sitemap generation (excludes API and protected routes)
- `web-app/eslint.config.mjs` - ESLint flat config
- `SundeeFundee/Package.swift` - Swift Package (iOS 18, macOS 15, watchOS 11)
- `SundeeFundeeApp/project.yml` - XcodeGen project config
- Bundle ID: `com.sundeefundee.app`
- Development team: `87VVCMCW3F`
- Code signing: Automatic (`CODE_SIGN_STYLE` not hardcoded)
- Widgets extension: `com.sundeefundee.app.widgets`
- App Group: `group.com.sundeefundee.shared`
## Platform Requirements
- Node.js 20+ (Cloud Functions engine requirement; dev machine runs 25.x)
- npm 11.x
- Xcode 16.0+ with Swift 6.0+
- Firebase CLI (for Cloud Functions deployment)
- Vercel CLI (for web app deployment)
- Web app: Vercel (Next.js 16, App Router, SSR)
- Cloud Functions: Google Cloud (us-central1, 512MiB memory, 120s timeout)
- iOS app: Apple App Store (iOS 18.0+)
- Database: Cloud Firestore (NoSQL, us-central1)
- AI: Vertex AI Gemini (us-central1)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- TypeScript/React files: kebab-case (`weight-calculations.ts`, `bottom-nav.tsx`, `auth-provider.tsx`)
- Test files: match source module name with `.test.ts` suffix (`weight-calculations.test.ts`)
- Swift files: PascalCase (`AppTheme.swift`, `WeightCalculatorTests.swift`)
- Swift test files: PascalCase with `Tests` suffix (`WeightCalculatorTests.swift`)
- Pure domain functions: camelCase (`roundToNearestFive`, `calculateTargetWeight`, `applyWeights`)
- Server actions: camelCase async functions (`getCycleStatus`, `getDashboardStats`)
- React components: PascalCase named exports (`Button`, `Card`, `PageHeader`)
- Swift functions: camelCase (`defaultPercentage`, `calculatePrescribedWeight`)
- Constants: UPPER_SNAKE_CASE for true constants (`STANDARD_BARBELL_KG`, `SESSION_EXPIRY_MS`, `PLUS_FEATURES`)
- Regular variables: camelCase
- Private/instance prefix: underscore for unused params (`_feature`, `_currentTier`)
- Interfaces: PascalCase (`ProgramExercise`, `CycleSettings`, `DashboardStats`)
- Type aliases: PascalCase (`WorkoutFocus`, `EnergyLevel`, `EquipmentAccess`)
- Enums: PascalCase const objects (`ExperienceLevel`, `SubscriptionTier`, `CyclePhase`)
## Code Style
- No Prettier config detected; formatting follows ESLint + TypeScript conventions
- Tailwind CSS 4 with `@theme` directive in `web-app/src/app/globals.css`
- Indentation: 2 spaces (TypeScript/React)
- ESLint 9 with `eslint-config-next` (core-web-vitals + typescript)
- Config: `web-app/eslint.config.mjs`
- Key rule: unused vars prefixed with `_` are ignored (`argsIgnorePattern: "^_"`, `varsIgnorePattern: "^_"`)
- Strict mode enabled (`"strict": true` in `tsconfig.json`)
- Target: ES2018, module resolution: bundler
- Path alias: `@/*` maps to `./src/*`
- No `enum` keyword -- use `as const` objects with derived types
## Import Organization
- `@/*` resolves to `web-app/src/*` (configured in both `tsconfig.json` and `vitest.config.ts`)
- Firebase Auth is always dynamically imported in client components to avoid SSR failures:
- Never import `firebase/auth` at the top level of client components.
## Component Patterns
- Feature pages are async Server Components (`web-app/src/app/(features)/**/page.tsx`)
- They call server actions directly and pass data to child components
- Authentication check at top: `const user = await getAuthUser(); if (!user) redirect("/sign-in");`
- Parallel data fetching with `Promise.all`:
- Required for: event handlers, `useState`, `useEffect`, `useRouter`, browser APIs
- Examples: `web-app/src/components/ui/button.tsx`, `web-app/src/components/layout/bottom-nav.tsx`, `web-app/src/components/providers/auth-provider.tsx`
- Located in `actions.ts` files co-located with their feature pages
- Example: `web-app/src/app/(features)/dashboard/actions.ts`
- Always start by calling `getAuthUser()` and returning `null`/empty if unauthenticated
- Use `userCollection(user.uid, "collectionName")` for Firestore queries
- Use `forwardRef` pattern for reusable UI components (`Button`, `Card`, `Input`)
- Set `displayName` on forwarded-ref components
- Example from `web-app/src/components/ui/button.tsx`:
## State Management
- `AuthProvider` at `web-app/src/components/providers/auth-provider.tsx` wraps the entire app
- Provides `user` (Firebase `User | null`) and `loading` (boolean)
- Access via `useAuth()` hook
- Syncs Firebase ID tokens to server-side session cookies via `/api/auth/session`
- No client-side data caching library (no React Query, SWR, etc.)
- Data fetched per-request in Server Components and server actions
- Firestore reads happen server-side via Firebase Admin SDK
- `AuthViewModel` (ObservableObject) manages auth state and `isGuest` flag
- `ThemeViewModel` manages theme state
- Gate CloudKit writes with `!authViewModel.isGuest`
## Data Access Patterns
- Use `getAuthUser()` from `web-app/src/lib/firestore.ts` for authentication
- Use `userCollection(uid, "name")` for subcollection queries
- Use `userDoc(uid)` for user-level document access
- Standard pattern:
- Lazy-initialized via Proxy pattern in `web-app/src/lib/firebase-admin.ts`
- Never call `getAdminApp()` directly -- use exported `adminAuth` and `db` proxies
- Use `getFirebaseAuth()` from `web-app/src/lib/firebase.ts` -- never import `firebase/auth` at top level
- Dynamic import pattern required to avoid SSR pre-render failures
## Error Handling
- Return `null` or empty arrays for unauthenticated users (never throw)
- Return typed result objects with default fallbacks
- Return `NextResponse.json({ error: "message" }, { status: code })`
- Log errors with `console.error` using bracketed context prefix: `console.error("[auth/session] ...", { message })`
- Distinguish config errors from user errors in auth routes
- Pure functions return default values for edge cases (never throw)
- `cyclePhaseMultiplier(null)` returns `1.0`
- `decodeExerciseValue(unknown)` always returns a valid `ExerciseValue`
- Use `try/catch` around dynamic imports and Firebase calls
- Empty `catch` blocks acceptable when failure is recoverable (e.g., persistence fallback in `AuthProvider`)
## Logging
- Server-side: `console.error("[context] Message", { details })`
- Client-side: `console.error("[auth] Message", error)` in auth flows
- Never leave `print()` statements in Swift code (caught in commit `80ba06d2`)
## Comments
- JSDoc on exported domain functions explaining purpose and formulas
- Section separators with `// ---------------------------------------------------------------------------` blocks
- `// MARK: -` sections in Swift files
- Used on domain functions for parameter descriptions and return value explanations
- Example from `web-app/src/lib/domain/plate-calculation.ts`:
## Function Design
## Module Design
- `web-app/src/lib/domain/index.ts` re-exports all domain modules
- Import from the barrel file in application code, from individual files in tests
## Domain-Specific Patterns
- Never use TypeScript `enum`. Use `as const` objects with derived types:
- Stored as text fields in Firestore (not numeric enums)
- Use a `type` field for variant discrimination:
- Switch exhaustively on the `type` field in functions
- Cycle phase, recovery phase, and energy level compose multiplicatively on base weights
- Multipliers are between 0.75 and 1.25, clamped after composition
- Example: `weight = max * percentage * energyMult * cycleMult`
- Encode as `rounds * 10000 + reps` in a single number
- Decode: `rounds = Math.floor(value / 10000)`, `reps = value % 10000`
- Higher is better
- `PLUS_FEATURES` and `PREMIUM_FEATURES` arrays define tier-gated features
- `canAccess(feature, tier)` checks rank-based access
- Users always retain read access to data created during a higher tier
## UI/UX Patterns
- Defined in `web-app/src/lib/theme.ts` (JS constants) and `web-app/src/app/globals.css` (CSS `@theme`)
- Primary colors: cream `#f4f0df`, navy `#0d1a40`, orange `#f27319`, gold `#d9b34d`
- Card background: `#fcfaf2`
- Fonts: Playfair Display (headings), Inter (body), JetBrains Mono (mono/numbers)
- Same tokens mirrored in iOS `SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift`
- Use semantic color names from `@theme`: `text-navy`, `bg-cream`, `border-gold/20`, `text-orange`
- Use spacing tokens: `gap-spacing-md`, `px-spacing-lg`, `p-4`
- Use radius tokens: `rounded-card`, `rounded-button`
- Inline `className` strings (no CSS modules)
- Feature pages use `max-w-xl mx-auto` container with `pb-20` for bottom nav clearance
- Bottom nav fixed at bottom with `pb-[env(safe-area-inset-bottom)]` for iOS notch
- Cards use `.card` class or `<Card>` component
- 5 tabs: Dashboard, Programs, Maxes, Benchmarks, More (Settings)
- Defined in `web-app/src/components/layout/bottom-nav.tsx` with SVG path icons
- Active state: gold text + thicker stroke; inactive: white text
## Git Workflow
- Commit each file separately -- stage and commit one file at a time
- Commit message format: `type(scope): description`
- Types observed: `fix`, `chore`, `feat`
- Scopes reference issue numbers: `fix(#120)`, `fix(#122)`
- Main branch: `main`
- No CI/CD pipeline; manual deployment via `vercel deploy --prod`
## Firestore Data Model Conventions
- User data: `users/{uid}/subcollection/{id}`
- User profile: `users/{uid}` (top-level doc)
- Cycle settings: `users/{uid}/cycleSettings/default` (single doc with known ID)
- Subscription: `users/{uid}/subscription/current` (single doc with known ID)
- AI usage: `users/{uid}/aiUsage/{YYYY-MM-DD}` (date-keyed docs)
- Benchmark definitions: `benchmarkDefinitions/{id}` (top-level, shared)
- Always use `user.uid` for ownership queries, never hardcoded strings
- Dates stored as Firestore Timestamps, converted with `(data.field as Timestamp).toDate()`
- Denormalized data is acceptable (e.g., `programName` stored in enrollment)
- Use `.orderBy("date", "desc")` as default sort for time-series subcollections
- Rules in `web-app/firestore.rules`: `request.auth.uid == userId` for user subcollections
- `benchmarkDefinitions` readable by all authenticated users, writable only via Admin SDK
## iOS-Specific Conventions
- All domain logic in `SundeeFundee/Sources/SundeeFundeeKit/`
- Tests in `SundeeFundee/Tests/SundeeFundeeKitTests/`
- Domain logic mirrors web app domain layer in `DomainLayer/` subdirectory
- Use `AppTheme.*` tokens for all colors, spacing, and typography
- Use `.artDecoBackground()` modifier on root views
- Views need `.frame(maxWidth: .infinity, maxHeight: .infinity)` before `.artDecoBackground()`
- Button styles: `.artDecoButton(style: .primary)` with `AppButtonStyle` enum
- XCTest framework for older tests (`XCTAssertEqual`, `XCTAssertGreaterThan`)
- Swift Testing framework for newer tests (`import Testing`, `@Test` functions)
- Test helpers: `makeDate()`, `makeWorkout()`, `makeExercise()` factory functions
- `@testable import SundeeFundeeKit` for internal access
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Next.js App Router with React 19 Server Components and Server Actions
- Firebase Auth + session cookies for server-side auth verification on web
- Pure TypeScript domain layer with zero framework dependencies (fully unit-tested)
- Dual AI workout pipelines: web uses Google GenAI SDK directly in API routes; Cloud Functions use Vertex AI
- iOS app uses Swift Package architecture with CloudKit persistence and StoreKit 2 subscriptions
- PWA with Serwist service worker for offline support
- Stripe integration for web subscriptions; StoreKit 2 for iOS subscriptions
## Layers
### Web App — Presentation Layer
- Purpose: Render pages, handle user interactions, manage client-side state
- Location: `web-app/src/app/` (route groups), `web-app/src/components/`
- Contains: Next.js App Router pages, layouts, React client components, UI primitives
- Depends on: Domain layer (via imports), Firebase Client SDK (via `AuthProvider`), API routes
- Used by: End users via browser/PWA
- `(auth)/` — Sign-in/sign-up pages, no authentication required
- `(features)/` — Protected routes (dashboard, workouts, programs, maxes, benchmarks, cycle, settings) with `BottomNav` layout
- `(marketing)/` — Public pages (blog, privacy, terms, support) with SEO metadata
- `(admin)/` — Admin dashboard with server-side auth gate checking `isAdmin(uid)`
### Web App — API Layer
- Purpose: Server-side logic, external integrations, auth session management
- Location: `web-app/src/app/api/`
- Contains: Next.js Route Handlers (`route.ts` files) for POST/GET/DELETE
- Depends on: Firebase Admin SDK (`web-app/src/lib/firebase-admin.ts`), domain layer, Stripe SDK
- Used by: Client components via `fetch()`
- `api/auth/session` — POST: create session cookie from Firebase ID token; DELETE: clear session
- `api/ai/generate` — AI workout generation using Google GenAI SDK
- `api/stripe/webhook` — Stripe webhook handler for subscription lifecycle events
- `api/stripe/checkout` — Create Stripe checkout sessions
- `api/stripe/portal` — Create Stripe billing portal sessions
- `api/cycle/status` — Cycle phase status endpoint
- `api/user/profile` — User profile CRUD
- `api/admin/*` — Admin CRUD routes for blog, benchmarks, programs, WODs, users, AI prompts, settings
### Web App — Domain Layer
- Purpose: Pure business logic with zero framework dependencies
- Location: `web-app/src/lib/domain/`
- Contains: TypeScript functions and type definitions for weight calculations, cycle phases, injury adaptation, benchmarks, subscriptions, AI workout math, program generation
- Depends on: Nothing (zero external dependencies)
- Used by: API routes, server actions, client components
- `types.ts` — Core type definitions (`ExerciseValue`, `Program`, `CyclePhase`, `SubscriptionTier`, enums as `as const` objects)
- `weight-calculations.ts` — 1RM percentage mapping, prescribed weight calculation
- `cycle-calculations.ts` — Cycle phase boundaries, status calculation, phase recommendations
- `cycle-adaptation-policy.ts` — Phase multipliers for load/sets/reps, readiness tiers, confidence levels
- `injury-adaptation-engine.ts` — Exercise contraindication checking, regression suggestions, load multiplier calculation
- `injury-support.ts` — Pain trend analysis, recovery phase transitions, sparkline data
- `benchmark-catalog.ts` — Static benchmark definitions catalog
- `benchmark-readiness.ts` — Benchmark readiness calculation based on cycle phase
- `subscription.ts` — Tier metadata, feature gating, usage limits, downgrade policy
- `ai-workout.ts` — Energy multipliers, cycle phase multipliers, rest time assignment, weight application
- `program-template-generator.ts` — Program template generation from presets
- `exercise-catalog.ts` — Weightlifting and conditioning exercise catalogs
- `body-location.ts` — Body region definitions for injury tracking
- `celebration-event.ts` — Achievement celebration types and display strings
- `cycle-calendar.ts` — Calendar day data with phase overlays
- `plate-calculation.ts` — Barbell plate calculation
- `weight-unit-conversion.ts` — lbs/kg conversion
### Web App — Library Layer
- Purpose: Infrastructure helpers, SDK wrappers, shared utilities
- Location: `web-app/src/lib/`
- Contains: Firebase client/admin initialization, Firestore helpers, Stripe integration, blog parser, theme tokens, auth helpers
- Depends on: Firebase SDK, Firebase Admin SDK, Stripe SDK, domain types
- Used by: API routes, server actions, client components
- `firebase.ts` — Firebase Client SDK initialization with dynamic auth domain resolution (`getFirebaseAuth()`)
- `firebase-admin.ts` — Firebase Admin SDK lazy initialization via Proxy pattern for `adminAuth` and `db`
- `firestore.ts` — `getAuthUser()` (session cookie verification), `userCollection()`, `userDoc()`, `db` export
- `social-auth.ts` — `signInWithGoogle()` with popup/redirect fallback for iOS, session cookie sync
- `stripe.ts` — Price ID mapping, Stripe client factory, subscription record normalization
- `subscription-state.ts` — Daily AI usage tracking, entitlement resolution
- `ai-generation.ts` — AI workout request validation, prompt building, response parsing, model config
- `blog.ts` — Blog post fetching from Firestore (was MDX, now Firestore-backed)
- `theme.ts` — Art Deco design tokens (cream/navy/orange)
- `admin-auth.ts` — Admin user verification
- `admin-firestore.ts` — Admin-specific Firestore helpers
- `write-validation.ts` — Input validation utilities
- `client-errors.ts` — Client-side error handling
- `sanitize.ts` — HTML sanitization
- `date-input.ts` — Date input formatting
### iOS App — Domain Layer
- Purpose: Pure Swift business logic, shared between iOS/watchOS/macOS
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/`
- Contains: Cycle calculations, injury models, benchmark catalog, AI workout types, program templates, celebration events, analytics aggregation, export, coach logic, intelligence features
- Depends on: Nothing (no external dependencies)
- Used by: iOS ViewModels and Views
- `Cycle/` — Cycle calculations, adaptation policy, calendar, settings
- `Injury/` — Body location, adaptation engine, injury models, support
- `Benchmark/` — Catalog, models, readiness
- `AIWorkout/` — AI workout types and generation helpers
- `Program/` — Program template generator
- `Coach/` — Coach context, memory models, deterministic and on-device coach services, preference learner
- `Intelligence/` — Plateau detector, schedule reshuffler, substitution ranker, weekly load analyzer
- `Analytics/` — Chart data aggregation
- `Export/` — Data export service
- `Celebration/` — Celebration events
### iOS App — Data Layer
- Purpose: Abstract data persistence with protocol-based client architecture
- Location: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/`
- Contains: DataClientProtocol, CloudKit client, HealthKit client, local data client, mocks, sync queue
- Depends on: CloudKit framework, HealthKit framework, Foundation
- Used by: ViewModels via `DataClientFactory.shared.client`
- `DataClientProtocol` — Async protocol for fetch/save/delete with generic Codable types
- `DataClientFactory.shared.client` — Thread-safe singleton holding the active client
- `CloudKitClient` — Actor-based CloudKit implementation for signed-in users
- `LocalDataClient` — Local storage for guest users
- `MockCloudKitClient` / `MockHealthKitClient` — In-memory mocks for testing
- `SyncQueue.swift` — Queues mutations offline and replays when connectivity returns
- `PendingMutation.swift` — Encoded mutation representation
- `NetworkMonitor.swift` — Connectivity observation
### iOS App — UI Layer
- Purpose: SwiftUI views and view models
- Location: `SundeeFundee/Sources/SundeeFundeeKit/UI/`
- Contains: App entry point views, tab navigation, feature views, view models, theme, shared UI models
- Depends on: Domain layer, Data layer, Auth, Subscription
- Used by: `SundeeFundeeApp` Xcode project
### Cloud Functions
- Purpose: Serverless backend for AI workout generation (secondary path to web app's direct API)
- Location: `firebase/functions/src/`
- Contains: Callable function `generateWorkoutFn`, Vertex AI integration, Firestore rate limiting
- Depends on: `firebase-admin`, `firebase-functions`, `@google-cloud/vertexai`
- Used by: Callable from Firebase Client SDK (alternative to web API route)
- `index.ts` — `generateWorkoutFn` callable function (auth check, tier check, rate limit, generate, save)
- `ai.ts` — Vertex AI Gemini Flash integration, workout response validation
- `rate-limit.ts` — Firestore-based daily rate limiting (plus: 1/day, premium: 10/day)
## Data Flow
### Web Auth Flow
### Web Data Flow (Server Actions)
### Web Data Flow (API Routes)
### AI Workout Generation (Web API Route)
### Stripe Subscription Flow
### iOS Data Flow
## Key Abstractions
### AuthProvider (Web)
- Purpose: React context providing Firebase Auth state to all client components
- Examples: `web-app/src/components/providers/auth-provider.tsx`
- Pattern: `"use client"` component wrapping the app, using dynamic `import("firebase/auth")` to avoid SSR failures, syncing ID tokens to server session cookies on every auth state change
### DataClientProtocol (iOS)
- Purpose: Abstract data persistence layer allowing CloudKit, local, and mock implementations
- Examples: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/DataClientProtocol.swift`
- Pattern: Protocol with generic `Codable & Sendable` types, actor-based implementations for thread safety, factory singleton for client switching
### Firebase Admin Proxy Pattern (Web)
- Purpose: Lazy initialization of Firebase Admin SDK only when first needed
- Examples: `web-app/src/lib/firebase-admin.ts`
- Pattern: JavaScript `Proxy` objects for `adminAuth` and `db` that initialize the app and services on first property access, avoiding cold-start issues in serverless environments
### Domain Barrel Export (Web)
- Purpose: Single import point for all domain logic
- Examples: `web-app/src/lib/domain/index.ts`
- Pattern: Re-exports all domain modules, enabling `import { ... } from "@/lib/domain"`
### ExerciseValue Discriminated Union
- Purpose: Flexible rep/set representation shared between TypeScript and Swift
- Examples: `web-app/src/lib/domain/types.ts` (TypeScript), `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/ExerciseValue.swift` (Swift)
- Pattern: Discriminated union with `type` field: `fixed`, `amrap`, `range`, `text`
## Entry Points
### Web App
- Location: `web-app/src/app/layout.tsx`
- Triggers: Vercel deployment, `npm run dev`
- Responsibilities: Root layout wrapping all pages in `AuthProvider`, setting metadata/viewport, loading global CSS
### Web Home Page
- Location: `web-app/src/app/page.tsx`
- Triggers: `GET /` request
- Responsibilities: Landing page (marketing content)
### Web Service Worker
- Location: `web-app/src/app/sw.ts`
- Triggers: Browser registration after production build
- Responsibilities: Precaching, runtime caching, navigation preload, auth route bypass
### iOS App Entry Point
- Location: `SundeeFundeeApp/SundeeFundee/App.swift`
- Triggers: App launch on iOS device
- Responsibilities: Creates `@StateObject` instances for `AuthViewModel` and `ThemeViewModel`, configures `StoreKitClient` for subscriptions, conditionally seeds screenshots in screenshot mode
### Cloud Functions
- Location: `firebase/functions/src/index.ts`
- Triggers: Firebase callable function invocation
- Responsibilities: Auth verification, tier check, rate limiting, AI workout generation, record saving
## Error Handling
- API routes return structured JSON errors with appropriate HTTP status codes (401, 400, 403, 429, 500, 502)
- Auth errors surface as user-friendly messages via `socialAuthErrorMessage()` in `web-app/src/lib/social-auth.ts`
- Blog fetching returns empty array on failure (graceful degradation)
- Domain functions are pure and throw typed errors
- Global error boundary at `web-app/src/app/error.tsx` and `web-app/src/app/global-error.tsx`
- `DataError` enum with `LocalizedError` conformance provides error descriptions and recovery suggestions
- `HealthError` enum for HealthKit-specific errors
- `SubscriptionError` enum for subscription operation errors
- Actor-based clients ensure thread-safe error handling
## Cross-Cutting Concerns
- Web: Firebase Auth (Google, Apple, Email/Password) with session cookies verified server-side
- iOS: Apple Sign-In only, session in Keychain, guest mode for offline/local use
- Both: `user.uid` threaded through all data-writing operations
- Web middleware checks `__session` cookie presence on protected routes
- Admin routes verified server-side via `isAdmin(uid)` in admin layout
- Firestore security rules restrict subcollections to `request.auth.uid == userId`
- Feature gating via `canAccess(feature, tier)` in domain layer
- Server-side entitlement resolution via `resolveEntitlement(uid)`
- Three tiers: Free, Sundee Plus, Sundee Premium
- Service worker with precaching and runtime caching via Serwist
- Auth routes bypass cache (NetworkOnly strategy)
- Manifest for standalone PWA install
- iOS: SyncQueue for offline mutation replay with CloudKit
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

| Skill | Description | Path |
|-------|-------------|------|
| asc-app-create-ui | Create an App Store Connect app via iris API using web session from Blitz | `.agents/skills/asc-app-create-ui/SKILL.md` |
| asc-aso-audit | Run an offline ASO audit on canonical App Store metadata under `./metadata` and surface keyword gaps using Astro MCP. Use after pulling metadata with `asc metadata pull`. | `.agents/skills/asc-aso-audit/SKILL.md` |
| asc-build-lifecycle | Track build processing, find latest builds, and clean up old builds with asc. Use when managing build retention or waiting on processing. | `.agents/skills/asc-build-lifecycle/SKILL.md` |
| asc-cli-usage | Guidance for using asc cli in this repo (flags, output formats, pagination, auth, and discovery). Use when asked to run or design asc commands or interact with App Store Connect via the CLI. | `.agents/skills/asc-cli-usage/SKILL.md` |
| asc-crash-triage | Triage TestFlight crashes, beta feedback, and performance diagnostics using asc. Use when the user asks about TF crashes, TestFlight crash reports, beta tester feedback, app hangs, disk writes, launch diagnostics, or wants a crash summary for a build or app. | `.agents/skills/asc-crash-triage/SKILL.md` |
| asc-iap-attach | Attach in-app purchases and subscriptions to an app version for App Store review. Use when the user has IAPs or subscriptions in "Ready to Submit" state that need to be included with a first-time version submission. Works for both first-time and subsequent submissions. | `.agents/skills/asc-iap-attach/SKILL.md` |
| asc-id-resolver | Resolve App Store Connect IDs (apps, builds, versions, groups, testers) from human-friendly names using asc. Use when commands require IDs. | `.agents/skills/asc-id-resolver/SKILL.md` |
| asc-localize-metadata | Automatically translate and sync App Store metadata (description, keywords, what's new, subtitle) to multiple languages using LLM translation and asc CLI. Use when asked to localize an app's App Store listing, translate app descriptions, or add new languages to App Store Connect. | `.agents/skills/asc-localize-metadata/SKILL.md` |
| asc-metadata-sync | Sync and validate App Store metadata and localizations with asc, including legacy metadata format migration. Use when updating metadata or translations. | `.agents/skills/asc-metadata-sync/SKILL.md` |
| asc-notarization | Archive, export, and notarize macOS apps using xcodebuild and asc. Use when you need to prepare a macOS app for distribution outside the App Store with Developer ID signing and Apple notarization. | `.agents/skills/asc-notarization/SKILL.md` |
| asc-ppp-pricing | Set territory-specific pricing for subscriptions and in-app purchases using current asc setup, pricing summary, price import, and price schedule commands. Use when adjusting prices by country or implementing localized PPP strategies. | `.agents/skills/asc-ppp-pricing/SKILL.md` |
| asc-privacy-nutrition-labels | Set up App Store privacy nutrition labels (data collection declarations) for an app. Use when the user needs to declare what data their app collects, how it's used, and whether it's linked to the user. Handles both "no data collected" and full data collection declarations. | `.agents/skills/asc-privacy-nutrition-labels/SKILL.md` |
| asc-release-flow | Determine whether an app is ready to submit, then drive the App Store release flow with asc, including first-time submission fixes for availability, in-app purchases, subscriptions, Game Center, and App Privacy. | `.agents/skills/asc-release-flow/SKILL.md` |
| asc-revenuecat-catalog-sync | Reconcile App Store Connect subscriptions and in-app purchases with RevenueCat products, entitlements, offerings, and packages using asc and RevenueCat MCP. Use when setting up or syncing subscription catalogs across ASC and RevenueCat. | `.agents/skills/asc-revenuecat-catalog-sync/SKILL.md` |
| asc-screenshot-resize | Resize and validate App Store screenshots for all device classes using macOS sips. Use when preparing or fixing screenshots for App Store Connect submission. | `.agents/skills/asc-screenshot-resize/SKILL.md` |
| asc-shots-pipeline | Orchestrate iOS screenshot automation with xcodebuild/simctl for build-run, AXe for UI actions, JSON settings and plan files, Koubou-based framing (`asc screenshots frame`), and screenshot upload (`asc screenshots upload`). Use when users ask for automated screenshot capture, AXe-driven simulator flows, frame composition, or screenshot-to-upload pipelines. | `.agents/skills/asc-shots-pipeline/SKILL.md` |
| asc-signing-setup | Set up bundle IDs, capabilities, signing certificates, provisioning profiles, and encrypted signing sync with the asc cli. Use when onboarding a new app, rotating signing assets, or sharing them across a team. | `.agents/skills/asc-signing-setup/SKILL.md` |
| asc-submission-health | Preflight App Store submissions, submit builds, and monitor review status with asc. Use when shipping or troubleshooting review submissions. | `.agents/skills/asc-submission-health/SKILL.md` |
| asc-subscription-localization | Bulk-localize subscription and in-app purchase display names across all App Store locales using asc. Use when you want to fill in subscription/IAP names for every language without clicking through App Store Connect manually. | `.agents/skills/asc-subscription-localization/SKILL.md` |
| asc-team-key-create | Create a new App Store Connect Team API Key with Admin permissions, download the one-time .p8 private key, and store it in ~/.blitz. Use when the user needs a new ASC API key for CLI auth, CI/CD, or external tooling. | `.agents/skills/asc-team-key-create/SKILL.md` |
| asc-testflight-orchestration | Orchestrate TestFlight distribution, groups, testers, and What to Test notes using asc. Use when rolling out betas. | `.agents/skills/asc-testflight-orchestration/SKILL.md` |
| asc-wall-submit | Submit or update a Wall of Apps entry in the App-Store-Connect-CLI repository using `asc apps wall submit`. Use when the user says "submit to wall of apps", "add my app to the wall", or "wall-of-apps". | `.agents/skills/asc-wall-submit/SKILL.md` |
| asc-whats-new-writer | Generate engaging, localized App Store release notes (What's New) from git log, bullet points, or free text using canonical metadata under `./metadata`. Optionally pairs with promotional text updates. | `.agents/skills/asc-whats-new-writer/SKILL.md` |
| asc-workflow | Define, validate, and run repo-local multi-step automations with `asc workflow` and `.asc/workflow.json`. Use when migrating from lane tools, wiring CI pipelines, or orchestrating repeatable `asc` + shell release flows with hooks, conditionals, and sub-workflows. | `.agents/skills/asc-workflow/SKILL.md` |
| asc-xcode-build | Build, archive, export, and manage Xcode version/build numbers with asc and xcodebuild before uploading to App Store Connect. Use when you need to create an IPA or PKG for upload. | `.agents/skills/asc-xcode-build/SKILL.md` |
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
