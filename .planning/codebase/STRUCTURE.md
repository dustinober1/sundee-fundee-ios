---
name: Codebase Structure
type: codebase-map
focus: arch
created: 2026-04-08
---

# Codebase Structure

**Analysis Date:** 2026-04-08

## Directory Layout

```
sundee-fundee/
├── web-app/                        # Main Next.js PWA application
│   ├── src/
│   │   ├── app/                    # Next.js App Router (pages, layouts, API routes)
│   │   ├── components/             # React components (UI, layout, providers, dashboard, admin, install)
│   │   └── lib/                    # Shared libraries, domain logic, Firebase/Stripe helpers
│   ├── content/blog/               # MDX blog content (legacy; blog now served from Firestore)
│   ├── public/                     # Static assets, manifest, icons, robots.txt
│   ├── scripts/                    # Build/utility scripts
│   ├── package.json                # Web app dependencies (Next.js 16, React 19, Firebase, Stripe)
│   ├── next.config.ts              # Next.js config with Serwist PWA, auth rewrites, security headers
│   ├── vitest.config.ts            # Vitest test runner config (domain layer coverage)
│   ├── tsconfig.json               # TypeScript config with @/* path alias
│   ├── eslint.config.mjs           # ESLint config
│   ├── firestore.rules             # Firestore security rules
│   └── next-sitemap.config.js      # Sitemap generation config
├── SundeeFundee/                   # Swift Package (SundeeFundeeKit) — iOS domain + UI
│   ├── Sources/SundeeFundeeKit/    # All Swift source code
│   ├── Tests/SundeeFundeeKitTests/ # XCTest unit tests
│   ├── scripts/                    # iOS build/utility scripts
│   └── Package.swift               # Swift Package manifest (iOS 18+, macOS 15+, watchOS 11+)
├── SundeeFundeeApp/                # Xcode project — iOS app entry point
│   ├── SundeeFundee/               # App target (App.swift, Info.plist, assets, entitlements, widgets)
│   └── SundeeFundee.xcodeproj/     # Xcode project file with shared scheme
├── firebase/
│   └── functions/                  # Firebase Cloud Functions for AI workout generation
│       ├── src/                    # TypeScript source (index.ts, ai.ts, rate-limit.ts)
│       ├── lib/                    # Compiled JavaScript output
│       ├── package.json            # Functions dependencies (firebase-admin, vertexai)
│       └── tsconfig.json           # Functions TypeScript config
├── backend/                        # Experimental backend (Teenybase/Cloudflare Workers)
├── docs/                           # Documentation and screenshots
│   ├── screenshots/                # Raw simulator screenshots
│   ├── superpowers/                # Spec and plan documents
│   └── app-store-copy.md           # App Store listing copy
├── scripts/                        # Root-level scripts (App Store marketing image generation)
├── plans/                          # Planning documents
├── .agents/skills/                 # Agent skill definitions for App Store Connect automation
├── .github/workflows/              # GitHub Actions (if any)
├── firebase.json                   # Firebase project config (functions source, Firestore rules)
├── firestore.indexes.json          # Firestore composite index definitions
├── CLAUDE.md                       # Project instructions for Claude Code
├── AGENTS.md                       # Agent configuration
└── package.json                    # Root package.json (backend scripts, teenybase)
```

## Directory Purposes

### `web-app/src/app/` — Next.js App Router

**Route Groups:**

**`(auth)/`** — Authentication pages (no auth required)
- `sign-in/page.tsx` — Sign-in page with Google, Apple, Email/Password
- `sign-up/page.tsx` — Sign-up page
- `layout.tsx` — Pass-through layout (no nav)

**`(features)/`** — Protected feature pages (auth required, `BottomNav` layout)
- `dashboard/` — Main dashboard page and server actions (`actions.ts`)
- `workouts/` — Workout list, new workout, AI workout generation
  - `ai/page.tsx` — AI workout questionnaire and preview
  - `new/page.tsx` — Manual workout creation
- `programs/` — Program list and detail (`[id]/`)
- `maxes/` — One-rep max tracking
- `benchmarks/` — Benchmark list and detail (`[id]/`)
- `cycle/` — Cycle tracking and calendar
- `settings/` — Profile, subscription, sign-out
- `layout.tsx` — Shared layout with `BottomNav`, `DiagonalPattern`, `max-w-xl` container

