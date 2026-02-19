# Technology Stack — PWA + Icon Enrichment + Rebrand

**Project:** Sundee-Fundee (rebranding from Strength)
**Milestone:** PWA capabilities, Lucide icon enrichment, rebrand
**Researched:** 2025-07-14
**Scope:** Stack additions/changes only — existing stack not re-researched

---

## Critical Context: Next.js 16 Uses Turbopack by Default

> **This changes everything about PWA library selection.**

Next.js 16 source (`node_modules/next/dist/lib/bundler.js`) confirms:
```javascript
// The default is turbopack when nothing is configured.
if (bundlerFlags.size === 0) {
    process.env.TURBOPACK = 'auto';
    return 0; // Bundler.Turbopack
}
```

The project's `npm run dev` (`next dev`) and `npm run build` (`next build`) **already use Turbopack** without needing any flag. This means:

- `@serwist/next` (webpack-based) ❌ — wrong bundler
- `@ducanh2912/next-pwa` (webpack-based) ❌ — wrong bundler AND abandoned Sep 2024
- `next-pwa` (webpack-based) ❌ — abandoned Aug 2022
- `@serwist/turbopack` ✅ — designed for exactly this configuration

---

## Recommended Additions

### PWA: Service Worker
| Package | Version | Role | Install as |
|---------|---------|------|-----------|
| `@serwist/turbopack` | `^9.5.6` | Next.js 16 + Turbopack SW integration | `dependencies` |
| `serwist` | `^9.5.6` | Core service worker runtime + Workbox | `dependencies` |

**Why `@serwist/turbopack` specifically:**
- Only actively maintained PWA library with explicit Turbopack support
- Official Serwist example repo uses `next: "16.1.6"` — exact match to this project
- Published 2026-02-13 (most recently updated of all options)
- `esbuild` peer dep is already installed at `v0.27.3` via Next.js (satisfies `>=0.25.0 <1.0.0`)
- ~550K monthly downloads for the `@serwist/*` family, actively maintained

**Why NOT the alternatives:**

| Library | Last Published | Problem |
|---------|--------------|---------|
| `next-pwa` v5.6.0 | Aug 2022 | Abandoned, webpack-only |
| `@ducanh2912/next-pwa` v10.2.9 | Sep 2024 | Webpack-only, abandoned |
| `@serwist/next` v9.5.6 | Feb 2026 | Active, but webpack-only — wrong for Next.js 16 |
| Custom Workbox | — | Too much boilerplate, no Next.js precaching integration |

### PWA: Web App Manifest
**No library needed.** Next.js 16 App Router has built-in manifest support via `MetadataRoute.Manifest`:

```typescript
// src/app/manifest.ts — built-in Next.js App Router convention
import type { MetadataRoute } from 'next'

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Sundee-Fundee',
    short_name: 'Sundee-Fundee',
    // ...
  }
}
```

The `MetadataRoute.Manifest` type is already defined in this project's installed Next.js 16.1.6 at `node_modules/next/dist/lib/metadata/types/manifest-types.d.ts`. It supports all fields: `display`, `icons`, `theme_color`, `background_color`, `start_url`, `shortcuts`, `screenshots`, etc.

**Why not `public/manifest.json`:** The `app/manifest.ts` route is the correct App Router pattern. It auto-serves at `/manifest.webmanifest` with the correct MIME type. Static `public/manifest.json` works but is the Pages Router pattern.

### PWA: Icon Generation
| Package | Version | Role | Install as |
|---------|---------|------|-----------|
| `@vite-pwa/assets-generator` | `^1.0.2` | Generate all PWA icon sizes from one source | `devDependencies` |

**Why `@vite-pwa/assets-generator`:**
- Zero-config CLI: one source SVG/PNG → full icon set (72, 96, 128, 144, 152, 192, 384, 512px PNGs + maskable variants)
- Also generates `apple-touch-icon` variants and `favicon.ico`
- Last updated Oct 2025 (actively maintained)
- Uses `sharp` internally — no browser required, pure CLI
- Framework-agnostic despite the "vite" name; works perfectly with Next.js
- Outputs icons directly to `public/icons/` — no config required

**Alternative considered:** `pwa-asset-generator` (v8.1.2, Sep 2025) — also good, but requires a running browser (puppeteer). `@vite-pwa/assets-generator` is simpler and faster.

**Do NOT install `sharp` directly.** It's bundled inside `@vite-pwa/assets-generator`. Adding it separately is redundant and can cause version conflicts.

### PWA: Install Prompt
**No library needed.** Implement as a custom React component:
- Use `beforeinstallprompt` event for Chrome/Android
- iOS requires `apple-mobile-web-app-capable` meta via Next.js `viewport` export (already supported in Next.js metadata API)

The Next.js official PWA guide (verified Feb 2026) explicitly states: _"we do not recommend [custom install button with beforeinstallprompt] as it is not cross browser and platform (does not work on Safari iOS)"_ — so keep the install prompt minimal, just handle the meta tags correctly.

---

## What NOT to Add

| Rejected Addition | Why |
|-------------------|-----|
| `react-pwa-install` or similar install libraries | Overkill; not cross-platform; handle manually |
| `workbox-*` packages directly | Already bundled inside `serwist` |
| `react-icons` | Already have `lucide-react` v0.564.0 — adding another icon library creates inconsistency |
| `sharp` (direct) | Bundled in `@vite-pwa/assets-generator`; separate install creates version conflicts |
| `@serwist/cli` | Only needed for webpack setup; `@serwist/turbopack` doesn't require it |
| `next-themes` | Not needed for this milestone |

---

## No Changes: Lucide React

`lucide-react` v0.564.0 is already installed and being used across the codebase. **No changes needed.**

