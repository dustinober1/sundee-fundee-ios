---
name: Coding Conventions
type: codebase-map
focus: quality
created: 2026-04-08
---

# Coding Conventions

**Analysis Date:** 2026-04-08

## Naming Patterns

**Files:**
- TypeScript/React files: kebab-case (`weight-calculations.ts`, `bottom-nav.tsx`, `auth-provider.tsx`)
- Test files: match source module name with `.test.ts` suffix (`weight-calculations.test.ts`)
- Swift files: PascalCase (`AppTheme.swift`, `WeightCalculatorTests.swift`)
- Swift test files: PascalCase with `Tests` suffix (`WeightCalculatorTests.swift`)

**Functions:**
- Pure domain functions: camelCase (`roundToNearestFive`, `calculateTargetWeight`, `applyWeights`)
- Server actions: camelCase async functions (`getCycleStatus`, `getDashboardStats`)
- React components: PascalCase named exports (`Button`, `Card`, `PageHeader`)
- Swift functions: camelCase (`defaultPercentage`, `calculatePrescribedWeight`)

**Variables:**
- Constants: UPPER_SNAKE_CASE for true constants (`STANDARD_BARBELL_KG`, `SESSION_EXPIRY_MS`, `PLUS_FEATURES`)
- Regular variables: camelCase
- Private/instance prefix: underscore for unused params (`_feature`, `_currentTier`)

**Types:**
- Interfaces: PascalCase (`ProgramExercise`, `CycleSettings`, `DashboardStats`)
- Type aliases: PascalCase (`WorkoutFocus`, `EnergyLevel`, `EquipmentAccess`)
- Enums: PascalCase const objects (`ExperienceLevel`, `SubscriptionTier`, `CyclePhase`)

## Code Style

**Formatting:**
- No Prettier config detected; formatting follows ESLint + TypeScript conventions
- Tailwind CSS 4 with `@theme` directive in `web-app/src/app/globals.css`
- Indentation: 2 spaces (TypeScript/React)

**Linting:**
- ESLint 9 with `eslint-config-next` (core-web-vitals + typescript)
- Config: `web-app/eslint.config.mjs`
- Key rule: unused vars prefixed with `_` are ignored (`argsIgnorePattern: "^_"`, `varsIgnorePattern: "^_"`)

**TypeScript:**
- Strict mode enabled (`"strict": true` in `tsconfig.json`)
- Target: ES2018, module resolution: bundler
- Path alias: `@/*` maps to `./src/*`
- No `enum` keyword -- use `as const` objects with derived types

## Import Organization

**Order:**
1. React/Next.js imports (`"react"`, `"next/..."`)
2. External packages (`"firebase/auth"`, `"stripe"`)
3. Internal library imports (`@/lib/...`, `@/components/...`)
4. Relative imports (`../...`, `./...`)
5. Type-only imports (`import type { ... }`)

**Path Aliases:**
- `@/*` resolves to `web-app/src/*` (configured in both `tsconfig.json` and `vitest.config.ts`)

**Dynamic Imports:**
- Firebase Auth is always dynamically imported in client components to avoid SSR failures:
```typescript
// Correct pattern:
const { signInWithEmailAndPassword } = await import("firebase/auth");
const { getFirebaseAuth } = await import("@/lib/firebase");
```
- Never import `firebase/auth` at the top level of client components.

## Component Patterns

**Server Components (default):**
- Feature pages are async Server Components (`web-app/src/app/(features)/**/page.tsx`)
- They call server actions directly and pass data to child components
- Authentication check at top: `const user = await getAuthUser(); if (!user) redirect("/sign-in");`
- Parallel data fetching with `Promise.all`:
```typescript
const [cycleStatus, stats, activeProgram, recentWins] = await Promise.all([
  getCycleStatus(),
  getDashboardStats(),
  getActiveProgram(),
  getRecentWins(),
]);
```

**Client Components (`"use client"`):**
- Required for: event handlers, `useState`, `useEffect`, `useRouter`, browser APIs
- Examples: `web-app/src/components/ui/button.tsx`, `web-app/src/components/layout/bottom-nav.tsx`, `web-app/src/components/providers/auth-provider.tsx`

**Server Actions (`"use server"`):**
- Located in `actions.ts` files co-located with their feature pages
- Example: `web-app/src/app/(features)/dashboard/actions.ts`
- Always start by calling `getAuthUser()` and returning `null`/empty if unauthenticated
- Use `userCollection(user.uid, "collectionName")` for Firestore queries

**UI Primitives:**
- Use `forwardRef` pattern for reusable UI components (`Button`, `Card`, `Input`)
- Set `displayName` on forwarded-ref components
- Example from `web-app/src/components/ui/button.tsx`:
```typescript
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", fullWidth = false, className = "", children, ...props }, ref) => {
    return (
      <button ref={ref} className={`...`} {...props}>
        {children}
      </button>
    );
  }
);
Button.displayName = "Button";
```

