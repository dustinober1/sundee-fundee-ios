# Phase 6: PWA Foundation - Research

**Researched:** 2026-02-20
**Domain:** Next.js App Router PWA (manifest, icons, iOS meta tags, middleware, Playwright)
**Confidence:** HIGH

---

## Summary

Phase 6 installs the PWA foundation: a web app manifest, a complete icon set, iOS `<head>` meta tags, middleware exclusions for PWA static files, and a Playwright guard (`serviceWorkers: 'block'`). **No service worker is introduced in this phase** — that is Phase 7.

The standard approach uses Next.js App Router's native metadata APIs throughout — `src/app/manifest.ts` for the manifest, `Metadata.appleWebApp` + `Metadata.icons` for iOS tags, and `Metadata.other` for the one tag Next.js generates with the wrong prefix. Sharp (already available in `node_modules` as a Next.js transitive dep) generates PNG icons from a programmatically drawn SVG source; no external icon file exists today.

**Primary recommendation:** Use Next.js App Router's built-in metadata pipeline for manifest and meta tags. Generate icons with Sharp at build time via a one-off script (`scripts/generate-icons.mjs`). Update middleware matcher regex to exclude `/manifest.json`, `/sw.js`, and `/workbox-*.js` before they are served.

---

## User Constraints

No `CONTEXT.md` exists for this phase. All decisions are at Claude's discretion, subject to the locked decisions in `STATE.md` and the phase description:

| Locked decision | Value |
|----------------|-------|
| Manifest `name` | `"Sundee-Fundee"` |
| Manifest `short_name` | `"SundeeFundee"` (12 chars, no hyphen) |
| Manifest `display` | `"standalone"` |
| Manifest `start_url` | `"/dashboard"` |
| `apple-mobile-web-app-title` | `"SundeeFundee"` |
| Playwright guard | `serviceWorkers: 'block'` in `playwright.config.ts` |
| Icon sizes | 192×192, 192×192 maskable, 512×512, 180×180 apple-touch-icon |

---

## Standard Stack

No new runtime dependencies are needed. Everything is already installed.

### Core (already in project)
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Next.js App Router | 16.1.6 | `manifest.ts` metadata route; `Metadata` export | Zero config, typed, SSR-safe |
| Sharp | 0.34.5 (transitive) | PNG icon generation from SVG | Fastest Node.js image processing; already in node_modules via Next.js |
| Playwright | 1.58.2 | `serviceWorkers: 'block'` guard | Already installed; typed option confirmed |

### New dev dependency needed
| Tool | Why |
|------|-----|
| `sharp` — add to `devDependencies` explicitly | It's a transitive dep of Next.js but not declared directly. Icon generation script needs it reliably. |

**Installation (one addition):**
```bash
npm install --save-dev sharp
```

### What NOT to install
- `next-pwa` — incompatible with Turbopack (Next.js 16 default)
- `@serwist/next` — same incompatibility (Phase 7 uses `@serwist/turbopack`)
- `pwa-asset-generator` — unnecessary, sharp covers the need
- Any manifest validator library — DevTools validation is sufficient

---

## Architecture Patterns

### Project Structure Changes
```
src/app/
├── manifest.ts          # NEW — Next.js App Router metadata route → /manifest.json
├── layout.tsx           # MODIFY — add Metadata.appleWebApp, icons, other
└── (existing routes)

public/
├── icons/               # NEW folder
│   ├── icon-192.png     # Android standard
│   ├── icon-192-maskable.png  # Android safe zone
│   ├── icon-512.png     # Chrome install prompt
│   └── apple-touch-icon.png  # 180×180, iOS home screen
└── (existing files)

scripts/
└── generate-icons.mjs   # NEW — Sharp icon generation, run once
```

### Pattern 1: Next.js App Router `manifest.ts`

**What:** A `src/app/manifest.ts` file exporting a default function. Next.js auto-routes it to `/manifest.json`.
**When to use:** Always for Next.js App Router PWA manifests.