Key facts confirmed:
- `sideEffects: false` — full tree-shaking works. Only imported icons end up in the bundle.
- Import pattern already in use is correct: `import { IconName } from 'lucide-react'`
- v0.564.0 is the latest available (verified via npm)
- 645 versions published — extremely active development; icons added frequently

**Icon enrichment is a code change, not a stack change.** Identify missing icon coverage in the UI and add named imports. No library installation required.

---

## Rebrand: Strength → Sundee-Fundee

**This is configuration and text changes only — no new packages.**

Files to update:

| File | Change |
|------|--------|
| `package.json` | `"name": "strength"` → `"name": "sundee-fundee"` |
| `src/app/layout.tsx` | Update `metadata.title` and `metadata.description` |
| `src/app/manifest.ts` | Set `name`, `short_name` to "Sundee-Fundee" (new file) |
| Any hardcoded "Strength" strings | Text search + replace |

---

## Complete Additions Summary

```bash
# Add to dependencies
npm install @serwist/turbopack serwist

# Add to devDependencies
npm install -D @vite-pwa/assets-generator
```

That's it. Two packages for the service worker, one for icon generation. Everything else (manifest, install prompt, rebrand, Lucide usage) is code changes to existing files.

---

## Integration: Dexie.js + Service Worker Coexistence

Dexie.js v4 uses IndexedDB in the **browser main thread** (page context). The service worker runs in a **separate thread** with its own scope.

**No conflict** — Dexie does not register a service worker. The Serwist service worker caches network requests (HTML, CSS, JS, API responses) without touching IndexedDB.

**Caching strategy for Supabase API calls:** Configure Serwist's `runtimeCaching` to **bypass** Supabase API routes (`/rest/v1/`, `auth.supabase.co`). Dexie is the offline data store; the service worker should not cache Supabase API responses or it will return stale data.

```typescript
// In app/sw.ts — exclude Supabase from SW caching
runtimeCaching: [
  {
    matcher: ({ url }) => url.hostname.includes('supabase.co'),
    handler: 'NetworkOnly', // Dexie handles offline, not SW cache
  },
  ...defaultCache, // Cache everything else
]
```

---

## Updated `next.config.ts` Shape

```typescript
import { withSerwist } from '@serwist/turbopack'
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  // existing config
}

export default withSerwist(nextConfig)
```

Note: `withSerwist` from `@serwist/turbopack` wraps the config — it does NOT use the `withSerwistInit({ swSrc, swDest })` pattern that `@serwist/next` uses. The Turbopack integration discovers the service worker differently.

---

## `tsconfig.json` Addition Required

Add `"webworker"` to lib for service worker types:

```json
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext", "webworker"]
  }
}
```

---

## Icon Sizes Required for PWA

The following icon files must exist in `public/icons/`:

| File | Size | Purpose |
|------|------|---------|
| `icon-72x72.png` | 72×72 | Android legacy |
| `icon-96x96.png` | 96×96 | Android |
| `icon-128x128.png` | 128×128 | Chrome Web Store |
| `icon-144x144.png` | 144×144 | Windows tile |
| `icon-152x152.png` | 152×152 | iOS |
| `icon-192x192.png` | 192×192 | Android home screen (required) |
| `icon-384x384.png` | 384×384 | Android splash |
| `icon-512x512.png` | 512×512 | App store / splash (required) |
| `icon-maskable-192x192.png` | 192×192 | Android adaptive icon |
| `icon-maskable-512x512.png` | 512×512 | Android adaptive icon |
| `apple-touch-icon.png` | 180×180 | iOS home screen |
| `favicon.ico` | 16+32+48 | Browser tab |

`@vite-pwa/assets-generator` generates all of these from a single source image (SVG recommended, high-res PNG minimum 512×512).

---

## Confidence Assessment

| Area | Confidence | Source |
|------|------------|--------|
| `@serwist/turbopack` is correct for Next.js 16 | HIGH | Serwist example repo uses `next: "16.1.6"` exactly; Next.js 16 source confirms Turbopack as default |
| Next.js 16 uses Turbopack by default | HIGH | `node_modules/next/dist/lib/bundler.js` source code verified |
| `esbuild` peer dep satisfied | HIGH | `node_modules/esbuild/package.json` shows v0.27.3, satisfies `>=0.25.0 <1.0.0` |
| Built-in `app/manifest.ts` works | HIGH | `MetadataRoute.Manifest` type confirmed in installed Next.js 16.1.6 |
| `@vite-pwa/assets-generator` for icons | HIGH | Official docs, last updated Oct 2025 |
| Dexie + SW coexistence is safe | HIGH | Dexie is main-thread only; no shared state with SW |
| `withSerwist` wrapping pattern for Turbopack | HIGH | Official example `next-turbo-basic/next.config.mjs` verified |

---

## Sources

| Source | Type | Used For |
|--------|------|---------|
| `node_modules/next/dist/lib/bundler.js` | Source code (HIGH) | Confirmed Turbopack default |
| `https://github.com/serwist/serwist/tree/main/examples/next-turbo-basic` | Official example (HIGH) | @serwist/turbopack setup |
| `https://registry.npmjs.org/@serwist/turbopack` | npm registry (HIGH) | Version, deps, peer deps |
| `https://nextjs.org/docs/app/guides/progressive-web-apps` | Official docs (HIGH) | Next.js manifest approach |
| `node_modules/next/dist/lib/metadata/types/manifest-types.d.ts` | Source code (HIGH) | MetadataRoute.Manifest type |
| npm download stats (api.npmjs.org) | npm registry (HIGH) | Library adoption comparison |
| `node_modules/lucide-react/package.json` | Source code (HIGH) | Tree-shaking, version |
