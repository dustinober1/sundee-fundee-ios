# Phase 7: Service Worker - Research

**Researched:** 2026-02-20
**Domain:** `@serwist/turbopack` + Next.js App Router + Service Worker lifecycle
**Confidence:** HIGH

---

## Summary

`@serwist/turbopack` (stable v9.5.6) is architecturally different from `@serwist/next` (webpack). Instead of injecting a build plugin, it provides a **Next.js Route Handler** at `app/serwist/[path]/route.ts` that compiles the SW via esbuild at request time (with `force-static` rendering, so it pre-renders at build time). The SW is served at `/serwist/sw.js`, not `/sw.js`. This means:

1. `middleware.ts` must exclude `/serwist/` paths (currently excludes `sw.js` only)
2. `tsconfig.json` must exclude `src/app/sw.ts` (SW uses `no-default-lib` + `webworker`, conflicts with `dom` lib)
3. `SerwistProvider` (from `@serwist/turbopack/react`) must be re-exported through a `"use client"` file before use in Server Component layout

**Critical finding**: `defaultCache` includes a cross-origin `NetworkFirst` handler (1-hour TTL) that **will cache Supabase API responses** unless a `NetworkOnly` rule is placed before `defaultCache` in `runtimeCaching`.

**Primary recommendation:** Install `@serwist/turbopack@9.5.6 serwist@9.5.6 esbuild@latest` as dev dependencies. Follow the Turbopack quick guide exactly. Add Supabase `NetworkOnly` rule as the first entry in `runtimeCaching`. Handle `controllerchange` in a standalone client component.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@serwist/turbopack` | 9.5.6 | SW compilation + Next.js Turbopack integration | Only valid approach for Next.js 16 Turbopack; `@serwist/next` uses webpack plugin (incompatible) |
| `serwist` | 9.5.6 | Core SW runtime (strategies, precache, fallbacks) | Provides `Serwist` class, `NetworkOnly`, `CacheFirst`, etc. in SW entry point |
| `esbuild` | 0.27.3+ | Compiles `app/sw.ts` → `sw.js` inside route handler | Required peer dep of `@serwist/turbopack` |

**Installation:**
```bash
npm i -D @serwist/turbopack esbuild serwist
```

> **Version note:** Stable `latest` is 9.5.6 for all three. A `preview` tag (10.0.0-preview.14) exists but is unstable. Use stable 9.5.6.

---

## Architecture Patterns

### Turbopack vs Webpack — Key Structural Difference

| | `@serwist/next` (webpack) | `@serwist/turbopack` |
|--|--|--|
| SW compilation | Webpack InjectManifest plugin at build time | esbuild inside Route Handler (`force-static`) |
| SW location | `public/sw.js` | `/serwist/sw.js` (served by route handler) |
| Config hook | Wraps `next.config.ts`, builds SW at `next build` | Wraps `next.config.ts` only adds `serverExternalPackages` |
| Layout wiring | Manual `navigator.serviceWorker.register()` | `SerwistProvider` from `@serwist/turbopack/react` |

### Recommended File Structure

```
src/app/
├── sw.ts                          # SW entry point (compiled by esbuild)
├── serwist/
│   └── [path]/
│       └── route.ts               # Route Handler that serves /serwist/sw.js
├── serwist-client.ts              # "use client" re-export of SerwistProvider
├── offline/
│   └── page.tsx                   # Branded offline fallback page
└── layout.tsx                     # Updated: SerwistProvider + SerwistReloadHandler

src/components/
└── SerwistReloadHandler.tsx       # Client component for controllerchange guard

next.config.ts                     # Updated: withSerwist wrapper
middleware.ts                      # Updated: exclude /serwist/ paths
tsconfig.json                      # Updated: exclude src/app/sw.ts
```

---

## Pattern 1: `next.config.ts` — `withSerwist` Wrapper

**What it does:** Adds `esbuild` and `esbuild-wasm` to `serverExternalPackages`. Nothing else — no plugin machinery.

```typescript
// next.config.ts
// Source: https://serwist.pages.dev/docs/next/turbo (official Turbopack guide)
import { withSerwist } from "@serwist/turbopack";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* existing config options */
};