**`(marketing)/`** — Public marketing pages (no auth, SEO-optimized)
- `blog/` — Blog list page
- `blog/[slug]/` — Individual blog post page
- `privacy/page.tsx` — Privacy policy
- `terms/page.tsx` — Terms of service
- `support/` — Support page and PWA install instructions (`support/install/`)

**`(admin)/`** — Admin dashboard (server-side auth gate via `getAuthUser()` + `isAdmin()`)
- `admin/ai/` — AI prompt management, rate limit monitoring
- `admin/catalog/` — Exercise catalog management
- `admin/content/` — Blog and support content management
- `admin/settings/` — Admin settings
- `admin/subscriptions/` — Subscription overview
- `admin/users/` — User management
- `admin/workouts/` — Benchmark, program, and WOD management
- `layout.tsx` — Server-side admin auth check, renders `AdminShell`

**`api/`** — API route handlers
- `auth/session/route.ts` — Session cookie creation and deletion
- `ai/generate/route.ts` — AI workout generation (Google GenAI SDK)
- `stripe/checkout/route.ts` — Stripe checkout session creation
- `stripe/portal/route.ts` — Stripe billing portal creation
- `stripe/webhook/route.ts` — Stripe webhook handler
- `cycle/status/route.ts` — Cycle status endpoint
- `user/profile/route.ts` — User profile CRUD
- `admin/*` — Admin API routes for all admin CRUD operations

**Root app files:**
- `layout.tsx` — Root layout: wraps in `AuthProvider`, sets metadata/viewport, loads `globals.css`
- `page.tsx` — Landing page (marketing)
- `sw.ts` — Service worker (Serwist): precaching, runtime caching, auth route bypass
- `globals.css` — Global styles (Tailwind CSS 4)
- `error.tsx` — Error boundary
- `global-error.tsx` — Global error boundary
- `not-found.tsx` — 404 page
- `apple-icon.png`, `icon.png`, `favicon.ico` — App icons

### `web-app/src/components/` — React Components

**`ui/`** — Reusable UI primitives
- `button.tsx`, `card.tsx`, `input.tsx` — Basic form elements
- `art-deco.tsx` — Art Deco decorative components (PageHeader, SectionHeader, ArtDecoRuleSmall, StatCard)
- `benchmark-ui.tsx` — Benchmark-specific UI components
- `cycle-adjustment-toggle.tsx` — Toggle for cycle-based load adjustments
- `cycle-phase-banner.tsx` — Banner showing current cycle phase
- `delete-record-button.tsx` — Reusable delete button with confirmation
- `form-alert.tsx` — Form validation alert display
- `shark-week-label.tsx`, `app-shark-mark.tsx` — Themed label components

**`layout/`** — Layout components
- `bottom-nav.tsx` — 5-tab bottom navigation (Dashboard, Programs, Workouts, Maxes, Settings)

**`providers/`** — React context providers
- `auth-provider.tsx` — Firebase Auth context (`AuthProvider`, `useAuth` hook)

**`dashboard/`** — Dashboard-specific components
- `CyclePhaseBanner.tsx`, `RecentWinsCard.tsx`, `SuggestedWorkoutCard.tsx`, `index.ts`

**`admin/`** — Admin dashboard components
- `admin-header.tsx`, `admin-shell.tsx`, `admin-sidebar.tsx` — Admin layout shell
- `data-table.tsx`, `detail-panel.tsx`, `search-command.tsx` — Data management UI
- `rich-text-editor.tsx` — TipTap-based rich text editor
- `confirm-dialog.tsx`, `empty-state.tsx`, `stat-card.tsx` — Utility components

**`install/`** — PWA install prompt components

### `web-app/src/lib/` — Shared Libraries

**`domain/`** — Pure TypeScript business logic (zero dependencies, fully unit-tested)
- `index.ts` — Barrel export re-exporting all domain modules
- `types.ts` — Core type definitions and enums
- `weight-calculations.ts`, `weight-unit-conversion.ts`, `plate-calculation.ts`
- `cycle-calculations.ts`, `cycle-adaptation-policy.ts`, `cycle-calendar.ts`
- `injury-adaptation-engine.ts`, `injury-support.ts`, `body-location.ts`
- `benchmark-catalog.ts`, `benchmark-readiness.ts`
- `exercise-catalog.ts`
- `subscription.ts`
- `ai-workout.ts`
- `program-template-generator.ts`
- `celebration-event.ts`

