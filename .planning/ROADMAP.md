# Roadmap: Strength (Workout Tracker)

## Milestones

- ✅ **v1.0 MVP** — Phases 1-4 (shipped 2026-02-19) · [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v1.1 Sundee-Fundee** — Phases 5-8 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-4) — SHIPPED 2026-02-19</summary>

- [x] Phase 1: Smart Guidance (3/3 plans) — completed 2026-02-18
- [x] Phase 2: Visual Progress (3/3 plans) — completed 2026-02-19
- [x] Phase 3: Cloud Sync (3/3 plans) — completed 2026-02-19
- [x] Phase 4: E2E Verification (2/2 plans) — completed 2026-02-19

Full details: [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)

</details>

---

## v1.1 Sundee-Fundee — Phases 5–8

**Overview:** Rebrand the app from "Strength" to "Sundee-Fundee", ship it as a fully installable PWA with a service worker, and enrich the UI with a consistent Lucide icon vocabulary. Built on a verified v1.0 foundation with 11 passing E2E tests.

**Requirements:** 14 total (BRAND-01/02/03, PWA-01/02/03/04/05/06, INSTALL-01/02, ICON-01/02/03/04)
**Depth:** Comprehensive
**Coverage:** 14/14 ✓

---

### Phase 5: Rebrand

**Goal:** Users and developers see "Sundee-Fundee" consistently everywhere the app name appears — browser tabs, metadata, page copy, and config files — with zero functional regression.

**Dependencies:** None (text-only changes; no new packages)

**Requirements:** BRAND-01, BRAND-02, BRAND-03

**Critical constraint:** `super('StrengthApp')` in `dexie.ts` is **permanently frozen** — changing it silently destroys all user data. Domain function names (`analyzeStrengthPatterns`, etc.) and the `<SelectItem value="strength">` fitness term are also excluded from rebrand scope.

**Success Criteria:**
1. Browser tab titles and `<head>` metadata read "Sundee-Fundee" on every route (dashboard, workout, progress, settings)
2. All visible UI copy — headers, onboarding welcome text, labels — shows "Sundee-Fundee" with no residual "Strength" app-name references
3. `package.json` `name` field, `README.md`, and `CLAUDE.md` reflect "Sundee-Fundee"
4. `grep -r "Strength" src/` returns only domain terms (function names, fitness terminology, `'StrengthApp'` IDB constant) — zero brand-name hits
5. All 11 existing Playwright E2E tests pass without modification

---

### Phase 6: PWA Foundation

**Goal:** The app is installable on Android and satisfies iOS home screen requirements — manifest served, icons generated, iOS meta tags present, middleware and Playwright config updated before the service worker is introduced.

**Dependencies:** Phase 5 (brand name needed for manifest `name` / `short_name` / `apple-mobile-web-app-title`)

**Requirements:** PWA-01, PWA-02, PWA-04, PWA-05, PWA-06

**Critical constraint:** `serviceWorkers: 'block'` (PWA-06) is added in this phase — before any service worker exists — so the Playwright guard is in place before Phase 7 introduces the SW.

**Success Criteria:**
1. Chrome DevTools → Application → Manifest shows no errors: `name: "Sundee-Fundee"`, `display: "standalone"`, `start_url: "/dashboard"`, theme/background colors, and all icon sizes listed
2. Icon set is complete and renders correctly: 192×192 (Android), 192×192 maskable (Android safe zone), 512×512, 180×180 apple-touch-icon (iOS home screen)
3. iOS Safari `<head>` contains `apple-mobile-web-app-capable`, `apple-mobile-web-app-status-bar-style`, and `apple-mobile-web-app-title: "SundeeFundee"` — icon appears on iOS home screen when added manually
4. Supabase auth middleware no longer routes `/sw.js`, `/workbox-*.js`, or `/manifest.json` through auth processing
5. All 11 Playwright E2E tests pass with `serviceWorkers: 'block'` present in `playwright.config.ts`

---

### Phase 7: Service Worker

