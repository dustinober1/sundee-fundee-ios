# Phase 5: Error Resilience - Research

**Researched:** 2026-03-21
**Domain:** React error boundaries, shimmer skeleton loaders, 404 routing (React 19 + React Router 7 + Vite PWA)
**Confidence:** HIGH

## Summary

Phase 5 addresses three distinct UX gaps: uncaught JavaScript render errors showing white screens (UX-01), blank space during data fetches (UX-02), and unknown URLs falling through to the SPA shell with no feedback (UX-03). All three are achievable with zero new runtime dependencies using patterns that already fit the project's existing React 19 + React Router 7 stack.

**For UX-01**, React Router 7's `createBrowserRouter` supports an `ErrorBoundary` route property (component reference, not element) at the root and at any nested level. The `useRouteError` hook provides the caught error inside the boundary component. A single root-level boundary on the top `{ element: <RootLayout /> }` entry catches all render errors globally; a second boundary on the `{ element: <AppLayout /> }` entry catches authenticated-route errors closer to the user's context.

**For UX-02**, the five data-fetching routes (Dashboard, Programs, History, Cycle, Maxes) all follow the same pattern: `const [isLoading, setIsLoading] = useState(true)` with a spinner today. Replacing the spinner with shimmer skeleton cards requires only a CSS animation + placeholder component — no library needed. The App Deco palette (cream `#F4F0DF`, navy `#0D1A40`) translates naturally to a skeleton with `--color-grey-light` base and a sweep gradient.

**For UX-03**, a wildcard `{ path: '*', element: <NotFound /> }` route at the end of the `children` array inside the root layout catches all unmatched paths. The `createBrowserRouter` call in `router.tsx` already scopes routes correctly; the catch-all must be placed at the outermost children level (not nested inside `AppLayout`) so it renders without the auth guard.

**Primary recommendation:** Implement all three requirements in a single plan wave — they share no runtime dependencies and total roughly 6 files of new code.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UX-01 | Root-level and route-level React error boundaries with recovery UI | React Router 7 `ErrorBoundary` route property + `useRouteError` hook; class component or function component with reset capability |
| UX-02 | Shimmer skeleton states on all data-fetching routes (Dashboard, Programs, History, Cycle, Maxes) | Pure CSS `@keyframes` shimmer pattern; `isLoading` state already present in all five routes; replace existing spinner with skeleton component |
| UX-03 | Branded 404 page for unknown routes | `{ path: '*' }` catch-all route in `createBrowserRouter`; must live outside `AppLayout` to bypass auth guard |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| react-router | ^7.13.1 (already installed) | `ErrorBoundary` route property, `useRouteError`, `path="*"` | Built into existing router — zero install cost |
| react | ^19.2.4 (already installed) | Class component `getDerivedStateFromError` + `componentDidCatch`, or function wrapper | React 19 improves error propagation; `onCaughtError`/`onUncaughtError` at root |
| CSS Modules (already used) | project-wide | Shimmer animation and skeleton placeholder styles | Matches every other route's `.module.css` pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| react-error-boundary | ^6.0.0 | Pre-built `ErrorBoundary` component with `resetKeys`, `onReset` | If custom class component boilerplate is unwanted; NOT required — the project is already using React Router's built-in boundary |

**Decision:** Do NOT install `react-error-boundary`. React Router 7's `ErrorBoundary` route property covers all UX-01 requirements. Adding a separate library creates two competing error-catching layers with unclear precedence.

**Installation:** No new packages required for any of the three requirements.

## Architecture Patterns

### Recommended Project Structure
```
pwa/src/
├── routes/
│   ├── router.tsx              # Add ErrorBoundary + path="*" entries
│   ├── RootErrorBoundary.tsx   # New — root-level error UI (UX-01)
│   ├── NotFound.tsx            # New — branded 404 page (UX-03)
│   ├── NotFound.module.css     # New
│   └── [Route].tsx             # Existing routes — replace spinner with <Skeleton>
└── components/
    └── Skeleton.tsx            # New — reusable shimmer skeleton card (UX-02)
    └── Skeleton.module.css     # New
```

### Pattern 1: React Router 7 Route-Level Error Boundary (UX-01)

