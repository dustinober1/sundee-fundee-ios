# Project Research Summary

**Project:** Sundee Fundee — Cross-Platform Rewrite (React Native + Expo + Firebase)
**Domain:** Cycle-aware strength training app (iOS, Android, Web)
**Researched:** 2026-03-14
**Confidence:** HIGH

## Executive Summary

Sundee Fundee is a validated iOS strength training product being ported to React Native + Expo for cross-platform reach. The iOS app has a proven domain layer (cycle adaptation, injury engine, benchmark scoring, rehab generation) that ports directly to TypeScript with identical architecture — this is the project's strongest asset and the correct starting point for the rewrite. Experts building this class of app in 2026 use Expo SDK 55 (managed workflow with a development client), React Native Firebase for offline-first Firestore, Zustand for state, RevenueCat for unified cross-platform subscriptions, and NativeWind v4 for styling. The stack is well-documented, widely adopted, and directly compatible with the app's requirements.

The recommended approach is a strict layered build: domain logic ported and tested before any UI, repository interfaces defined before implementations, Firebase Auth and security rules written before any data is stored. This mirrors how the iOS app was built and preserves the 100% tested domain layer as the project's competitive moat. The core differentiators — cycle-aware load adaptation, injury modification engine, and AI workout generation — exist nowhere else as an integrated cross-platform offering. No mainstream competitor (Hevy, Strong, Fitbod, FitrWoman) combines all three.

The primary risks are infrastructure decisions made in Phase 1: using the wrong Firebase SDK (JS vs. native), deferring Firestore security rules on health data, and not establishing the Stripe webhook for RevenueCat entitlement sync. Each of these is extremely costly to fix mid-project. A secondary risk is numeric/date semantic drift when porting Swift domain logic to TypeScript — this is subtle, silent, and directly impacts the product's core value proposition. Both risks are fully preventable with the correct sequencing in the roadmap.

---

## Key Findings

### Recommended Stack

The stack centers on Expo SDK 55 (React Native 0.83, New Architecture mandatory) with a custom development client via EAS Build — Expo Go cannot be used because React Native Firebase, RevenueCat, and MMKV all require native modules. React Native Firebase (`@react-native-firebase/*`) is the only correct choice for Firestore offline persistence in React Native; the Firebase JS SDK silently fails on persistence in this environment. State is split between Zustand (client/auth/UI state) and TanStack Query (server state, AI calls), mirroring the iOS ViewModel pattern with less boilerplate. RevenueCat v9 handles iOS, Android, and Web subscriptions from a single SDK — no separate Stripe integration is needed because RevenueCat Web Billing (Stripe-backed) unifies entitlements across platforms.

**Core technologies:**
- Expo SDK 55 + React Native 0.83: Universal framework — New Architecture is mandatory, start clean
- React Native Firebase (~21.x): Offline-first Firestore, Auth, Cloud Functions — native SDK required for persistence
- Zustand v5: Auth routing, UI state — maps directly to iOS AppState/ViewModel pattern
- TanStack Query v5: Server state caching for programs, WOD, AI calls
- RevenueCat (react-native-purchases v9): Unified subscriptions across iOS/Android/Web
- NativeWind v4 + Gluestack UI v3: Art Deco design tokens cross-platform (use v4, not v5 preview)
- MMKV v3: Synchronous local storage for workout execution hot paths (30x faster than AsyncStorage)
- Firebase Cloud Functions v2: Gemini AI proxy (replaces Cloudflare Worker), WOD admin writes
- TypeScript 5.x: Required for safe domain logic port from Swift
- date-fns v4 + zod v3: Date arithmetic (cycle calculations) and runtime Gemini output validation

**Critical version constraints:**
- NativeWind v4 requires Tailwind CSS v3 (not v4) — NativeWind v5 is unstable as of March 2026
- Expo SDK 55 requires Node.js 20.19.4+, 22.13.0+, or 24.3.0+ — Node 18 not supported
- All `@react-native-firebase/*` packages must be the same version — install via `npx expo install`
- React Native Firebase + Expo SDK 55 requires `expo-build-properties` with `forceStaticLinking: true`

### Expected Features