export default withSerwist(nextConfig);
```

---

## Pattern 2: Route Handler — `src/app/serwist/[path]/route.ts`

The route handler at this exact path serves `/serwist/sw.js` and `/serwist/sw.js.map`. It's `force-static`, so Next.js pre-renders it at build time via `generateStaticParams`.

```typescript
// src/app/serwist/[path]/route.ts
// Source: https://serwist.pages.dev/docs/next/turbo (official Turbopack guide)
import { spawnSync } from "node:child_process";
import { createSerwistRoute } from "@serwist/turbopack";

const revision =
  spawnSync("git", ["rev-parse", "HEAD"], { encoding: "utf-8" }).stdout.trim() ??
  crypto.randomUUID();

export const { dynamic, dynamicParams, revalidate, generateStaticParams, GET } =
  createSerwistRoute({
    additionalPrecacheEntries: [{ url: "/offline", revision }],
    swSrc: "src/app/sw.ts",   // path relative to project CWD
    useNativeEsbuild: true,
  });
```

> **Note on `swSrc` path:** The path is relative to the process CWD (project root). This project uses `src/app/` so it's `"src/app/sw.ts"`, not `"app/sw.ts"`.

> **Note on Next.js version:** The docs say "If you are using Next.js versions older than 15.0.0, add the `nextConfig` option." Since this project uses Next.js 16.1.6 (≥15), the `nextConfig` option is NOT needed.

---

## Pattern 3: Service Worker Entry Point — `src/app/sw.ts`

### Critical: Supabase `NetworkOnly` MUST come before `defaultCache`

The `defaultCache` from `@serwist/turbopack/worker` includes a **cross-origin `NetworkFirst` handler** (1-hour TTL). Supabase API calls are cross-origin and WILL be cached by this rule unless explicitly overridden before it.

```typescript
// src/app/sw.ts
// Source: Based on official turbo guide + verified defaultCache source inspection
/// <reference no-default-lib="true" />
/// <reference lib="esnext" />
/// <reference lib="webworker" />
import { defaultCache } from "@serwist/turbopack/worker";
import type { PrecacheEntry, SerwistGlobalConfig } from "serwist";
import { NetworkOnly, Serwist } from "serwist";

declare global {
  interface WorkerGlobalScope extends SerwistGlobalConfig {
    __SW_MANIFEST: (PrecacheEntry | string)[] | undefined;
  }
}

declare const self: ServiceWorkerGlobalScope;

const serwist = new Serwist({
  precacheEntries: self.__SW_MANIFEST,
  skipWaiting: true,
  clientsClaim: true,
  navigationPreload: true,
  runtimeCaching: [
    // ⚠️ MUST be first — overrides defaultCache's cross-origin NetworkFirst handler
    // which would otherwise cache Supabase responses for 1 hour
    {
      matcher: ({ url }) => url.hostname.endsWith(".supabase.co"),
      handler: new NetworkOnly(),
    },
    ...defaultCache,
  ],
  fallbacks: {
    entries: [
      {
        url: "/offline",
        matcher({ request }) {
          return request.destination === "document";
        },
      },
    ],
  },
});