```typescript
// src/app/manifest.ts
import type { MetadataRoute } from 'next'

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Sundee-Fundee',
    short_name: 'SundeeFundee',
    description: 'Track your workouts and fitness goals',
    start_url: '/dashboard',
    display: 'standalone',
    background_color: '#ffffff',
    theme_color: '#171717',
    icons: [
      {
        src: '/icons/icon-192.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: '/icons/icon-192-maskable.png',
        sizes: '192x192',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/icons/icon-512.png',
        sizes: '512x512',
        type: 'image/png',
      },
    ],
  }
}
```

**Verified:** `MetadataRoute.Manifest` type in `node_modules/next/dist/lib/metadata/types/manifest-types.d.ts` — `purpose: 'any' | 'maskable' | 'monochrome'` supported. Next.js serves this at `/manifest.json` via `is-metadata-route.js` which has `MANIFEST_JSON_REGEX = /^[\\/]manifest\.json$/`.

### Pattern 2: iOS Meta Tags in `layout.tsx`

**What:** `Metadata.appleWebApp` and `Metadata.icons.apple` in root layout.
**Critical gotcha:** `appleWebApp.capable: true` generates `mobile-web-app-capable` (W3C tag), NOT `apple-mobile-web-app-capable` (the Apple-specific tag that the success criteria checks for). Use `Metadata.other` for the Apple-specific version.

```typescript
// src/app/layout.tsx
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Sundee-Fundee',
  description: 'Track your workouts and fitness goals',
  manifest: '/manifest.json',
  icons: {
    apple: [
      { url: '/icons/apple-touch-icon.png', sizes: '180x180', type: 'image/png' },
    ],
  },
  appleWebApp: {
    capable: true,                        // → <meta name="mobile-web-app-capable">
    title: 'SundeeFundee',               // → <meta name="apple-mobile-web-app-title">
    statusBarStyle: 'black-translucent', // → <meta name="apple-mobile-web-app-status-bar-style">
  },
  other: {
    // appleWebApp.capable generates 'mobile-web-app-capable' (W3C), NOT 'apple-mobile-web-app-capable'
    // The success criteria requires the apple-specific version — add it explicitly:
    'apple-mobile-web-app-capable': 'yes',
  },
}
```

**Verified:** `AppleWebAppMeta` function in `node_modules/next/dist/lib/metadata/generate/basic.js` confirms `capable` generates `mobile-web-app-capable` (line: `name: 'mobile-web-app-capable'`). The `apple-mobile-web-app-title` and `apple-mobile-web-app-status-bar-style` tags ARE generated correctly by Next.js.

### Pattern 3: Icon Generation Script

**What:** One-off Node.js script using Sharp to create PNG icons from SVG.
**When to use:** No source image exists — generate programmatically.

```javascript
// scripts/generate-icons.mjs
import sharp from 'sharp'
import { mkdir } from 'fs/promises'
import { fileURLToPath } from 'url'
import { join, dirname } from 'path'

const __dirname = dirname(fileURLToPath(import.meta.url))
const publicDir = join(__dirname, '..', 'public', 'icons')

await mkdir(publicDir, { recursive: true })

// Source SVG: dark background (#171717), white "SF" monogram
const svgSource = `
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="80" fill="#171717"/>
  <text x="256" y="340" font-family="system-ui, -apple-system, sans-serif"
    font-size="220" font-weight="700" fill="white" text-anchor="middle">SF</text>
</svg>
`

const svgBuffer = Buffer.from(svgSource)

// Standard 192×192
await sharp(svgBuffer).resize(192, 192).png().toFile(join(publicDir, 'icon-192.png'))

// Maskable 192×192 (safe zone = inner 75%; icon fills full bleed)
// Maskable icons should fill the entire canvas with no padding
const svgMaskable = `
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <rect width="512" height="512" fill="#171717"/>
  <text x="256" y="340" font-family="system-ui, -apple-system, sans-serif"
    font-size="200" font-weight="700" fill="white" text-anchor="middle">SF</text>
