# Architecture Research

**Domain:** Cross-platform fitness app — React Native + Expo + Firebase (offline-first, subscription-gated)
**Researched:** 2026-03-14
**Confidence:** HIGH (Firebase, RevenueCat, Expo docs); MEDIUM (folder structure patterns, community best practices)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │Dashboard │  │Workouts  │  │  Cycle   │  │ Settings │  ...   │
│  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
├───────┴──────────────┴─────────────┴──────────────┴─────────────┤
│                     State / Hooks Layer                          │
│  ┌───────────┐  ┌──────────────┐  ┌────────────────────────┐    │
│  │Zustand    │  │ Custom Hooks │  │ Domain Logic (pure TS) │    │
│  │Stores     │  │ (use-cases)  │  │ /src/domain/           │    │
│  └─────┬─────┘  └──────┬───────┘  └────────────────────────┘    │
├────────┴───────────────┴────────────────────────────────────────┤
│                      Repository Layer                            │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │FirestoreRepo  │  │ LocalRepo    │  │  PaymentRepository   │  │
│  │(CRUD + sync)  │  │(AsyncStorage)│  │  (RevenueCat)        │  │
│  └───────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
├──────────┴────────────────┴────────────────────────┴─────────────┤
│                        Data Layer                                │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐             │
│  │  Firestore   │  │AsyncStorage  │  │ RevenueCat │             │
│  │(native SDK)  │  │(local cache) │  │ + Stripe   │             │
│  └──────────────┘  └──────────────┘  └────────────┘             │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │Firebase Auth │  │Cloud Funcs   │                             │
│  │(Apple/Google │  │(Gemini proxy,│                             │
│  │ Email/Guest) │  │ WOD writes)  │                             │
│  └──────────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Screen components | Render UI, handle user events | React functional components, Expo Router pages |
| Zustand stores | Global app state (auth, subscriptions, UI flags) | Per-domain slices: useAuthStore, useSubscriptionStore |
| Custom hooks (use-cases) | Orchestrate domain logic + repository calls | `useGenerateWorkout()`, `useCycleAdaptation()` |
| Domain layer | Pure business logic — cycle adaptation, injury engine, benchmarks | Zero-dependency TypeScript modules, 100% testable |
| Repository interfaces | Typed contracts for data access | TypeScript interfaces, one implementation per backend |
| Firestore repository | CRUD to Firestore; offline handled by native SDK | react-native-firebase/firestore |
| Local repository | Offline-only guest data; persisted state | AsyncStorage via Zustand `persist` middleware |
| Payment repository | Entitlement checks, purchase flows | RevenueCat react-native-purchases (mobile + web) |
| Firebase Auth | User identity, sign-in providers | react-native-firebase/auth |
| Cloud Functions | Server-side: Gemini proxy, WOD admin writes | Node.js/TypeScript Firebase Functions |

## Recommended Project Structure

