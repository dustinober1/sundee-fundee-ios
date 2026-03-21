# PWA Conversion Plan: Expo → Vite + React Router + Stripe

## Overview

Convert Sundee Fundee from React Native + Expo to a pure web PWA using Vite, React Router v7, and Stripe-only payments. Deploy as a single URL accessible on any device.

**What stays:** `src/domain/` (47 files, ~9,719 LOC pure TS), Firebase backend, Firestore rules, Cloud Functions, theme tokens, bundled resources (programs.json, exercises.json, wods.json).

**What goes:** React Native, Expo, RevenueCat, EAS, Metro, all `expo-*` packages, `react-native-*` packages.

---

## Phase 1: Project Scaffolding

### 1.1 Initialize Vite + React + TypeScript project
- Create `pwa/` directory at repo root (parallel to existing app during migration)
- `npm create vite@latest pwa -- --template react-ts`
- Install core dependencies:
  - `react-router` v7 (routing)
  - `vite-plugin-pwa` (service worker, manifest, offline)
  - `firebase` JS SDK (auth, firestore, analytics, functions, app-check, messaging)
  - `date-fns` v4 (already used)
  - `jszip` (CSV/ZIP export)
  - `stripe` (via Stripe.js + `@stripe/stripe-js`)

### 1.2 Configure PWA manifest
- `manifest.json`: app name, icons, `display: standalone`, theme color (#0D1A40 navy), background (#F4F0DF cream)
- Service worker via `vite-plugin-pwa` with Workbox for offline caching
- Cache strategies: network-first for Firestore, cache-first for static assets

### 1.3 Set up path aliases
- Match existing `@/src/*` alias in `vite.config.ts` so domain/repo imports stay unchanged

---

## Phase 2: Copy Portable Layers (Zero Changes)

### 2.1 Domain layer → copy as-is
- `src/domain/**` — 47 files, pure TypeScript, zero dependencies
- All unit tests come along unchanged

### 2.2 Theme tokens → convert to CSS custom properties
- `src/theme/colors.ts` → keep as TS exports AND generate `theme.css` with CSS variables
- `src/theme/typography.ts` → keep as TS exports AND generate typography CSS

### 2.3 Resources → copy as-is
- `resources/programs.json`, `resources/exercises.json`, `resources/wods.json`

---

## Phase 3: Firebase Integration (Minimal Changes)

### 3.1 Firebase init for web
- Use existing `src/firebase/auth.web.ts` as starting point
- Configure: Auth, Firestore, Analytics, Functions, App Check (reCAPTCHA v3), Cloud Messaging (web push via service worker)
- Remove all `@react-native-firebase/*` references — web SDK only

### 3.2 Repository layer — keep Firestore repos, drop Local repos
- Keep all `Firestore*Repo.ts` files — they use the Firebase JS SDK already
- Replace `AsyncStorage` local repos with `localStorage`/`IndexedDB` implementations
- The repository interfaces (`*Repo.ts`) stay identical
- `migration.ts` — adapt for localStorage → Firestore migration (guest → auth)

### 3.3 Auth layer
- Keep `AuthContext.tsx` — adapt from `onAuthStateChanged` (RN Firebase) to web SDK
- Keep `useEmailAuth.ts` — swap to `firebase/auth` web imports
- Keep `useGoogleSignIn.ts` — use `signInWithPopup` + `GoogleAuthProvider`
- Keep `useGuestSignIn.ts` — `signInAnonymously` works the same
- Apple Sign-In — use `signInWithPopup` + `OAuthProvider('apple.com')`
- Drop `useAppleSignIn.ts` (Expo-specific) — rewrite as web OAuth
- Drop `expo-secure-store` usage — no longer needed (web auth is cookie/token based)

---

## Phase 4: Routing (React Router v7)

### 4.1 Route structure
Map existing Expo Router file structure to React Router:

```
src/routes/
├── root.tsx                    → Root layout (Firebase init, providers)
├── sign-in.tsx                 → /sign-in
├── verify-email.tsx            → /verify-email
├── onboarding/
│   ├── layout.tsx
│   ├── name.tsx                → /onboarding/name
│   ├── experience.tsx          → /onboarding/experience
│   ├── goal.tsx                → /onboarding/goal
│   ├── gender.tsx              → /onboarding/gender
│   └── cycle.tsx               → /onboarding/cycle
├── app/
│   ├── layout.tsx              → Auth guard + nav layout
│   ├── dashboard.tsx           → / (home)
│   ├── history.tsx             → /history
│   ├── maxes.tsx               → /maxes
│   ├── cycle.tsx               → /cycle
│   ├── settings.tsx            → /settings
│   ├── exercise-detail.tsx     → /exercises/:id
│   ├── exercise-picker.tsx     → /exercises/pick
│   ├── workout-session.tsx     → /workout
│   ├── workout-detail.tsx      → /workout/:id
│   ├── timer-mode.tsx          → /workout/timer
│   ├── programs/
│   │   ├── index.tsx           → /programs
│   │   ├── detail.tsx          → /programs/:id
│   │   └── session.tsx         → /programs/:id/session
│   ├── benchmarks/
│   │   ├── index.tsx           → /benchmarks
│   │   ├── detail.tsx          → /benchmarks/:id
│   │   └── create.tsx          → /benchmarks/create
│   ├── injuries/
│   │   ├── index.tsx           → /injuries
│   │   ├── detail.tsx          → /injuries/:id
│   │   └── body-map.tsx        → /injuries/body-map
│   ├── ai-workout/
│   │   ├── config.tsx          → /ai-workout
│   │   └── preview.tsx         → /ai-workout/preview
│   ├── wods.tsx                → /wods
│   └── goodbye.tsx             → /goodbye
```

### 4.2 Navigation
- Bottom tab bar → responsive: bottom tabs on mobile viewports, sidebar on desktop
- `useNavigate()` replaces `router.push()` / `router.replace()`
- `useParams()` replaces `useLocalSearchParams()`
- `<Navigate to>` replaces `<Redirect href>`

---

## Phase 5: UI Rewrite (React Native → HTML/CSS)

### 5.1 Component mapping

| React Native | Web Replacement |
|---|---|
| `<View>` | `<div>` |
| `<Text>` | `<span>`, `<p>`, `<h1>`-`<h6>` |
| `<ScrollView>` | `<div>` with `overflow-y: auto` |
| `<Pressable>` | `<button>` |
| `<TextInput>` | `<input>` / `<textarea>` |
| `<Modal>` | `<dialog>` or portal-based modal |
| `<FlatList>` | `<div>` with map (virtualize with `@tanstack/react-virtual` if needed) |
| `<ActivityIndicator>` | CSS spinner |
| `<Image>` | `<img>` |
| `StyleSheet.create()` | CSS modules or Tailwind CSS |
| `Platform.OS` checks | Remove — web only |

### 5.2 Styling approach
- **CSS Modules** (`.module.css`) for component-scoped styles — closest to current StyleSheet pattern
- OR **Tailwind CSS** for faster development and built-in responsive utilities
- CSS custom properties from theme tokens for consistent Art Deco look
- Responsive breakpoints: mobile (<640px), tablet (640-1024px), desktop (>1024px)

### 5.3 Native module replacements

| Feature | Expo Module | Web Replacement |
|---|---|---|
| Haptics | `expo-haptics` | `navigator.vibrate()` with graceful no-op |
| Audio | `expo-audio` | `new Audio()` HTML5 audio |
| Keep awake | `expo-keep-awake` | `navigator.wakeLock.request('screen')` |
| Network detection | `expo-network` | `navigator.onLine` + event listeners |
| File export | `expo-file-system` + `expo-sharing` | `Blob` + `URL.createObjectURL` + `<a download>` / Web Share API |
| Notifications | `expo-notifications` | Web Notifications API + Firebase Cloud Messaging service worker |
| Gradients | `expo-linear-gradient` | CSS `linear-gradient()` |
| Secure store | `expo-secure-store` | Not needed (Firebase Auth handles tokens) |
| Status bar | `expo-status-bar` | `<meta name="theme-color">` |

### 5.4 Charts
- Replace `react-native-gifted-charts` with a web charting library
- Options: **Recharts** (React-native friendly API), **Chart.js** via `react-chartjs-2`, or lightweight **uPlot**
- Recharts recommended — similar declarative API, good responsive support

### 5.5 Calendar
- Replace `react-native-calendars` with a web calendar component
- Options: **react-day-picker** (lightweight), or custom grid (the cycle calendar is simple enough)

### 5.6 Drag and drop
- Replace `react-native-draggable-flatlist` with **@dnd-kit/core** (best web DnD library)
- Used in workout session for exercise reordering

---

## Phase 6: Payments — Stripe Only

### 6.1 Simplify Cloud Functions
- **Keep** `createCheckoutSession.ts` — works as-is
- **Simplify** `stripeWebhook.ts` — remove all RevenueCat grant/revoke calls, keep Firestore writes only
- **Add** `createPortalSession.ts` — new Cloud Function for Stripe Customer Portal (manage subscription)

### 6.2 Simplify client
- **Remove** RevenueCat (`react-native-purchases`) entirely
- **Simplify** `useEntitlements.ts` — keep only the Firestore `onSnapshot` path (remove mobile/RC path)
- **Simplify** `PaywallModal` → `PricingPage.tsx` — full route instead of modal, Stripe Checkout redirect only
- **Simplify** `EntitlementContext.tsx` — remove platform branching
- **Add** Manage Subscription button in Settings → opens Stripe Customer Portal

### 6.3 Pricing flow
1. User clicks Subscribe → calls `createCheckoutSession` Cloud Function
2. Redirects to Stripe Checkout (hosted by Stripe — handles payment form, 3D Secure, etc.)
3. On success → Stripe webhook fires → Cloud Function writes `premiumEntitlement.active = true` to Firestore
4. `useEntitlements` picks it up via `onSnapshot` → UI updates in real-time
5. Manage/cancel → `createPortalSession` → redirect to Stripe Customer Portal

---

## Phase 7: PWA Configuration

### 7.1 Service worker
- Workbox via `vite-plugin-pwa`
- **Precache**: app shell, CSS, JS bundles, fonts, icons
- **Runtime cache**: Firestore responses (network-first), static assets (cache-first)
- **Offline page**: show cached data, queue writes for sync

### 7.2 Install experience
- `beforeinstallprompt` event → custom "Add to Home Screen" banner
- iOS: `<meta name="apple-mobile-web-app-capable">` + splash screens
- Desktop: Chrome/Edge install prompt

### 7.3 Web Push Notifications
- Firebase Cloud Messaging web SDK
- Service worker handles background messages
- Notification permission request on first workout reminder setup

---

## Phase 8: Deployment

### 8.1 Hosting options (pick one)
- **Firebase Hosting** — simplest since already using Firebase, automatic SSL, CDN
- **Cloudflare Pages** — faster global CDN, already have a Cloudflare worker
- **Vercel** — great DX, preview deployments per PR

### 8.2 CI/CD
- GitHub Actions: build → test → deploy on push to main
- Preview deployments on PRs
- No more EAS builds, no more app store submissions

### 8.3 Domain
- `app.sundeefundee.com` or `sundeefundee.com`

---

## Phase 9: Testing

### 9.1 Existing tests
- `src/domain/**` tests — run unchanged (pure TS)
- Repository tests — adapt mocks from AsyncStorage to localStorage
- Component tests — rewrite with React Testing Library (web, not RN)

### 9.2 New tests
- E2E with Playwright (replaces manual device testing)
- Lighthouse CI for PWA score validation
- Service worker offline tests

---

## Migration Order (Recommended)

| Step | What | Est. Effort | Risk |
|------|------|-------------|------|
| 1 | Scaffold Vite project, copy domain + theme + resources | Low | None |
| 2 | Firebase web init + auth flows | Medium | Auth edge cases |
| 3 | Repository layer adaptation | Low | localStorage ↔ Firestore sync |
| 4 | React Router setup + route definitions | Medium | Route mapping |
| 5 | Core screens: Sign-in, Dashboard, Settings | Medium | UI rewrite |
| 6 | Workout flow: Session, Timer, Exercise Picker | High | Most complex UI |
| 7 | Programs, Benchmarks, History, Maxes | Medium | Mostly list/detail views |
| 8 | Cycle tracking, Injuries, AI Workout | Medium | Charts, body map SVG |
| 9 | Onboarding flow | Low | Simple forms |
| 10 | Stripe payment simplification | Low | Already mostly built |
| 11 | PWA config (manifest, service worker, offline) | Medium | Caching strategy |
| 12 | Responsive design pass | Medium | Mobile/tablet/desktop |
| 13 | Testing (unit, integration, E2E, Lighthouse) | Medium | Coverage |
| 14 | Deploy + DNS | Low | Standard |

---

## What Gets Deleted

- `app/` directory (Expo Router screens)
- All `expo-*` packages
- All `react-native-*` packages
- `app.json`, `eas.json`, `metro.config.js`, `babel.config.js` (Expo config)
- `__mocks__/` (Expo module mocks)
- RevenueCat integration (`react-native-purchases`, RC API calls in webhook)
- `src/firebase/auth.ts` (native) — keep only `auth.web.ts`
- `src/firebase/init.ts` (native init orchestration)
- Platform.OS branching throughout codebase

## What Stays

- `src/domain/**` — all business logic
- `src/theme/**` — design tokens
- `resources/**` — bundled data
- `functions/**` — Cloud Functions (simplified)
- `firestore.rules` — security rules
- `wod-dashboard/` — admin dashboard (already Next.js web app)
- `_legacy-swift/` — archived reference
