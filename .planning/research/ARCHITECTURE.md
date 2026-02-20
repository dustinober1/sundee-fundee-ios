# Architecture Research

**Domain:** Flutter full rewrite of an offline-first workout tracker (web + Android + iOS)
**Researched:** 2026-02-20
**Confidence:** HIGH (architecture patterns), MEDIUM (Firebase framework-specific details), MEDIUM (Supabase offline ecosystem direction)

## Standard Architecture

### System Overview

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                           Presentation Layer                            │
│ Flutter UI (screens/widgets) + Router + Design system                   │
├──────────────────────────────────────────────────────────────────────────┤
│                           Application Layer                             │
│ Feature ViewModels / Controllers + Use Cases                            │
├──────────────────────────────────────────────────────────────────────────┤
│                              Data Layer                                 │
│ Repositories (single source of truth per aggregate)                     │
│   ├─ LocalDataSource (Drift DB)                                         │
│   ├─ RemoteDataSource (Supabase client)                                 │
│   └─ SyncOrchestrator (queue, retry, conflict policy)                   │
├──────────────────────────────────────────────────────────────────────────┤
│                           Platform/Infra Layer                          │
│ Drift engine (sqlite mobile, wasm web) + connectivity/background jobs   │
│ Firebase Hosting (web deploy) + CI/CD                                   │
└──────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| UI + Router | Render parity flows and navigation | Flutter widgets + `go_router` |
| ViewModels | UI state, intents, orchestration | `riverpod`/`Notifier` or equivalent |
| Repositories | Source of truth and boundary | Feature repositories, no repo-to-repo dependency |
| LocalDataSource | Offline persistence + queries | Drift tables + DAOs |
| RemoteDataSource | Supabase auth/data I/O | `supabase_flutter` client wrappers |
| SyncOrchestrator | Push/pull, retries, queue drain, merge strategy | Dedicated service with idempotent operations |
| Background sync adapters | Trigger sync on app resume/network | lifecycle listeners + Workmanager (mobile) |
| Web hosting/deploy | Build + route hosting | Firebase Hosting + rewrite to SPA index |

## Integration Points (Existing → Flutter)

### Behavioral Source-of-Truth (Parity Contract)

Current Next.js app behavior remains authoritative during rewrite. Create a parity contract document and test matrix before implementation:

- Onboarding behavior and persisted profile fields
- Program browsing and cycle start logic
- Workout logging flow (set entry, PR detection, completion)
- Recommendation triggers/rules
- Progress calculations and chart datasets
- Sync UX states (`offline`, `pending`, `syncing`, `synced`, `error`, `disabled`)

### Existing Integration Mapping

| Existing (Next.js) | Flutter Target | Migration Notes |
|---|---|---|
| Dexie schema in `src/lib/db/dexie.ts` | Drift schema + migrations | Keep table semantics and IDs stable for parity |
| React Contexts (`User`, `Exercise`, `RestTimer`, `Cycle`) | Feature-scoped providers/viewmodels | Preserve state transitions, not component structure |
| Sync engine (`src/lib/sync/*`) | SyncOrchestrator service | Keep queue/retry/idempotent upserts as same policy |
| Static program JSON in `src/data/programs/*` | Bundled Flutter assets + typed parser | Reuse exact source files for parity |
| Route set (`/dashboard`, `/programs`, `/workout/:id`, etc.) | `go_router` routes | Keep path/flow parity for web deep links |
| Supabase auth + tables | Supabase client + same backend schema | Avoid backend schema churn in rewrite |

## New vs Modified Components

### New Components (Flutter rewrite)

1. **AppShell + Router layer** (cross-platform Flutter shell)
2. **Drift database module** (DAOs, queries, migrations, transaction policies)
3. **SyncOrchestrator** (explicit queue, retry, conflict policy)
4. **Platform adapters**
   - mobile background sync trigger (Workmanager/foreground resume)
   - web lifecycle + connectivity trigger
5. **Firebase web deployment module**
   - hosting config, rewrites, CI deploy job