serwist.addEventListeners();
```

### `defaultCache` contents (verified from `@serwist/turbopack@9.5.6` source)

In **development** (`NODE_ENV !== "production"`): ALL requests → `NetworkOnly`. No caching at all.

In **production**: Strategies by asset type:
| Pattern | Strategy | TTL |
|---------|----------|-----|
| `fonts.gstatic.com/*` | CacheFirst | 365 days |
| `fonts.googleapis.com/*` | StaleWhileRevalidate | 7 days |
| `*.eot|otf|ttf|woff|woff2` | StaleWhileRevalidate | 7 days |
| `*.jpg|jpeg|gif|png|svg|ico|webp` | StaleWhileRevalidate | 30 days |
| `/_next/static/**/*.js` | CacheFirst | 24 hours |
| `/_next/image?url=…` | StaleWhileRevalidate | 24 hours |
| `*.mp3|wav|ogg` | CacheFirst | 24 hours |
| `*.mp4|webm` | CacheFirst | 24 hours |
| `*.js` | StaleWhileRevalidate | 24 hours |
| `*.css|less` | StaleWhileRevalidate | 24 hours |
| `/_next/data/**/*.json` | NetworkFirst | 24 hours |
| `*.json|xml|csv` | NetworkFirst | 24 hours |
| `/api/auth/*` | **NetworkOnly** | — |
| Same-origin `/api/*` GET | NetworkFirst | 24 hours |
| RSC prefetch requests | NetworkFirst | 24 hours |
| RSC requests | NetworkFirst | 24 hours |
| HTML (same-origin) | NetworkFirst | 24 hours |
| Same-origin (catch-all) | NetworkFirst | 24 hours |
| **Cross-origin (catch-all)** | **NetworkFirst** | **1 hour** ← Supabase without our override |
| `.*` GET (final fallback) | NetworkOnly | — |

---

## Pattern 4: Layout Wiring

### Step 1: Create `"use client"` re-export

Required because `SerwistProvider` is a client component but `layout.tsx` is a Server Component.

```typescript
// src/app/serwist-client.ts
"use client";
export { SerwistProvider } from "@serwist/turbopack/react";
```

### Step 2: Update `layout.tsx`

```typescript
// src/app/layout.tsx (additions)
import { SerwistProvider } from "./serwist-client";
import { SerwistReloadHandler } from "@/components/SerwistReloadHandler";

// In RootLayout:
<body ...>
  <SerwistProvider swUrl="/serwist/sw.js">
    <Providers>
      {children}
      <BottomNavigation />
      <SerwistReloadHandler />
    </Providers>
  </SerwistProvider>
</body>
```

---

## Pattern 5: `controllerchange` Handler

`SerwistProvider` does NOT expose a `controllerchange` callback. Manual implementation required.

**Design decision: workout detection via URL pathname.** The app's workout session is at `/workout/[id]`. Checking `pathname.startsWith('/workout')` is reliable and requires no context plumbing into a component outside `<Providers>`.

```typescript
// src/components/SerwistReloadHandler.tsx
"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";

const PENDING_RELOAD_KEY = "serwist_pending_reload";

export function SerwistReloadHandler() {
  const pathname = usePathname();

  useEffect(() => {
    // Check if a reload was deferred during a previous workout
    if (sessionStorage.getItem(PENDING_RELOAD_KEY) && !pathname.startsWith("/workout")) {
      sessionStorage.removeItem(PENDING_RELOAD_KEY);
      window.location.reload();
    }
  }, [pathname]);

  useEffect(() => {
    if (!("serviceWorker" in navigator)) return;

    const handleControllerChange = () => {
      if (pathname.startsWith("/workout")) {
        // Defer reload — store flag, clear after workout
        sessionStorage.setItem(PENDING_RELOAD_KEY, "1");
      } else {
        window.location.reload();
      }
    };

    navigator.serviceWorker.addEventListener("controllerchange", handleControllerChange);
    return () => {
      navigator.serviceWorker.removeEventListener("controllerchange", handleControllerChange);
    };
  }, [pathname]);

  return null;
}
```

> **Why `usePathname` not context:** `SerwistReloadHandler` is placed OUTSIDE `<Providers>` in the layout (sibling, not child). Using `usePathname()` from Next.js navigation avoids needing to pipe workout state through. If `SerwistReloadHandler` needs to be INSIDE `<Providers>`, switch to checking `useRestTimerContext().isRunning` instead.

---

## Pattern 6: `/offline` Page

The offline fallback page must be pre-cached. The SW's `fallbacks.entries` points to `/offline` which maps to this page. It only displays when a navigation request fails offline.

```typescript
// src/app/offline/page.tsx
import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Offline – Sundee-Fundee",
};

export default function OfflinePage() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen gap-4 p-6 text-center">
      <h1 className="text-2xl font-bold">You're offline</h1>
      <p className="text-muted-foreground">
        Check your connection and try again.
      </p>
      <Link
        href="/dashboard"
        className="text-primary underline underline-offset-4"
      >
        Back to Dashboard
      </Link>
    </div>
  );
}
```

> **Important:** `/offline` must be listed in `additionalPrecacheEntries` in the route handler with a `revision`. Without this, the SW won't pre-cache the page and the fallback will fail.

---

## Pattern 7: Middleware Update

The current `middleware.ts` excludes `sw.js` (bare filename). With `@serwist/turbopack`, the SW is at `/serwist/sw.js` — a different URL. The `/serwist/` route must be excluded to prevent unnecessary Supabase auth processing on SW file requests.

**Current exclusion:**
```
/((?!_next/static|_next/image|favicon.ico|manifest\.json|sw\.js|workbox-.*\.js|.*\.(?:svg|png|jpg|jpeg|gif|webp)$).*)
```

**Updated exclusion** (add `serwist/`):
```typescript
matcher: [
  '/((?!_next/static|_next/image|favicon.ico|manifest\\.json|sw\\.js|workbox-.*\\.js|serwist/.*|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
],
```

---

## Pattern 8: `tsconfig.json` Update

`src/app/sw.ts` uses `/// <reference no-default-lib="true" />` which strips DOM types. Including it in the main TypeScript project causes conflicts (WebWorker `self` vs DOM `self`). Exclude it from the main compilation.

```json
{
  "compilerOptions": { /* no changes */ },
  "exclude": [
    "node_modules",
    "src/app/sw.ts"
  ]
}
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SW compilation under Turbopack | Custom esbuild script | `createSerwistRoute` from `@serwist/turbopack` | Handles manifest injection, path remapping, dev vs prod, sourcemaps |
| Precache manifest generation | Manual file list | `__SW_MANIFEST` injection by Serwist | Handles revision hashing, Next.js static file paths |
| SW registration | `navigator.serviceWorker.register()` | `SerwistProvider` from `@serwist/turbopack/react` | Handles scope, update detection, `cacheOnNavigation` |

