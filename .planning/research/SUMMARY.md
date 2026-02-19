# Research Summary — Sundee-Fundee v1.1

**Milestone:** PWA + Rebrand (Strength → Sundee-Fundee) + Lucide Icon Enrichment
**Synthesized:** 2025-07-15
**Research files:** STACK.md · FEATURES.md · ARCHITECTURE.md · PITFALLS.md

---

## Executive Summary

Sundee-Fundee v1.1 adds three tightly-related capabilities to an already-working offline-first fitness tracker: PWA installability (home screen icon, standalone mode, offline fallback), a brand rename from "Strength" to "Sundee-Fundee", and a pass to enrich icon usage across the UI using the already-installed `lucide-react` library. The existing architecture (Next.js 16 App Router + Dexie.js IndexedDB + Supabase sync) is a solid foundation — the PWA layer sits *below* the sync layer and is architecturally independent from Dexie, so the offline-first data story is unchanged.

The single highest-impact technical decision is **which PWA library to use**. Next.js 16 defaults to Turbopack, which means the entire mainstream library ecosystem (`next-pwa`, `@ducanh2912/next-pwa`, `@serwist/next`) is incompatible with `next dev` / `next build` as currently configured. The correct library is **`@serwist/turbopack`** (paired with `serwist` core), which is the only actively-maintained option with explicit Turbopack support and is validated against `next: "16.1.6"` in the official Serwist example repo.

The rebrand carries one non-obvious data-loss trap: the Dexie IndexedDB database is named `'StrengthApp'` and that string **must never change** — changing it silently orphans all existing user data. Everything else in the rebrand is safe text substitution. Plan accordingly: mark the DB name as permanently frozen on day one of the rebrand phase.

---

## Key Findings

### From STACK.md — Technology Additions

| Package | Version | Role | Notes |
|---------|---------|------|-------|
| `@serwist/turbopack` | `^9.5.6` | PWA service worker (Next.js 16 + Turbopack) | **Only valid option for this stack** |
| `serwist` | `^9.5.6` | SW runtime, Workbox integration | Peer of the above |
| `@vite-pwa/assets-generator` | `^1.0.2` | Icon generation (devDep) | One source SVG → full icon set |

**No other packages needed.** The web app manifest uses Next.js 16 App Router's built-in `MetadataRoute.Manifest` (`app/manifest.ts`). Lucide enrichment is code-only — `lucide-react` v0.564.0 is already installed. The rebrand is text changes only.

**Critical version note:** `@serwist/next` (webpack-only) will *appear* to install fine but silently fails in dev and build under Next.js 16's Turbopack default. Use `@serwist/turbopack` exclusively.

---

### From FEATURES.md — What to Build

**Must ship (table stakes — app is not a credible PWA without these):**
- `app/manifest.ts` with `display: standalone`, `theme_color`, `start_url: "/dashboard"`, 192×192 + 512×512 icons
- iOS `<head>` meta tags (`apple-mobile-web-app-capable`, `status-bar-style`, `apple-mobile-web-app-title`)
- Apple touch icons (180×180, 167×167, 152×152) — iOS **ignores** the manifest `icons` array entirely
- Android icons: 192×192 (regular), 192×192 (maskable), 512×512
- Service worker with stale-while-revalidate for app shell; network-only for Supabase + API routes
- Offline fallback page at `/offline` — branded, links to `/dashboard`
- Viewport `viewport-fit=cover` for iPhone notch/Dynamic Island
- Full rebrand: title, manifest name, `apple-mobile-web-app-title`, onboarding welcome text
- Replace `OfflineBanner` inline SVG with `<WifiOff>` from lucide-react (existing inconsistency)

**Ship in v1.1 if effort is low (confirmed low complexity):**
- Android manifest shortcuts ("Log Workout" → `/workout`, "View Progress" → `/progress`)
- iOS install nudge — detect iOS + non-standalone, show "Share → Add to Home Screen" tooltip
- SW update notification toast ("New version available — tap to update")
- Icon enrichment: `Trophy`/`Flame` on progress cards; `BarChart2` for volume; `AlarmClockCheck` for rest timer complete; `CircleCheck`/`CircleX` for set status