**What:** Add `ErrorBoundary` component property to route objects in `createBrowserRouter`. React Router calls `createElement(ErrorBoundary)` automatically when any render error occurs in that route subtree. The boundary component uses `useRouteError` to access the thrown value.

**When to use:** Root-level boundary catches everything; a second boundary on the `AppLayout` route provides a more contextual recovery UI within the authenticated shell (retains nav bar).

**Two-boundary strategy:**
1. Root boundary — fallback for errors that escape the app layout (e.g., errors in `RootLayout`, `EntitlementProvider`, `SessionProvider`)
2. AppLayout boundary — fallback for errors in any authenticated route, with "go back to Dashboard" recovery

**Example:**
```typescript
// Source: https://reactrouter.com/how-to/error-boundary
import { useRouteError, isRouteErrorResponse, Link } from 'react-router';

export function RootErrorBoundary() {
  const error = useRouteError();
  const message = isRouteErrorResponse(error)
    ? `${error.status} ${error.statusText}`
    : error instanceof Error
      ? error.message
      : 'An unexpected error occurred.';

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Something went wrong</h1>
      <p className={styles.message}>{message}</p>
      <Link to="/" className={styles.retryBtn} reloadDocument>
        Reload App
      </Link>
    </div>
  );
}
```

**Router wiring:**
```typescript
// router.tsx
export const router = createBrowserRouter([
  {
    element: <RootLayout />,
    ErrorBoundary: RootErrorBoundary,        // ← root catch-all
    children: [
      { path: '/sign-in', element: <L><SignIn /></L> },
      { path: '/verify-email', element: <L><VerifyEmail /></L> },
      { path: '/onboarding', element: <L><Onboarding /></L> },
      { path: '/onboarding/:step', element: <L><Onboarding /></L> },
      {
        element: <AppLayout />,
        ErrorBoundary: AppErrorBoundary,     // ← auth-route catch-all
        children: [/* ... existing children ... */],
      },
      { path: '*', element: <L><NotFound /></L> },  // ← UX-03
    ],
  },
]);
```

**Key fact (verified from official docs):** `ErrorBoundary` (capital E, component reference) and `errorElement` (JSX element instance) are functionally equivalent. `ErrorBoundary` is preferred because React Router calls `createElement` internally — less boilerplate.

### Pattern 2: Shimmer Skeleton Component (UX-02)

**What:** A CSS `@keyframes` sweep animation on a placeholder element. No JS required. A single reusable `<SkeletonCard />` component replaces the existing spinners in all five routes.

**When to use:** Wherever `isLoading === true` and a list of cards or a data section is expected. Render N skeleton cards (e.g., 3-4) to approximate the shape of real content.

**CSS implementation (pure, no library):**
```css
/* Skeleton.module.css */
@keyframes shimmer {
  0%   { background-position: -200% 0; }
  100% { background-position:  200% 0; }
}

.card {
  background: linear-gradient(
    90deg,
    var(--color-grey-light) 25%,
    var(--color-cream-light) 50%,
    var(--color-grey-light) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.4s ease-in-out infinite;
  border-radius: 8px;
  height: 80px;
  margin-bottom: 12px;
}
```

**React component:**
```typescript
// components/Skeleton.tsx
interface SkeletonCardProps {
  count?: number;
  height?: number;
}

export function SkeletonCard({ count = 4, height = 80 }: SkeletonCardProps) {
  return (
    <>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className={styles.card} style={{ height }} />
      ))}
    </>
  );
}
```

**Usage in a route:**
```typescript
// History.tsx — replace spinner block
{isLoading ? (
  <SkeletonCard count={4} />
) : groups.length === 0 ? (
  <p className={styles.empty}>No workouts yet.</p>
) : (
  /* existing list render */
)}
```

**Routes to update:** Dashboard, Programs, History, Cycle, Maxes. All five already have `isLoading` boolean state and a spinner placeholder — only the `isLoading` branch changes.

**Dashboard special case:** Dashboard currently renders `isLoading` implicitly (no spinner shown today — it just renders with empty state). It needs `isLoading` state added + `SkeletonCard` wired to both the WOD area and the quick-links grid.

### Pattern 3: Branded 404 Page (UX-03)

**What:** A `path="*"` wildcard route at the outermost `children` level inside `RootLayout`. React Router matches routes top-to-bottom and this entry catches anything not matched by the auth routes, onboarding routes, or authenticated app routes.