```
src/
├── app/                    # Expo Router pages (file-based routing)
│   ├── (auth)/             # Sign-in, onboarding routes
│   ├── (tabs)/             # Main tab bar: dashboard, programs, workouts, cycle, history
│   ├── _layout.tsx         # Root layout, auth gate, theme provider
│   └── +not-found.tsx      # 404 fallback
│
├── domain/                 # Pure TypeScript — zero framework deps
│   ├── cycle/              # Phase inference, adaptation multipliers
│   ├── injury/             # Injury engine, exercise substitution
│   ├── benchmarks/         # Benchmark catalog, scoring
│   ├── maxes/              # 1RM calculations
│   ├── pain/               # Pain trend analysis
│   ├── rehab/              # Rehab session generation
│   └── types.ts            # Shared domain types (enums, interfaces)
│
├── repositories/           # Data access contracts + implementations
│   ├── interfaces/         # TypeScript interfaces (IWorkoutRepo, ICycleRepo, etc.)
│   ├── firestore/          # react-native-firebase implementations
│   ├── local/              # AsyncStorage implementations (guest mode)
│   └── index.ts            # Factory: returns correct impl based on auth mode
│
├── stores/                 # Zustand global state slices
│   ├── auth-store.ts       # Auth state, currentUser, mode (authenticated/guest)
│   ├── subscription-store.ts # RevenueCat entitlements
│   └── ui-store.ts         # Modal state, loading flags
│
├── hooks/                  # Use-case hooks — orchestrate domain + repositories
│   ├── use-generate-workout.ts
│   ├── use-cycle-adaptation.ts
│   ├── use-injury-engine.ts
│   └── use-workout-execution.ts
│
├── features/               # Feature modules (self-contained per tab/feature)
│   ├── dashboard/
│   │   ├── components/
│   │   └── dashboard-screen.tsx
│   ├── programs/
│   ├── workouts/
│   ├── cycle/
│   ├── history/
│   ├── benchmarks/
│   ├── maxes/
│   └── settings/
│
├── components/             # Shared, reusable UI components
│   ├── ui/                 # Base: Button, Card, Badge, Input
│   └── workout/            # ForTimerTimer, AmrapTimer, EmomTimer, etc.
│
├── theme/                  # Design tokens: Art Deco palette, typography, spacing
│   └── index.ts
│
├── services/               # External service integrations (non-repository)
│   ├── firebase.ts         # Firebase app init
│   ├── revenuecat.ts       # RevenueCat SDK init
│   └── analytics.ts        # Firebase Analytics wrapper
│
├── utils/                  # Pure utility functions (formatters, date helpers)
└── types/                  # App-wide TypeScript types (not domain types)
```

### Structure Rationale

- **`domain/`** mirrors the existing iOS `Domain/` folder exactly — pure logic, no RN/Firebase imports. This enables direct TypeScript porting from Swift with identical test coverage.
- **`repositories/`** mirrors iOS `Repositories/` protocol-based pattern. Factory function swaps Firestore vs AsyncStorage implementation based on auth mode (authenticated vs guest).
- **`stores/`** stays thin — only global cross-cutting state. Feature state lives inside feature hooks.
- **`features/`** is feature-first, not layer-first. All code for a feature (screen + components) co-locates, reducing navigation cost when working on one feature.
- **`hooks/`** are the use-case layer — they call domain functions and repositories together, analogous to iOS ViewModels.

## Architectural Patterns

### Pattern 1: Repository Factory Pattern

**What:** A factory function returns the correct repository implementation based on auth mode. Authenticated users get Firestore repos; guest users get AsyncStorage repos. Consumers never know which they get.

**When to use:** Required — this is how offline guest mode works without branching logic throughout the codebase.

**Trade-offs:** Adds indirection; simpler apps can hard-code Firestore. Worth it here because guest mode is a first-class requirement.

**Example:**
```typescript
// repositories/index.ts
export function getWorkoutRepo(authMode: 'authenticated' | 'guest'): IWorkoutRepository {
  return authMode === 'authenticated'
    ? new FirestoreWorkoutRepository()
    : new LocalWorkoutRepository();
}

// Usage in hook
const workoutRepo = getWorkoutRepo(useAuthStore(s => s.mode));
```

### Pattern 2: Pure Domain Layer (Zero Framework Deps)

**What:** All business logic (cycle math, injury substitution, benchmark scoring, pain trends) lives in `src/domain/` as plain TypeScript functions and classes. No React, no Firebase, no Expo imports allowed in this folder.

**When to use:** Always — this is what makes the domain testable with Jest without mocking anything.

**Trade-offs:** Requires discipline to keep the boundary clean. Eslint import rules can enforce it.

**Example:**
```typescript
// domain/cycle/adaptation.ts
export function adaptWorkloadForPhase(
  baseLoad: number,
  phase: CyclePhase,
  symptoms: Symptom[]
): AdaptedWorkload {
  const multiplier = PHASE_MULTIPLIERS[phase];
  const symptomAdjustment = computeSymptomAdjustment(symptoms);
  return { load: baseLoad * multiplier * symptomAdjustment };
}
// No React. No Firebase. Pure logic. Jest testable.
```

