# Feature Landscape: PWA + Icon Enrichment

**Domain:** Mobile-first fitness tracking PWA (iOS + Android installable)
**App:** Strength → Sundee-Fundee (rebrand in progress)
**Researched:** 2025-07-15
**Confidence:** HIGH (platform requirements verified against Apple developer docs and web.dev; library availability verified against installed packages)

---

## Table Stakes

Features users expect from a credible installable fitness PWA. Missing any of these = product feels like a website, not an app.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Web App Manifest (`manifest.json`) | Required for install prompt on Android; required for home screen icon on iOS | Low | Must have `name`, `short_name`, `icons`, `display: standalone`, `start_url` |
| App icons — 192×192 PNG | Minimum size for Android home screen / install prompt | Low | Must be included in manifest |
| App icons — 512×512 PNG | Required for Android splash screen; Chrome install criteria | Low | Chrome won't show install prompt without it |
| `apple-touch-icon` 180×180 PNG | iOS Safari "Add to Home Screen" icon | Low | iOS completely ignores the manifest `icons` array; requires `<link rel="apple-touch-icon">` in `<head>` |
| `display: standalone` in manifest | Removes browser chrome (URL bar, back button) on Android | Low | Without this, installed PWA looks like a browser tab |
| `apple-mobile-web-app-capable` meta tag | Enables standalone mode on iOS | Low | Required for iOS to hide Safari chrome |
| `apple-mobile-web-app-status-bar-style` meta tag | Controls iOS status bar appearance | Low | Use `"default"` or `"black-translucent"` |
| `theme_color` in manifest | Chrome uses this for the toolbar color on Android | Low | Should match app's primary color |
| `background_color` in manifest | Splash screen background before app loads | Low | Use white `#ffffff` or app bg color |
| HTTPS deployment | Required for service worker registration; required for PWA install | Low | Already satisfied by Vercel deployment |
| Service worker registered | Required for offline functionality and install criteria | Medium | App already has Dexie offline storage; SW adds network caching on top |
| Offline fallback page | Shows branded page when user is offline and navigates to uncached route | Medium | Prevents blank white screen — critical UX for gym use where WiFi is absent |
| Viewport meta tag with `viewport-fit=cover` | Safe area insets for iPhone notch/Dynamic Island | Low | Add `viewport-fit=cover` to existing viewport meta |
| `short_name` ≤ 12 chars | Home screen icon labels truncate on small phones | Low | "Strength" (8 chars) or new brand name must fit |
| Update notification / reload prompt | When new SW version deploys, prompt user to refresh | Medium | Without this, users run stale code indefinitely |

---

## Differentiators

Features that separate a polished PWA from a bare-minimum one. Not expected, but visibly raise perceived quality.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Maskable icon (192×192 with safe zone) | On Android, icon fills adaptive shape (circle, squircle) instead of appearing on white square | Low-Med | Needs 192px PNG with content confined to center 80% ("safe zone"); declare `"purpose": "maskable"` in manifest |
| App manifest shortcuts | Long-press on home screen icon → quick-start "Log Workout" or "Start Rest Timer" | Low | Up to 4 shortcuts supported on Android; iOS ignores them currently |
| PWA install banner / nudge UI | Prompt logged-in users who visit 3+ times to install; show custom UI instead of default browser prompt | Medium | `beforeinstallprompt` event (Android/Chrome only); iOS requires manual instruction — show a custom tooltip with "Share → Add to Home Screen" |
| iOS install instructions modal | iOS has no install prompt API — must tell users how manually | Low | Detect `navigator.standalone === false` + iOS UA; show bottom sheet with step-by-step Safari Share instructions |
| Splash screen (iOS) | Branded loading screen instead of blank white on app open | Medium-High | Requires `<link rel="apple-touch-startup-image">` with exact pixel-perfect sizes per device (14+ size variants for all iPhones); or use a meta-based approach |
| `screenshots` in manifest | Google Play / Chrome install dialog shows app screenshots | Low | Two screenshots: one narrow (phone), one wide (tablet); improves conversion to install |
| Maskable icon generator tooling | `maskable.app` editor lets you preview adaptive icon in all Android shapes before committing | Low | Tooling recommendation, not code — use during icon creation |
| Dumbbell/BicepsFlexed app icon SVG | App icon uses a recognizable fitness symbol, scales well to all sizes | Low | Current app has no custom icons in `public/`; generate icon from Lucide SVG + brand color |
| `WifiOff` icon in offline banner | Replace current raw SVG inline in `OfflineBanner` with `import { WifiOff }` from lucide-react | Low | Already have `WifiOff` available in lucide-react 0.564; removes inline SVG inconsistency |
| Icon enrichment — workout cards | Use `Dumbbell`, `Weight`, `BicepsFlexed` per exercise category | Low | Currently limited to nav icons; card-level icons add visual scanning affordance |
| Icon enrichment — progress screen | `TrendingUp` for PRs, `Trophy` for milestones, `Flame` for streaks, `BarChart2` for volume | Low | All confirmed available in lucide-react 0.564 |
| Icon enrichment — rest timer | `Timer` for countdown, `AlarmClockCheck` for complete, `SkipForward` for skip rest | Low | All confirmed available; currently timer uses no icons except Play/Pause |
| Icon enrichment — status states | `CircleCheck` for complete, `CircleX` for skipped, `Loader2` for syncing | Low | Consistent status vocabulary across the app |
| `theme-color` meta with dark mode variant | `<meta name="theme-color" media="(prefers-color-scheme: dark)" content="...">` | Low | Keeps Android status bar matching dark mode; requires two meta tags |
| Rebrand in manifest + meta tags | Update `name`, `short_name`, `description` to new brand; update page `<title>` | Low | Currently set to "Strength" in `layout.tsx`; must update before launch |

