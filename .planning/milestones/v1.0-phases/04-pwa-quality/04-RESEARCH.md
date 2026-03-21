# Phase 4: PWA Quality - Research

**Researched:** 2026-03-21
**Domain:** Progressive Web App (PWA) — icons, service worker offline fallback, install prompts, Lighthouse audit
**Confidence:** HIGH

## Summary

Phase 4 has a well-defined scope: generate real icon PNGs, wire an offline fallback through workbox, add a cross-platform install prompt, and verify a green Lighthouse PWA audit. The manifest is already declared in `vite.config.ts` with the correct icon paths — they just need the files to exist. Workbox (v7.4.0) is already installed and configured; `navigateFallback` requires a single line addition. The install prompt splits into two separate code paths: Android uses the `beforeinstallprompt` Web API and iOS uses user-agent + `navigator.standalone` detection.

The SVG favicon uses a complex multi-layered design with display-p3 color space and Gaussian blur filters. The safe conversion approach is `sharp` with `fit: 'contain'` + background fill — this guarantees the icon aspect ratio is preserved and the navy background fills any gaps. The maskable variant should be a separate 512px entry (same file is acceptable per the context decision) with the `purpose: 'maskable'` property — Lighthouse and Chrome specifically check that the `purpose` values are declared separately, not combined as `any maskable`.

