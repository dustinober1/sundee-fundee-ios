# Requirements: v1.1 Sundee-Fundee

**Milestone:** v1.1 — Rebrand + PWA + Icon Enrichment
**Status:** Defined 2026-02-19
**Previous milestone requirements:** see `.planning/milestones/v1.0-REQUIREMENTS.md`

---

## v1.1 Requirements

### Rebrand

- [ ] **BRAND-01**: User sees "Sundee-Fundee" as the app name in browser tab titles, page metadata, and the document title across all routes
- [ ] **BRAND-02**: User sees "Sundee-Fundee" in all visible UI text (replacing any "Strength" references in headers, labels, copy)
- [ ] **BRAND-03**: App configuration files (package.json, README, next.config.ts comments) reflect the new app name

### PWA Foundation

- [ ] **PWA-01**: App serves a valid web app manifest with `name: "Sundee-Fundee"`, `short_name: "SundeeFundee"`, `display: "standalone"`, and appropriate theme/background colors
- [ ] **PWA-02**: App icon set is complete: 192×192px, 512×512px, 512×512px maskable (Android safe zone), and 180×180px apple-touch-icon (iOS)
- [ ] **PWA-03**: App registers a service worker (via `@serwist/turbopack`) that caches the app shell and serves a navigation fallback — Supabase API calls explicitly excluded from caching
- [ ] **PWA-04**: iOS-specific `<head>` meta tags are present: `apple-touch-icon`, `apple-mobile-web-app-capable`, `apple-mobile-web-app-title: "SundeeFundee"`
- [ ] **PWA-05**: Supabase auth middleware excludes `/sw.js` and `/manifest.json` routes from processing
- [ ] **PWA-06**: Existing 11 Playwright E2E tests continue to pass after service worker is introduced (`serviceWorkers: 'block'` added to playwright.config.ts)

### Install Experience

- [ ] **INSTALL-01**: Android users see an "Add to Home Screen" install banner/prompt powered by the `beforeinstallprompt` event deferral pattern
- [ ] **INSTALL-02**: iOS users can access step-by-step "Add to Home Screen" instructions via a modal (Share → Add to Home Screen guidance)

### Icon Enrichment

- [ ] **ICON-01**: `OfflineBanner` component uses `<WifiOff>` from Lucide React instead of inline SVG
- [ ] **ICON-02**: Dashboard cards display contextual Lucide icons (e.g., `Trophy` for PRs, `Flame` for activity/streak, `BarChart2` for progress section)
- [ ] **ICON-03**: Active workout and workout logging pages use fitness-specific Lucide icons (e.g., `Dumbbell`, `AlarmClockCheck`, `Target`, `CircleCheck`)
- [ ] **ICON-04**: Bottom navigation bar uses a consistent Lucide icon set aligned with each tab's purpose

---

## Future Requirements (deferred)

- iOS splash screen assets (significant asset work, defer to v1.2)
- PWA push notifications (iOS 16.4+ only, limited reach, defer to v2.0)
- PWA shortcuts / screenshots in manifest (boosts store discoverability, defer to v1.2)
- Native App Store / Play Store submission (out of scope for PWA approach)

---

## Out of Scope

- **IndexedDB database name change** — `'StrengthApp'` in `dexie.ts` must never change; doing so silently destroys all user data with no error thrown. Explicitly excluded from rebrand.
- **Visual design refresh** — Colors, typography, and component styling stay as-is. Name and icon only.
- **React Native / Capacitor** — Web PWA approach chosen. No native app codebase.
- **Background sync via Service Worker** — App already handles offline queuing via localStorage; Service Worker Background Sync is redundant and iOS support is unreliable.

---

## Traceability

| Requirement | Phase | Status |
|------------|-------|--------|
| BRAND-01 | Phase 5 — Rebrand | Complete |
| BRAND-02 | Phase 5 — Rebrand | Complete |
| BRAND-03 | Phase 5 — Rebrand | Complete |
| PWA-01 | Phase 6 — PWA Foundation | Complete |
| PWA-02 | Phase 6 — PWA Foundation | Complete |
| PWA-04 | Phase 6 — PWA Foundation | Complete |
| PWA-05 | Phase 6 — PWA Foundation | Complete |
| PWA-06 | Phase 6 — PWA Foundation | Complete |
| PWA-03 | Phase 7 — Service Worker | Complete |
| INSTALL-01 | Phase 8 — Install + Icon Polish | Pending |
| INSTALL-02 | Phase 8 — Install + Icon Polish | Pending |
| ICON-01 | Phase 8 — Install + Icon Polish | Pending |
| ICON-02 | Phase 8 — Install + Icon Polish | Pending |
| ICON-03 | Phase 8 — Install + Icon Polish | Pending |
| ICON-04 | Phase 8 — Install + Icon Polish | Pending |