---

## Anti-Features

Things to explicitly NOT build in v1.1. Common mistakes in this domain.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Background sync API for workout uploads | Background Sync API is Android/Chrome only; iOS Safari does not support it as of 2025 | Use foreground sync on app resume — the existing Supabase sync queue fires on reconnect, which is sufficient |
| Push notifications (Phase 1) | Requires VAPID server setup, notification permission UX, platform-specific payloads; iOS only got Web Push in iOS 16.4 (Safari); adds significant backend complexity | Defer to future milestone; rest timer already handles in-app timing needs |
| Web Share Target (receive shared content) | Niche use case; requires manifest `share_target` entry + server handler; zero user demand for a workout logger | Skip entirely |
| Custom install prompt on desktop browsers | This app is mobile-first; desktop PWA install is a distraction; desktop users prefer the web version | Let desktop browsers show default install affordance (or none); don't build custom desktop install UI |
| Splash screen with per-device image variants | Requires 14+ `<link rel="apple-touch-startup-image">` entries with media queries for every iPhone viewport; becomes maintenance burden immediately | Use a solid `background_color` in manifest + fast app load instead |
| Offline sync conflict resolution UI | Complex CRDT/merge UI; overkill when a single user owns all their data | "Last write wins" is acceptable for solo workout data; document the policy, don't build resolution UI |
| Service worker for API routes (Supabase calls) | Caching Supabase REST responses in the SW cache is risky (stale data, auth token issues) | Let Supabase calls go network-only; cache only static assets and app shell |
| `next-pwa` (legacy, deprecated) | `next-pwa` by cyrilwanner is unmaintained; `@ducanh2912/next-pwa` is the community fork | Use `@serwist/next` instead — actively maintained, supports Next.js 14+ including 16.x |

---

## Platform-Specific Requirements

### iOS PWA (Safari "Add to Home Screen")

iOS PWA support is fundamentally different from Android. Treat as a separate implementation target.

**What iOS ignores from `manifest.json`:**
- The `icons` array — completely ignored. iOS uses `<link rel="apple-touch-icon">` only.
- The `display` field — iOS always runs standalone when added via Safari
- `shortcuts` — not supported
- `screenshots` — not supported

**What iOS requires in `<head>`:**

```html
<!-- Standalone mode (hides Safari chrome) -->
<meta name="apple-mobile-web-app-capable" content="yes">

<!-- Status bar color -->
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<!-- Options: "default" (white bar), "black" (black bar), "black-translucent" (overlaps content) -->

<!-- App name on home screen (overrides <title>) -->
<meta name="apple-mobile-web-app-title" content="Strength">
<!-- Keep ≤ 12 chars for safe display -->

<!-- Home screen icon — iOS picks highest resolution available -->
<link rel="apple-touch-icon" href="/icons/apple-touch-icon.png">
<link rel="apple-touch-icon" sizes="152x152" href="/icons/apple-touch-icon-152x152.png">
<link rel="apple-touch-icon" sizes="167x167" href="/icons/apple-touch-icon-167x167.png">
<link rel="apple-touch-icon" sizes="180x180" href="/icons/apple-touch-icon-180x180.png">
```

