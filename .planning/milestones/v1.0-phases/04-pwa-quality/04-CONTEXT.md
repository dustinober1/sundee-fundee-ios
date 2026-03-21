# Phase 4: PWA Quality - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Phase Boundary

The app passes a Lighthouse PWA audit, shows production-quality icons, serves a branded offline page, and surfaces an install prompt. Covers PWA-01 (icons), PWA-02 (Lighthouse), PWA-03 (offline fallback), PWA-04 (install prompt). No error boundaries, no skeleton states, no analytics — those are Phase 5 and 6.

</domain>

<decisions>
## Implementation Decisions

### Icon source and generation
- Generate all PNG icons from existing `pwa/public/favicon.svg`
- Output: 192px, 512px PNGs in `pwa/public/icons/` directory
- Also generate 180px `apple-touch-icon.png` in `pwa/public/`
- Background color: navy (#0D1A40) — matches manifest theme_color
- Maskable icon: same artwork with ~10% auto-padding for safe zone (no separate design)

### Offline fallback page
- Static `offline.html` file in `pwa/public/` — pre-cached by service worker
- Art Deco themed: navy (#0D1A40) background, cream (#F4F0DF) text, orange (#F2731A) accent button
- Content: app logo, "You're currently offline" message, "Check your connection and try again"
- "Try Again" button calls `window.location.reload()`
- Configure workbox `navigateFallback` in vite.config.ts to serve offline.html

### Install prompt behavior
- **Android:** Capture `beforeinstallprompt` event, defer it, show prompt after first workout completion
- **iOS Safari:** Non-blocking bottom banner with share icon instruction ("Tap [↑] then Add to Home Screen"), dismissible
- **Dismissal behavior:** Shows once per session (sessionStorage). Reappears on next session.
- **Standalone detection:** Suppress prompt entirely if `display-mode: standalone` matches (already installed)
- **Trigger:** After first workout complete (meaningful engagement moment)

### Lighthouse audit scope
- Target: all green PWA installability checks (manifest, service worker, HTTPS, icons)
- Fix only PWA-specific issues — performance, accessibility, and SEO issues belong in later phases
- Manual Lighthouse audit against deployed URL — no Lighthouse CI in GitHub Actions

### Claude's Discretion
- Icon generation tooling (sharp, canvas, or manual conversion)
- Exact workbox configuration for navigateFallback and offline routing
- Offline page HTML/CSS implementation details
- Install prompt React component structure (hook vs context vs component)
- Any Lighthouse PWA fixes not covered by the specific decisions above

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `pwa/public/favicon.svg` — Source SVG for icon generation
- `pwa/vite.config.ts` — VitePWA plugin already configured with manifest, workbox, and icon references
- Art Deco theme colors used throughout the app (navy, cream, orange)

### Established Patterns
- VitePWA with `registerType: 'autoUpdate'` — service worker auto-updates
- Workbox caching: Firestore NetworkFirst, images CacheFirst
- Manifest already declares icons at `/icons/icon-192.png` and `/icons/icon-512.png` — files need to be created

### Integration Points
- `vite.config.ts` workbox config needs `navigateFallback: '/offline.html'` added
- `pwa/public/icons/` directory needs to be created with generated PNGs
- `apple-touch-icon.png` referenced in `includeAssets` needs to be created
- Install prompt hook/component needs to integrate with workout completion event
- `pwa/public/offline.html` needs to be added and pre-cached

</code_context>

<specifics>
## Specific Ideas

- Offline page follows the branded message + logo pattern (navy background, cream text, orange CTA button)
- Install prompt on iOS is a bottom banner, not a modal — non-intrusive
- Install prompt timing tied to workout completion, not arbitrary visit count

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-pwa-quality*
*Context gathered: 2026-03-21*
