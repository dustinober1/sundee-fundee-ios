# Domain Pitfalls

**Domain:** Offline-First Workout Tracking — PWA + Rebrand Milestone
**Researched:** 2026-07-14
**Scope:** Adding PWA to existing Next.js 16 App Router app with Dexie.js v4, Supabase auth, and Playwright E2E tests

---

## Critical Pitfalls

Mistakes that cause test failures, data loss, or production regressions.

---

### PITFALL-C1: Serwist Doesn't Support Turbopack — Dev Server Silently Fails

**What goes wrong:** `next dev` in Next.js 16 defaults to Turbopack. `@serwist/next` is webpack-only. Running the dev server without `--webpack` means the service worker is never compiled and never registered, but no error is thrown — you just have a PWA that silently doesn't work in development.

**Why it happens:** `@serwist/next` injects itself into webpack's compilation pipeline. When Turbopack is the bundler, the plugin's hooks never fire. The warning printed to the console is easy to miss.

**Confirmed in source:** The `@serwist/next` v9.5.x source (`packages/next/src/index.ts`) reads `process.env.TURBOPACK` and emits a warning but **does not throw**. The official example's `package.json` uses `"dev": "next dev --webpack"` explicitly.

**Consequences:** You write the PWA, it appears to work in production, but you can't test it locally. Bugs in service worker logic stay hidden until production deployment.

**Prevention:**
```json
// package.json — always use --webpack for dev and build
"scripts": {
  "dev": "next dev --webpack",
  "build": "next build --webpack",
  "start": "next start"
}
```
Add a CI check: if `TURBOPACK` env var is set and serwist is not disabled, fail the build.

**Alternatively:** Set `disable: process.env.NODE_ENV !== 'production'` in `withSerwistInit()` and keep using Turbopack for dev. But then you never test the service worker locally — accept that tradeoff consciously.

**Detection warning sign:** Running `next dev` (no `--webpack`) and seeing "[@serwist/next] WARNING: You are using '@serwist/next' with `next dev --turbopack`" in the console.

**Phase:** PWA Foundation

---

### PITFALL-C2: Playwright Tests Break When Service Worker Is Active