### Pattern 3: Offline-First with react-native-firebase

**What:** Use `react-native-firebase` (native SDK wrapper) instead of the Firebase JS SDK. On iOS and Android, Firestore offline persistence is enabled by default with the native SDK — no extra configuration. Writes queue locally and sync automatically on reconnect.

**When to use:** Required for offline support. The Firebase JS SDK does NOT support Firestore offline persistence in React Native/Expo. The native SDK does.

**Trade-offs:** Requires a custom Expo dev client (cannot use Expo Go). Config plugins via `app.json` handle native configuration — no manual Xcode/Gradle editing needed. Build via `eas build` instead of Expo Go.

**Example:**
```typescript
// Default behavior — no extra setup needed for offline
import firestore from '@react-native-firebase/firestore';

// This write queues locally if offline, syncs when online
await firestore()
  .collection('users')
  .doc(userId)
  .collection('workouts')
  .add(workoutData);
```

**Critical constraint:** Transactions fail when offline. Use standard document writes (not transactions) for data that must work offline. Reserve transactions for server-side Cloud Functions only.

### Pattern 4: RevenueCat Unified Entitlements

**What:** RevenueCat `react-native-purchases` (v9.7.6+) manages subscriptions across iOS, Android, and Web from a single SDK. On iOS/Android, it wraps StoreKit/Google Play. On Web, it uses RevenueCat Web Billing (backed by Stripe). The `appUserID` is your Firebase UID — this links entitlements to your user identity across platforms.

**When to use:** Use this pattern for all paywall gates. Never check payment state from Apple/Google directly — always check RevenueCat entitlements.

**Trade-offs:** RevenueCat Web Billing is a separate product from native IAP (different Stripe account configuration). Entitlements unify at the RevenueCat layer. Web checkout at lower price tier is their stated use case.

**Example:**
```typescript
// Platform-specific purchase initiation
// .native.ts — iOS/Android
await Purchases.purchasePackage(selectedPackage);

// .web.ts — Web (opens RevenueCat-hosted Stripe checkout)
await Purchases.purchasePackage(selectedPackage);
// SDK handles platform differences; entitlement check is identical:
const { customerInfo } = await Purchases.getCustomerInfo();
const isPremium = customerInfo.entitlements.active['premium'] !== undefined;
```

## Data Flow

### Workout Execution Flow (Offline-Critical)

```
User starts workout
    ↓
useWorkoutExecution() hook
    ↓ (reads from local cache or Firestore)
WorkoutRepository.getProgram()
    ↓ (Firestore cached data — available offline)
Domain: adaptWorkloadForPhase(baseLoad, cyclePhase, symptoms)
    ↓
Domain: applyInjuryModifications(exercises, injuryProfile)
    ↓
Screen renders adapted workout
    ↓ (user completes sets, logs results)
WorkoutRepository.saveCompletedSet()
    ↓ (writes to Firestore local cache immediately)
    ↓ (auto-syncs to Firestore server when online)
History updated via real-time Firestore listener
```

### Auth + Routing Flow

```
App starts
    ↓
Firebase Auth state listener (immediate — cached from last session)
    ↓
         ┌── No user → guest mode OR sign-in screen
         └── User exists → AppState: authenticated
                               ↓
                 RevenueCat.logIn(firebaseUID) — links entitlements
                               ↓
                 Check entitlements → premium or free tier
                               ↓
                 Navigate to main tabs
```

### AI Workout Generation Flow

```
User requests AI workout
    ↓
useGenerateWorkout() hook
    ↓ (checks connectivity)
         ┌── Offline → return cached/fallback workout
         └── Online → call Cloud Function endpoint
                          ↓
               Cloud Function (Gemini proxy)
                          ↓ (returns workout JSON)
              Domain: validateAndAdaptWorkout()
                          ↓
              Save to Firestore (queued if offline mid-request)
```

### State Management