## State Management

**React Context:**
- `AuthProvider` at `web-app/src/components/providers/auth-provider.tsx` wraps the entire app
- Provides `user` (Firebase `User | null`) and `loading` (boolean)
- Access via `useAuth()` hook
- Syncs Firebase ID tokens to server-side session cookies via `/api/auth/session`

**Server State:**
- No client-side data caching library (no React Query, SWR, etc.)
- Data fetched per-request in Server Components and server actions
- Firestore reads happen server-side via Firebase Admin SDK

**iOS State:**
- `AuthViewModel` (ObservableObject) manages auth state and `isGuest` flag
- `ThemeViewModel` manages theme state
- Gate CloudKit writes with `!authViewModel.isGuest`

## Data Access Patterns

**Server-side Firestore:**
- Use `getAuthUser()` from `web-app/src/lib/firestore.ts` for authentication
- Use `userCollection(uid, "name")` for subcollection queries
- Use `userDoc(uid)` for user-level document access
- Standard pattern:
```typescript
const user = await getAuthUser();
if (!user) return [];
const snapshot = await userCollection(user.uid, "collectionName")
  .orderBy("date", "desc")
  .get();
return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
```

**Firebase Admin SDK Initialization:**
- Lazy-initialized via Proxy pattern in `web-app/src/lib/firebase-admin.ts`
- Never call `getAdminApp()` directly -- use exported `adminAuth` and `db` proxies

**Client-side Firebase:**
- Use `getFirebaseAuth()` from `web-app/src/lib/firebase.ts` -- never import `firebase/auth` at top level
- Dynamic import pattern required to avoid SSR pre-render failures

## Error Handling

**Server Actions:**
- Return `null` or empty arrays for unauthenticated users (never throw)
- Return typed result objects with default fallbacks

**API Routes:**
- Return `NextResponse.json({ error: "message" }, { status: code })`
- Log errors with `console.error` using bracketed context prefix: `console.error("[auth/session] ...", { message })`
- Distinguish config errors from user errors in auth routes

**Domain Functions:**
- Pure functions return default values for edge cases (never throw)
- `cyclePhaseMultiplier(null)` returns `1.0`
- `decodeExerciseValue(unknown)` always returns a valid `ExerciseValue`

**Async Error Handling:**
- Use `try/catch` around dynamic imports and Firebase calls
- Empty `catch` blocks acceptable when failure is recoverable (e.g., persistence fallback in `AuthProvider`)

## Logging

**Framework:** `console` (no structured logging library)

**Patterns:**
- Server-side: `console.error("[context] Message", { details })`
- Client-side: `console.error("[auth] Message", error)` in auth flows
- Never leave `print()` statements in Swift code (caught in commit `80ba06d2`)

## Comments

**When to Comment:**
- JSDoc on exported domain functions explaining purpose and formulas
- Section separators with `// ---------------------------------------------------------------------------` blocks
- `// MARK: -` sections in Swift files

**JSDoc/TSDoc:**
- Used on domain functions for parameter descriptions and return value explanations
- Example from `web-app/src/lib/domain/plate-calculation.ts`:
```typescript
/**
 * Returns the plates needed per side to reach the target total weight.
 * Uses a greedy algorithm with the standard plate sizes.
 *
 * @param totalWeightKg  The desired total barbell weight in kg.
 * @param barbellWeightKg  The weight of the barbell itself.
 * @returns Array of { weight, count } for each plate denomination used (per side).
 */
```

## Function Design

**Size:** Functions are short and focused, typically 5-20 lines. Domain functions are single-responsibility pure functions.

**Parameters:** Use typed interfaces for complex parameters. Simple parameters are positional.

**Return Values:** Always return typed values. Use `null` for "not found" rather than `undefined`. Use `as const` for constant return values.

## Module Design

**Exports:** Named exports only. No default exports except for page components (Next.js requirement).

**Barrel Files:**
- `web-app/src/lib/domain/index.ts` re-exports all domain modules
- Import from the barrel file in application code, from individual files in tests

## Domain-Specific Patterns

**Const Objects for Enums:**
- Never use TypeScript `enum`. Use `as const` objects with derived types:
```typescript
export const SubscriptionTier = { free: "free", plus: "plus", premium: "premium" } as const;
export type SubscriptionTier = (typeof SubscriptionTier)[keyof typeof SubscriptionTier];
```
- Stored as text fields in Firestore (not numeric enums)

**Discriminated Unions:**
- Use a `type` field for variant discrimination:
```typescript
export type ExerciseValue =
  | { type: "fixed"; value: number }
  | { type: "amrap" }
  | { type: "range"; low: number; high: number }
  | { type: "text"; value: string };
```
- Switch exhaustively on the `type` field in functions