---

## Common Pitfalls

### Pitfall 1: Using `@serwist/next` (webpack) instead of `@serwist/turbopack`
**What goes wrong:** The webpack plugin silently fails or is ignored when Next.js 16 uses Turbopack as the default bundler. No SW is generated. No error is surfaced.  
**How to avoid:** Always use `@serwist/turbopack` for Next.js 16. Never use `@serwist/next` with Turbopack.  
**Warning signs:** `public/sw.js` was never created after `next build`.

### Pitfall 2: Supabase responses cached by `defaultCache`
**What goes wrong:** `defaultCache` has a catch-all cross-origin `NetworkFirst` handler that caches `*.supabase.co` responses for 1 hour. Auth state becomes stale; data sync fails silently when served from cache.  
**How to avoid:** Add `NetworkOnly` for `*.supabase.co` as the **first** entry in `runtimeCaching`, before spreading `...defaultCache`.  
**Warning signs:** Network tab shows Supabase requests served `(ServiceWorker)` instead of going to network.

### Pitfall 3: `app/sw.ts` TypeScript conflicts
**What goes wrong:** `src/app/sw.ts` uses `/// <reference no-default-lib="true" />` and `webworker` lib. If not excluded from `tsconfig.json`, TypeScript emits errors about `self` type, `fetch` type conflicts, etc.  
**How to avoid:** Add `"src/app/sw.ts"` to `tsconfig.json` `exclude` array.  
**Warning signs:** `tsc --noEmit` or VS Code shows type errors in `sw.ts`.

### Pitfall 4: SW served at `/sw.js` not `/serwist/sw.js`
**What goes wrong:** `SerwistProvider swUrl="/sw.js"` won't find the SW. Registration silently fails (404 in DevTools).  
**How to avoid:** Always use `swUrl="/serwist/sw.js"` for `@serwist/turbopack`.  
**Warning signs:** DevTools Application tab shows no service worker registered.

### Pitfall 5: Testing offline in development
**What goes wrong:** `defaultCache` uses `NetworkOnly` for ALL requests in development (`NODE_ENV !== "production"`). "Offline" mode in DevTools will show failures even with a correctly configured SW.  
**How to avoid:** Test offline behavior with a production build (`npm run build && npm run start`), not the dev server.  
**Warning signs:** Offline testing fails in dev but pass in prod build — this is expected behavior.

### Pitfall 6: Missing `"use client"` on `SerwistProvider` import
**What goes wrong:** `SerwistProvider` is a client component. Importing it directly in a Server Component (`layout.tsx`) causes Next.js to throw a build error.  
**How to avoid:** Create `src/app/serwist-client.ts` with `"use client"` directive re-exporting `SerwistProvider`, then import from that file.  
**Warning signs:** Build error: "Client components cannot be imported from server components".

### Pitfall 7: `controllerchange` fires during workout → data loss
**What goes wrong:** When a new SW takes control, if we call `window.location.reload()` immediately, any unsaved workout set data (held in component state) is lost.  
**How to avoid:** Check `pathname.startsWith('/workout')` before reloading. Store a `sessionStorage` flag and reload after the user navigates away from the workout route.  
**Warning signs:** User reports losing set data when the app updates.

