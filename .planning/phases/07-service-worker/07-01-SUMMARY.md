---
phase: "07"
plan: "01"
name: "Service Worker Infrastructure"
subsystem: "pwa"
tags: ["service-worker", "serwist", "turbopack", "offline", "pwa", "caching"]

dependency-graph:
  requires:
    - "06-02: middleware.ts with static asset exclusions (extended here)"
  provides:
    - "SW compilation pipeline via esbuild route handler"
    - "Service worker served at /serwist/sw.js"
    - "Supabase NetworkOnly exclusion in runtimeCaching"
    - "44-entry precache including /offline fallback"
  affects:
    - "07-02: SerwistProvider + controllerchange handler wired into layout.tsx"
    - "08-xx: Offline page content, Lighthouse PWA audit"

tech-stack:
  added:
    - "@serwist/turbopack@9.5.6"
    - "serwist@9.5.6"
    - "esbuild@0.27.3"
  patterns:
    - "createSerwistRoute for Turbopack esbuild-based SW compilation"
    - "NetworkOnly before defaultCache pattern for auth-gated API exclusion"
    - "force-static route handler pre-renders SW at build time"

key-files:
  created:
    - "src/app/sw.ts"
    - "src/app/serwist/[path]/route.ts"
  modified:
    - "package.json"
    - "package-lock.json"
    - "next.config.ts"
    - "tsconfig.json"
    - "middleware.ts"

decisions:
  - id: "SW-01"
    decision: "Supabase NetworkOnly placed before defaultCache"
    rationale: "defaultCache includes cross-origin NetworkFirst (1hr TTL) that would cache auth-gated Supabase responses"
    alternatives: "Use defaultCache unmodified"
    impact: "Supabase requests always go to network; no stale auth or data responses"
  - id: "SW-02"
    decision: "swSrc: 'src/app/sw.ts' (project-root-relative)"
    rationale: "createSerwistRoute resolves relative to CWD (project root)"
    alternatives: "path.join(process.cwd(), 'src/app/sw.ts') if CWD issues on Vercel"
    impact: "Works locally and in Vercel build (same CWD)"
  - id: "SW-03"
    decision: "useNativeEsbuild: true in createSerwistRoute"
    rationale: "Uses locally installed esbuild rather than bundled version, better version control"
    alternatives: "false (bundled esbuild)"
    impact: "esbuild@0.27.3 used for SW compilation"

metrics:
  duration: "~2 minutes"
  tasks-completed: 3
  tasks-total: 3
  completed: "2026-02-20"
---

# Phase 7 Plan 01: Service Worker Infrastructure Summary

**One-liner:** Serwist Turbopack SW pipeline via esbuild route handler with Supabase NetworkOnly exclusion precaching 44 entries.

## What Was Built

Service worker infrastructure for PWA offline support using `@serwist/turbopack@9.5.6`. The compilation pipeline uses a Next.js route handler (`/serwist/[path]`) that compiles `src/app/sw.ts` via esbuild at build time (`force-static`). The SW is served at `/serwist/sw.js` (not `/sw.js`). Build verified: 44 precache entries generated.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Install Serwist packages | 3036d8f | package.json, package-lock.json |
| 2 | Configure next.config.ts + tsconfig.json | 5459fc4 | next.config.ts, tsconfig.json |
| 3 | Create SW + route handler + middleware | ac86654 | src/app/sw.ts, src/app/serwist/[path]/route.ts, middleware.ts |

## Verification Results

| Check | Result |
|-------|--------|
| `npm run build` | ✅ Success — `44 precache entries (1871.63 KiB)` |
| `ls src/app/serwist/[path]/route.ts` | ✅ File exists |
| `grep -c "NetworkOnly" src/app/sw.ts` | ✅ `2` (import + handler) |
| `npx tsc --noEmit` | ⚠️ 2 pre-existing errors in test files (RestTimerExpanded.test.tsx, RestTimerPill.test.tsx) — confirmed pre-existed before this plan |

## Decisions Made

### SW-01: Supabase NetworkOnly Placement
**Decision:** Place `NetworkOnly` for `*.supabase.co` as the FIRST entry in `runtimeCaching`, before `...defaultCache`.

**Rationale:** `defaultCache` includes a catch-all cross-origin `NetworkFirst` handler (1-hour TTL). Without this override, every Supabase API call would be cached for 1 hour, causing stale auth state and silent data sync failures when served from cache.

### SW-02: `swSrc` Path Resolution
**Decision:** Use `swSrc: "src/app/sw.ts"` (project-root-relative string).

**Rationale:** `createSerwistRoute` resolves paths relative to CWD, which is the project root both locally and on Vercel. Confirmed working — build succeeded.

### SW-03: `useNativeEsbuild: true`
**Decision:** Use locally installed esbuild (v0.27.3) rather than the bundled version.

**Rationale:** Better version control; esbuild added as explicit devDependency at matching version.

## Must-Haves Verification

| Must-Have | Status |
|-----------|--------|
| Service worker compiles without TypeScript errors | ✅ Build succeeded, SW compiled by esbuild |
| Route handler serves sw.js at /serwist/sw.js | ✅ `● /serwist/[path]` with `/serwist/sw.js` in build output |
| Supabase routes configured as NetworkOnly before defaultCache | ✅ Line 22 in sw.ts — first entry before `...defaultCache` |
| Middleware excludes /serwist/ paths from auth processing | ✅ `serwist/.*` added to matcher negative lookahead |

## Artifacts Produced

### `src/app/sw.ts`
Service worker entry point. Triple-slash directives (`no-default-lib`, `esnext`, `webworker`) prevent TypeScript conflicts. `NetworkOnly` for `*.supabase.co` placed before `defaultCache`. Fallback to `/offline` for all `document` navigation requests.

### `src/app/serwist/[path]/route.ts`
Route handler using `createSerwistRoute`. Serves `/serwist/sw.js` (and `.map`). Uses `generateStaticParams` for `force-static` pre-rendering at build time. `additionalPrecacheEntries` includes `/offline` with git-SHA-based revision to ensure cache invalidation on deploy.

### `next.config.ts`
Wrapped with `withSerwist()`. Adds `esbuild` and `esbuild-wasm` to `serverExternalPackages` so esbuild runs server-side in the route handler.

### `tsconfig.json`
`src/app/sw.ts` excluded from main TypeScript compilation. Prevents `no-default-lib` + `webworker` lib from conflicting with `dom` lib used by the rest of the app.

### `middleware.ts`
Matcher pattern updated to include `serwist/.*` in the negative lookahead. Prevents Supabase auth client initialization on every SW file request.

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

**Phase 7 Plan 02** can proceed:
- SW infrastructure is live — `SerwistProvider` can be wired into `layout.tsx`
- `SerwistReloadHandler` component can be created
- `src/app/serwist-client.ts` (`"use client"` re-export) can be created
- `/offline` page referenced in SW precache (needs to exist as actual page)

**Blockers:** None.