**What goes wrong:** `BrowserContext.route()` does **not** intercept requests that pass through a registered service worker. This is a documented Playwright limitation (see: https://github.com/microsoft/playwright/issues/1090).

**Why it matters for this app:** The existing sync tests (`sync-verification.spec.ts`) currently work because they inject fake Supabase env vars at the server level. But if any future test uses `page.route()` to mock API calls, and the service worker has cached or is routing those requests, the mocks will be silently bypassed.

**Also:** The service worker registers immediately and begins intercepting navigation fetches. If a Playwright test checks redirect behavior or response headers on a navigation, the cached SW response may differ from the live server response.

**Consequences:** Tests pass locally (first run, SW not yet installed) but intermittently fail on subsequent runs once the SW is cached. CI with a clean browser context will pass; developer machine with a warm cache will fail.

**Prevention — add `serviceWorkers: 'block'` to `playwright.config.ts`:**
```typescript
// playwright.config.ts
use: {
  baseURL: 'http://localhost:3000',
  trace: 'on-first-retry',
  serviceWorkers: 'block',  // ADD THIS — prevents SW from intercepting test requests
},
```
This tells Playwright's Chromium to block all service worker registration for the test context. The service worker code will still build and be served; it just won't activate during tests.

**Detection warning sign:** Tests that rely on a specific response body/header pass on first run but intermittently fail on second run in the same browser context.

**Phase:** PWA Foundation (must fix before or alongside SW registration)

---

### PITFALL-C3: Supabase Middleware Intercepts `/sw.js` and `/workbox-*.js`

**What goes wrong:** The current `middleware.ts` matcher `'/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'` **does match** `/sw.js` and `/manifest.json`. This is verified:

```
/sw.js       → matched (true)  ← PROBLEM
/manifest.json → matched (true) ← PROBLEM
/_next/static/foo.js → not matched (correct)
```

The middleware calls `supabase.auth.getUser()` on every matched request. This means:
1. Every service worker update check (which happens on every page load in the background) makes an unnecessary Supabase auth call
2. In test environments with `NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321` (fake), the auth call to a non-running local Supabase adds latency or error noise to SW fetch events
3. Workbox generates multiple chunk files (`workbox-*.js`) — all caught by the middleware

**Consequences:** Slower SW registration/update checks. Supabase auth errors logged for static assets in test mode.

**Prevention — update middleware matcher to exclude service worker and manifest files:**
```typescript
// middleware.ts
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|sw\\.js|workbox-.*\\.js|manifest\\.json|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
```

**Phase:** PWA Foundation

---

### PITFALL-C4: `skipWaiting + clientsClaim` Can Interrupt In-Flight Dexie Transactions

**What goes wrong:** The standard serwist service worker template uses `skipWaiting: true` and `clientsClaim: true`. This causes a new service worker to activate immediately without waiting for existing tabs to close. When the SW activates, all existing browser clients are claimed, which can force a page refresh or emit a `controllerchange` event mid-operation.

Dexie v4 listens for the IndexedDB `versionchange` event and closes the database gracefully, but an in-flight `bulkPut()` or `transaction()` can still be aborted if the IDB connection is disrupted by the version change notification.

**Most dangerous scenario:** User is mid-workout, filling in sets (which trigger `db.completedSets.add()` calls). The SW updates in the background, `skipWaiting` fires, `clientsClaim` takes over, the page is force-navigated. Workout data for the current session is lost.

**Prevention:**
1. Keep `skipWaiting: true` (for security — ensures new SW takes over quickly), BUT handle the `controllerchange` event in the app to warn the user before refreshing:
```typescript
// In a client component, add SW update handling
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    // Only auto-reload if user is NOT in an active workout
    if (!isWorkoutInProgress) {
      window.location.reload();
    }
    // Otherwise: show "Update available — reload when done" banner
  });
}
```
2. Do NOT disable `skipWaiting` — this leads to zombied service workers and worse problems.

**Detection warning sign:** User reports that workout data occasionally disappears or that the app unexpectedly reloads during a workout.

**Phase:** PWA Foundation — address in the SW registration component

---

### PITFALL-C5: Dexie Database Named `StrengthApp` — Never Rename It

**What goes wrong:** The Dexie database is constructed with `super('StrengthApp')` in `src/lib/db/dexie.ts`. This name is the IndexedDB database name stored in the browser. If a future rebrand leads anyone to change this string (e.g., to `SundeeFundeeApp` or whatever the new brand name is), every existing user's data becomes inaccessible — the old database is orphaned and the new name starts fresh.

**Why it happens:** Developers see `new StrengthDatabase()` and a class called `StrengthDatabase` with `super('StrengthApp')` and assume the string is just a label to update as part of a rebrand.

**Consequences:** All existing user workout history, cycles, PRs, and settings are silently lost. The app opens fresh as if new. No error is thrown.

**Prevention:**
- Add a comment block to `dexie.ts` immediately:
```typescript
constructor() {
  // ⚠️ DATABASE NAME IS PERMANENT — DO NOT CHANGE THIS STRING.
  // Changing 'StrengthApp' would orphan all existing user data
  // in IndexedDB. The brand name in the UI is separate from the DB name.
  super('StrengthApp');
```
- The rebrand only touches UI strings (metadata, manifest, component text). The DB name is an implementation detail, not a brand asset.

**Phase:** Rebrand — mark as explicitly out-of-scope on day one

---

## Moderate Pitfalls

Issues that cause user-facing problems or integration headaches, but are recoverable.

---

### PITFALL-M1: Navigation Caching Bypasses Supabase Session Refresh

**What goes wrong:** With `cacheOnNavigation: true` (the serwist option that caches full page responses), subsequent navigations are served from the SW cache. The Next.js middleware — which refreshes the Supabase auth session cookie — never runs for cached responses. After a few hours, the session cookie becomes stale.

**Why it matters:** The app uses Supabase for sync. A stale session means `supabase.auth.getUser()` returns `null`, silently disabling sync without telling the user they need to re-authenticate.

**Prevention:** 
- Use `cacheOnNavigation: false` (the default). Let navigations always hit the server so middleware can refresh tokens.
- Only cache static assets (JS, CSS, images, fonts) via runtime caching.
- The `defaultCache` from `@serwist/next/worker` handles App Router's RSC requests correctly but doesn't override this behavior — you must not enable `cacheOnNavigation` for an app with server-side auth.

**Detection warning sign:** Users report "not syncing" after leaving the app open for a few hours and returning.

**Phase:** PWA Foundation

---

### PITFALL-M2: iOS Has No `beforeinstallprompt` — The Install Banner Never Appears

**What goes wrong:** Android Chrome shows a native "Add to Home Screen" install prompt that can be triggered programmatically via the `beforeinstallprompt` event. iOS Safari **never** fires this event. On iOS, users can only install via the Share sheet → "Add to Home Screen" — there's no programmatic install trigger.

**Why it matters:** If the plan includes a "Install App" button or banner, it will work on Android but do nothing on iOS. Building it generically without detecting the platform wastes effort and produces broken UI on iOS.

**iOS-specific requirements for the PWA to be installable:**
- `<link rel="apple-touch-icon" href="/icons/apple-touch-icon.png">` in `<head>` (not just in manifest.json)
- The icon must be exactly 180×180px
- `<meta name="apple-mobile-web-app-capable" content="yes">` (older iOS) / `apple-web-app` metadata in Next.js layout
- `<meta name="apple-mobile-web-app-status-bar-style" content="default">` for status bar appearance

**Prevention:** Build install UI with explicit platform detection:
```typescript
// Android: listen for beforeinstallprompt
// iOS: show a "tap Share then Add to Home Screen" instruction tooltip
// Neither: show nothing
const isIOS = /iphone|ipad|ipod/i.test(navigator.userAgent);
const isInStandaloneMode = window.matchMedia('(display-mode: standalone)').matches;
```

**Phase:** PWA Foundation

---

### PITFALL-M3: Missing Icon Sizes Block Android Install Prompt

**What goes wrong:** Chrome on Android requires at least a **192×192** and a **512×512** icon in `manifest.json` for the PWA to qualify for "Add to Home Screen." Missing either size means no install prompt, no matter how complete the rest of the manifest is.

**Also required for full support:**
- A maskable icon (for adaptive icon support on Android 8+). Use `"purpose": "maskable"` on a separate icon entry — **do not** use `"purpose": "any maskable"` which is deprecated in the spec.
- The maskable icon must have its content within the "safe zone" (center 80% of the canvas). Logo elements that bleed to the edge will be cropped in Android's circular/squircle icon shapes.
- iOS wants `apple-touch-icon` in `<head>` (see PITFALL-M2), not just manifest.json.

**Minimum manifest.json icon set:**
```json
"icons": [
  { "src": "/icons/icon-192x192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
  { "src": "/icons/icon-512x512.png", "sizes": "512x512", "type": "image/png", "purpose": "any" },
  { "src": "/icons/icon-512x512-maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
]
```

**Detection warning sign:** Chrome DevTools → Application → Manifest shows "Installability: No matching service worker detected" or "No icons with sizes '512x512'" error.

**Phase:** PWA Foundation

---

### PITFALL-M4: iOS PWA Storage Isolation — Version-Dependent Behavior

**What goes wrong:** On iOS **before 16.4**, PWA home screen apps share their storage with Safari (same origin). On iOS **16.4+**, PWA home screen apps get dedicated isolated storage. This means:

- Pre-16.4: user's Safari browsing data and the PWA's IndexedDB are in the same origin. Safari's aggressive storage eviction policy could purge Dexie data if the origin hasn't been accessed in >7 days.
- 16.4+: the PWA's storage is separate and won't be evicted by Safari's policy. BUT: it's also a separate IDB from Safari, so signing in via Safari doesn't carry over to the PWA instance.

**For this app:** Supabase auth sessions stored in cookies/localStorage are also separated. A user who authenticates in Safari and then opens the PWA from Home Screen (iOS 16.4+) will appear signed out in the PWA.

**Prevention:**
- Use `navigator.storage.persist()` to request persistent storage. On iOS 16.4+ PWA, this is granted automatically.
- Document this behavior in onboarding: "For the best experience, sign in from the installed app."
- Do not assume the user's Supabase session transfers from browser to PWA on iOS.

**Phase:** PWA Foundation

---

### PITFALL-M5: iOS Splash Screens Are Device-Specific Static Images

**What goes wrong:** iOS uses static PNG splash screens for the PWA launch screen (the brief full-screen image while the app loads). These must be pre-generated for every device resolution. Unlike Android (which generates the splash screen from the manifest's `background_color` and `icons`), iOS has no automatic splash screen generation.

**Required approach:** Generate PNG splash screens for all target device sizes (iPhone SE, iPhone 14/15, iPhone 14/15 Plus, iPhone 14/15 Pro, iPhone 14/15 Pro Max, iPad, etc.) and reference them with `<link rel="apple-touch-startup-image">` with `media` queries.

**Without splash screens:** Users see a white flash before the app renders. Not a functional problem, but looks unpolished for a fitness app that's being rebranded.

**Prevention:** Use a tool like `pwa-asset-generator` to generate splash screens from a single source image:
```bash
npx pwa-asset-generator ./public/icons/icon-512x512.png ./public/icons \
  --manifest ./public/manifest.json \
  --index ./src/app/layout.tsx \
  --splash-only
```

**Phase:** Rebrand — after final brand assets are settled

---

### PITFALL-M6: Rebrand Strings Are Scattered Across Multiple Files

**What goes wrong:** The current brand name "Strength" appears in at minimum:
- `src/app/layout.tsx` → `metadata.title = "Strength - Workout Tracker"` and `metadata.description`
- `package.json` → `"name": "strength"` (this is the npm package name, low impact)
- The Dexie class `StrengthDatabase` and `StrengthApp` DB name (do NOT change these — see PITFALL-C5)
- Any `<title>` or hardcoded text in components found via `grep -r "Strength" src/`
- `public/manifest.json` → `"name"` and `"short_name"` (once created)
- OG images if they exist
- Email templates (if any)

**Prevention:** Before starting the rebrand, run an audit:
```bash
grep -r "Strength\|strength" src/ --include="*.tsx" --include="*.ts" \
  --exclude-dir=node_modules | grep -v "StrengthApp\|StrengthDatabase"
```
Create a single `src/lib/constants/brand.ts` file with `APP_NAME`, `APP_DESCRIPTION`, `APP_TAGLINE` constants. Import everywhere instead of hardcoding strings.

**Phase:** Rebrand

---

## Minor Pitfalls

Annoyances and polish issues that are fixable but easy to miss.

---

### PITFALL-N1: Missing `viewport-fit=cover` Breaks Safe Area on iPhone X+

**What goes wrong:** The current layout does not set `viewport-fit=cover`. On iPhones with a notch or Dynamic Island, content can be clipped or there's an ugly white bar in standalone mode.

**Prevention:**
```typescript
// src/app/layout.tsx
export const viewport: Viewport = {
  themeColor: '#[brand-color]',
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover',  // Required for iPhone notch
};
```
Then use CSS `env(safe-area-inset-*)` for bottom navigation padding (the `BottomNavigation` component especially needs this — iPhone home indicator overlaps fixed bottom content).

**Phase:** PWA Foundation

---

### PITFALL-N2: `theme-color` Meta Tag Is Not Set

**What goes wrong:** The current `layout.tsx` metadata doesn't include `themeColor`. On Android Chrome, the browser toolbar stays its default color instead of matching the app brand color. In standalone PWA mode, this is more jarring since the status bar will be the wrong color.

**Prevention:** Add `themeColor` to the viewport export in `layout.tsx`:
```typescript
export const viewport: Viewport = {
  themeColor: '#[brand-primary-color]',
};
```
Also set `background_color` and `theme_color` in `manifest.json` to match.

**Phase:** Rebrand

---

### PITFALL-N3: Workbox Cache Size Grows Unbounded Without Limits

**What goes wrong:** A fitness tracker generates many unique URLs (`/workout/back-squat-complete-cycle`, `/workout/bench-press-cycle`, etc.). Without explicit `maxEntries` limits in `runtimeCaching`, the Workbox cache can grow large over time, especially if the user visits many different workout pages.

**Prevention:** Set `maxEntries` and `maxAgeSeconds` on all runtime cache entries:
```typescript
// In sw.ts runtimeCaching config
{
  matcher: /^https:\/\/your-domain\.com\/workout\/.*/,
  handler: 'NetworkFirst',
  options: {
    cacheName: 'workout-pages',
    expiration: {
      maxEntries: 50,
      maxAgeSeconds: 60 * 60 * 24 * 7, // 1 week
    },
  },
},
```

**Phase:** PWA Foundation

---

### PITFALL-N4: `manifest.json` `start_url` Must Match App's Base Path

**What goes wrong:** If `start_url` in `manifest.json` is set to `/` but Vercel or Next.js is deployed with a base path, the installed PWA will open to a 404 or the wrong page.

**Also:** `start_url` should include a query param like `?source=pwa` so analytics can differentiate PWA installs from browser visits (common pattern, optional).

**Prevention:** Set `start_url: '/'` (since this app has no base path) and `scope: '/'`. If a base path is ever added, update both fields.

**Phase:** PWA Foundation

---

### PITFALL-N5: OG Image and Favicon Still Reference Old Brand

**What goes wrong:** The current `public/` directory only has the default Next.js static files (globe.svg, vercel.svg, next.svg). There's no `og-image.png`, `favicon.ico`, or `apple-touch-icon.png` with the new brand. After rebrand, sharing the app link will show either a default/missing preview or the old brand.

**Audit checklist for rebrand:**
- `public/favicon.ico` — browser tab icon
- `public/icons/apple-touch-icon.png` (180×180) — iOS home screen
- `public/icons/icon-192x192.png` — Android home screen
- `public/icons/icon-512x512.png` — Android splash
- `public/icons/icon-512x512-maskable.png` — Android adaptive icon
- `public/og-image.png` (1200×630) — social share preview
- `src/app/layout.tsx` `metadata.openGraph.images` — OG image URL
- `public/manifest.json` → `name`, `short_name`, `background_color`, `theme_color`

**Phase:** Rebrand

---

## Phase-Specific Warnings

| Phase | Topic | Likely Pitfall | Required Action |
|-------|-------|---------------|-----------------|
| PWA Foundation | Dev server setup | PITFALL-C1: Turbopack breaks SW compilation | Add `--webpack` to dev/build scripts |
| PWA Foundation | Playwright tests | PITFALL-C2: SW intercepts test routes | Add `serviceWorkers: 'block'` to `playwright.config.ts` |
| PWA Foundation | Middleware | PITFALL-C3: SW/manifest caught by auth middleware | Update matcher to exclude `sw.js`, `workbox-*.js`, `manifest.json` |
| PWA Foundation | SW activation | PITFALL-C4: `skipWaiting` disrupts Dexie transactions | Handle `controllerchange` event, defer reload during active workout |
| PWA Foundation | Auth session | PITFALL-M1: Navigation caching bypasses session refresh | Keep `cacheOnNavigation: false` |
| PWA Foundation | Install prompt | PITFALL-M2: iOS has no install API | Build install banner with platform detection |
| PWA Foundation | Icon requirements | PITFALL-M3: Missing sizes block Android install prompt | Generate 192, 512, 512-maskable icons |
| PWA Foundation | iOS storage | PITFALL-M4: Storage isolated from Safari on iOS 16.4+ | Document auth flow for PWA vs browser |
| PWA Foundation | Layout | PITFALL-N1: Missing `viewport-fit=cover` | Add to viewport metadata, add safe-area padding to BottomNavigation |
| Rebrand | DB naming | PITFALL-C5: Renaming Dexie DB destroys user data | Comment the DB name as immutable, explicitly exclude from rebrand scope |
| Rebrand | String audit | PITFALL-M6: Brand strings scattered across codebase | Run grep audit, create `brand.ts` constants file |
| Rebrand | Assets | PITFALL-N5: Icons/OG images still reference old brand | Regenerate all icon sizes from new brand assets |
| Rebrand | Splash screens | PITFALL-M5: iOS splash screens need per-device PNGs | Use `pwa-asset-generator` after final assets are settled |

---

## Sources

| Finding | Source | Confidence |
|---------|--------|------------|
| Turbopack incompatibility with `@serwist/next` | `@serwist/next` v9.5.x source (`packages/next/src/index.ts`) — reads `process.env.TURBOPACK` and emits warning | HIGH |
| Official example uses `--webpack` flag | `examples/next-basic/package.json` in serwist repo (Next.js 16.1.6) | HIGH |
| Playwright `serviceWorkers: 'block'` option | Playwright API docs (`BrowserContext.newContext` options) — confirmed `"allow" \| "block"` | HIGH |
| Playwright route() doesn't intercept SW requests | Playwright docs note + GitHub issue #1090 | HIGH |
| `/sw.js` matched by current middleware | Verified via Node.js regex test against current `middleware.ts` matcher | HIGH (verified in code) |
| Dexie DB name is `StrengthApp` | `src/lib/db/dexie.ts` line 31: `super('StrengthApp')` | HIGH (verified in code) |
| iOS no `beforeinstallprompt` | Known platform limitation, confirmed in MDN and Apple docs | HIGH |
| iOS 16.4+ PWA storage isolation | Documented in WebKit release notes for Safari 16.4 (March 2023) | MEDIUM |
| Chrome requires 192+512 icons for install prompt | Chrome PWA criteria, verified in DevTools installability checker | HIGH |
| `cacheOnNavigation` and session refresh risk | Derived from serwist source + Next.js middleware behavior | MEDIUM |