**Primary recommendation:** Use `sharp` in a `scripts/generate-icons.mjs` file to produce all PNGs; configure workbox `navigateFallback` in `vite.config.ts`; implement a single `useInstallPrompt` hook that handles both Android and iOS; write a self-contained `offline.html` with inline styles matching the Art Deco theme.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Generate all PNG icons from existing `pwa/public/favicon.svg`
- Output: 192px, 512px PNGs in `pwa/public/icons/` directory
- Also generate 180px `apple-touch-icon.png` in `pwa/public/`
- Background color: navy (#0D1A40) — matches manifest theme_color
- Maskable icon: same artwork with ~10% auto-padding for safe zone (no separate design)
- Static `offline.html` file in `pwa/public/` — pre-cached by service worker
- Art Deco themed: navy (#0D1A40) background, cream (#F4F0DF) text, orange (#F2731A) accent button
- Content: app logo, "You're currently offline" message, "Check your connection and try again"
- "Try Again" button calls `window.location.reload()`
- Configure workbox `navigateFallback` in vite.config.ts to serve offline.html
- **Android:** Capture `beforeinstallprompt` event, defer it, show prompt after first workout completion
- **iOS Safari:** Non-blocking bottom banner with share icon instruction ("Tap [↑] then Add to Home Screen"), dismissible
- **Dismissal behavior:** Shows once per session (sessionStorage). Reappears on next session.
- **Standalone detection:** Suppress prompt entirely if `display-mode: standalone` matches (already installed)
- **Trigger:** After first workout complete (meaningful engagement moment)
- Target: all green PWA installability checks (manifest, service worker, HTTPS, icons)
- Fix only PWA-specific issues — performance, accessibility, and SEO issues belong in later phases
- Manual Lighthouse audit against deployed URL — no Lighthouse CI in GitHub Actions

### Claude's Discretion
- Icon generation tooling (sharp, canvas, or manual conversion)
- Exact workbox configuration for navigateFallback and offline routing
- Offline page HTML/CSS implementation details
- Install prompt React component structure (hook vs context vs component)
- Any Lighthouse PWA fixes not covered by the specific decisions above

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PWA-01 | Production 192px and 512px PNG icons on disk matching manifest declarations | sharp SVG-to-PNG script with navy background fill; `fit: 'contain'` preserves aspect ratio |
| PWA-02 | Lighthouse PWA audit passes installability, accessibility, and performance checks | Manifest already has required fields; icons + service worker are the remaining gaps |
| PWA-03 | Custom branded offline fallback page served by service worker | workbox `navigateFallback: '/offline.html'` + `offline.html` in `globPatterns` |
| PWA-04 | "Add to Home Screen" install prompt on Android; instructional modal on iOS | `beforeinstallprompt` hook for Android; user-agent + `navigator.standalone` for iOS |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| vite-plugin-pwa | 1.2.0 (installed) | Service worker generation, manifest injection | Already in project; wraps workbox-build |
| workbox-core / workbox-routing | 7.4.0 (installed) | Runtime caching, navigateFallback, offline routing | Bundled by vite-plugin-pwa; no separate install needed |
| sharp | ^0.34.x (to install) | SVG-to-PNG conversion with resize and background fill | Fastest Node image processing lib; handles display-p3 SVG |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| vitest + @testing-library/react | 4.1.0 / 16.3.2 (installed) | Component tests for install prompt hook | Testing `useInstallPrompt` hook logic in jsdom |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| sharp | canvas (node-canvas) | canvas requires Cairo native binaries; harder to install in CI. sharp uses libvips and has better CI support |
| sharp | Inkscape CLI / ImageMagick | Not available in standard CI; extra system dependency |
| Custom hook | react-ios-pwa-prompt npm package | Package is stale (v2.0.6, last published ~1 year ago); custom hook is <50 lines and avoids the dependency |

**Installation (one-time, dev-only):**
```bash
# In repo root (for the generate-icons script)
npm install --save-dev sharp
# OR install inside pwa/ if preferred
cd pwa && npm install --save-dev sharp
```

## Architecture Patterns

### Recommended Project Structure
```
pwa/
├── public/
│   ├── favicon.svg               # Source SVG (existing)
│   ├── apple-touch-icon.png      # 180x180 (to generate)
│   ├── offline.html              # Branded offline fallback (to create)
│   └── icons/
│       ├── icon-192.png          # Standard 192x192 (to generate)
│       └── icon-512.png          # Standard + maskable 512x512 (to generate)
├── src/
│   └── hooks/                    # Create this directory
│       └── useInstallPrompt.ts   # Cross-platform install prompt hook
scripts/
└── generate-icons.mjs            # Node script to produce PNGs from SVG
```

### Pattern 1: Icon Generation Script (sharp)

**What:** A standalone Node ESM script that reads `pwa/public/favicon.svg`, uses `sharp` to resize + fill background, and writes PNGs to `pwa/public/icons/` and `pwa/public/`.

**When to use:** Run once manually; re-run only if the source SVG changes.

**Example:**
```javascript
// scripts/generate-icons.mjs
// Source: https://sharp.pixelplumbing.com/api-resize/
import sharp from 'sharp';
import { mkdir } from 'fs/promises';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const svgPath = resolve(__dirname, '../pwa/public/favicon.svg');
const iconsDir = resolve(__dirname, '../pwa/public/icons');
const publicDir = resolve(__dirname, '../pwa/public');
const NAVY = { r: 13, g: 26, b: 64, alpha: 1 }; // #0D1A40

await mkdir(iconsDir, { recursive: true });

// Standard icons
for (const size of [192, 512]) {
  await sharp(svgPath)
    .resize(size, size, { fit: 'contain', background: NAVY })
    .flatten({ background: NAVY })
    .png()
    .toFile(resolve(iconsDir, `icon-${size}.png`));
  console.log(`Generated icon-${size}.png`);
}

// Apple touch icon (180px)
await sharp(svgPath)
  .resize(180, 180, { fit: 'contain', background: NAVY })
  .flatten({ background: NAVY })
  .png()
  .toFile(resolve(publicDir, 'apple-touch-icon.png'));
console.log('Generated apple-touch-icon.png');
```

**Run:** `node scripts/generate-icons.mjs`

**Maskable note:** The context decision uses the same 512px file for maskable purpose. Since the SVG content occupies roughly the center of the icon (the lightning bolt shape is smaller than the canvas), the navy background provides natural padding. The maskable safe zone requires the icon's artwork to stay within the central 80% circle (radius = 40% of width). Verify at https://maskable.app after generation.

### Pattern 2: workbox navigateFallback Configuration

**What:** Add `navigateFallback` to the existing workbox config in `vite.config.ts` so the service worker intercepts failed navigation requests and serves the cached `offline.html`.

**When to use:** Any time the user navigates to a route while offline.

**Example:**
```typescript
// Source: https://vite-pwa-org.netlify.app/workbox/generate-sw
VitePWA({
  registerType: 'autoUpdate',
  includeAssets: ['favicon.svg', 'apple-touch-icon.png', 'offline.html'],
  manifest: { /* existing manifest unchanged */ },
  workbox: {
    globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
    navigateFallback: '/offline.html',
    navigateFallbackDenylist: [/^\/api\//],  // exclude API routes from fallback
    runtimeCaching: [ /* existing entries unchanged */ ],
  },
})
```

**Critical detail:** `offline.html` must appear in BOTH `includeAssets` AND `globPatterns` to be pre-cached. The `includeAssets` tells VitePWA to copy it; `globPatterns` includes it in the precache manifest. The current `globPatterns` already matches `html` files so `offline.html` in `public/` will be picked up.

### Pattern 3: useInstallPrompt Hook

**What:** A single custom React hook that captures `beforeinstallprompt` (Android) and detects iOS Safari conditions, returning state and handlers for each platform.

**When to use:** Mount hook in a layout or top-level component; show install UI when workout completes.

**Dismissal note:** Context says sessionStorage (once per session). Use `sessionStorage.setItem('installPromptDismissed', '1')` for the dismissed flag.

**Standalone check:** Use `window.matchMedia('(display-mode: standalone)').matches` — more reliable than `navigator.standalone` (which is iOS-only). Also check `navigator.standalone` for iOS Safari compatibility.

**Example:**
```typescript
// Source: https://web.dev/learn/pwa/installation-prompt
// pwa/src/hooks/useInstallPrompt.ts
import { useState, useEffect } from 'react';

type InstallPromptState = {
  androidPrompt: BeforeInstallPromptEvent | null;
  isIOS: boolean;
  isStandalone: boolean;
  isDismissed: boolean;
  triggerAndroid: () => Promise<void>;
  dismiss: () => void;
};

// BeforeInstallPromptEvent is not in standard lib.dom.d.ts
interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

function detectIOS(): boolean {
  const ua = window.navigator.userAgent;
  return /iPad|iPhone|iPod/.test(ua) && !(window as unknown as { MSStream?: unknown }).MSStream;
}

function isAlreadyInstalled(): boolean {
  return (
    window.matchMedia('(display-mode: standalone)').matches ||
    (navigator as unknown as { standalone?: boolean }).standalone === true
  );
}

export function useInstallPrompt(): InstallPromptState {
  const [androidPrompt, setAndroidPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isDismissed, setIsDismissed] = useState<boolean>(
    () => sessionStorage.getItem('installPromptDismissed') === '1'
  );
  const isStandalone = isAlreadyInstalled();
  const isIOS = detectIOS() && !isStandalone;

  useEffect(() => {
    if (isStandalone) return;
    const handler = (e: Event) => {
      e.preventDefault();
      setAndroidPrompt(e as BeforeInstallPromptEvent);
    };
    window.addEventListener('beforeinstallprompt', handler);
    return () => window.removeEventListener('beforeinstallprompt', handler);
  }, [isStandalone]);

  async function triggerAndroid() {
    if (!androidPrompt) return;
    await androidPrompt.prompt();
    const { outcome } = await androidPrompt.userChoice;
    if (outcome === 'dismissed') dismiss();
    setAndroidPrompt(null);
  }

  function dismiss() {
    sessionStorage.setItem('installPromptDismissed', '1');
    setIsDismissed(true);
  }

  return { androidPrompt, isIOS, isStandalone, isDismissed, triggerAndroid, dismiss };
}
```

**Install prompt component integration:** The hook is consumed in `WorkoutSession.tsx` and `ProgramSession.tsx` at the workout completion point (`handleFinish` / `handleComplete`), or in a wrapper component rendered by `AppLayout.tsx`.

### Pattern 4: Offline Page HTML

**What:** A self-contained `offline.html` with all CSS inline (no external dependencies) so it works even when all other assets are uncached.

**When to use:** Served by workbox navigateFallback when a navigation request fails offline.

```html
<!-- pwa/public/offline.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Offline — Sundee Fundee</title>
  <style>
    /* All CSS must be inline — no external files */
    body {
      margin: 0;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      background-color: #0D1A40;
      color: #F4F0DF;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      text-align: center;
      padding: 2rem;
      box-sizing: border-box;
    }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    p  { font-size: 1rem; opacity: 0.8; margin-bottom: 2rem; }
    button {
      background-color: #F2731A;
      color: #F4F0DF;
      border: none;
      padding: 0.75rem 2rem;
      border-radius: 4px;
      font-size: 1rem;
      cursor: pointer;
    }
    button:hover { opacity: 0.9; }
  </style>
</head>
<body>
  <h1>You're currently offline</h1>
  <p>Check your connection and try again</p>
  <button onclick="window.location.reload()">Try Again</button>
</body>
</html>
```

**Important:** No external image src, no CDN fonts. The logo SVG can be inlined as a `<svg>` element if needed.

### Pattern 5: Manifest Icon Array — Separate purpose entries

**What:** Two separate icon entries for `any` and `maskable` in the vite.config.ts manifest.

**Why:** Combining `purpose: 'any maskable'` is discouraged by the Chrome team — it causes poor padding on one platform or the other. Lighthouse requires at least one maskable icon.

```typescript
// vite.config.ts manifest icons (corrected)
icons: [
  { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
  { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png' },
  { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
]
```

The current config already has this exact pattern — leave as-is.

### Anti-Patterns to Avoid

- **purpose: 'any maskable' on a single icon entry:** Lighthouse reports a warning; browsers apply incorrect padding. Use two separate entries.
- **Referencing offline.html in navigateFallback before the file exists:** Build will succeed but service worker will cache a 404. The file must be in `public/` before building.
- **External CSS/fonts in offline.html:** If the browser is offline, no external resources load. Everything must be inline.
- **Using localStorage for sessionStorage use case:** Context says "once per session" — use `sessionStorage`, not `localStorage`.
- **Calling `prompt()` more than once on a captured BeforeInstallPromptEvent:** The API only allows one call. Set to null after calling.
- **Calling `isAlreadyInstalled()` only on mount:** The display-mode can change if user opens from home screen in a new tab. Re-evaluate on mount is fine for this use case.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SVG-to-PNG conversion at multiple sizes | Custom canvas render loop | `sharp` with `.resize()` + `.flatten()` | Handles display-p3 color space, Gaussian blur filters in the SVG, alpha channel, and CI environments without a headless browser |
| Service worker offline routing | Custom fetch event handler | workbox `navigateFallback` (already in vite-plugin-pwa) | Workbox handles cache versioning, precache manifest updates, and edge cases like opaque responses |
| Detecting display-mode standalone | Custom `localStorage` flag or URL param | `window.matchMedia('(display-mode: standalone)').matches` | OS-native API; no stored state can go stale |

**Key insight:** The entire workbox layer (runtime caching, navigateFallback, precache manifest) is already generated by vite-plugin-pwa — the only work is adding the `navigateFallback` config key and ensuring the offline.html file exists.

## Common Pitfalls

### Pitfall 1: offline.html not pre-cached by workbox
**What goes wrong:** `navigateFallback: '/offline.html'` is set, but the offline page returns a 404 when offline because workbox never cached it.
**Why it happens:** `offline.html` must be part of the precache manifest. By default, workbox's `globPatterns` in vite-plugin-pwa scans the `dist/` folder after build. If `offline.html` is not in `public/`, it won't be in `dist/`.
**How to avoid:** Place `offline.html` in `pwa/public/`. The existing `globPatterns: ['**/*.{js,css,html,...}']` will capture it. Also add `'offline.html'` to `includeAssets`.
**Warning signs:** After deploy, open DevTools → Application → Cache Storage → no entry for `/offline.html`.

### Pitfall 2: sharp failing on complex SVG with filters
**What goes wrong:** `sharp` produces a blank or partial PNG because the SVG uses `feGaussianBlur` filters, `color(display-p3 ...)` fill syntax, and `<mask>` elements.
**Why it happens:** Sharp uses libvips for SVG rendering (via librsvg). Some CSS-in-SVG color functions and complex filter graphs are not fully supported in all librsvg versions.
**How to avoid:** Verify the output PNG visually after generation. If the icon appears blank/incorrect, use `--density 144` equivalent (sharp automatically rasterizes at higher density). If librsvg parsing fails, fallback: render the SVG in a headless browser (Playwright) to PNG as a one-time operation, or simplify the SVG colors to hex values.
**Warning signs:** Generated PNG is all-black or shows only the base shape without gradient effects.

### Pitfall 3: beforeinstallprompt never fires
**What goes wrong:** The Android install prompt is never triggered because Chrome's installability criteria aren't met.
**Why it happens:** Chrome requires: valid manifest with name, start_url, display, and 192px + 512px icons that actually exist and return HTTP 200. If any icon file is missing or returns 404, the event won't fire.
**How to avoid:** Ensure icon files are deployed before testing. Check Chrome DevTools → Application → Manifest → "Add to Home Screen" installability errors.
**Warning signs:** Event listener attached but event never fires in Chrome Android or Chrome desktop (which also fires it).

### Pitfall 4: iOS prompt shows in standalone mode
**What goes wrong:** iOS users who already installed the app see the "Add to Home Screen" banner inside the installed app.
**Why it happens:** `navigator.standalone` is iOS Safari-specific. If the check is missing or wrong, it shows in all contexts.
**How to avoid:** Check both `window.matchMedia('(display-mode: standalone)').matches` AND `navigator.standalone === true` before rendering the iOS banner. The hook pattern above handles this.
**Warning signs:** Feedback from installed-app users seeing the install prompt.

### Pitfall 5: Lighthouse audit run against dev server, not production build
**What goes wrong:** Lighthouse shows "does not have a service worker" even though service workers are registered.
**Why it happens:** vite-plugin-pwa does NOT register a service worker in development mode by default (`registerType: 'autoUpdate'` only generates SW in production build).
**How to avoid:** Always run Lighthouse against the deployed production URL or `npx vite preview` after `npm run build`. Never against `npm run dev`.
**Warning signs:** Lighthouse shows PWA failures that contradict what the manifest says.

### Pitfall 6: maskable icon fails safe zone check
**What goes wrong:** Lighthouse or maskable.app shows artwork clipped outside the safe zone circle.
**Why it happens:** The SVG has content that extends to the edges (the lightning bolt shape in favicon.svg does reach near the SVG viewBox edges at some positions).
**How to avoid:** After generating the 512px icon, verify at https://maskable.app. If artwork is clipped, add explicit padding via sharp's `extend()` method or use `fit: 'contain'` with a larger effective area (e.g., resize to 410px and extend to 512px with navy background).
**Warning signs:** maskable.app preview shows visible cropping in any mask shape.

## Code Examples

### Full icon generation script
```javascript
// Source: https://sharp.pixelplumbing.com/api-resize/
// scripts/generate-icons.mjs
import sharp from 'sharp';
import { mkdir } from 'fs/promises';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SVG = resolve(__dirname, '../pwa/public/favicon.svg');
const ICONS = resolve(__dirname, '../pwa/public/icons');
const PUBLIC = resolve(__dirname, '../pwa/public');
const NAVY = { r: 13, g: 26, b: 64, alpha: 1 };

await mkdir(ICONS, { recursive: true });

const configs = [
  { size: 192, out: resolve(ICONS, 'icon-192.png') },
  { size: 512, out: resolve(ICONS, 'icon-512.png') },
  { size: 180, out: resolve(PUBLIC, 'apple-touch-icon.png') },
];

for (const { size, out } of configs) {
  await sharp(SVG)
    .resize(size, size, { fit: 'contain', background: NAVY })
    .flatten({ background: NAVY })
    .png()
    .toFile(out);
  console.log(`Generated ${out}`);
}
```

### workbox navigateFallback addition (vite.config.ts diff)
```typescript
// Source: https://vite-pwa-org.netlify.app/workbox/generate-sw
workbox: {
  globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
  navigateFallback: '/offline.html',        // ADD THIS LINE
  // navigateFallbackDenylist: [/^\/api\//], // optional: exclude API routes
  runtimeCaching: [
    // ... existing entries unchanged
  ],
},
```

### iOS detection for install banner
```typescript
// Source: https://web.dev/learn/pwa/installation-prompt
// MDN: https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeinstallprompt_event
function isIOSSafari(): boolean {
  const ua = window.navigator.userAgent;
  const isIOS = /iPad|iPhone|iPod/.test(ua);
  const isSafari = /Safari/.test(ua) && !/CriOS|FxiOS|OPiOS|mercury/.test(ua);
  return isIOS && isSafari;
}

function isStandalone(): boolean {
  return (
    window.matchMedia('(display-mode: standalone)').matches ||
    (navigator as { standalone?: boolean }).standalone === true
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `purpose: 'any maskable'` combined | Separate icon entries: `purpose: 'any'` and `purpose: 'maskable'` | Chrome guidance 2023+ | Lighthouse warns on combined; separate entries required for full green audit |
| `navigator.standalone` only for iOS detection | `matchMedia('(display-mode: standalone)')` + `navigator.standalone` | PWA spec evolution | `matchMedia` works in all browsers; `navigator.standalone` is iOS-only legacy |
| Lighthouse CI required for PWA verification | Manual Lighthouse against production URL | Decision: no Lighthouse CI (context confirms) | Simpler CI pipeline; manual gate before merge |
| EU iOS 17.4 removed standalone PWA support | iOS 17.5 restored standalone PWA | March 2024 / May 2024 | EU users can install PWAs again; banner is appropriate to show |

**Deprecated/outdated:**
- `purpose: 'any maskable'` combined string: discouraged, use two entries
- `navigator.getInstalledRelatedApps()`: Experimental, poor support, not needed here

## Open Questions

1. **SVG rendering fidelity in sharp/librsvg**
   - What we know: The favicon.svg uses display-p3 color space, feGaussianBlur filters, and `<mask>` elements — complex rendering
   - What's unclear: Whether the installed version of librsvg on the dev machine fully renders these effects
   - Recommendation: Run the script, inspect the output PNG, and verify visually. If blank, simplify SVG colors to sRGB hex equivalents for icon use only, or use a fallback approach (Playwright screenshot of the SVG at target size).

2. **apple-touch-icon reference in index.html**
   - What we know: `index.html` has `<link rel="apple-touch-icon" href="/icons/icon-192.png" />` (line 10), but the context decision places `apple-touch-icon.png` at root `/` (`pwa/public/apple-touch-icon.png`)
   - What's unclear: Whether the index.html href should be updated to `/apple-touch-icon.png` or the file should go in `icons/`
   - Recommendation: Generate `apple-touch-icon.png` at `pwa/public/apple-touch-icon.png` and update `index.html` to `href="/apple-touch-icon.png"`. The `includeAssets` in vite.config.ts already lists `'apple-touch-icon.png'` expecting it at the root.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | vitest 4.1.0 + @testing-library/react 16.3.2 |
| Config file | `pwa/vitest.config.ts` |
| Quick run command | `cd pwa && npx vitest run src/hooks` |
| Full suite command | `cd pwa && npx vitest run` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PWA-01 | Icon PNG files exist at declared paths with correct dimensions | manual (file check) | `ls -la pwa/public/icons/` + Chrome DevTools Application panel | n/a — file output, not unit testable |
| PWA-02 | Lighthouse PWA audit green | manual | Run Lighthouse in Chrome DevTools against deployed URL | n/a — manual only |
| PWA-03 | offline.html exists and is pre-cached by service worker | manual + unit | unit: `cd pwa && npx vitest run src/hooks`; manual: DevTools → Cache Storage | ❌ Wave 0 |
| PWA-04 | useInstallPrompt returns correct state for Android/iOS/standalone | unit | `cd pwa && npx vitest run src/hooks/useInstallPrompt.test.ts -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd pwa && npx vitest run src/hooks`
- **Per wave merge:** `cd pwa && npx vitest run`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `pwa/src/hooks/useInstallPrompt.test.ts` — covers PWA-04 (hook unit test: Android state, iOS state, standalone suppression, sessionStorage dismissal)
- [ ] `pwa/src/hooks/` directory — needs to be created (no `hooks/` directory currently exists in `pwa/src/`)

## Sources

### Primary (HIGH confidence)
- https://vite-pwa-org.netlify.app/workbox/generate-sw — navigateFallback, globPatterns, includeAssets
- https://web.dev/learn/pwa/installation-prompt — beforeinstallprompt lifecycle, display-mode detection, iOS limitations
- https://sharp.pixelplumbing.com/api-resize/ — sharp resize with fit: 'contain' and background fill
- https://sharp.pixelplumbing.com/api-operation/ — flatten() for alpha compositing
- https://web.dev/articles/maskable-icon — safe zone spec (40% radius = 80% safe diameter)
- https://developer.chrome.com/docs/lighthouse/pwa/installable-manifest — exact Lighthouse manifest requirements
- Inspected `pwa/vite.config.ts`, `pwa/package.json`, `pwa/public/favicon.svg` — direct project codebase review

### Secondary (MEDIUM confidence)
- https://dev.to/progressier/why-a-pwa-app-icon-shouldnt-have-a-purpose-set-to-any-maskable-4c78 — separate purpose entries recommendation
- https://blog.wick.technology/pwa-install-prompt/ — React hook pattern for cross-platform install prompt
- https://chapimaster.com/programming/vite/create-custom-offline-page-react-pwa — navigateFallback + includeAssets wiring

### Tertiary (LOW confidence)
- https://www.magicbell.com/blog/pwa-ios-limitations-safari-support-complete-guide — iOS 17.4 EU removal, 17.5 restoration (news article, not official)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — vite-plugin-pwa, workbox, and sharp are all verified; versions confirmed from installed packages
- Architecture: HIGH — navigateFallback pattern verified from official vite-pwa docs; install prompt pattern from web.dev
- Pitfalls: MEDIUM — SVG rendering in sharp/librsvg is the main risk area; all others are verified patterns

**Research date:** 2026-03-21
**Valid until:** 2026-09-21 (stable PWA web platform specs; vite-plugin-pwa is active but 1.x is pinned in project)
