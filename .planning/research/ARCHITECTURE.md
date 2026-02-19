# Architecture Patterns: PWA + Rebrand Integration

**Project:** Sundee-Fundee (rebrand from Strength)
**Milestone:** PWA + Rebrand
**Researched:** 2025-07-14
**Confidence:** HIGH

---

## 1. PWA Manifest Placement in Next.js App Router

### The answer: `src/app/manifest.ts` (NOT `public/manifest.json`)

Next.js 16 App Router supports file-based metadata conventions. A file at `app/manifest.ts` exports a function returning a `MetadataRoute.Manifest` object. Next.js compiles it into a route at `/manifest.webmanifest` served with the correct `Content-Type` header.

**Source:** [Next.js 16.1.6 official docs — manifest.json file convention](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/manifest) — confirmed current

```ts
// src/app/manifest.ts
import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Sundee-Fundee',
    short_name: 'Sundee-Fundee',
    description: 'Track your workouts and build strength',
    start_url: '/dashboard',
    display: 'standalone',
    orientation: 'portrait',
    background_color: '#000000',
    theme_color: '#000000',
    icons: [
      { src: '/icons/icon-192x192.png', sizes: '192x192', type: 'image/png', purpose: 'maskable' },
      { src: '/icons/icon-512x512.png', sizes: '512x512', type: 'image/png' },
    ],
  };
}
```

**Why not `public/manifest.json`?**
- Static `public/manifest.json` works but is the Pages Router pattern. App Router has `app/manifest.ts` as the canonical approach.
- Both `@ducanh2912/next-pwa` and `@serwist/next` explicitly document `app/manifest.json` / `app/manifest.ts` as the App Router path.
- TypeScript file allows dynamic values, consistent with the rest of the App Router conventions.

---

## 2. Service Worker Placement and Registration

### Recommended library: `@serwist/next` v9.5.6

**Why @serwist/next over alternatives:**
- Actively maintained (latest: 9.5.6 as of July 2025)
- Purpose-built for Next.js App Router (peer deps: `next >= 14.0.0`)
- Service worker source at `app/sw.ts` (compiled to `public/sw.js`)
- Workbox-powered with sensible defaults via `defaultCache`
- TypeScript-first; types ship with the package

**Why not `next-pwa` 5.6.0 (original):**
- Last updated 2022 — pre-App Router era
- No peer dependency validation for Next.js 14+
- No active maintenance

**`@ducanh2912/next-pwa` 10.2.9** is also valid and maintained (peer: `next >= 14.0.0`). Simpler config, slightly less App Router documentation. Either works; this guide uses `@serwist/next`.

### File layout after PWA addition

```
src/app/
  sw.ts               ← SW source (compiled to public/sw.js at build)
  manifest.ts         ← Web app manifest (App Router file convention)
  offline/
    page.tsx          ← Minimal offline fallback page

public/
  sw.js               ← Compiled output (gitignored)
  workbox-*.js        ← Workbox runtime (gitignored)
  icons/
    icon-192x192.png  ← Required for PWA installability
    icon-512x512.png  ← Required for PWA installability
    apple-touch-icon.png  ← iOS home screen (180×180px)
```

### `next.config.ts` changes

```ts
// next.config.ts
import withSerwistInit from '@serwist/next';

const withSerwist = withSerwistInit({
  swSrc: 'app/sw.ts',
  swDest: 'public/sw.js',
});

const nextConfig = {
  // existing config (currently empty)
};

export default withSerwist(nextConfig);
```

### Service worker registration

Serwist auto-injects a registration script — no manual `navigator.serviceWorker.register()` call needed in `layout.tsx`. The `register: true` default handles it.

### `.gitignore` additions needed

```
# Serwist generated
public/sw.js
public/sw.js.map
public/swe-worker*.js
public/workbox-*.js
```

---

## 3. Service Worker Caching Strategy

### Critical principle: IndexedDB lives completely outside the service worker's cache

Dexie.js reads/writes IndexedDB directly in the browser's storage layer. Service workers intercept **network fetch events** only — they have no effect on IndexedDB read/write operations. This means:

- **Dexie.js data is safe** — the SW cannot corrupt or interfere with the `StrengthApp` IndexedDB database
- **No special SW config needed for Dexie** — the two systems are architecturally independent
- **The offline-first architecture is already working** — PWA adds installability + app shell caching on top

### What to cache

