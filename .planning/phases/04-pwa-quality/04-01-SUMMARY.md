---
phase: 04-pwa-quality
plan: 01
subsystem: pwa-icons-offline
tags: [pwa, icons, service-worker, workbox, offline]
dependency_graph:
  requires: []
  provides: [PWA-01, PWA-02, PWA-03]
  affects: [pwa/vite.config.ts, pwa/index.html, pwa/public/]
tech_stack:
  added: [sharp (dev)]
  patterns: [workbox navigateFallback, PWA icon generation from SVG]
key_files:
  created:
    - scripts/generate-icons.mjs
    - pwa/public/icons/icon-192.png
    - pwa/public/icons/icon-512.png
    - pwa/public/apple-touch-icon.png
    - pwa/public/offline.html
  modified:
    - pwa/vite.config.ts
    - pwa/index.html
    - pwa/package.json
decisions:
  - sharp installed in pwa/ node_modules; generate-icons.mjs uses createRequire pointed at pwa/package.json to resolve sharp from correct location when run from repo root
  - favicon.svg uses display-p3 color space; simplified SVG copy with sRGB fallback colors (#863bff purple) used for icon generation to ensure librsvg compatibility
  - navigateFallbackDenylist [/^\/api\//] excludes API routes from offline fallback to prevent service worker intercepting real API errors
metrics:
  duration: ~10min
  completed: 2026-03-21
  tasks_completed: 2
  files_changed: 8
---

# Phase 04 Plan 01: PWA Icons and Offline Fallback Summary

**One-liner:** Generated production PWA icon PNGs from SVG source using sharp and wired workbox navigateFallback to a branded Art Deco offline page.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Generate PWA icon PNGs and create offline fallback page | 4f84011 | scripts/generate-icons.mjs, pwa/public/icons/icon-192.png, pwa/public/icons/icon-512.png, pwa/public/apple-touch-icon.png, pwa/public/offline.html |
| 2 | Wire workbox navigateFallback and fix apple-touch-icon href | 82fee01 | pwa/vite.config.ts, pwa/index.html |

## What Was Built

**Icon generation script** (`scripts/generate-icons.mjs`): Node ESM script that reads a simplified sRGB SVG and uses sharp to produce three PNG icons with navy (#0D1A40) background via `flatten + fit: contain`. Generates 192x192, 512x512 (manifest icons), and 180x180 (Apple touch icon). Script runs from repo root using `createRequire` pointed at `pwa/package.json` to find sharp in pwa's node_modules.

**Icon PNGs**: Three production-ready PNG files at the exact paths declared in the manifest — `pwa/public/icons/icon-192.png`, `pwa/public/icons/icon-512.png`, `pwa/public/apple-touch-icon.png`. Dimensions verified via sharp metadata.

**Branded offline page** (`pwa/public/offline.html`): Self-contained HTML with all CSS inline, Art Deco theme (navy #0D1A40 background, cream #F4F0DF text, orange #F2731A CTA button). Includes inline SVG lightning bolt logo. No external fonts, images, or scripts. "Try Again" button calls `window.location.reload()`.

**Workbox configuration** (`pwa/vite.config.ts`): Added `navigateFallback: '/offline.html'` and `navigateFallbackDenylist: [/^\/api\//]` to workbox block. Added `'offline.html'` to `includeAssets` for precaching. Manifest icon array retains all three entries including the separate `purpose: 'maskable'` entry for icon-512.png.

**apple-touch-icon fix** (`pwa/index.html`): Changed `href="/icons/icon-192.png"` to `href="/apple-touch-icon.png"` to match the generated file location.

## Verification Results

- icon-192.png: 192x192 OK (sharp metadata)
- icon-512.png: 512x512 OK (sharp metadata)
- apple-touch-icon.png: 180x180 OK (sharp metadata)
- offline.html exists at pwa/public/offline.html
- navigateFallback: '/offline.html' confirmed in vite.config.ts
- apple-touch-icon href: /apple-touch-icon.png confirmed in index.html
- maskable count: 1 (manifest retains separate maskable entry)
- Production build: succeeds, dist/offline.html present, dist/sw.js generated

## Deviations from Plan

**1. [Rule 1 - Bug] sharp module resolution from repo root**
- **Found during:** Task 1 execution
- **Issue:** Script runs from repo root but sharp is installed in pwa/node_modules. `require('sharp')` failed with MODULE_NOT_FOUND.
- **Fix:** Used `createRequire(resolve(ROOT, 'pwa/package.json'))` to create a require function scoped to pwa's node_modules directory.
- **Files modified:** scripts/generate-icons.mjs
- **Commit:** 4f84011

**2. [Rule 2 - Missing critical functionality] Simplified SVG for icon generation**
- **Found during:** Task 1 design
- **Issue:** The favicon.svg uses `color(display-p3 ...)` color space syntax, which may not be handled by all librsvg versions bundled with sharp. The plan anticipated this and instructed using an sRGB copy.
- **Fix:** generate-icons.mjs uses a SIMPLIFIED_SVG constant with plain hex color `#863bff` (sRGB equivalent), including a navy rect background, ensuring reliable rendering across all sharp/librsvg versions.
- **Files modified:** scripts/generate-icons.mjs
- **Commit:** 4f84011

## Self-Check: PASSED

- scripts/generate-icons.mjs: FOUND
- pwa/public/icons/icon-192.png: FOUND (192x192 verified)
- pwa/public/icons/icon-512.png: FOUND (512x512 verified)
- pwa/public/apple-touch-icon.png: FOUND (180x180 verified)
- pwa/public/offline.html: FOUND
- pwa/vite.config.ts: navigateFallback wired
- pwa/index.html: apple-touch-icon href fixed
- Commits 4f84011 and 82fee01: FOUND