</svg>
`
await sharp(Buffer.from(svgMaskable)).resize(192, 192).png().toFile(join(publicDir, 'icon-192-maskable.png'))

// 512×512
await sharp(svgBuffer).resize(512, 512).png().toFile(join(publicDir, 'icon-512.png'))

// 180×180 apple-touch-icon (iOS uses square icons, no rounded corners applied by us)
await sharp(svgBuffer).resize(180, 180).png().toFile(join(publicDir, 'apple-touch-icon.png'))

console.log('Icons generated in public/icons/')
```

**Run command:**
```bash
node scripts/generate-icons.mjs
```

### Pattern 4: Middleware Matcher Update

**What:** Extend the negative lookahead to exclude PWA static files from Supabase auth processing.

```typescript
// middleware.ts — updated config.matcher only
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|manifest\\.json|sw\\.js|workbox-.*\\.js|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

**Why:** The current matcher excludes image extensions but NOT `manifest.json`, `sw.js`, or `workbox-*.js`. These JS/JSON files pass through `supabase.auth.getUser()`, adding unnecessary auth latency and causing potential 401 responses for the manifest. Phase 7 will serve `sw.js` from `public/` — excluding it now future-proofs the middleware before the SW is introduced.

**Verified:** Current matcher in `middleware.ts` line 42: `'/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'`

### Pattern 5: Playwright `serviceWorkers: 'block'`

**What:** Add `serviceWorkers: 'block'` to the global `use` config in `playwright.config.ts`.
**Purpose:** Prevents any future service worker from intercepting test network requests. Safe to add before any SW exists.

```typescript
// playwright.config.ts — add to use block
use: {
  baseURL: 'http://localhost:3000',
  trace: 'on-first-retry',
  serviceWorkers: 'block',  // ADD THIS
},
```

**Verified:** `serviceWorkers?: "allow"|"block"` confirmed in `node_modules/playwright-core/types/types.d.ts`. Playwright 1.58.2 is installed.

### Anti-Patterns to Avoid
- **Putting `manifest.json` in `public/`:** Next.js App Router's `src/app/manifest.ts` is the canonical approach — it's typed, served with correct `Content-Type: application/manifest+json`, and can be dynamic. A static `public/manifest.json` works but loses TypeScript checking.
- **Using `metadata.manifest` without also linking to the manifest URL in the HTML head:** The `manifest: '/manifest.json'` field in `Metadata` export is what triggers `<link rel="manifest" href="/manifest.json">` in the `<head>`. Without it, the manifest file exists but is never referenced.
- **Not using `purpose: 'maskable'` for the maskable icon:** Without this, Android uses the standard icon in adaptive icon contexts (may get padded to white/black square).
- **Using `appleWebApp: true` (boolean shorthand):** This generates `mobile-web-app-capable` but not `apple-mobile-web-app-title` or `statusBarStyle`. Always use the object form.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Manifest route | Custom Next.js API route returning JSON | `src/app/manifest.ts` with `MetadataRoute.Manifest` | Next.js serves with correct MIME type, no extra code |
| Apple meta tags | Raw `<meta>` in `<head>` JSX | `Metadata.appleWebApp` + `Metadata.other` in layout | Type-safe, SSR-correct, no hydration issues |
| Apple touch icon link | Manual `<link rel="apple-touch-icon">` | `Metadata.icons.apple` array | Generated at correct location in `<head>` |
| Icon PNG files | Manual creation in design tool | Sharp script from SVG | Reproducible, scriptable, no binary files in git history |

---

## Common Pitfalls

### Pitfall 1: `mobile-web-app-capable` vs `apple-mobile-web-app-capable`
**What goes wrong:** `appleWebApp: { capable: true }` generates `<meta name="mobile-web-app-capable">` (W3C spec), not `<meta name="apple-mobile-web-app-capable">` (Apple legacy). DevTools/automated checks that look for the `apple-` prefix will fail.
**Why it happens:** Next.js follows the W3C standard. The Apple-specific tag predates the standard.
**How to avoid:** Add `other: { 'apple-mobile-web-app-capable': 'yes' }` to the `Metadata` export. Both tags can coexist.
**Warning signs:** iOS home screen "Add to Home Screen" works but the success criteria grep for `apple-mobile-web-app-capable` returns nothing.

### Pitfall 2: Manifest served through Supabase auth
**What goes wrong:** `manifest.json` returns 401/redirect when the user is not authenticated, breaking the install prompt in Chrome DevTools and causing Android "Add to Home Screen" failures.
**Why it happens:** The current middleware matcher only excludes image extensions, not `.json` files by path.
**How to avoid:** Add `manifest\\.json` to the negative lookahead in the matcher regex BEFORE testing in DevTools.
**Warning signs:** Chrome DevTools → Application → Manifest shows "Fetching manifest..." indefinitely, or manifest request in Network tab shows 302 redirect to `/auth`.

### Pitfall 3: Maskable icon safe zone violation
**What goes wrong:** Icon artwork gets clipped on Android adaptive icons because content extends into the outer 25% of the canvas.
**Why it happens:** Maskable icons are cropped to a circle/squircle — only the inner 75% "safe zone" is guaranteed visible.
**How to avoid:** Ensure the "SF" text in the maskable variant fits within the central 75% of the 192×192 canvas (≤144px square centered).
**Warning signs:** On Android, the icon appears clipped or the letter gets cut off at the edges.

### Pitfall 4: `start_url: "/dashboard"` requires auth
**What goes wrong:** PWA opens to an auth redirect instead of the dashboard when the user is not logged in.
**Why it happens:** `/dashboard` is protected by Supabase middleware. On a fresh install or after session expiry, the user lands on the login page, not the dashboard.
**How to avoid:** This behavior is intentional and acceptable — the middleware handles the redirect gracefully. Document it. Do NOT change `start_url` to `/` as that's outside this phase's scope.
**Warning signs:** Not a bug — it's expected behavior. The manifest is still valid.

### Pitfall 5: `short_name` length
**What goes wrong:** Android home screen truncates names longer than ~12 characters.
**Why it happens:** Display area under app icons is small on Android.
**How to avoid:** `short_name: "SundeeFundee"` = 12 chars exactly. `"Sundee-Fundee"` = 13 chars — do NOT use the hyphenated form for `short_name`.
**Warning signs:** Verified: `"SundeeFundee".length === 12` ✓

### Pitfall 6: Sharp not in `devDependencies`
**What goes wrong:** Icon generation script fails in CI or on fresh installs if sharp isn't declared as a dependency.
**Why it happens:** Sharp is currently a transitive dep of Next.js (for image optimization), not directly declared.
**How to avoid:** Run `npm install --save-dev sharp` to make the dependency explicit.
**Warning signs:** `generate-icons.mjs` fails with "Cannot find module 'sharp'" after `npm ci`.

---

## Code Examples

### Complete `manifest.ts`
```typescript
// src/app/manifest.ts
// Source: Next.js App Router docs — special file: manifest.ts
import type { MetadataRoute } from 'next'

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Sundee-Fundee',
    short_name: 'SundeeFundee',
    description: 'Track your workouts and fitness goals',
    start_url: '/dashboard',
    display: 'standalone',
    background_color: '#ffffff',
    theme_color: '#171717',
    icons: [
      {
        src: '/icons/icon-192.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: '/icons/icon-192-maskable.png',
        sizes: '192x192',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/icons/icon-512.png',
        sizes: '512x512',
        type: 'image/png',
      },
    ],
  }
}
```

### Updated `layout.tsx` metadata export
```typescript
// src/app/layout.tsx — metadata section only
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Sundee-Fundee',
  description: 'Track your workouts and fitness goals',
  manifest: '/manifest.json',
  icons: {
    apple: [
      { url: '/icons/apple-touch-icon.png', sizes: '180x180', type: 'image/png' },
    ],
  },
  appleWebApp: {
    capable: true,
    title: 'SundeeFundee',
    statusBarStyle: 'black-translucent',
  },
  other: {
    // Next.js appleWebApp.capable generates 'mobile-web-app-capable' (W3C)
    // but NOT 'apple-mobile-web-app-capable' (Apple-specific).
    // Both are needed to satisfy the success criteria.
    'apple-mobile-web-app-capable': 'yes',
  },
}
```

### Updated `middleware.ts` matcher
```typescript
// middleware.ts — config export only
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|manifest\\.json|sw\\.js|workbox-.*\\.js|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