| Asset type | Strategy | Rationale |
|------------|----------|-----------|
| Next.js JS/CSS chunks (`/_next/static/`) | `StaleWhileRevalidate` | Fast loads; update in background |
| Static images (`/icons/`, `/public/*.svg`) | `CacheFirst` (30-day TTL) | Never change between deploys |
| Google Fonts (Geist) | `CacheFirst` | External, changes rarely |
| App shell HTML frames | `NetworkFirst` with offline fallback | Ensures navigation works offline |
| Static program JSON | Already bundled in JS chunks | No separate cache entry needed |

### What NOT to cache

| Asset type | Why not |
|------------|---------|
| Supabase API calls (`*.supabase.co`) | Auth-sensitive; stale data is dangerous |
| Auth routes (`/auth/*`) | Must never serve stale auth responses |
| IndexedDB data | Already local; SW can't cache it anyway |
| Service worker itself (`/sw.js`) | Browsers bypass SW for SW fetches |

### Minimal `app/sw.ts` for this app

```ts
// app/sw.ts
import { defaultCache } from '@serwist/next/worker';
import type { PrecacheEntry, SerwistGlobalConfig } from 'serwist';
import { Serwist } from 'serwist';

declare global {
  interface WorkerGlobalScope extends SerwistGlobalConfig {
    __SW_MANIFEST: (PrecacheEntry | string)[] | undefined;
  }
}
declare const self: ServiceWorkerGlobalScope;

const serwist = new Serwist({
  precacheEntries: self.__SW_MANIFEST,
  skipWaiting: true,
  clientsClaim: true,
  navigationPreload: true,
  runtimeCaching: defaultCache,  // pre-configured for /_next/static/**, fonts, images
  fallbacks: {
    entries: [
      {
        url: '/offline',  // served when navigation fails offline
        matcher({ request }) {
          return request.destination === 'document';
        },
      },
    ],
  },
});

serwist.addEventListeners();
```

`defaultCache` from `@serwist/next/worker` handles Next.js static assets, fonts, and images with sensible strategies. No manual Workbox route configuration needed.

---

## 4. Middleware Compatibility

The existing `middleware.ts` matcher pattern:

```ts
// Current — needs updating
matcher: [
  '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
]
```

**Problem:** `/sw.js` and `/workbox-*.js` pass through the Supabase auth middleware unnecessarily. The middleware calls `supabase.auth.getUser()` and adds cookie overhead for SW fetches.

**Fix — add `sw.js` and `workbox-` to exclusion pattern:**

```ts
// middleware.ts — updated matcher
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|sw\\.js|workbox-.*|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
```

This is a minor optimization — the middleware already has a no-op guard when Supabase env vars are missing, so it won't break anything either way. But excluding SW files is clean practice.

---

## 5. Rebrand File Inventory

### Rule: "Strength" as app brand = change. "strength" as fitness domain = keep.

The word "strength" appears in two distinct contexts in this codebase:
1. **App brand name** → "Strength" (the product name) — must change to "Sundee-Fundee"
2. **Domain terminology** → "strength training", "build strength", goal value `'strength'` — keep as-is

### Files requiring brand name changes (user-visible text)

| File | Line(s) | Current | Change to |
|------|---------|---------|-----------|
| `src/app/layout.tsx` | 18–19 | `title: "Strength - Workout Tracker"` | `title: "Sundee-Fundee"` |
| `src/components/onboarding/onboarding-wizard.tsx` | 60 | `'Welcome to Strength'` | `'Welcome to Sundee-Fundee'` |
| `README.md` | 1 | `# Strength - Workout Tracking App` | `# Sundee-Fundee - Workout Tracking App` |
| `package.json` | 2 | `"name": "strength"` | `"name": "sundee-fundee"` |
| `package-lock.json` | 2, 8 | `"name": "strength"` | `"name": "sundee-fundee"` |
| `CLAUDE.md` | 7 | `**Strength** is a mobile-first...` | `**Sundee-Fundee** is a mobile-first...` |

### Files requiring brand name changes (developer/planning docs)

| File | What to update |
|------|---------------|
| `.planning/PROJECT.md` | App name in title and description |
| `.planning/ROADMAP.md` | App name in title |
| `.planning/STATE.md` | App name in core value statement |
| `.planning/MILESTONES.md` | App name references |
| `.planning/research/SUMMARY.md` | App name in title |
| `.github/copilot-instructions.md` | App name in title and description |

### Files intentionally NOT changing