**`domain/__tests__/`** — Unit tests (one file per domain module)

**Infrastructure files:**
- `firebase.ts` — Firebase Client SDK init (`getFirebaseAuth()`)
- `firebase-admin.ts` — Firebase Admin SDK init (lazy Proxy pattern for `adminAuth`, `db`)
- `firestore.ts` — Firestore helpers (`getAuthUser()`, `userCollection()`, `userDoc()`)
- `social-auth.ts` — Google/Apple sign-in flows with popup/redirect handling
- `stripe.ts` — Stripe price IDs, client factory, subscription normalization
- `subscription-state.ts` — Daily AI usage tracking, entitlement resolution
- `ai-generation.ts` — AI request validation, prompt building, response parsing
- `blog.ts` — Blog post fetching from Firestore
- `theme.ts` — Art Deco design tokens
- `admin-auth.ts` — Admin user verification
- `admin-firestore.ts` — Admin-specific Firestore helpers
- `write-validation.ts` — Input validation utilities
- `client-errors.ts` — Client-side error types
- `sanitize.ts` — HTML sanitization
- `date-input.ts` — Date input formatting
- `complete-social-redirect.ts` — OAuth redirect completion handler

### `SundeeFundee/Sources/SundeeFundeeKit/` — Swift Package

**`Activity/`** — Live Activity attributes for workout tracking
- `LiveWorkoutActivityAttributes.swift`

**`Auth/`** — Apple Sign-In implementation
- `AppleAuthClient.swift` — Actor-based Apple auth client
- `AppleAuthResult.swift` — Auth result type
- `AuthError.swift` — Auth error types
- `KeychainHelper.swift` — Keychain storage for session

**`Calculations/`** — Weight and unit calculations
- `WeightCalculator.swift` — Prescribed weight calculation from 1RM
- `PlateCalculator.swift` — Barbell plate calculation
- `UnitConverter.swift` — lbs/kg conversion

**`DataLayer/`** — Data persistence abstraction
- `Protocols/DataClientProtocol.swift` — Generic async CRUD protocol
- `Protocols/HealthClientProtocol.swift` — HealthKit operations protocol
- `Actors/CloudKitClient.swift` — CloudKit implementation (actor)
- `Actors/HealthKitClient.swift` — HealthKit implementation (actor)
- `Actors/LocalDataClient.swift` — Local storage for guest mode
- `DataClientFactory.swift` — Thread-safe singleton holding active client
- `HealthClientFactory.swift` — Thread-safe singleton holding active health client
- `Helpers/CyclePhaseHelper.swift` — Cycle phase calculation helper
- `Mocks/MockCloudKitClient.swift` — In-memory mock for testing
- `Mocks/MockHealthKitClient.swift` — In-memory mock for testing
- `SyncQueue/SyncQueue.swift` — Offline mutation queue
- `SyncQueue/PendingMutation.swift` — Encoded mutation representation
- `SyncQueue/NetworkMonitor.swift` — Network connectivity observation

**`DomainLayer/`** — Pure Swift business logic (mirrors web domain)
- `Cycle/` — Cycle calculations, adaptation policy, calendar, settings
- `Injury/` — Body location, adaptation engine, injury models, support
- `Benchmark/` — Catalog, models, readiness
- `AIWorkout/` — AI workout types
- `Program/` — Program template generator
- `Coach/` — Coach context, memory, deterministic/on-device services, preference learner
- `Intelligence/` — Plateau detection, schedule reshuffling, substitution ranking, weekly load analysis
- `Analytics/` — Chart data aggregation
- `Export/` — Data export service and models
- `Celebration/` — Celebration event types
- `Exercise/` — Exercise catalog
- `ExerciseValue.swift` — Discriminated union for rep/set values

**`Models/`** — Core data models
- `Workout.swift` — Workout model with exercises and sets
- `Exercise.swift` — Exercise model with types

