---
phase: "06"
plan: "01"
name: "generate-pwa-icons-manifest"
subsystem: "pwa"
tags: ["pwa", "manifest", "icons", "sharp", "next.js"]

dependency-graph:
  requires: ["05-01"]
  provides: ["pwa-manifest", "pwa-icons"]
  affects: ["06-02", "06-03"]

tech-stack:
  added: ["sharp@0.34.5"]
  patterns: ["Next.js App Router metadata route", "SVG-to-PNG icon generation"]

file-tracking:
  key-files:
    created:
      - "scripts/generate-icons.mjs"
      - "public/icons/icon-192.png"
      - "public/icons/icon-192-maskable.png"
      - "public/icons/icon-512.png"
      - "public/icons/apple-touch-icon.png"
      - "src/app/manifest.ts"
    modified:
      - "package.json"
      - "package-lock.json"

decisions:
  - id: "D1"
    choice: "Next.js metadata route for manifest"
    why: "App Router auto-serves manifest.ts as /manifest.webmanifest with correct MIME type — no manual route needed"
  - id: "D2"
    choice: "SVG-to-PNG via Sharp (programmatic, not asset-based)"
    why: "Reproducible, no Figma/design tool dependency, version-controlled generation script"
  - id: "D3"
    choice: "apple-touch-icon excluded from manifest icons array"
    why: "iOS uses <link rel='apple-touch-icon'> in layout.tsx; adding to manifest is redundant and may cause duplication"
  - id: "D4"
    choice: "Manifest served at /manifest.webmanifest (not /manifest.json)"
    why: "Next.js App Router metadata route convention — Next.js injects correct <link rel='manifest'> href automatically"

metrics:
  duration: "12 minutes"
  completed: "2026-02-20"
  tasks-completed: 2
  tasks-total: 2
---

# Phase 06 Plan 01: Generate PWA Icons & Manifest Summary

**One-liner:** Sharp SVG→PNG icon generation (4 sizes) + Next.js manifest.ts metadata route serving valid PWA manifest at /manifest.webmanifest

## What Was Built

Generated 4 PWA icons programmatically from SVG using Sharp, and created the Next.js App Router `manifest.ts` metadata route to serve the web app manifest automatically.

### Icons Generated

| File | Size | Purpose |
|------|------|---------|
| `icon-192.png` | 192×192 | Standard Android icon (rounded corners, dark bg, white SF) |
| `icon-192-maskable.png` | 192×192 | Full-bleed maskable, text in 75% safe zone |
| `icon-512.png` | 512×512 | Chrome install prompt icon |
| `apple-touch-icon.png` | 180×180 | iOS home screen (iOS applies own rounding) |

### Manifest Values

- **name:** Sundee-Fundee
- **short_name:** SundeeFundee (12 chars, no hyphen)
- **display:** standalone
- **start_url:** /dashboard
- **theme_color:** #171717 | **background_color:** #ffffff

## Verification Results

| Check | Result |
|-------|--------|
| `ls public/icons/` shows 4 PNG files | ✓ |
| `file public/icons/*.png` confirms PNG format | ✓ |
| All icons 3–14KB (reasonable range) | ✓ |
| `npm ls sharp` shows sharp@0.34.5 in devDeps | ✓ |
| `GET /manifest.webmanifest` returns valid JSON | ✓ |
| `GET /icons/icon-*.png` all return 200 | ✓ |
| TypeScript (`src/**`) compiles with no errors | ✓ |

## Task Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Generate PWA icons with Sharp | `e899cf2` |
| 2 | Create manifest.ts metadata route | `f2202f2` |

## Decisions Made

1. **Next.js metadata route** — `src/app/manifest.ts` auto-served as `/manifest.webmanifest`; Next.js injects `<link rel="manifest">` automatically
2. **Programmatic SVG→PNG** — `scripts/generate-icons.mjs` is reproducible and design-tool-free
3. **apple-touch-icon not in manifest** — iOS reads `<link rel="apple-touch-icon">` from layout.tsx; manifest entry is redundant
4. **Manifest URL is /manifest.webmanifest** — Not /manifest.json; this is Next.js App Router convention

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

- Phase 06-02 (iOS meta tags + middleware) builds on these icons ✓ (already completed)
- Phase 06-03 (service worker) can proceed with icons in place ✓
- Chrome DevTools → Application → Manifest can now be validated in browser