| File | Content | Why keep |
|------|---------|----------|
| `src/lib/db/dexie.ts:31` | `super('StrengthApp')` | **CRITICAL: IndexedDB database name — see §6** |
| `src/lib/db/dexie.ts:14` | `class StrengthDatabase` | Internal class — can cosmetically rename to `AppDatabase` but zero user impact |
| `src/types/user.ts:2` | `'strength'` in `PrimaryGoal` union | Workout goal value, not app brand. Changing breaks Dexie data. |
| `src/types/cycle.ts:75` | `PhaseStrengthProfile` | Internal TypeScript type for strength-phase analysis |
| `src/lib/cycle-calculations.ts` | `analyzeStrengthPatterns`, `predictStrengthWindow` | Domain function names |
| `src/components/onboarding/onboarding-wizard.tsx:115` | `<SelectItem value="strength">Build Strength</SelectItem>` | User's workout goal choice, not brand name |
| All test files with `'StrengthApp'` IDB name | E2E tests: `indexedDB.open('StrengthApp')` | Must match actual IDB name or tests break |
| Program JSON files | "strength" in descriptions | Fitness content, not brand |

---

## 6. Critical: IndexedDB Database Name

**Do NOT change `super('StrengthApp')` in `src/lib/db/dexie.ts`.**

The IndexedDB database is named `'StrengthApp'`. If this string changes (even to `'SundeeFundee'`):
- The browser treats it as a **new, empty database**
- All existing user workout data, 1RMs, cycles, and progress is **silently orphaned** (still exists in the old DB name but the app no longer opens it)
- Users who already have data effectively lose everything on their next visit

### Decision for this milestone

**Keep `'StrengthApp'` as the IDB name.** The database name is an internal implementation detail — users never see it. The class can be cosmetically renamed to `AppDatabase` without any data impact:

```ts
// Safe: class rename only affects TypeScript, not the browser IDB
export class AppDatabase extends Dexie {
  // ...
  constructor() {
    super('StrengthApp'); // ← this string MUST stay 'StrengthApp'
  }
}
export const db = new AppDatabase();
```

E2E tests that reference `indexedDB.open('StrengthApp')` must also stay unchanged.

---

## 7. New Files vs. Modified Files

### New files to create

| File | Purpose |
|------|---------|
| `src/app/manifest.ts` | Web app manifest (App Router file convention) |
| `src/app/sw.ts` | Service worker source → compiled to `public/sw.js` |
| `src/app/offline/page.tsx` | Minimal offline fallback shown when navigation fails |
| `public/icons/icon-192x192.png` | PWA icon (required for install prompt) |
| `public/icons/icon-512x512.png` | PWA icon large (required for install prompt) |
| `public/icons/apple-touch-icon.png` | iOS home screen icon (180×180px) |

### Files to modify

| File | Change |
|------|--------|
| `next.config.ts` | Add `withSerwist` wrapper |
| `src/app/layout.tsx` | Update metadata: title, description, manifest, appleWebApp, viewport export |
| `middleware.ts` | Add `sw\\.js\|workbox-.*` to matcher exclusions |
| `tsconfig.json` | Add `"@serwist/next/typings"` to `types`, `"webworker"` to `lib`, add `public/sw.js` to `exclude` |
| `.gitignore` | Add `public/sw.js*`, `public/workbox-*.js`, `public/swe-worker*.js` |
| `package.json` | Add `@serwist/next`; add `serwist` to devDependencies; rename `"name"` to `"sundee-fundee"` |
| `README.md` | App name rebrand |
| `CLAUDE.md` | App name rebrand |
| `src/components/onboarding/onboarding-wizard.tsx` | "Welcome to Strength" → "Welcome to Sundee-Fundee" |

---

## 8. `layout.tsx` Metadata Update

The current metadata block is minimal. Full PWA + rebrand version:

```ts
// src/app/layout.tsx
import type { Metadata, Viewport } from "next";

const APP_NAME = "Sundee-Fundee";
const APP_TITLE = "Sundee-Fundee — Workout Tracker";
const APP_DESCRIPTION = "Track your workouts and build strength with Sundee-Fundee.";

export const metadata: Metadata = {
  applicationName: APP_NAME,
  title: {
    default: APP_TITLE,
    template: `%s — ${APP_NAME}`,
  },
  description: APP_DESCRIPTION,
  manifest: "/manifest.webmanifest",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: APP_TITLE,
  },
  formatDetection: {
    telephone: false,
  },
};

// themeColor goes in viewport export (not metadata) in Next.js 14+
export const viewport: Viewport = {
  themeColor: "#000000",
};
```

**Note:** `themeColor` moved to `viewport` export (not `metadata`) in Next.js 14. Using `metadata.themeColor` triggers a deprecation warning in Next.js 16.

---

## 9. Build Order Recommendation

**Phase order: Rebrand → Icons/Manifest → Service Worker**

### Phase 1: Rebrand (text changes only)

Pure text substitutions. No functional risk — app continues to work identically after these changes.