**Critical placement:** The `path="*"` route must be a sibling of `AppLayout`'s entry (not a child), so it renders WITHOUT the auth guard. A user navigating to `/random-garbage` must see a 404 page — not get redirected to sign-in.

**Example:**
```typescript
// NotFound.tsx
import { Link } from 'react-router';
import styles from './NotFound.module.css';

export function NotFound() {
  return (
    <div className={styles.container}>
      <h1 className={styles.code}>404</h1>
      <p className={styles.message}>This page doesn't exist.</p>
      <Link to="/" className={styles.homeBtn}>Back to App</Link>
    </div>
  );
}
```

**SPA rewrite rule note:** Firebase Hosting's SPA rewrite (`"destination": "/index.html"`) sends all unmatched server paths to the SPA. The React Router `path="*"` then renders the 404 component client-side. This is correct behavior — the 404 is a client-side render, not an HTTP 404 response. No Firebase config change is needed.

### Anti-Patterns to Avoid

- **Wrapping `<RouterProvider>` in a React class `ErrorBoundary`:** Errors in `RouterProvider` itself are extremely rare, and this creates a duplicate boundary that competes with React Router's built-in mechanism. Use the route-level `ErrorBoundary` property only.
- **Placing `path="*"` inside `AppLayout`'s children:** Requires the user to be authenticated to see the 404 page. Unknown routes for unauthenticated users silently redirect to sign-in — confusing.
- **Skeleton with fixed pixel heights that don't match real content:** Jarring layout shift when real content loads. Match skeleton card height to approximately the real card height in each route.
- **Using `isLoading` for the Cycle route's full-page spinner:** Cycle currently returns early with a full-screen spinner (`if (isLoading) return <div>...`). Replace this early-return with the `isLoading` branch pattern consistent with the other routes to enable the shimmer pattern.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Error catch in router | Custom React class ErrorBoundary wrapping RouterProvider | React Router `ErrorBoundary` route property | React Router's mechanism integrates with loader errors, route transitions, and concurrent mode; custom class boundary around RouterProvider cannot catch loader errors |
| Shimmer animation | External skeleton library (e.g., `react-loading-skeleton`) | Pure CSS `@keyframes` in a `.module.css` | The project uses CSS Modules throughout; a library adds 10+ kB for a 10-line CSS animation |
| 404 detection | Custom useEffect checking `window.location` | React Router `path="*"` | React Router's pattern matching is already the source of truth for what constitutes a valid route |

**Key insight:** All three UX requirements are solved by React Router 7 configuration (error boundary + catch-all route) plus a ~20-line CSS animation. No runtime library additions are needed.

## Common Pitfalls

### Pitfall 1: `useRouteError` called outside a route error boundary
**What goes wrong:** Calling `useRouteError()` in a component that is NOT the `ErrorBoundary` for a route throws a React Router invariant error.
**Why it happens:** `useRouteError` reads context injected only when React Router renders the `ErrorBoundary` component.
**How to avoid:** `useRouteError()` must only be called in the component passed as the `ErrorBoundary` route property (or `errorElement`). Do not call it in regular route components.
**Warning signs:** "useRouteError() may only be used within a data router" or similar invariant errors in console.

### Pitfall 2: Error boundary not resetting on navigation
**What goes wrong:** After a render error, the user navigates to another route but the error boundary UI persists because `hasError` state is never reset.
**Why it happens:** React Router's `ErrorBoundary` component is unmounted/remounted on navigation between routes, which naturally resets state. However, if two routes share the same boundary instance (parent-level), navigation within that subtree may NOT reset it.
**How to avoid:** The `AppErrorBoundary` should include a "Go to Dashboard" link using `<Link to="/" reloadDocument>` (full reload) OR `<Link to="/">` (SPA navigation that unmounts/remounts). The `reloadDocument` approach is safer for catastrophic errors.
**Warning signs:** Error UI persists after clicking back/forward.

### Pitfall 3: Skeleton count mismatch causes layout shift
**What goes wrong:** Skeleton renders 4 cards but the real data has 1 or 15 items — visible jump.
**Why it happens:** Static skeleton count doesn't reflect real data shape.
**How to avoid:** Use a conservative default count (3-4) that is approximate. The visual shift is acceptable as long as the skeleton height-per-card matches real card height reasonably.
**Warning signs:** Large cumulative layout shift (CLS) in Lighthouse.