**Icon sizes for iOS (verified from Apple developer docs):**
| Size | Device |
|------|--------|
| 180×180 | iPhone (all current models, @3x) |
| 167×167 | iPad Pro |
| 152×152 | iPad, iPad mini |

**iOS-specific limitations to design around:**
- No `beforeinstallprompt` event — you cannot trigger an install prompt programmatically
- No push notifications below iOS 16.4 (when added to home screen only, even then)
- `window.navigator.standalone` = `true` when running as installed PWA — use this to detect install state
- iOS kills service worker when app is backgrounded for >30 seconds; don't rely on SW for long-running background tasks

**iOS install nudge pattern:**
Detect iOS Safari + not standalone, show a bottom sheet saying:
> "Tap the Share button (↑) → Add to Home Screen"
Trigger after 2nd or 3rd session, or when user navigates to workout logging.

---

### Android PWA (Chrome)

Android has first-class PWA support via Chrome's install criteria.

**Chrome install criteria (all must be met):**
1. Served over HTTPS ✓ (Vercel)
2. Has a valid `manifest.json` linked in `<head>`
3. Has a registered service worker with a `fetch` handler
4. Has icons: at minimum 192×192 AND 512×512 PNG

**`manifest.json` minimum for Chrome install prompt:**
```json
{
  "name": "Strength - Workout Tracker",
  "short_name": "Strength",
  "description": "Track workouts, build strength",
  "start_url": "/dashboard",
  "display": "standalone",
  "orientation": "portrait",
  "theme_color": "#000000",
  "background_color": "#ffffff",
  "icons": [
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-192x192-maskable.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

**Maskable icon safe zone rule:**
- Total icon: 192×192px
- Safe zone (content area): center 80% = 153×153px
- Outer 10% (19px each side) is the "bleed zone" — may be cropped on some Android shapes
- Background should be solid color (not transparent) — use app's primary brand color

**Android shortcuts (long-press on icon):**
```json
"shortcuts": [
  {
    "name": "Log Workout",
    "short_name": "Log",
    "url": "/workout",
    "icons": [{ "src": "/icons/shortcut-workout.png", "sizes": "96x96" }]
  },
  {
    "name": "View Progress",
    "short_name": "Progress",
    "url": "/progress",
    "icons": [{ "src": "/icons/shortcut-progress.png", "sizes": "96x96" }]
  }
]
```

---

## Service Worker Caching Strategy

The app already has Dexie.js for data offline. The service worker layer handles **assets and navigation** — not data.

**Recommended tool:** `@serwist/next` v9.5.6 (confirmed: supports Next.js `>=14.0.0`, includes 16.x)

**Caching strategy by resource type:**

| Resource Type | Strategy | Rationale |
|---------------|----------|-----------|
| App shell (HTML, JS chunks) | **Stale-While-Revalidate** | Fast load from cache; updates in background |
| Static assets (images, fonts) | **Cache First** (30-day expiry) | Fonts/images rarely change; network hit is waste |
| Next.js build chunks (`/_next/static/*`) | **Cache First** (immutable) | Hashed filenames = safe to cache forever |
| API routes (`/api/*`) | **Network Only** | Auth, Supabase calls must be fresh |
| Supabase calls (`*.supabase.co`) | **Network Only** | Never cache auth-gated data |
| `/~offline` fallback | **Precached** | Shown when navigation fails offline |

**Offline fallback page `/~offline`:**
- Must be a pre-rendered HTML page in the app
- Should show branded message + explain offline state
- Link to `/dashboard` (which loads from Dexie cache)
- Include `WifiOff` icon (available in lucide-react)

**SW update flow:**
```
SW update detected → show toast "New version available" → button "Update Now" → reload
```
Use `skipWaiting: true` + `clientsClaim: true` in serwist config. Pair with a `useRegisterSW` hook that watches for `waiting` state and shows the in-app prompt.

---

## Icon Requirements Matrix

Complete list of icon files to generate for full coverage:

| File | Size | Purpose | Platform |
|------|------|---------|---------|
| `/public/icons/icon-192x192.png` | 192×192 | Manifest icon | Android |
| `/public/icons/icon-192x192-maskable.png` | 192×192 | Adaptive icon | Android |
| `/public/icons/icon-512x512.png` | 512×512 | Splash screen, install dialog | Android |
| `/public/icons/apple-touch-icon.png` | 180×180 | Fallback Apple touch icon | iOS |
| `/public/icons/apple-touch-icon-180x180.png` | 180×180 | iPhone @3x | iOS |
| `/public/icons/apple-touch-icon-167x167.png` | 167×167 | iPad Pro | iOS |
| `/public/icons/apple-touch-icon-152x152.png` | 152×152 | iPad / iPad mini | iOS |
| `/public/favicon.ico` | 32×32 + 16×16 | Browser tab | All |
| `/public/icons/favicon-32x32.png` | 32×32 | Browser tab (PNG) | All |
| `/public/icons/favicon-16x16.png` | 16×16 | Browser tab legacy | All |

**Icon design recommendation:**
Use a `Dumbbell` or `BicepsFlexed` Lucide icon rendered as SVG to PNG at each required size. Both are confirmed available in lucide-react 0.564. For the app icon, place on a solid-color branded background (use the app's `--primary` color, currently near-black `oklch(0.205 0 0)`). White icon on dark background reads well at small sizes and produces a distinctive app icon.

**Icon generation workflow (no design tools required):**
1. Export the Lucide `Dumbbell` SVG node to a string
2. Wrap in a colored SVG rectangle (branded bg)
3. Use `sharp` npm package to rasterize to PNG at each required size
4. For maskable: ensure icon fills only center 80% of canvas

---

## Lucide Icon Usage Patterns

### Current State (confirmed from codebase scan)

Already in use:
- `LayoutDashboard` — bottom nav Dashboard
- `Dumbbell` — bottom nav Programs
- `ClipboardPlus` — bottom nav Workout
- `TrendingUp` — bottom nav Progress
- `Play`, `Pause`, `SkipForward`, `Timer` — rest timer
- `Calendar`, `Sun`, `Moon`, `Droplets`, `Thermometer`, `HeartPulse` — cycle tracking
- `Plus`, `Minus`, `ChevronUp`, `ChevronDown`, `Check`, `X` — workout input controls
- `Info`, `ArrowRight` — generic UI

The `OfflineBanner` uses a **raw inline SVG** instead of importing `WifiOff` from lucide-react — this is an inconsistency to fix.

---

### Recommended Icon Assignments by UI Context

**App-level & Navigation:**
| Context | Icon | Rationale |
|---------|------|-----------|
| Dashboard | `LayoutDashboard` | Already in use ✓ |
| Programs | `Dumbbell` | Already in use ✓ |
| Workout logging | `ClipboardPlus` | Already in use ✓ |
| Progress | `TrendingUp` | Already in use ✓ |
| Settings (if added) | `Settings2` | Cleaner than `Cog` at small sizes |
| Profile | `User` | Standard convention |

**Workout / Exercise:**
| Context | Icon | Rationale |
|---------|------|-----------|
| Strength/barbell exercises | `Dumbbell` | Direct semantic match |
| Bodyweight exercises | `PersonStanding` or `BicepsFlexed` | Clear human-body reference |
| Cardio / conditioning | `Footprints` or `Bike` | Context-dependent |
| Exercise set complete | `CircleCheck` | Consistent with shadcn/ui patterns |
| Exercise set skipped | `CircleX` | Clear negative state |
| Rep/set input row | `Minus` / `Plus` | Already in use ✓ |
| 1RM / personal record | `Trophy` or `Medal` | Trophy for overall PR; Medal for exercise-specific |
| Rest timer running | `Timer` | Already in use ✓ |
| Rest timer complete | `AlarmClockCheck` | Communicates "alarm triggered" clearly |
| Skip rest | `SkipForward` | Already in use ✓ |

**Progress / Analytics:**
| Context | Icon | Rationale |
|---------|------|-----------|
| Volume over time | `BarChart2` | Bar chart = volume accumulation |
| 1RM trend | `TrendingUp` | Linear progress line |
| PR celebration | `Trophy` or `Zap` | Trophy for records; Zap for energy/power |
| Streak / consistency | `Flame` | Universally understood streak icon |
| Workout frequency | `Calendar` | Already in use ✓ |
| Plateau warning | `Target` | "Off target" semantic |

**Status / System:**
| Context | Icon | Rationale |
|---------|------|-----------|
| Offline state | `WifiOff` | Replace current inline SVG in `OfflineBanner` |
| Online/connected | `Wifi` | |
| Syncing | `Loader2` (animated) + `RefreshCw` | `Loader2` for active sync; `RefreshCw` for "sync now" button |
| Sync complete | `CircleCheck` | |
| New update available | `Download` | "Download new version" semantic |
| Auth / account | `User` | |

**Cycle Tracking (existing feature):**
| Context | Icon | Rationale |
|---------|------|-----------|
| Current phase | `Sun` / `Moon` | Already in use ✓ |
| BBT log | `Thermometer` | Already in use ✓ |
| Symptoms | `Droplets` | Already in use ✓ |
| Cycle calendar | `Calendar` | Already in use ✓ |
| Heart rate / HRV | `HeartPulse` | Already in use ✓ |

---

## MVP Recommendation for v1.1

### Must ship (PWA baseline — all table stakes):

1. **`manifest.json`** with correct icons, `display: standalone`, `theme_color`, `start_url: "/dashboard"`
2. **iOS `<head>` meta tags** — `apple-mobile-web-app-capable`, `status-bar-style`, `apple-mobile-web-app-title`
3. **Apple touch icons** — 180×180, 167×167, 152×152 in `public/icons/`
4. **Android icons** — 192×192 (regular), 192×192 (maskable), 512×512
5. **Service worker** via `@serwist/next` — stale-while-revalidate for app shell, cache-first for static assets, network-only for API
6. **Offline fallback page** at `/~offline` — branded, links to dashboard
7. **Replace `OfflineBanner` inline SVG** with `<WifiOff>` from lucide-react
8. **App rebrand meta** — update `<title>`, manifest `name`/`short_name`, `apple-mobile-web-app-title` to new brand
9. **Viewport `viewport-fit=cover`** — handles iPhone safe area insets

### Ship in v1.1 if effort is low (differentiators with low complexity):

10. **Android shortcuts** in manifest — "Log Workout" → `/workout`, "View Progress" → `/progress`
11. **iOS install nudge** — detect iOS + non-standalone, show "Share → Add to Home Screen" tooltip
12. **SW update notification toast** — "New version available, tap to update"
13. **Icon enrichment pass** — replace missing icons in progress cards, exercise cards (use `Trophy`, `Flame`, `BarChart2`)

### Defer post-v1.1:

- Push notifications — backend complexity, iOS requirements, not needed while rest timer is in-app
- Per-device splash screen images — 14+ variants, fragile maintenance, marginal gain
- Background Sync API — iOS doesn't support it; existing foreground queue is sufficient

---

## Sources

| Claim | Source | Confidence |
|-------|--------|------------|
| iOS ignores manifest `icons` array | [Apple Developer Docs — Configuring Web Applications](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/ConfiguringWebApplications/ConfiguringWebApplications.html) | HIGH |
| iOS apple-touch-icon sizes (180, 167, 152) | Apple Developer Docs (verified same URL) | HIGH |
| `apple-mobile-web-app-capable` required for standalone | Apple Developer Docs (verified same URL) | HIGH |
| Chrome install criteria (HTTPS + manifest + SW + 192+512 icons) | [web.dev — Add a web app manifest](https://web.dev/articles/add-manifest) | HIGH |
| Maskable icon safe zone = center 80% | [web.dev — Maskable icons](https://web.dev/articles/maskable-icon) | HIGH |
| `@serwist/next` v9.5.6 peer deps `next >= 14` | npm registry (verified) | HIGH |
| Serwist implementation steps (withSerwist, sw.ts, manifest) | [serwist.pages.dev/docs/next/getting-started](https://serwist.pages.dev/docs/next/getting-started) | HIGH |
| Lucide icons availability (Dumbbell, Trophy, Flame, WifiOff, etc.) | Verified via `require('./node_modules/lucide-react')` at v0.564.0 | HIGH |
| iOS Background Sync not supported | Community knowledge — not directly verified this session | LOW — verify before relying on this |
| iOS Web Push requires iOS 16.4+ when added to home screen | Community knowledge | LOW — verify before implementing push |