**Goal:** The app shell loads from cache when the network is offline, navigation fallback works, and Supabase API calls are never cached — Lighthouse PWA score reaches ≥ 90.

**Dependencies:** Phase 6 (manifest and icons must be verified before adding SW complexity; middleware exclusion must be in place)

**Requirements:** PWA-03

**Critical constraints:**
- Must use `@serwist/turbopack` (not `@serwist/next` — webpack-only, silently fails under Next.js 16 Turbopack)
- All `*.supabase.co` routes configured as `NetworkOnly` — SW must not cache auth-gated Supabase responses
- `controllerchange` event handled in layout to defer page reload when a workout is in progress (prevents mid-workout data loss)

**Success Criteria:**
1. Chrome DevTools → Network tab set to "Offline" → navigate to `/dashboard` → app shell and previously cached assets load without a network error
2. Navigating to an uncached route while offline shows the branded `/offline` fallback page with a link back to `/dashboard`
3. Supabase API calls (auth, data sync) are never served from cache — confirmed via DevTools Network tab showing `(ServiceWorker)` only for shell assets, not `*.supabase.co` requests
4. Lighthouse PWA audit (production build) scores ≥ 90 with no installability or offline errors
5. All 11 Playwright E2E tests continue to pass (SW blocked by config from Phase 6)

---

### Phase 8: Install Experience + Icon Enrichment

**Goal:** Android users see an install prompt, iOS users have clear "Add to Home Screen" guidance, and the app presents a consistent, meaningful Lucide icon vocabulary across all major UI surfaces.

**Dependencies:** Phase 6 (PWA-01/02 manifest and icons must exist for Android install prompt to fire; Phase 7 not required — install and icons are independent of the service worker)

**Requirements:** INSTALL-01, INSTALL-02, ICON-01, ICON-02, ICON-03, ICON-04

**Success Criteria:**
1. On Android Chrome (or DevTools mobile simulation), an "Add to Home Screen" install banner appears, powered by `beforeinstallprompt` deferral — tapping it triggers the native install dialog
2. iOS users can tap a persistent UI affordance (button or banner) to open a step-by-step modal showing "Tap Share → Add to Home Screen" with a visual guide
3. `OfflineBanner` displays the `<WifiOff>` Lucide icon — inline SVG is fully removed
4. Dashboard cards display contextually appropriate Lucide icons: `Trophy` for PRs, `Flame` for activity/streak, `BarChart2` for the progress section — each icon matches its card's purpose at a glance
5. Active workout and logging pages show fitness-specific Lucide icons (`Dumbbell`, `AlarmClockCheck`, `Target`, `CircleCheck`) and bottom navigation uses a consistent Lucide icon set aligned with each tab's purpose

---

## Progress

| Phase | Milestone | Goal | Requirements | Plans Complete | Status | Completed |
|-------|-----------|------|--------------|----------------|--------|-----------|
| 1. Smart Guidance | v1.0 | Smart weight recommendations | RECOM-01/02/03 | 3/3 | ✅ Complete | 2026-02-18 |
| 2. Visual Progress | v1.0 | Progress visualization | CHART-01/02/03 | 3/3 | ✅ Complete | 2026-02-19 |
| 3. Cloud Sync | v1.0 | Supabase backup + restore | SYNC-01/02/03 | 3/3 | ✅ Complete | 2026-02-19 |
| 4. E2E Verification | v1.0 | Verified test coverage | TEST-01/02/03 | 2/2 | ✅ Complete | 2026-02-19 |
| 5. Rebrand | v1.1 | Sundee-Fundee everywhere | BRAND-01/02/03 | 1/1 | ✅ Complete | 2026-02-20 |
| 6. PWA Foundation | v1.1 | Installable PWA basics | PWA-01/02/04/05/06 | 0/? | ⬜ Pending | — |
| 7. Service Worker | v1.1 | Offline shell + caching | PWA-03 | 0/? | ⬜ Pending | — |
| 8. Install + Icon Polish | v1.1 | Install UX + icon enrichment | INSTALL-01/02, ICON-01/02/03/04 | 0/? | ⬜ Pending | — |
