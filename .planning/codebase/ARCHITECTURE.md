---
name: Architecture
type: codebase-map
focus: arch
created: 2026-04-08
---

# Architecture

**Analysis Date:** 2026-04-08

## Pattern Overview

**Overall:** Multi-platform application with a Next.js 16 App Router web app (PWA), a native iOS app (Swift/SwiftUI), and Firebase Cloud Functions. The web and iOS apps share a common domain model but use entirely separate backend stacks: the web app uses Firebase (Auth, Firestore, Cloud Functions) while the iOS app uses Apple Sign-In + CloudKit.

**Key Characteristics:**
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

**Route Groups:**
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

**Key API Routes:**
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

**Key Modules:**
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

**Key Files:**
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

**Subdirectories:**
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

**Key Pattern — Protocol + Factory:**
- `DataClientProtocol` — Async protocol for fetch/save/delete with generic Codable types
- `DataClientFactory.shared.client` — Thread-safe singleton holding the active client
- `CloudKitClient` — Actor-based CloudKit implementation for signed-in users
- `LocalDataClient` — Local storage for guest users
- `MockCloudKitClient` / `MockHealthKitClient` — In-memory mocks for testing

**Sync Queue:**
- `SyncQueue.swift` — Queues mutations offline and replays when connectivity returns
- `PendingMutation.swift` — Encoded mutation representation
- `NetworkMonitor.swift` — Connectivity observation

### iOS App — UI Layer

- Purpose: SwiftUI views and view models
- Location: `SundeeFundee/Sources/SundeeFundeeKit/UI/`
- Contains: App entry point views, tab navigation, feature views, view models, theme, shared UI models
- Depends on: Domain layer, Data layer, Auth, Subscription
- Used by: `SundeeFundeeApp` Xcode project

**Views:** Dashboard, Workouts (list/detail/AI/picker), Programs, Maxes, Benchmarks, Cycle calendar, Analytics (charts), Settings, Pain tracking, Export, Share, Onboarding, Insights

### Cloud Functions