```
Zustand stores (global, persisted via AsyncStorage)
    auth-store: { user, mode, firebaseUID }
    subscription-store: { entitlements, isPremium }
    ui-store: { activeModal, loadingStates }
         ↓ (subscribed via selectors)
Feature hooks → Domain logic → Repository calls
         ↓
Firestore real-time listeners push updates back to hooks
         ↓
Hooks return derived state to screen components
```

## Build Order Implications

Build in this dependency order — each layer depends only on what came before:

1. **Domain layer** (`src/domain/`) — No deps. Port Swift logic to TypeScript here first. Establish test coverage before any UI work.
2. **Repository interfaces** (`src/repositories/interfaces/`) — Define contracts before implementations.
3. **Firebase + Auth setup** — SDK init, auth listeners, `useAuthStore`. Everything authenticated depends on this.
4. **Local repositories** (`src/repositories/local/`) — Guest mode. Unblocks offline testing without Firestore.
5. **Firestore repositories** (`src/repositories/firestore/`) — Authenticated mode data access.
6. **Zustand stores** (`src/stores/`) — Global state wiring.
7. **Core use-case hooks** (`src/hooks/`) — Orchestrate domain + repos.
8. **RevenueCat integration** (`src/services/revenuecat.ts`, `subscription-store`) — Can be stubbed early; needs real SKU IDs for paywall testing.
9. **Feature screens** (`src/features/`) — Build last; they consume everything above.
10. **Cloud Functions** — Can develop in parallel with mobile; needed for AI workout generation and WOD admin writes.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Monorepo, single Firestore database, no sharding needed. EAS Build for CI. |
| 1k-10k users | Monitor Firestore read costs on program catalog (public collection — all users read same data). Add Firestore caching rules. Consider bundling programs.json fallback. |
| 10k-100k users | Cloud Functions cold starts become noticeable for AI generation — keep Functions warm or move to Cloud Run. Firestore costs scale linearly; review query patterns for hotspots. |
| 100k+ users | Firestore document contention on public WOD documents (many users reading same doc). Consider CDN-cached static WOD delivery. RevenueCat at this scale is still fine — it's designed for it. |

### Scaling Priorities

1. **First bottleneck — Firestore read costs:** Public program catalog and WODs read by every user on launch. Mitigate by bundling programs.json and wods.json in the app binary; use Firestore only for updates.
2. **Second bottleneck — Cloud Function latency:** AI workout generation goes cold. Mitigate with minimum instance count (1) once user volume justifies the cost (~$5/month).

## Anti-Patterns

### Anti-Pattern 1: Using Firebase JS SDK for Offline Persistence

**What people do:** Install `firebase` (JS SDK) in Expo and expect offline persistence to work.
**Why it's wrong:** The Firebase JS SDK relies on IndexedDB for persistence, which is not available in React Native. Firestore offline persistence silently fails or throws errors.
**Do this instead:** Use `@react-native-firebase/firestore` (the native SDK wrapper via Expo Config Plugin). Offline persistence is enabled by default on iOS and Android with zero extra configuration.

### Anti-Pattern 2: Domain Logic in Screens or Hooks

**What people do:** Write cycle math, injury substitution, or benchmark scoring directly in screen components or hooks.
**Why it's wrong:** Untestable without rendering. Violates the iOS architecture that proved this logic correct with 100% coverage. Leads to duplication across platforms.
**Do this instead:** All business logic goes in `src/domain/` as pure TypeScript. Hooks call domain functions and pass results to screens.

### Anti-Pattern 3: Transactions for Offline-Capable Writes

**What people do:** Use Firestore transactions (`runTransaction`) for workout logging and set tracking because they feel "safer."
**Why it's wrong:** Firestore transactions require a server round-trip and fail when offline. Workout logging must work offline.
**Do this instead:** Use standard document writes or batch writes for all user data that must work offline. Reserve transactions for server-side logic (Cloud Functions) where connectivity is guaranteed.

### Anti-Pattern 4: One Monolithic Zustand Store