6. **Parity test harness**
   - golden behavior tests vs existing app contracts

### Modified/Retained External Systems

1. **Supabase backend:** retained, minimal/no schema change preferred
2. **Program content:** retained (same JSON semantics)
3. **Recommendations logic:** port logic, avoid behavior drift
4. **Chart math:** keep formulas identical; only rendering library changes

## Recommended Project Structure

```text
flutter_app/
├── lib/
│   ├── app/
│   │   ├── router/
│   │   ├── theme/
│   │   └── bootstrap/
│   ├── core/
│   │   ├── db/                 # Drift setup, migrations, adapters
│   │   ├── sync/               # queue, policies, orchestrator
│   │   ├── network/            # connectivity + client wrappers
│   │   └── utils/
│   ├── features/
│   │   ├── onboarding/
│   │   ├── dashboard/
│   │   ├── programs/
│   │   ├── workout/
│   │   ├── progress/
│   │   └── settings_sync/
│   ├── repositories/
│   └── services/
├── assets/
│   └── programs/               # migrated JSON program definitions
├── web/
│   └── (hosting entrypoint files)
└── test/
    ├── unit/
    ├── integration/
    └── e2e/
```

### Structure Rationale

- **Feature-first folders:** keeps parity work trackable by user workflow.
- **Core db/sync separation:** isolates highest-risk migration surface.
- **Repository boundary:** aligns with Flutter architecture guidance for data ownership.

## Data Flow (Offline-First)

### Read Flow (recommended)

```text
UI intent
  → ViewModel
    → Repository (single source)
      → Local DB emit immediately
      → Remote refresh (if online)
      → Upsert local DB
      → UI receives updated stream
```

### Write Flow (recommended for this project)

```text
User logs set/workout
  → ViewModel command
    → Repository writes local DB in transaction (authoritative)
    → enqueue sync job (if not synced yet)
    → SyncOrchestrator push when online
    → mark sync state + timestamps
```

### Sync State Flow

```text
Connectivity/app-resume/auth event
  → SyncOrchestrator
    → drain queue with retry/backoff
    → pull latest cloud snapshot/deltas
    → merge policy (LWW + idempotent upsert where applicable)
    → publish sync status to UI
```

## Storage Architecture Recommendation

### Local Store: Drift

- **Mobile (Android/iOS):** SQLite-backed Drift.
- **Web:** Drift Wasm database with OPFS when available; IndexedDB-based shared fallback where OPFS requirements are not met.
- This gives one DB abstraction across all three targets while preserving local-first behavior.

### Remote/Sync: Supabase (retained)

- Keep Supabase for auth + backup/sync parity.
- Treat `supabase_flutter` as remote transport/auth layer, not offline cache.
- Explicit sync engine remains required (queue + conflict handling), same as current app philosophy.

## Migration Strategy (Low-Risk)

### Phase boundary plan

1. **Phase A — Foundations + parity contracts**
   - Define parity acceptance criteria by workflow.
   - Stand up Flutter app shell, routing, theming, base state pattern.

2. **Phase B — Data core (highest risk first)**
   - Implement Drift schema mirroring current logical model.
   - Implement repository interfaces and local transactions.
   - Port recommendation/progress calculation logic with tests.

3. **Phase C — Sync parity**
   - Implement Supabase auth integration.
   - Implement SyncOrchestrator (queue/retry/pull/push/status states).
   - Verify offline-create/online-drain behavior on all platforms.

4. **Phase D — Feature-by-feature UI parity**
   - Onboarding → Programs/Cycles → Workout logger → Dashboard/Progress.
   - Keep each feature behind parity tests before moving on.

5. **Phase E — Web deploy + release pipeline**
   - Firebase Hosting configuration and deployment automation.
   - SPA routing rewrite and cache strategy validation.

6. **Phase F — Cutover + rollback readiness**
   - Staged rollout, telemetry checks, fallback plan.

### Why this order