### Pitfall 4: `path="*"` placed at wrong nesting level
**What goes wrong:** Unknown URLs redirect to sign-in instead of showing 404.
**Why it happens:** Wildcard route nested inside `AppLayout`'s children — the auth guard triggers before the 404 renders.
**How to avoid:** The `path: '*'` route must be a sibling of the `AppLayout` entry object in the `children` array of the root route.
**Warning signs:** Navigating to `/random` as a logged-out user goes to `/sign-in`.

### Pitfall 5: Dashboard's missing `isLoading` state
**What goes wrong:** Dashboard currently initializes `profile` and `todayWOD` as `null` with no loading flag — it just renders empty state while fetching. Adding a skeleton requires also adding `isLoading` state.
**Why it happens:** Dashboard was written with optimistic empty rendering (shows greeting immediately, WOD card appears when data arrives).
**How to avoid:** Add `const [isLoading, setIsLoading] = useState(true)` in Dashboard's `useEffect`, set to `false` after both fetches complete (use `Promise.all` on the two existing `useEffect` calls or merge them).
**Warning signs:** Skeleton never shows (or shows permanently) on Dashboard.

## Code Examples

Verified patterns from official sources and project conventions:

### Router with ErrorBoundary + catch-all
```typescript
// Source: https://reactrouter.com/how-to/error-boundary (verified 2026-03-21)
// pwa/src/routes/router.tsx

export const router = createBrowserRouter([
  {
    element: <RootLayout />,
    ErrorBoundary: RootErrorBoundary,
    children: [
      { path: '/sign-in', element: <L><SignIn /></L> },
      { path: '/verify-email', element: <L><VerifyEmail /></L> },
      { path: '/onboarding', element: <L><Onboarding /></L> },
      { path: '/onboarding/:step', element: <L><Onboarding /></L> },
      {
        element: <AppLayout />,
        ErrorBoundary: AppErrorBoundary,
        children: [/* existing authenticated routes */],
      },
      { path: '*', element: <L><NotFound /></L> },
    ],
  },
]);
```

### RootErrorBoundary using useRouteError
```typescript
// Source: https://reactrouter.com/how-to/error-boundary
import { useRouteError, isRouteErrorResponse } from 'react-router';

export function RootErrorBoundary() {
  const error = useRouteError();
  const message = isRouteErrorResponse(error)
    ? `${error.status} ${error.statusText}`
    : error instanceof Error
      ? error.message
      : 'Unknown error';

  return (
    <div className={styles.container}>
      <h1 className={styles.heading}>Something went wrong</h1>
      <p className={styles.detail}>{message}</p>
      <a href="/" className={styles.btn}>Reload App</a>
    </div>
  );
}
```