### Pitfall 8: Route handler path depth
**What goes wrong:** The route MUST be at `[path]` (not `[...path]`). The `@serwist/turbopack` source comment explicitly says: "Asset and chunk names must be at the top, as our path is `/serwist/[path]`, not `/serwist/[...path]`". Deeper paths would cause 404s for sourcemaps.  
**How to avoid:** Create `src/app/serwist/[path]/route.ts` — exactly one dynamic segment.

---

## Build/Test Verification

### Local verification (production build required for offline testing)
```bash
npm run build
npm run start
# Navigate to http://localhost:3000
# Open DevTools → Application → Service Workers → verify "Activated and running"
# Network tab → set "Offline" → navigate to /dashboard → app shell loads
# Navigate to /some-unknown-route → /offline fallback shows
# Network tab → verify *.supabase.co requests show "pending/failed" not "(ServiceWorker)"
```

### Lighthouse PWA audit
```bash
# Must use production build
npm run build && npm run start
# Open Chrome → DevTools → Lighthouse → PWA audit → target score ≥ 90
```

### E2E tests (all 11 must still pass)
```bash
npm run test:e2e
```
> `serviceWorkers: 'block'` in `playwright.config.ts` (Phase 6) prevents the SW from interfering with tests. No changes needed to Playwright config.

### DevTools checks
- **Application → Service Workers**: Shows `/serwist/sw.js`, status "Activated and running"
- **Application → Cache Storage**: Shows `serwist-precache-*` with pre-cached shell assets
- **Network tab (Offline mode)**: App shell routes show `(ServiceWorker)`, Supabase requests show failed (not served from cache)

---

## Open Questions

1. **`swSrc` path on Vercel vs local**
   - What we know: `swSrc: "src/app/sw.ts"` is relative to CWD (project root). Works locally.
   - What's unclear: Whether Vercel's build CWD is the same as the repo root.
   - Recommendation: Use `path.join(process.cwd(), "src/app/sw.ts")` in route handler if CWD issues arise. Verify on first deployment.

2. **`reloadOnOnline` prop of `SerwistProvider`**
   - What we know: Defaults to `true` — reloads the page when network comes back online.
   - What's unclear: Could this also interrupt a workout? The user might lose state.
   - Recommendation: Set `reloadOnOnline={false}` in `SerwistProvider` and implement custom reload logic only for `controllerchange`. Keep it simple.

3. **`SerwistReloadHandler` placement in layout**
   - What we know: It needs `usePathname()` from Next.js. Can be placed anywhere inside the `<html>` tree.
   - What's unclear: Whether it should be inside or outside `<Providers>`. If inside: can use RestTimerContext for more accurate in-workout detection. If outside: uses `pathname` check only.
   - Recommendation: Place INSIDE `<Providers>` to allow future upgrade to RestTimerContext check.

---

## Sources

### Primary (HIGH confidence)
- Official Serwist Turbopack guide: https://serwist.pages.dev/docs/next/turbo — Installation, Route Handler, SW template, SerwistProvider
- Official GitHub example (`next-turbo-basic`): `github.com/serwist/serwist/tree/main/examples/next-turbo-basic` — Route handler exact code, layout pattern
- Verified `@serwist/turbopack@9.5.6` npm package source (unpacked locally) — `src/index.worker.ts` (defaultCache full contents), `src/index.react.tsx` (SerwistProvider source), `src/index.ts` (createSerwistRoute, withSerwist source)
- npm registry: `@serwist/turbopack` and `serwist` — latest: 9.5.6, preview: 10.0.0-preview.14

### Secondary (MEDIUM confidence)
- Serwist runtime caching docs: https://serwist.pages.dev/docs/serwist/runtime-caching — NetworkOnly usage pattern

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from npm registry + official docs
- Architecture: HIGH — verified from official example + package source code
- `defaultCache` contents: HIGH — read directly from unpacked npm package source
- `controllerchange` pattern: MEDIUM — standard web API; `SerwistProvider` source confirmed it doesn't handle this natively
- Pitfalls: HIGH — verified from source code inspection + official docs

**Research date:** 2026-02-20
**Valid until:** 2026-04-20 (stable library; unlikely to change quickly)

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PWA-03 | App registers a service worker (via `@serwist/turbopack`) that caches the app shell and serves a navigation fallback — Supabase API calls explicitly excluded from caching | `createSerwistRoute` provides SW registration; `defaultCache` provides shell caching; custom `NetworkOnly` rule before `defaultCache` excludes Supabase; `fallbacks.entries` configures offline navigation fallback |
</phase_requirements>