**`Subscription/`** — StoreKit 2 subscription management
- `SubscriptionTier.swift` — Tier definitions and feature limits
- `SubscriptionClientProtocol.swift` — Async subscription protocol
- `SubscriptionClientFactory.swift` — Thread-safe singleton
- `StoreKitClient.swift` — Native StoreKit 2 implementation (actor)
- `MockSubscriptionClient.swift` — Mock for testing
- `SubscriptionError.swift` — Error types

**`UI/`** — SwiftUI views and view models
- `App/SundeeFundeeApp.swift` — `MainTabView`, `AuthView`, `ThemeViewModel`, `Tab` enum
- `Theme/AppTheme.swift` — Art Deco design tokens (`AppTheme.*`)
- `ViewModels/` — Observable view models (Auth, Analytics, Benchmarks, Export, PainTracking)
- `Views/` — Feature views organized by feature (Analytics, Benchmarks, Cycle, Dashboard, Export, Insights, Maxes, Onboarding, Pain, Programs, Settings, Share, Workouts)
- `Models/SharedModels.swift` — Shared UI model types

**`Screenshot/ScreenshotSeeder.swift`** — Test data seeder for App Store screenshots

**`Exports.swift`** — Public API documentation (comment file listing all public types)

### `SundeeFundeeApp/` — Xcode Project

**`SundeeFundee/`** — App target
- `App.swift` — `@main` entry point, creates AuthViewModel/ThemeViewModel, configures StoreKitClient
- `Info.plist` — App configuration (device capabilities: arm64)
- `SundeeFundee.entitlements` — App entitlements (HealthKit, CloudKit)
- `PrivacyInfo.xcprivacy` — Privacy manifest (required for App Store)
- `Assets.xcassets/` — App icon and colors

**`SundeeFundeeWidgets/`** — Widget extension
- `LiveWorkoutWidget.swift` — Live Activity widget for active workouts

**`SundeeFundee.xcodeproj/`** — Xcode project files
- `xcshareddata/xcschemes/SundeeFundee.xcscheme` — Shared build scheme with test action

### `firebase/functions/` — Cloud Functions

- `src/index.ts` — `generateWorkoutFn` callable function entry point
- `src/ai.ts` — Vertex AI Gemini Flash integration and response parsing
- `src/rate-limit.ts` — Firestore-based daily rate limiting
- `lib/` — Compiled JavaScript output
- `package.json` — Functions dependencies
- `tsconfig.json` — TypeScript config

### `backend/` — Experimental Backend

- `src-backend/worker.ts` — Cloudflare Worker
- `teenybase.ts` — Teenybase ORM/config
- `wrangler.toml` — Wrangler deployment config
- `package.json` — Backend dependencies

### `docs/` — Documentation

- `screenshots/` — Raw iOS simulator screenshots
- `superpowers/specs/` — Feature specifications
- `superpowers/plans/` — Implementation plans
- `app-store-copy.md` — App Store listing copy
- `TODO.md` — Tracking document

### `scripts/` — Root Scripts

- `generate_appstore_marketing.py` — iPhone marketing screenshots (Pillow, navy background)
- `generate_ipad_marketing.py` — iPad marketing screenshots

### `.agents/skills/` — Agent Automation Skills

App Store Connect automation skill definitions for build lifecycle, submission, screenshots, IAP, localization, signing, and more. Each skill is a directory with instructions and reference files.

## Key File Locations

### Entry Points

| Entry Point | File | Purpose |
|-------------|------|---------|
| Web root layout | `web-app/src/app/layout.tsx` | Wraps app in AuthProvider, global metadata |
| Web landing page | `web-app/src/app/page.tsx` | Marketing landing page |
| Web service worker | `web-app/src/app/sw.ts` | PWA offline support |
| Web middleware | `web-app/src/middleware.ts` | Auth gate for protected routes |
| iOS app entry | `SundeeFundeeApp/SundeeFundee/App.swift` | @main SwiftUI app |
| iOS tab view | `SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift` | MainTabView, AuthView |
| Cloud Functions | `firebase/functions/src/index.ts` | generateWorkoutFn callable |
| Backend worker | `backend/src-backend/worker.ts` | Cloudflare Worker |

### Configuration