- Data/sync foundations are the migration’s failure point; build them before polishing UI.
- Feature porting after stable repositories avoids duplicate rewrites.
- Hosting/deploy is last because it depends on stable app behavior.

## Architectural Patterns to Follow

### Pattern 1: Repository as single source of truth

**What:** UI never calls remote/local services directly.
**When:** Always for feature data.
**Trade-off:** Slight boilerplate; major testability/stability gain.

### Pattern 2: Local-first writes + async sync

**What:** Commit locally first, sync in background.
**When:** Workout logging and session state updates.
**Trade-off:** Requires explicit conflict policies.

### Pattern 3: SyncOrchestrator as dedicated subsystem

**What:** One service owns queue, retries, conflict policy, and status emissions.
**When:** Any app with optional cloud sync.
**Trade-off:** Additional subsystem complexity, but prevents sync logic scattering.

## Anti-Patterns to Avoid

### Anti-Pattern 1: “Supabase SDK equals offline sync” assumption

**What people do:** Treat backend SDK as full local-sync engine.
**Why bad:** Loses deterministic queueing/conflict control and parity with current behavior.
**Do instead:** Keep explicit sync orchestration and local DB authority.

### Anti-Pattern 2: UI-first migration before data parity

**What people do:** Rebuild screens quickly before replicating data semantics.
**Why bad:** Hidden parity regressions discovered late.
**Do instead:** Lock data contracts + tests before broad UI migration.

### Anti-Pattern 3: Web-only architecture leaking into mobile assumptions

**What people do:** Assume browser lifecycle/storage behaviors generalize to iOS/Android.
**Why bad:** Background execution and persistence behavior diverge.
**Do instead:** Use platform adapters behind shared orchestrator interfaces.

## Firebase Hosting (Web) Deployment Architecture

- Build Flutter web artifacts (`build/web`) in CI.
- Deploy with Firebase CLI using framework-aware flow described in Flutter docs.
- Ensure SPA route rewrites to `index.html` so deep links work.
- Keep hosting as delivery layer only; no business logic in hosting config.

## Scalability Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0–1k users | Single Supabase project, client-side sync queue sufficient |
| 1k–100k users | Harden retry/backoff, add telemetry around sync lag/conflicts |
| 100k+ users | Move toward server-assisted delta sync/ops logs and stricter conflict policy |

## Confidence Notes / Open Questions

1. **HIGH:** Flutter official architecture and offline-first repository guidance is clear and current.
2. **HIGH:** Drift web persistence options (OPFS/IndexedDB fallback) and constraints are documented.
3. **MEDIUM:** Firebase framework-aware Flutter hosting page content was partially inaccessible in fetch; deployment workflow corroborated via Flutter official deployment docs.
4. **MEDIUM:** Supabase still requires custom offline sync architecture for this use case; ecosystem partners exist (PowerSync/ElectricSQL), but adopting them would be a scope change vs parity rewrite.

## Sources

- Flutter app architecture guide: https://docs.flutter.dev/app-architecture/guide
- Flutter offline-first pattern: https://docs.flutter.dev/app-architecture/design-patterns/offline-first
- Flutter web deployment guide: https://docs.flutter.dev/deployment/web
- Firebase Hosting for Flutter (official): https://firebase.google.com/docs/hosting/frameworks/flutter
- Drift web platform docs: https://drift.simonbinder.eu/platforms/web/
- Drift WasmDatabase API: https://pub.dev/documentation/drift/latest/wasm/WasmDatabase-class.html
- Drift storage implementations: https://pub.dev/documentation/drift/latest/wasm/WasmStorageImplementation.html
- Supabase Flutter package docs: https://pub.dev/packages/supabase_flutter
- Current project schema reference: `/Users/dustinober/Projects/Sundee-Fundee/src/lib/db/dexie.ts`
- Current project sync reference: `/Users/dustinober/Projects/Sundee-Fundee/src/lib/sync/sync-engine.ts`
- Current project sync queue reference: `/Users/dustinober/Projects/Sundee-Fundee/src/lib/sync/sync-queue.ts`