**What people do:** Put all app state (auth, subscriptions, workout state, cycle state, UI flags) in a single Zustand store.
**Why it's wrong:** Causes unnecessary re-renders across unrelated components. Hard to persist selectively. Hard to test.
**Do this instead:** Split stores by domain (`useAuthStore`, `useSubscriptionStore`, `useUIStore`). Feature-specific state stays in feature hooks, not global stores.

### Anti-Pattern 5: Hardcoding Subscription Checks Against Apple/Google

**What people do:** Use `expo-in-app-purchases` or StoreKit directly to check if a user is subscribed.
**Why it's wrong:** Platform-specific. Breaks on Web. Doesn't account for cross-platform purchases (user subscribed on web, using on iOS).
**Do this instead:** Always check `Purchases.getCustomerInfo()` from RevenueCat. Entitlements are unified across all platforms.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Firebase Auth | `@react-native-firebase/auth` listeners → `useAuthStore` | Apple Sign-In requires native module; cannot use Expo Go |
| Firestore | `@react-native-firebase/firestore` with offline persistence on by default | Settings must be called before first interaction |
| Firebase Cloud Functions | HTTP callable functions via `@react-native-firebase/functions` | Used for Gemini proxy, WOD admin; not for offline-critical paths |
| RevenueCat | `react-native-purchases` SDK, logIn with Firebase UID as `appUserID` | Requires `expo-dev-client` build; Web uses Web Billing (Stripe) |
| Gemini AI | Via Firebase Cloud Function (replaces Cloudflare Worker) | Functions endpoint returns workout JSON; degrade gracefully offline |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Domain ↔ Hooks | Direct TypeScript function calls | Domain has no async; hooks add async + repo calls |
| Hooks ↔ Repositories | Repository interface method calls | Hooks never import Firestore directly |
| Repositories ↔ Firestore | `@react-native-firebase/firestore` API | Offline cache transparent at this layer |
| Screens ↔ Stores | Zustand selectors (avoid subscribing to entire store) | Use `store(s => s.specificField)` selectors always |
| Mobile ↔ Web (payments) | RevenueCat unified entitlements via shared `appUserID` | Platform-specific purchase initiation, unified entitlement check |

## Sources

- [Expo — Offline-first apps with Legend State](https://expo.dev/blog/offline-first-apps-with-expo-and-legend-state) — LOCAL_FIRST pattern reference
- [Expo — Firebase integration guide](https://docs.expo.dev/guides/using-firebase/) — JS SDK vs react-native-firebase tradeoffs
- [React Native Firebase — Firestore usage](https://rnfirebase.io/firestore/usage) — Offline persistence, query patterns, constraints
- [React Native Firebase — Offline support](https://rnfirebase.io/database/offline-support) — Cache size, goOffline/goOnline mechanics
- [Firebase — Access data offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline) — Official offline docs
- [RevenueCat — Expo integration](https://www.revenuecat.com/docs/getting-started/installation/expo) — Native + web billing setup
- [RevenueCat — Cross-platform subscriptions](https://www.revenuecat.com/blog/engineering/cross-platform-subscriptions-ios-android-web/) — Unified entitlements architecture
- [Expo — App folder structure best practices](https://expo.dev/blog/expo-app-folder-structure-best-practices) — Recommended structure
- [Firestore offline persistence issue — Firebase JS SDK #436](https://github.com/firebase/firebase-js-sdk/issues/436) — Confirms JS SDK limitation in RN
- [Firestore Offline Gotchas — Roberto Hernandez](https://betterprogramming.pub/a-few-gotchas-to-consider-when-working-with-firestores-offline-mode-and-react-native-42al) — Practical pitfalls
- [SystemsArchitect — Firestore conflict resolution](https://www.systemsarchitect.io/services/google-firestore/solutions/pt/google-firestore-solutions-problem-handling-offline-data-synchronization-conf) — Last-write-wins and CRDT patterns

---
*Architecture research for: React Native + Expo + Firebase cross-platform fitness app (Sundee Fundee)*
*Researched: 2026-03-14*