- Purpose: Serverless backend for AI workout generation (secondary path to web app's direct API)
- Location: `firebase/functions/src/`
- Contains: Callable function `generateWorkoutFn`, Vertex AI integration, Firestore rate limiting
- Depends on: `firebase-admin`, `firebase-functions`, `@google-cloud/vertexai`
- Used by: Callable from Firebase Client SDK (alternative to web API route)

**Components:**
- `index.ts` — `generateWorkoutFn` callable function (auth check, tier check, rate limit, generate, save)
- `ai.ts` — Vertex AI Gemini Flash integration, workout response validation
- `rate-limit.ts` — Firestore-based daily rate limiting (plus: 1/day, premium: 10/day)

## Data Flow

### Web Auth Flow

1. User clicks "Sign in with Google" or "Sign in with Apple" on `web-app/src/app/(auth)/sign-in/page.tsx`
2. `signInWithGoogle()` from `web-app/src/lib/social-auth.ts` handles popup (or redirect on iOS Safari)
3. Firebase Client SDK authenticates the user, returns `User` object
4. `AuthProvider` (`web-app/src/components/providers/auth-provider.tsx`) listens via `onIdTokenChanged`
5. On auth state change, client calls `POST /api/auth/session` with the Firebase ID token
6. Server verifies ID token via `adminAuth.verifyIdToken()`, creates session cookie via `adminAuth.createSessionCookie()`
7. Session cookie (`__session`) set as httpOnly, secure, sameSite=lax, 13-day expiry
8. Subsequent requests carry the cookie; `web-app/src/middleware.ts` checks for cookie presence on protected routes
9. Server-side data access uses `getAuthUser()` from `web-app/src/lib/firestore.ts` which verifies the session cookie

### Web Data Flow (Server Actions)

1. User interacts with a feature page (e.g., Dashboard)
2. Client component calls a server action from `actions.ts` co-located with the page
3. Server action calls `getAuthUser()` to authenticate and get `uid`
4. Server action reads/writes Firestore via `userCollection(uid, "collectionName")` or `userDoc(uid)`
5. Data is returned to the client component as plain objects
6. Example pattern from `web-app/src/app/(features)/dashboard/actions.ts`:
   ```typescript
   const user = await getAuthUser();
   if (!user) return [];
   const snapshot = await userCollection(user.uid, "collectionName").orderBy("date", "desc").get();
   return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
   ```

### Web Data Flow (API Routes)

1. Client component calls `fetch("/api/...")` from a `"use client"` component
2. API route handler in `web-app/src/app/api/*/route.ts` calls `getAuthUser()`
3. Handler validates request, processes business logic using domain functions
4. Handler reads/writes Firestore via `db` from `web-app/src/lib/firebase-admin.ts`
5. Response returned as JSON

### AI Workout Generation (Web API Route)

1. User fills out workout questionnaire on `web-app/src/app/(features)/workouts/ai/page.tsx`
2. Client POSTs to `/api/ai/generate` with time, focus, energy, equipment, cycle phase
3. API route authenticates user, resolves subscription entitlement
4. Fetches user context (profile, maxes, recent workouts, exercise catalog) in parallel
5. Builds prompt using `buildWorkoutPrompt()` and system instruction from `web-app/src/lib/ai-generation.ts`
6. Calls Google GenAI SDK (`@google/genai`) with Gemini Flash Lite
7. Parses response with `parseAIWorkoutResponse()`, increments daily AI usage
8. Saves generation record to `users/{uid}/generatedWorkoutRecords`
9. Returns workout with usage metadata

### Stripe Subscription Flow

1. User selects a plan on the subscription page
2. Client calls `/api/stripe/checkout` to create a Stripe Checkout Session with `userId` in metadata
3. User completes payment on Stripe's hosted checkout
4. Stripe sends `checkout.session.completed` webhook to `/api/stripe/webhook`
5. Webhook handler verifies signature, extracts userId from metadata, retrieves subscription from Stripe
6. Maps priceId to tier via `tierFromPriceId()` from `web-app/src/lib/stripe.ts`
7. Upserts subscription record to `users/{uid}/subscription/current`
8. Client reads subscription status from Firestore or via API

### iOS Data Flow

1. User authenticates via Apple Sign-In (no Firebase on iOS)
2. `AuthViewModel` stores session in Keychain via `KeychainHelper`
3. `DataClientFactory.shared.client` is set to `CloudKitClient` for signed-in users or `LocalDataClient` for guests
4. ViewModels use the protocol (`DataClientProtocol`) to fetch/save/delete records
5. All writes gate on `!authViewModel.isGuest` to prevent CloudKit writes in guest mode
6. `SyncQueue` queues mutations offline and replays on connectivity restore
7. `HealthKitClient` syncs workout data to Apple Health

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

**Strategy:** Defensive with graceful degradation

**Web Patterns:**
- API routes return structured JSON errors with appropriate HTTP status codes (401, 400, 403, 429, 500, 502)
- Auth errors surface as user-friendly messages via `socialAuthErrorMessage()` in `web-app/src/lib/social-auth.ts`
- Blog fetching returns empty array on failure (graceful degradation)
- Domain functions are pure and throw typed errors
- Global error boundary at `web-app/src/app/error.tsx` and `web-app/src/app/global-error.tsx`

**iOS Patterns:**
- `DataError` enum with `LocalizedError` conformance provides error descriptions and recovery suggestions
- `HealthError` enum for HealthKit-specific errors
- `SubscriptionError` enum for subscription operation errors
- Actor-based clients ensure thread-safe error handling

## Cross-Cutting Concerns

**Logging:** Console-based (`console.error`, `console.log`) with `[auth/session]`, `[ai/generate]` prefixes for traceability. No structured logging framework.

**Validation:** Input validation in `web-app/src/lib/write-validation.ts` (server-side) and `web-app/src/lib/ai-generation.ts` (AI request validation). Domain types use `as const` objects for enums, enforced at TypeScript level. Buttons disabled for invalid input rather than silently failing.

**Authentication:**
- Web: Firebase Auth (Google, Apple, Email/Password) with session cookies verified server-side
- iOS: Apple Sign-In only, session in Keychain, guest mode for offline/local use
- Both: `user.uid` threaded through all data-writing operations

**Authorization:**
- Web middleware checks `__session` cookie presence on protected routes
- Admin routes verified server-side via `isAdmin(uid)` in admin layout
- Firestore security rules restrict subcollections to `request.auth.uid == userId`

**Subscription Tiers:**
- Feature gating via `canAccess(feature, tier)` in domain layer
- Server-side entitlement resolution via `resolveEntitlement(uid)`
- Three tiers: Free, Sundee Plus, Sundee Premium

**Offline/PWA:**
- Service worker with precaching and runtime caching via Serwist
- Auth routes bypass cache (NetworkOnly strategy)
- Manifest for standalone PWA install
- iOS: SyncQueue for offline mutation replay with CloudKit

---

*Architecture analysis: 2026-04-08*