**Defer post-v1.1 (explicitly out of scope):**
- Push notifications (iOS 16.4+ only, VAPID backend required)
- Per-device iOS splash screen images (14+ static PNGs, fragile maintenance)
- Background Sync API (iOS doesn't support it; existing foreground queue is sufficient)
- Web Share Target

---

### From ARCHITECTURE.md — Critical Decisions

1. **Manifest location:** `src/app/manifest.ts` (App Router convention) — NOT `public/manifest.json` (Pages Router pattern). Served at `/manifest.webmanifest` with correct MIME type.

2. **SW file layout:**
   ```
   src/app/sw.ts          ← SW source (you write this)
   src/app/offline/       ← Fallback page
   src/app/manifest.ts    ← Manifest
   public/sw.js           ← Compiled output (gitignore this)
   public/icons/          ← Generated icon files
   ```

3. **`next.config.ts` shape** (Turbopack integration — different from webpack-based docs):
   ```ts
   import { withSerwist } from '@serwist/turbopack'
   export default withSerwist(nextConfig)
   ```
   Not `withSerwistInit({ swSrc, swDest })` — that's the webpack pattern.

4. **Supabase caching rule:** Configure all `*.supabase.co` routes as `NetworkOnly` in runtime caching. Dexie handles offline data; the SW must not cache auth-gated Supabase responses.

5. **Middleware update required:** Current matcher catches `/sw.js` and `/workbox-*.js`, routing them through Supabase auth. Add exclusions: `sw\\.js|workbox-.*\\.js|manifest\\.json`.

6. **Build phase order: Rebrand → Icons/Manifest → Service Worker.** SW is highest-risk — build on a verified foundation.

7. **Rebrand scope — what to change vs. what to freeze:**

   | Change | Freeze |
   |--------|--------|
   | `layout.tsx` title/description | `super('StrengthApp')` in `dexie.ts` ← **data loss if changed** |
   | `package.json` name field | `PrimaryGoal` union value `'strength'` (fitness domain term) |
   | `onboarding-wizard.tsx` welcome text | E2E tests referencing `'StrengthApp'` IDB name |
   | `manifest.ts` name/short_name | All domain function names (`analyzeStrengthPatterns`, etc.) |
   | `README.md`, `CLAUDE.md`, `.planning/` docs | `<SelectItem value="strength">Build Strength</SelectItem>` |

8. **`tsconfig.json` additions:** Add `"webworker"` to `lib` array for SW types.

9. **`.gitignore` additions:** `public/sw.js*`, `public/workbox-*.js`, `public/swe-worker*.js`.

---

### From PITFALLS.md — Top Pitfalls (Ordered by Severity)

| # | Pitfall | Phase | Impact | Fix |
|---|---------|-------|--------|-----|
| C1 | **`@serwist/next` is webpack-only — SW silently absent under Turbopack** | PWA | Silent failure in dev + prod | Use `@serwist/turbopack`; do not use `@serwist/next` |
| C2 | **Playwright tests break when SW is active** | PWA | Intermittent CI failures | Add `serviceWorkers: 'block'` to `playwright.config.ts` immediately |
| C3 | **Middleware intercepts `/sw.js` + `/workbox-*.js`** | PWA | Auth overhead on every SW update check | Update matcher exclusion pattern |
| C4 | **`skipWaiting + clientsClaim` can abort in-flight Dexie transactions** | PWA | Mid-workout data loss | Handle `controllerchange` event; defer reload when workout is in progress |
| C5 | **Renaming `'StrengthApp'` IDB name orphans all user data** | Rebrand | Complete data loss for existing users | Comment the line as immutable; exclude from rebrand scope |
| M1 | **`cacheOnNavigation: true` bypasses Supabase session refresh** | PWA | Silent sync failures after hours | Keep `cacheOnNavigation: false` (default) |
| M2 | **iOS has no `beforeinstallprompt`** | PWA | Install UI broken on iOS | Platform-detect; show "Share → Add to Home Screen" tooltip on iOS |
| M3 | **Missing 192×192 + 512×512 icons blocks Android install prompt** | PWA | App not installable on Android | Generate both sizes; include maskable variant |
| M6 | **Brand strings scattered — easy to miss some** | Rebrand | Inconsistent branding post-launch | Run `grep -r "Strength" src/` audit before starting; create `brand.ts` constants |
| N1 | **Missing `viewport-fit=cover`** | PWA | Content clipped by iPhone notch | Add `viewportFit: 'cover'` to viewport export; add safe-area padding to `BottomNavigation` |

---

## Implications for Roadmap

### Recommended Phase Structure

**Phase 1 — Rebrand** *(text changes, zero functional risk)*

Scope: All user-visible "Strength" → "Sundee-Fundee" substitutions. Create `src/lib/constants/brand.ts` with `APP_NAME`, `APP_TITLE`, `APP_DESCRIPTION` constants imported everywhere.

Deliverable: App runs identically with new name in browser tab, onboarding, README, planning docs.

Pitfalls to prevent: C5 (IDB name freeze), M6 (scattered strings audit).

Validation: App starts, tests pass, `grep -r "Strength" src/` returns only domain terms.

---

**Phase 2 — Icons + Manifest** *(PWA installability without offline caching)*

Scope:
- Generate icon assets (`@vite-pwa/assets-generator` from source SVG/PNG)
- Create `src/app/manifest.ts`
- Update `layout.tsx` metadata (manifest link, `appleWebApp`, `viewport` export with `viewportFit: 'cover'` and `themeColor`)
- Add `<link rel="apple-touch-icon">` tags
- Update `tsconfig.json` (add `"webworker"` to lib for type support)

Deliverable: App passes Chrome installability check. "Add to Home Screen" prompt appears on Android. iOS icon renders correctly.

Pitfalls to prevent: M2 (iOS install banner), M3 (icon sizes), N1 (viewport-fit), N2 (theme-color).

Validation: Chrome DevTools → Application → Manifest — no errors. Lighthouse PWA score improves. Mobile install prompt fires.

---

**Phase 3 — Service Worker + Offline Shell** *(highest complexity, build last)*

Scope:
- Install `@serwist/turbopack` + `serwist`
- `next.config.ts` — add `withSerwist` wrapper
- `src/app/sw.ts` — Serwist config with `defaultCache`, `NetworkOnly` for Supabase, offline fallback
- `src/app/offline/page.tsx` — branded offline page
- Update `middleware.ts` matcher (exclude SW/workbox files)
- Add `.gitignore` entries for compiled SW output
- Add `serviceWorkers: 'block'` to `playwright.config.ts`
- Handle `controllerchange` in layout to defer reload during active workouts

Deliverable: App loads shell offline. Lighthouse PWA score ≥ 90.

Pitfalls to prevent: C1 (correct library), C2 (Playwright), C3 (middleware), C4 (skipWaiting), M1 (session refresh).

Validation: Network offline in DevTools → navigate to `/dashboard` → app shell loads from cache → Dexie data visible → no broken UI.

---

**Phase 4 — Icon Enrichment + Polish** *(code-only, low risk)*

Scope:
- Replace `OfflineBanner` inline SVG with `<WifiOff />`
- Progress screen: add `Trophy`, `Flame`, `BarChart2`, `TrendingUp`
- Rest timer: add `AlarmClockCheck` for complete state
- Workout cards: add `CircleCheck`/`CircleX` for set status, `Dumbbell`/`BicepsFlexed` by category
- SW update toast (`Download` icon + "New version available" message)
- iOS install nudge (platform-detected, `Share → Add to Home Screen` tooltip)
- Android manifest shortcuts

Deliverable: Visually polished icon vocabulary throughout the app; SW update UX; platform-appropriate install guidance.

---

### Research Flags

| Phase | Research Needed? | Rationale |
|-------|-----------------|-----------|
| Phase 1 — Rebrand | ❌ No | Pure text substitution; patterns are well-documented |
| Phase 2 — Icons/Manifest | ❌ No | Chrome installability criteria and iOS requirements are fully specified in FEATURES.md + PITFALLS.md |
| Phase 3 — Service Worker | ⚠️ Maybe | `@serwist/turbopack` integration pattern is in official examples, but Turbopack-specific behavior may surprise; consider a spike before full implementation |
| Phase 4 — Icon Enrichment | ❌ No | Icon names confirmed available in installed lucide-react v0.564.0 |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack (library selection) | **HIGH** | `@serwist/turbopack` confirmed against Next.js 16.1.6 source; esbuild peer dep verified |
| Features (what to build) | **HIGH** | iOS/Android PWA requirements verified against Apple dev docs and web.dev; lucide icon names verified in installed package |
| Architecture (file layout + patterns) | **HIGH** | App Router manifest convention verified in Next.js 16.1.6 docs; Turbopack `withSerwist` pattern from official example |
| Pitfalls | **HIGH** (most) | C1–C5, M2, M3, N1 verified via source code or official docs. **MEDIUM** for M1 (derived behavior) and M4 (iOS 16.4 storage isolation) |

### Open Questions (Need Decisions Before Implementation)

1. **Final brand assets:** What is the source SVG/PNG for the app icon? A high-res source is required for `@vite-pwa/assets-generator`. Dumbbell/BicepsFlexed on brand-color background is recommended.

2. **`short_name` character limit:** Must be ≤ 12 characters for safe display on small phone screens. "Sundee-Fundee" is 13 characters — decide on a short name (e.g., "S-Fundee", "SunFundee") or accept truncation.

3. **`start_url` auth state:** Should the PWA open at `/dashboard` (requires auth) or `/` (redirects to auth if needed)? Opening at `/dashboard` with a stale session will redirect to login — confirm intended behavior.

4. **Playwright SW block scope:** Adding `serviceWorkers: 'block'` is recommended; confirm no existing or planned tests intentionally test SW behavior.

5. **Supabase realtime:** The `NetworkOnly` rule for `*.supabase.co` is correct for HTTP. Confirm whether realtime WebSocket subscriptions are in use — the SW won't intercept WebSocket traffic regardless.

---

## Sources (Aggregated)

| Source | Used In | Confidence |
|--------|---------|------------|
| `node_modules/next/dist/lib/bundler.js` — Turbopack default | STACK | HIGH |
| Serwist example `next-turbo-basic` (Next.js 16.1.6) | STACK | HIGH |
| `node_modules/next/dist/lib/metadata/types/manifest-types.d.ts` | STACK | HIGH |
| npm registry: `@serwist/turbopack`, `@vite-pwa/assets-generator` | STACK | HIGH |
| `node_modules/lucide-react/package.json` | STACK, FEATURES | HIGH |
| Apple Developer Docs — Configuring Web Applications | FEATURES | HIGH |
| web.dev — Add a web app manifest + Maskable icons | FEATURES, PITFALLS | HIGH |
| serwist.pages.dev — Getting started (Next.js) | ARCHITECTURE | HIGH |
| Next.js 16.1.6 docs — manifest.json file convention | ARCHITECTURE | HIGH |
| `src/lib/db/dexie.ts:31` — `super('StrengthApp')` | ARCHITECTURE, PITFALLS | HIGH |
| `middleware.ts:38-42` — matcher pattern | ARCHITECTURE, PITFALLS | HIGH |
| Playwright API docs — `serviceWorkers: 'block'` | PITFALLS | HIGH |
| WebKit release notes — Safari 16.4 PWA storage isolation | PITFALLS | MEDIUM |