Research confirms no major competitor combines cycle-aware strength programming + injury modification + AI workout generation in a single cross-platform app. This is the market gap Sundee Fundee occupies.

**Must have (table stakes):**
- Offline-first workout logging (sets, reps, weight) — gyms have dead zones; data loss is unforgivable
- Rest timer with background support — critical path for active workout
- Exercise library (200+ exercises) — logging requires findable exercises
- Personal records and 1RM tracking — primary retention mechanic
- Workout history with source filtering — users reference past sessions
- Progress charts and analytics — visualizing gains is the motivation loop
- Firebase Auth: Apple Sign-In, Google Sign-In, Email/Password, Guest mode
- Cloud sync via Firestore — multi-device expected by 2026 users
- Program/plan catalog — structured training for users who want it
- Settings: units (lbs/kg), theme

**Should have (competitive advantage):**
- Cycle phase tracking and load adaptation — primary differentiator; no cross-platform competitor does this
- Injury profile + adaptation engine — second differentiator; automated substitution at depth no competitor offers
- AI workout generation (Gemini) with offline fallback — third differentiator, requires Cloud Function
- Benchmark catalog with result tracking — sport-performance positioning; unique among competitors
- RevenueCat + Stripe dual pricing — lower web price incentivizes direct purchase, reduces App Store cut
- Art Deco aesthetic — distinctive identity in a sea of neon fitness apps
- PR detection with prominent display — retention signal
- WOD (Workout of the Day) feed — engagement loop, requires admin tooling

**Add after validation (v1.x):**
- Readiness survey integration with AI prompt context
- Pain trend analysis UI (data collected at v1, surface insights in v1.1)
- Phase transition advisor UI
- HealthKit / Health Connect write-back
- Rehab session generation

**Defer (v2+):**
- Exercise video demos (CDN cost; validate MAU first)
- Social features / friend leaderboard (moderation cost; validate retention first)
- Wearable native apps (Wear OS / watchOS are distinct SDKs)
- Nutrition phase guidance (editorial content, not a feature at launch)

**Anti-features — do not build:**
- Social feed (shifts product identity; moderation cost is a second product)
- Real-time coaching / live classes (separate streaming infrastructure product)
- Nutrition macro tracking (dilutes strength training focus)

### Architecture Approach

The architecture follows the iOS app's layered pattern translated to React Native: pure TypeScript domain layer (zero framework dependencies) at the base, repository interfaces above it (swapping Firestore vs. AsyncStorage implementations based on auth mode), Zustand stores for cross-cutting global state, feature hooks (use-cases) that orchestrate domain + repos, and feature screens at the top. This maps directly: `src/domain/` = iOS `Domain/`, `src/repositories/` = iOS `Repositories/`, feature hooks = iOS ViewModels. The repository factory pattern is required — authenticated users get Firestore repos, guest users get AsyncStorage repos, with consumers unaware of which they hold.

**Major components:**
1. Domain layer (`src/domain/`) — Pure TypeScript, zero deps; cycle math, injury engine, benchmark scoring, pain analysis, rehab generation
2. Repository layer (`src/repositories/`) — Typed interfaces + Firestore/AsyncStorage implementations; factory selects by auth mode
3. Zustand stores (`src/stores/`) — Auth state, subscription entitlements, UI flags only; feature state stays in hooks
4. Feature hooks (`src/hooks/`) — Orchestrate domain calls + repo calls; analogous to iOS ViewModels
5. Feature screens (`src/features/`) — Expo Router file-based pages; one directory per tab
6. Firebase Cloud Functions — Gemini proxy (AI workout gen), WOD admin writes; not used for offline-critical paths

**Critical patterns:**
- Never `await` Firestore writes in user-interactive flows — fire-and-forget, optimistic UI update
- Never use Firestore transactions for offline-capable writes — transactions require server round-trip
- Always check RevenueCat entitlements (never check Apple/Google directly) — unified across platforms
- Use Firebase UID as RevenueCat `appUserID` — links entitlements to identity

### Critical Pitfalls

1. **Wrong Firebase SDK (JS vs. native)** — Install `@react-native-firebase` from day one; abandon Expo Go immediately; never mix JS SDK and native SDK in the same project. Recovery if discovered mid-project is a full SDK swap across all Firebase references.