Tasks:
- `package.json` name
- `layout.tsx` metadata title/description  
- `onboarding-wizard.tsx` welcome text
- `README.md`, `CLAUDE.md`, `.planning/` docs

Validates: App still runs, metadata shows new name in browser tab.

### Phase 2: Icons + Manifest (PWA installability)

Creates the manifest and icon assets. Makes the app installable without full offline caching.

Tasks:
- Design/generate icons (192×192, 512×512, 180×180 apple touch)
- `src/app/manifest.ts`
- Updated `layout.tsx` metadata (manifest link, appleWebApp, viewport)

Validates: Chrome DevTools → Application → Manifest shows correctly. "Add to Home Screen" install prompt appears on mobile.

### Phase 3: Service Worker (offline app shell)

Adds caching layer. Highest complexity and risk of regression.

Tasks:
- Install `@serwist/next`
- `next.config.ts` withSerwist wrapper
- `src/app/sw.ts` service worker source
- `src/app/offline/page.tsx` fallback page
- `tsconfig.json` additions
- `.gitignore` additions
- `middleware.ts` matcher update

Validates: App loads offline (kill network in DevTools → reload). Dexie IndexedDB data still accessible offline (was already true; confirm unchanged). PWA Lighthouse score ≥ 90.

### Why NOT service worker first

If the SW is misconfigured (wrong scope, aggressive caching of JS chunks), it can serve stale app shells that break Dexie's module loading or context providers. Building icons/manifest first verifies PWA basics work, then the SW adds caching knowing the foundation is solid.

---

## 10. No New Components Required

The rebrand and PWA work is **infrastructure and text**, not new UI. No new React component patterns emerge:

1. **`src/app/offline/page.tsx`** — Minimal server component, ~20 lines. No Dexie, no context. Just "You're offline" with a reload button.

2. **Optional post-milestone: `InstallPrompt.tsx`** — A client component listening to `beforeinstallprompt` to show a custom "Add to Home Screen" nudge (similar to existing `sync-nudge.tsx` pattern). Not required for installability; deferred until after core PWA ships.

---

## 11. Existing Architecture Diagram (Updated with PWA layer)

```
┌─────────────────────────────────────────────────────────────┐
│                     UI Layer (React)                        │
│  Dashboard  │  Logger  │  Charts  │  Programs  │  Offline  │
├─────────────────────────────────────────────────────────────┤
│          State Layer (React Context)                        │
│     UserContext / ExerciseContext / RestTimerContext        │
├─────────────────────────────────────────────────────────────┤
│          Data Layer (Dexie.js → IndexedDB)                  │
│  users / oneRepMaxes / activeCycles / completedWorkouts     │
├─────────────────────────────────────────────────────────────┤
│          Sync Layer (Supabase — optional)                   │
│  localStorage offline queue → Supabase on reconnect        │
├─────────────────────────────────────────────────────────────┤
│  ★ NEW: PWA Layer (Service Worker — app shell caching)      │
│  Caches: JS/CSS chunks, static icons, fonts (NOT IDB data) │
│  Does NOT intercept: Supabase calls, auth routes, IndexedDB │
└─────────────────────────────────────────────────────────────┘
```

The PWA layer sits below sync — it caches the app's static assets for fast load and fallback navigation. It is architecturally separate from the Dexie offline-first data layer.

---

## Sources

| Claim | Source | Confidence |
|-------|--------|------------|
| `app/manifest.ts` is the App Router convention | [Next.js 16.1.6 docs — manifest.json](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/manifest) | HIGH |
| `@serwist/next` v9.5.6 setup steps | [serwist.pages.dev/docs/next/getting-started](https://serwist.pages.dev/docs/next/getting-started) | HIGH |
| `@ducanh2912/next-pwa` v10.2.9 peer deps | [npmjs.com/@ducanh2912/next-pwa](https://registry.npmjs.org/@ducanh2912/next-pwa/latest) | HIGH |
| `@serwist/next` v9.5.6 peer deps | [npmjs.com/@serwist/next](https://registry.npmjs.org/@serwist/next/latest) | HIGH |
| SW doesn't interfere with IndexedDB | SW spec: SW only intercepts `fetch` events, not IDB API calls | HIGH |
| Dexie IDB name `'StrengthApp'` | Direct code inspection: `src/lib/db/dexie.ts:31` | HIGH |
| `themeColor` moved to `viewport` export | Next.js 14 migration (confirmed present in Next.js 16.1.6) | MEDIUM |
| Middleware matcher pattern | Direct code inspection: `middleware.ts:38-42` | HIGH |