### Pure CSS shimmer keyframe
```css
/* Source: CSS standard @keyframes — verified pattern, widely documented */
/* pwa/src/components/Skeleton.module.css */
@keyframes shimmer {
  0%   { background-position: -200% 0; }
  100% { background-position:  200% 0; }
}

.card {
  background: linear-gradient(
    90deg,
    var(--color-grey-light) 25%,
    var(--color-cream-light) 50%,
    var(--color-grey-light) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.4s ease-in-out infinite;
  border-radius: 8px;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `React.Component` class boundary only | React Router `ErrorBoundary` route property | React Router v6.4+ (data router era) | No class component needed for route-scoped error handling |
| Separate 404 view from error handling | `path="*"` catch-all as standard router pattern | React Router v4+ | Catch-all route is idiomatic; no custom middleware needed |
| Skeleton libraries (`react-loading-skeleton`, `react-placeholder`) | Pure CSS `@keyframes` | Always possible; libraries grew popular ~2019 then CSS-only became preferred | Zero dependency cost, full design token integration |
| `errorElement={<Component />}` (JSX) | `ErrorBoundary={Component}` (reference) | React Router v6.4+ | Cleaner — React Router calls `createElement` internally |

**Deprecated/outdated:**
- React `componentDidCatch` as the sole error boundary mechanism: still valid but React Router's route-level mechanism is preferred for routed apps.
- `react-error-boundary` npm package: useful outside a router context, but redundant when using React Router 7 data router mode.

## Open Questions

1. **Should `AppErrorBoundary` render inside or outside the `<AppLayout>` shell?**
   - What we know: Placing `ErrorBoundary` on the `{ element: <AppLayout /> }` entry means React Router renders `AppErrorBoundary` in place of `AppLayout` when an error is caught — the nav bar disappears.
   - What's unclear: Whether the design requires the nav bar to be visible during error state (better UX) or not (simpler implementation).
   - Recommendation: The planner can decide. The simpler path (ErrorBoundary on AppLayout route, nav disappears on error) is fully sufficient for UX-01. Keeping the nav bar during errors requires wrapping AppLayout's `<Outlet />` in a separate boundary class component inside AppLayout itself — more complex.

2. **Dashboard loading state approach**
   - What we know: Dashboard currently uses two separate `useEffect` calls that each resolve independently — `profile` and `todayWOD` load independently.
   - What's unclear: Whether to merge them into a single `Promise.all` (cleaner, single `isLoading` flag) or track them separately (each section skeletons independently).
   - Recommendation: Merge into `Promise.all` in a single `useEffect` for consistency with History's existing pattern.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest ^4.1.0 + @testing-library/react ^16.3.2 |
| Config file | `pwa/vitest.config.ts` |
| Quick run command | `cd pwa && npx vitest run src/components/Skeleton.test.tsx src/routes/RootErrorBoundary.test.tsx src/routes/NotFound.test.tsx` |
| Full suite command | `cd pwa && npx vitest run` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UX-01 | `RootErrorBoundary` renders heading and reload link when error thrown | unit | `cd pwa && npx vitest run src/routes/RootErrorBoundary.test.tsx` | Wave 0 |
| UX-01 | `AppErrorBoundary` renders recovery UI and "Back to Dashboard" link | unit | `cd pwa && npx vitest run src/routes/AppErrorBoundary.test.tsx` | Wave 0 |
| UX-02 | `SkeletonCard` renders correct number of shimmer divs | unit | `cd pwa && npx vitest run src/components/Skeleton.test.tsx` | Wave 0 |
| UX-03 | `NotFound` renders 404 heading and home link | unit | `cd pwa && npx vitest run src/routes/NotFound.test.tsx` | Wave 0 |

### Sampling Rate
- **Per task commit:** `cd pwa && npx vitest run src/routes/RootErrorBoundary.test.tsx src/routes/NotFound.test.tsx src/components/Skeleton.test.tsx`
- **Per wave merge:** `cd pwa && npx vitest run`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `pwa/src/routes/RootErrorBoundary.test.tsx` — covers UX-01 (root boundary render)
- [ ] `pwa/src/routes/AppErrorBoundary.test.tsx` — covers UX-01 (app boundary render)
- [ ] `pwa/src/components/Skeleton.test.tsx` — covers UX-02 (skeleton card renders N divs)
- [ ] `pwa/src/routes/NotFound.test.tsx` — covers UX-03 (404 heading + home link)

## Sources

### Primary (HIGH confidence)
- React Router official docs (`https://reactrouter.com/how-to/error-boundary`) — `ErrorBoundary` route property, `useRouteError`, `isRouteErrorResponse`
- React Router official docs (`https://reactrouter.com/en/main/route/error-element`) — `errorElement` vs `ErrorBoundary` distinction
- CSS `@keyframes` spec — shimmer via `background-position` animation is a CSS standard, zero risk

### Secondary (MEDIUM confidence)
- npm registry listing for `react-error-boundary` — confirmed version 6.0.0, React 19 compatible; ruled out as unnecessary given React Router 7 built-in support
- GitHub discussion `remix-run/react-router#11456` — confirmed `ErrorBoundary` (component) and `errorElement` (element) are functionally equivalent

### Tertiary (LOW confidence)
- None — all critical claims verified against official documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — React Router 7 and Vitest already installed; no new dependencies
- Architecture: HIGH — `ErrorBoundary` route property and `path="*"` documented in official React Router 7 docs
- Pitfalls: HIGH — `useRouteError` scoping and `path="*"` placement verified against official docs and router source

**Research date:** 2026-03-21
**Valid until:** 2026-09-21 (stable — React Router 7 semver stable, CSS `@keyframes` is a CSS standard)