2. **Firestore writes blocking UI offline** — Never `await` write operations in interactive flows. Fire-and-forget writes, optimistic local state, `onSnapshot` listeners for state. Test: airplane mode + complete workout + verify no UI freeze.

3. **Firestore security rules left open on health data** — Write production security rules on day one, before any data is stored. Cycle logs, injury profiles, and readiness survey responses are among the most sensitive personal health data categories. Run a rules test suite in CI.

4. **RevenueCat + Stripe entitlement gap** — Build the Stripe webhook → Firebase Cloud Function → RevenueCat REST API pipeline before shipping Stripe checkout. Web subscribers will not get entitlements without it. This is not automatic.

5. **Domain logic numeric/date drift in TypeScript port** — Store all dates as Unix timestamps. Use `Math.floor()` for integer division. Mirror every Swift domain test with TypeScript counterpart using identical inputs. Benchmark `roundsAndReps` scoring is particularly susceptible to floating-point noise.

6. **Sign in with Apple missing user data on subsequent logins** — Apple only returns name and email on first authorization. Persist both to Firestore in the auth callback, before any navigation. Test by: sign in, revoke in iOS Settings, sign in again, verify display name.

7. **OTA updates breaking native-dependent code** — Run Expo fingerprint diff before every OTA push. If any dependency changed its native surface, do a full EAS Build instead. Never OTA-push subscription/payment changes.

---

## Implications for Roadmap

Architecture research establishes a strict dependency order: domain before repos, repos before auth, auth before features. Pitfalls research establishes that several decisions in Phase 1 are nearly impossible to reverse mid-project. The phase structure below reflects both constraints.

### Phase 1: Foundation and Infrastructure
**Rationale:** Three pitfalls are catastrophic if deferred — wrong Firebase SDK, open security rules, and missing Stripe webhook. All three must be resolved before any feature work. Firebase Auth, the development client setup, and Firestore security rules are prerequisites for every subsequent phase.
**Delivers:** Working EAS development build; Firebase Auth (Apple, Google, Email, Guest); Firestore with production security rules; RevenueCat initialized with Firebase UID; Stripe webhook → RevenueCat sync pipeline; CI with fingerprint checks; no Expo Go.
**Addresses:** Auth (table stakes), Cloud sync (table stakes), Guest mode (table stakes)
**Avoids:** Firebase SDK wrong choice (Pitfall 1), Firestore security rules open (Pitfall 6), RevenueCat Stripe sync gap (Pitfall 7), OTA update crashes (Pitfall 4), Sign in with Apple data loss (Pitfall 5)
**Research flag:** Standard patterns — well-documented Firebase + Expo + RevenueCat setup. Skip research phase.

### Phase 2: Domain Layer Port
**Rationale:** The domain layer is the project's competitive moat and has zero dependencies — it can be built and fully tested before any UI or backend work. All differentiating features (cycle adaptation, injury engine, benchmarks, pain analysis) depend on domain types and functions being correct. Bugs introduced here propagate to every downstream feature.
**Delivers:** Full TypeScript port of all 21+ iOS Swift domain files; 100% test coverage; parity tests against Swift baseline for cycle phase inference, injury multipliers, benchmark scoring, and 1RM calculations; confirmed correct numeric/date semantics.
**Addresses:** Cycle-aware adaptation (differentiator), Injury engine (differentiator), Benchmark scoring (differentiator)
**Avoids:** Domain logic numeric/date drift (Pitfall 8)
**Research flag:** Standard patterns — direct Swift-to-TypeScript port with pure Jest tests. Skip research phase.

### Phase 3: Data Layer and Offline Architecture
**Rationale:** All features that store or retrieve data depend on the repository layer being in place. The offline-first guarantee — the single most important reliability requirement — must be established here, not bolted on later. Repository interfaces, Firestore implementations, local (AsyncStorage) guest implementations, and the repository factory must all be in place before feature screens consume them.
**Delivers:** Repository interfaces for all data types (workouts, cycles, injuries, programs, benchmarks); Firestore implementations with offline persistence verified; AsyncStorage implementations for guest mode; repository factory; Zustand stores wired; Firebase emulator suite running locally.
**Addresses:** Offline functionality (table stakes), Guest mode (table stakes), Multi-device sync (table stakes)
**Avoids:** Firestore writes blocking UI offline (Pitfall 2), Firestore transactions for offline-capable writes (Architecture anti-pattern)
**Research flag:** Standard patterns. Skip research phase.