### Updated `playwright.config.ts` use block
```typescript
// playwright.config.ts — use block only
use: {
  baseURL: 'http://localhost:3000',
  trace: 'on-first-retry',
  serviceWorkers: 'block',
},
```

### Theme color values
The app uses a neutral black/white design from `globals.css`:
- Light mode background: `oklch(1 0 0)` = `#ffffff`
- Light mode foreground/primary: `oklch(0.145 0 0)` ≈ `#171717`
- Use `theme_color: '#171717'`, `background_color: '#ffffff'`

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| `public/manifest.json` static file | `src/app/manifest.ts` metadata route | Typed, MIME-correct, can be dynamic |
| Manual `<meta>` tags in JSX head | `Metadata.appleWebApp` in layout.tsx | Type-safe, SSR-correct |
| `next-pwa` or `workbox-webpack-plugin` | `@serwist/turbopack` (Phase 7) | Required for Next.js 16 Turbopack |

---

## Open Questions

1. **Source icon design**
   - What we know: No source SVG/PNG exists; Sharp can create one programmatically
   - What's unclear: Brand prefers a specific icon design vs a simple monogram "SF"
   - Recommendation: Use "SF" monogram on dark background (`#171717`) — matches app's neutral design; can be replaced later. This is fully within Claude's discretion.