| Config | File | Purpose |
|--------|------|---------|
| Next.js | `web-app/next.config.ts` | Serwist PWA, auth rewrites, security headers |
| TypeScript (web) | `web-app/tsconfig.json` | Strict mode, @/* path alias |
| TypeScript (functions) | `firebase/functions/tsconfig.json` | Functions compilation |
| Vitest | `web-app/vitest.config.ts` | Test runner, domain coverage |
| ESLint | `web-app/eslint.config.mjs` | Linting rules |
| PostCSS/Tailwind | `web-app/postcss.config.mjs` | Tailwind CSS 4 processing |
| Sitemap | `web-app/next-sitemap.config.js` | Sitemap generation, route exclusions |
| Firebase | `firebase.json` | Functions source, Firestore rules path |
| Firestore rules | `web-app/firestore.rules` | Security rules |
| Firestore indexes | `firestore.indexes.json` | Composite index definitions |
| Swift Package | `SundeeFundee/Package.swift` | iOS 18+, zero external deps, Swift 6 |
| Xcode project | `SundeeFundeeApp/SundeeFundee.xcodeproj/project.pbxproj` | Xcode project config |
| Wrangler | `wrangler.toml` / `backend/wrangler.toml` | Cloudflare Workers config |
| Env example (web) | `web-app/.env.example` | Required environment variables template |

### Core Logic

| Module | File | Purpose |
|--------|------|---------|
| Domain types | `web-app/src/lib/domain/types.ts` | Core type definitions, enums, ExerciseValue |
| Domain barrel | `web-app/src/lib/domain/index.ts` | Re-exports all domain modules |
| Firebase client | `web-app/src/lib/firebase.ts` | Client SDK init with dynamic auth domain |
| Firebase admin | `web-app/src/lib/firebase-admin.ts` | Admin SDK lazy init via Proxy |
| Firestore helpers | `web-app/src/lib/firestore.ts` | getAuthUser(), userCollection(), userDoc() |
| Social auth | `web-app/src/lib/social-auth.ts` | Google/Apple sign-in with redirect fallback |
| Stripe | `web-app/src/lib/stripe.ts` | Price IDs, client factory, tier mapping |
| AI generation | `web-app/src/lib/ai-generation.ts` | Request validation, prompt building, response parsing |
| Subscription | `web-app/src/lib/domain/subscription.ts` | Tier metadata, feature gating, usage limits |
| iOS auth | `SundeeFundee/Sources/SundeeFundeeKit/Auth/AppleAuthClient.swift` | Apple Sign-In |
| iOS data client | `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/DataClientProtocol.swift` | Data protocol |
| iOS data factory | `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/DataClientFactory.swift` | Client switching |
| iOS subscription | `SundeeFundee/Sources/SundeeFundeeKit/Subscription/StoreKitClient.swift` | StoreKit 2 |
| iOS theme | `SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift` | Art Deco tokens |
| iOS auth VM | `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/AuthViewModel.swift` | Auth state, guest mode |

### Testing

| Tests | File Pattern | Purpose |
|-------|-------------|---------|
| Web domain tests | `web-app/src/lib/domain/__tests__/*.test.ts` | One test file per domain module |
| iOS domain tests | `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/` | Domain logic tests |
| iOS model tests | `SundeeFundee/Tests/SundeeFundeeKitTests/ModelTests/` | Model tests |
| iOS data tests | `SundeeFundee/Tests/SundeeFundeeKitTests/DataLayerTests/` | Data layer tests |
| iOS auth tests | `SundeeFundee/Tests/SundeeFundeeKitTests/AuthTests/` | Auth tests |
| iOS VM tests | `SundeeFundee/Tests/SundeeFundeeKitTests/ViewModelTests/` | ViewModel tests |
| iOS activity tests | `SundeeFundee/Tests/SundeeFundeeKitTests/ActivityTests/` | Live Activity tests |

## Naming Conventions

**Files:**
- Web pages: `page.tsx` (App Router convention)
- Web layouts: `layout.tsx` (App Router convention)
- Web API routes: `route.ts` (App Router convention)
- Web server actions: `actions.ts` (co-located with page)
- Web components: `kebab-case.tsx` (e.g., `bottom-nav.tsx`, `delete-record-button.tsx`)
- Web lib modules: `kebab-case.ts` (e.g., `firebase-admin.ts`, `weight-calculations.ts`)
- Domain modules: `kebab-case.ts` matching module name
- Domain tests: `kebab-case.test.ts` matching domain module name
- Swift files: `PascalCase.swift` (e.g., `CloudKitClient.swift`, `WeightCalculator.swift`)
- Swift tests: `PascalCaseTests.swift` (e.g., `CycleCalculationsTests.swift`)

**Directories:**
- Web route groups: `(parenthesized)` for App Router route groups (no URL segment)
- Web API routes: Match URL path structure
- Swift: `PascalCase/` for feature grouping

## Where to Add New Code

### New Web Feature Page

1. Create directory: `web-app/src/app/(features)/<feature>/page.tsx`
2. Add server actions: `web-app/src/app/(features)/<feature>/actions.ts`
3. Add route to middleware matcher in `web-app/src/middleware.ts`
4. Add bottom nav tab (if needed) in `web-app/src/components/layout/bottom-nav.tsx`

### New Web API Route

1. Create directory: `web-app/src/app/api/<path>/route.ts`
2. Export named functions (`GET`, `POST`, `PUT`, `DELETE`)
3. Use `getAuthUser()` from `web-app/src/lib/firestore.ts` for authentication
4. Use `userCollection(uid, "collectionName")` or `userDoc(uid)` for data access

### New Domain Logic (Web)

1. Create module: `web-app/src/lib/domain/<module-name>.ts`
2. Export from barrel: Add to `web-app/src/lib/domain/index.ts`
3. Create test: `web-app/src/lib/domain/__tests__/<module-name>.test.ts`
4. Pure functions only — no framework imports, no side effects, no external dependencies

### New iOS Feature

1. Domain logic: `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/<Feature>/`
2. View: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/<Feature>/<FeatureView>.swift`
3. ViewModel: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/<Feature>ViewModel.swift`
4. Tests: `SundeeFundee/Tests/SundeeFundeeKitTests/DomainTests/<FeatureTests>.swift`
5. Add tab to `MainTabView` in `SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift`

### New Web Component

- UI primitive: `web-app/src/components/ui/<component-name>.tsx`
- Layout component: `web-app/src/components/layout/<component-name>.tsx`
- Feature component: `web-app/src/components/<feature>/<component-name>.tsx`

### New Admin Feature

1. Page: `web-app/src/app/(admin)/admin/<feature>/page.tsx`
2. API route: `web-app/src/app/api/admin/<feature>/route.ts` (and `api/admin/<feature>/[id]/route.ts` for detail)
3. Component: `web-app/src/components/admin/<component-name>.tsx`

### New Cloud Function

1. Add function to `firebase/functions/src/index.ts`
2. Add supporting module: `firebase/functions/src/<module>.ts`
3. Build: `cd firebase/functions && npm run build`
4. Deploy: `firebase deploy --only functions`

## Special Directories

**`.planning/codebase/`** — Generated codebase analysis documents (this file)
- Generated: Yes (by `/gsd-map-codebase` command)
- Committed: Yes

**`.agents/skills/`** — Agent automation skill definitions
- Contains: ~25 App Store Connect automation skill directories
- Generated: No (manually maintained)
- Committed: Yes

**`web-app/content/blog/`** — Blog MDX content (legacy)
- Generated: No
- Committed: Yes
- Note: Blog posts are now stored in Firestore (`blogPosts` collection), this directory contains only `welcome.mdx`

**`web-app/public/icons/`** — PWA icons
- Generated: No (manually created)
- Committed: Yes

**`docs/screenshots/`** — Raw simulator screenshots
- Generated: Yes (by iOS simulator and screenshot scripts)
- Committed: Yes

**`firebase/functions/lib/`** — Compiled Cloud Functions
- Generated: Yes (by `npm run build`)
- Committed: Yes

**`SundeeFundeeApp/SundeeFundee/Assets.xcassets/`** — Xcode asset catalog
- Generated: No (manually managed)
- Committed: Yes

**`backend/`** — Experimental backend
- Status: Experimental, uses Teenybase ORM on Cloudflare Workers
- Not actively used by the main application

---

*Structure analysis: 2026-04-08*