### Phase 4: Core Workout Execution
**Rationale:** Workout logging is the product's primary loop. Everything else enhances it. Rest timer background behavior, PR detection, exercise library, and the history view all depend on workout logging working correctly first. This phase produces the core retention mechanic.
**Delivers:** Exercise library (200+ exercises); workout logging (offline-verified); rest timer with background support and screen-lock survival; PR detection with prominent display; workout history with source filtering; progress charts.
**Addresses:** Workout logging (P1), Rest timer (P1), Exercise library (P1), PR detection (P1), Workout history (P1), Progress charts (P1)
**Avoids:** Workout timer dying on screen lock (UX Pitfall), FlatList performance on history list (Performance Pitfall), No offline indicator during workout execution (UX Pitfall)
**Research flag:** Background task timer implementation may need targeted research — `expo-task-manager` behavior on Android is less documented than iOS. Consider a focused research spike before implementing.

### Phase 5: Differentiating Features (Cycle, Injury, AI)
**Rationale:** These are the product's identity. They depend on the domain layer (Phase 2) and data layer (Phase 3) being in place. Cycle tracking must be fully opt-in — non-cycle users must have full functionality without any cycle gate. AI generation requires an offline fallback before it can ship.
**Delivers:** Cycle phase tracking and load adaptation; injury profile and adaptation engine; AI workout generation via Firebase Cloud Functions (Gemini) with offline templated fallback; readiness survey (basic capture); program catalog with Firestore delivery and bundled JSON fallback; benchmark catalog and result recording.
**Addresses:** Cycle-aware adaptation (P1 differentiator), Injury engine (P1 differentiator), AI workout generation (P1 differentiator), Program catalog (P1), Benchmark catalog (P2)
**Avoids:** Cycle data shown to users who skipped opt-in (UX Pitfall), AI generation without offline fallback (launch blocker), Cloud Function cold start UX failure (Performance Pitfall)
**Research flag:** Firebase Cloud Functions v2 minimum instance configuration and cold start mitigation may benefit from a targeted research spike, particularly around concurrency settings for the Gemini proxy.

### Phase 6: Subscriptions and Monetization
**Rationale:** The RevenueCat + Stripe webhook pipeline was wired in Phase 1. This phase builds the paywall UI, entitlement gates around premium features, and the subscription management screens. Paywalls must not interrupt the first workout — gate premium features only, ensure core execution is free.
**Delivers:** RevenueCat paywall UI (iOS App Store, Google Play); RevenueCat Web Billing (Stripe) checkout; entitlement gates on cycle adaptation and AI generation; subscription management and restore purchases; customer center UI; account management and data export.
**Addresses:** RevenueCat + Stripe dual pricing (differentiator), Account management (table stakes)
**Avoids:** Paywall interrupting first workout attempt (UX Pitfall), Entitlement check against Apple/Google directly (Architecture anti-pattern)
**Research flag:** RevenueCat Web Billing paywall UI customization in React Native is less-documented than native mobile flows. A targeted research spike recommended before implementation.

### Phase 7: Polish, Security, and Pre-Launch
**Rationale:** Art Deco UI consistency across iOS and Android requires deliberate cross-platform testing. Android navigation conventions, keyboard handling, and bottom sheet behavior all need explicit attention. Firebase App Check, final security audit, and OTA update policy must be enforced before launch.
**Delivers:** Art Deco design system refinement (cross-platform); Android material convention adaptations; keyboard handling (`react-native-keyboard-controller`); Firebase App Check (DeviceCheck + Play Integrity); final Firestore security rules audit; performance profiling (FlatList, bundle size); OTA fingerprint policy in CI; App Store and Play Store submission via EAS Submit.
**Addresses:** Art Deco aesthetic (differentiator), Security hardening
**Avoids:** Art Deco not adapted for Android (UX Pitfall), Firebase API key abuse without App Check (Security Pitfall)
**Research flag:** Standard patterns. Skip research phase.