**Multiplier-Based Adaptation:**
- Cycle phase, recovery phase, and energy level compose multiplicatively on base weights
- Multipliers are between 0.75 and 1.25, clamped after composition
- Example: `weight = max * percentage * energyMult * cycleMult`

**Benchmark `roundsAndReps` Scoring:**
- Encode as `rounds * 10000 + reps` in a single number
- Decode: `rounds = Math.floor(value / 10000)`, `reps = value % 10000`
- Higher is better

**Feature Gating:**
- `PLUS_FEATURES` and `PREMIUM_FEATURES` arrays define tier-gated features
- `canAccess(feature, tier)` checks rank-based access
- Users always retain read access to data created during a higher tier

## UI/UX Patterns

**Art Deco Theme Tokens:**
- Defined in `web-app/src/lib/theme.ts` (JS constants) and `web-app/src/app/globals.css` (CSS `@theme`)
- Primary colors: cream `#f4f0df`, navy `#0d1a40`, orange `#f27319`, gold `#d9b34d`
- Card background: `#fcfaf2`
- Fonts: Playfair Display (headings), Inter (body), JetBrains Mono (mono/numbers)
- Same tokens mirrored in iOS `SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift`

**Tailwind Usage:**
- Use semantic color names from `@theme`: `text-navy`, `bg-cream`, `border-gold/20`, `text-orange`
- Use spacing tokens: `gap-spacing-md`, `px-spacing-lg`, `p-4`
- Use radius tokens: `rounded-card`, `rounded-button`
- Inline `className` strings (no CSS modules)

**Layout:**
- Feature pages use `max-w-xl mx-auto` container with `pb-20` for bottom nav clearance
- Bottom nav fixed at bottom with `pb-[env(safe-area-inset-bottom)]` for iOS notch
- Cards use `.card` class or `<Card>` component

**Bottom Navigation:**
- 5 tabs: Dashboard, Programs, Maxes, Benchmarks, More (Settings)
- Defined in `web-app/src/components/layout/bottom-nav.tsx` with SVG path icons
- Active state: gold text + thicker stroke; inactive: white text

## Git Workflow

**Commit Strategy:**
- Commit each file separately -- stage and commit one file at a time
- Commit message format: `type(scope): description`
- Types observed: `fix`, `chore`, `feat`
- Scopes reference issue numbers: `fix(#120)`, `fix(#122)`

**Branch Strategy:**
- Main branch: `main`
- No CI/CD pipeline; manual deployment via `vercel deploy --prod`

## Firestore Data Model Conventions

**Document Paths:**
- User data: `users/{uid}/subcollection/{id}`
- User profile: `users/{uid}` (top-level doc)
- Cycle settings: `users/{uid}/cycleSettings/default` (single doc with known ID)
- Subscription: `users/{uid}/subscription/current` (single doc with known ID)
- AI usage: `users/{uid}/aiUsage/{YYYY-MM-DD}` (date-keyed docs)
- Benchmark definitions: `benchmarkDefinitions/{id}` (top-level, shared)

**Data Conventions:**
- Always use `user.uid` for ownership queries, never hardcoded strings
- Dates stored as Firestore Timestamps, converted with `(data.field as Timestamp).toDate()`
- Denormalized data is acceptable (e.g., `programName` stored in enrollment)
- Use `.orderBy("date", "desc")` as default sort for time-series subcollections

**Security:**
- Rules in `web-app/firestore.rules`: `request.auth.uid == userId` for user subcollections
- `benchmarkDefinitions` readable by all authenticated users, writable only via Admin SDK

## iOS-Specific Conventions

**Swift Package Structure:**
- All domain logic in `SundeeFundee/Sources/SundeeFundeeKit/`
- Tests in `SundeeFundee/Tests/SundeeFundeeKitTests/`
- Domain logic mirrors web app domain layer in `DomainLayer/` subdirectory

**SwiftUI Patterns:**
- Use `AppTheme.*` tokens for all colors, spacing, and typography
- Use `.artDecoBackground()` modifier on root views
- Views need `.frame(maxWidth: .infinity, maxHeight: .infinity)` before `.artDecoBackground()`
- Button styles: `.artDecoButton(style: .primary)` with `AppButtonStyle` enum

**Testing:**
- XCTest framework for older tests (`XCTAssertEqual`, `XCTAssertGreaterThan`)
- Swift Testing framework for newer tests (`import Testing`, `@Test` functions)
- Test helpers: `makeDate()`, `makeWorkout()`, `makeExercise()` factory functions
- `@testable import SundeeFundeeKit` for internal access

---

*Convention analysis: 2026-04-08*