2. **`theme_color` exact hex**
   - What we know: App uses `oklch(0.145 0 0)` ≈ `#171717` for primary/foreground
   - What's unclear: Exact conversion of oklch to hex (oklch uses a wider gamut)
   - Recommendation: Use `#171717` — visually equivalent for status bar coloring purposes

3. **`start_url` offline behavior**
   - What we know: `/dashboard` redirects to `/auth/login` when unauthenticated
   - What's unclear: Whether to document this as acceptable or file a future task
   - Recommendation: Document in PLAN as expected behavior; Phase 7 SW can serve an offline page

---

## Sources

### Primary (HIGH confidence)
- `node_modules/next/dist/lib/metadata/types/manifest-types.d.ts` — full Manifest type verified
- `node_modules/next/dist/lib/metadata/generate/basic.js` — AppleWebAppMeta function confirmed; `capable` generates `mobile-web-app-capable` (not `apple-mobile-web-app-capable`)
- `node_modules/next/dist/lib/metadata/generate/icons.js` — apple icon generates `rel="apple-touch-icon"` confirmed
- `node_modules/next/dist/lib/metadata/is-metadata-route.js` — `MANIFEST_JSON_REGEX` confirms manifest.ts routes to `/manifest.json`
- `node_modules/playwright-core/types/types.d.ts` — `serviceWorkers?: "allow"|"block"` confirmed
- `middleware.ts` — current matcher verified (excludes images, NOT manifest/sw)
- `playwright.config.ts` — current use block verified (no serviceWorkers)
- `src/app/layout.tsx` — current metadata export verified
- `public/` — confirmed no icons exist yet

### Secondary (MEDIUM confidence)
- `node_modules/sharp/package.json` v0.34.5 — Sharp available in node_modules; not in devDependencies (needs explicit install)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from node_modules source
- Architecture: HIGH — Next.js manifest.ts pattern confirmed from internal metadata route handler
- Pitfalls: HIGH — `capable` tag name discrepancy confirmed from source code inspection
- Icon generation: HIGH — Sharp in node_modules, API is stable and well-documented

**Research date:** 2026-02-20
**Valid until:** 2026-03-22 (stable Next.js APIs; 30 days)