### Phase 8: v1.x Enhancements (Post-Launch)
**Rationale:** These features extend value for validated users. WOD feed requires admin tooling (WOD dashboard already exists). Pain trend analysis and phase transition advisor collect data in Phase 5 — the UI surfaces in v1.1. Rehab session generation validates injury profile adoption before investing further.
**Delivers:** WOD (Workout of the Day) feed with cycle phase annotations; pain trend analysis UI; phase transition advisor UI; readiness survey AI prompt integration; HealthKit / Health Connect write-back; rehab session generation.
**Addresses:** WOD feed (P2), Readiness survey (P2), Pain trend analysis (P2), Phase transition advisor (P2), Rehab session generation (P2)
**Research flag:** Health Connect (Android) may need a research spike — Google Play whitelist approval timeline affects delivery schedule.

### Phase Ordering Rationale

- Phase 1 before everything: Wrong Firebase SDK and open security rules on health data are the two decisions that cannot be undone without destroying prior work. The Stripe webhook must also exist before the payment UI is built.
- Phase 2 before Phase 3: Domain interfaces define the types that repositories store and return. Building repos against undefined domain types wastes work.
- Phase 3 before Phase 4: Workout logging requires the repository layer. Building screens before repos invites hardcoded data access that becomes technical debt.
- Phase 4 before Phase 5: Core workout loop must work before differentiating features are layered on. Cycle adaptation and injury engine modify an existing workout — the workout must exist first.
- Phase 5 before Phase 6: Paywall gates must know which features they protect. Feature implementation confirms what is free vs. premium.
- Phase 7 last before launch: Polish and security are gate checks, not build sequences.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (workout execution):** Background timer implementation on Android (`expo-task-manager` foreground service) — behavior diverges from iOS and community docs are sparse.
- **Phase 5 (AI generation):** Firebase Cloud Functions v2 minimum instance configuration for Gemini proxy — cold start mitigation specifics under Expo's callable function pattern.
- **Phase 6 (payments):** RevenueCat Web Billing paywall UI in React Native — less documented than native mobile RevenueCat flows; Stripe webhook verification in Firebase Cloud Functions.
- **Phase 8 (Health Connect):** Google Play whitelist approval process and timeline — affects whether HealthKit/Health Connect parity is achievable in v1.x or must slip to v2.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Firebase + Expo + RevenueCat setup is heavily documented with official guides.
- **Phase 2:** Pure TypeScript port with Jest — no framework involvement.
- **Phase 3:** Repository pattern with Firestore offline persistence is well-documented in official React Native Firebase docs.
- **Phase 7:** App Store submission via EAS Submit is well-documented; App Check setup has official Firebase guides.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core libraries (Expo SDK 55, React Native Firebase, RevenueCat v9, NativeWind v4) verified against official documentation. Version compatibility matrix cross-checked. Firebase JS SDK vs. native pitfall is well-established with multiple independent sources. |
| Features | HIGH | Competitor analysis based on multiple sources (Hevy, Strong, Fitbod, FitrWoman). Table stakes features are industry-standard. Differentiators validated by iOS app's existing implementation. Anti-features identified by first principles + gamification research (PMC study). |
| Architecture | HIGH | Layered architecture mirrors proven iOS app structure. Firestore offline persistence behavior, repository factory pattern, and RevenueCat entitlement model are all verified against official docs. Build order derived from actual dependency graph. |
| Pitfalls | HIGH | All critical pitfalls verified against official Firebase, Expo, RevenueCat, and Apple documentation. Several (Firebase SDK dual package hazard, Sign in with Apple data loss) confirmed by published issue trackers with user-reported cases. |

**Overall confidence:** HIGH

### Gaps to Address

- **Background timer specifics (Android):** `expo-task-manager` foreground service behavior on Android needs a targeted implementation spike in Phase 4. iOS behavior is well-documented; Android diverges and community docs are inconsistent.
- **RevenueCat Web Billing UI customization depth:** How much the React Native purchases UI can be themed to match Art Deco aesthetic is unclear from documentation. Validate during Phase 6 planning.
- **Health Connect approval timeline:** Google Play whitelist propagation (5-7 days per official docs) may be longer in practice. Do not commit to Health Connect in a phase with a hard deadline without validating current approval timelines.
- **Entitlement gate placement (free vs. premium):** The recommendation is cycle adaptation and AI workouts are premium; basic logging and programs are free. This must be validated against actual user onboarding conversion before being locked in as a business rule.
- **Firebase App Check emulator bypass:** Development builds with App Check enforced will block the Firebase emulator suite. The bypass configuration pattern for development builds needs confirmation before Phase 1 closes.

---

## Sources

### Primary (HIGH confidence)
- [Expo SDK 55 Changelog](https://expo.dev/changelog/sdk-55) — SDK version, RN 0.83, New Architecture mandatory
- [Expo — Using Firebase Guide](https://docs.expo.dev/guides/using-firebase/) — JS SDK vs. native Firebase RN guidance
- [React Native Firebase — rnfirebase.io](https://rnfirebase.io/) — Offline persistence, Expo compatibility
- [Firebase — Access data offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline) — Offline persistence platform support matrix
- [RevenueCat — Expo Installation](https://www.revenuecat.com/docs/getting-started/installation/expo) — Setup, development build requirement
- [RevenueCat — Web Billing announcement](https://www.revenuecat.com/blog/engineering/revenuecat-react-native-sdk-adds-react-native-web-support/) — Web Billing via Stripe in react-native-purchases v9.7.6+
- [Firebase JS SDK Issue #7947](https://github.com/firebase/firebase-js-sdk/issues/7947) — Confirms Firestore persistence not supported in Firebase JS SDK for RN
- [NativeWind Installation](https://www.nativewind.dev/docs/getting-started/installation) — v4 setup, v5 preview status
- [Firestore Insecure Rules — Firebase Docs](https://firebase.google.com/docs/firestore/security/insecure-rules) — Rules security guidance
- [RevenueCat — Cross-platform subscriptions](https://www.revenuecat.com/blog/engineering/cross-platform-subscriptions-ios-android-web/) — Unified entitlements architecture

### Secondary (MEDIUM confidence)
- [Galaxies.dev — React Native Tech Stack 2025](https://galaxies.dev/article/react-native-tech-stack-2025) — Community consensus on Zustand + TanStack Query
- [RNF Issue #8657](https://github.com/invertase/react-native-firebase/issues/8657) — Expo SDK 54/55 build fix with forceStaticLinking
- [Expo SDK 53 Firebase Breaking Integration — Issue #36602](https://github.com/expo/expo/issues/36602) — JS SDK + Expo SDK 53+ conflict details
- [Best Strength Training Apps 2026 — findyouredge.app](https://www.findyouredge.app/news/best-strength-training-apps-2026) — Competitor feature comparison
- [FlatList Performance — React Native Official](https://reactnative.dev/docs/optimizing-flatlist-configuration) — List performance optimization
- [5 OTA Update Best Practices — Expo Blog](https://expo.dev/blog/5-ota-update-best-practices-every-mobile-team-should-know) — Fingerprint policy, update channels
- [Firestore Offline Gotchas — Better Programming](https://betterprogramming.pub/a-few-gotchas-to-consider-when-working-with-firestores-offline-mode-and-react-native-42al) — Practical offline pitfalls
- [RevenueCat Stripe Billing Integration](https://www.revenuecat.com/docs/web/integrations/stripe) — Webhook sync requirements
- [react-native-mmkv GitHub](https://github.com/mrousavy/react-native-mmkv) — Performance benchmarks vs. AsyncStorage

### Tertiary (LOW confidence — validate during implementation)
- [Making Apple Auth Work with Firebase in Expo](https://vandevliet.me/making-apple-authentication-work-with-firebase-auth-w-react-native/) — Sign in with Apple edge cases
- [Expo — Managed to Bare Workflow Migration](https://oneuptime.com/blog/post/2026-01-15-expo-managed-to-bare-workflow/view) — Ejection cost evidence
- [FitrWoman App Store listing](https://apps.apple.com/us/app/fitrwoman/id1189050449) — Cycle app feature set reference

---
*Research completed: 2026-03-14*
*Ready for roadmap: yes*
