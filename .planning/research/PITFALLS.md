# Pitfalls Research

**Domain:** React Native + Expo + Firebase fitness app (cross-platform rewrite from native iOS)
**Researched:** 2026-03-14
**Confidence:** HIGH (verified against official docs and multiple independent sources)

---

## Critical Pitfalls

### Pitfall 1: Firebase JS SDK vs React Native Firebase — Wrong SDK for the Job

**What goes wrong:**
Teams start with the Firebase JS SDK (the npm `firebase` package) because it is familiar and well-documented. On Expo SDK 53+, Metro's new `unstable_enablePackageExports: true` default conflicts with Firebase's CommonJS `.cjs` files used for React Native compatibility. Auth components fail to register ("Component auth has not been registered yet"), analytics/Crashlytics/Dynamic Links are unavailable entirely, and offline persistence behaves differently than on native because the JS SDK uses IndexedDB (browser) rather than the native SQLite persistence layer.

**Why it happens:**
The Firebase JS SDK documentation is written for web. Developers reuse what they know. Expo's quick-start guides historically showed the JS SDK, creating muscle memory. Expo SDK 53 broke previously-working JS SDK setups without obvious error messages.

**How to avoid:**
Use `@react-native-firebase` (the Invertase library) from day one. This requires a custom Development Build — do not use Expo Go. Configure EAS Build from project initialization. Never mix the JS SDK and the native Firebase SDK in the same project (this causes the "dual package hazard" that produces silent failures).

**Warning signs:**
- "Component auth has not been registered yet" error
- Auth state is lost on app restart (falling back to in-memory persistence)
- Firestore offline queries returning stale or empty data on cold start
- Build-time Metro errors about `exports` field resolution

**Phase to address:** Project scaffold / Phase 1 — foundation decision. Changing SDK mid-project requires removing all SDK references.

---

### Pitfall 2: Firestore Offline Persistence — await on Writes Blocks UI

**What goes wrong:**
The app is advertised as offline-first. Developers write code like `await firestore().collection('workouts').doc(id).set(data)`. When the device has no connection, this promise does not resolve until the write is acknowledged by the server. The UI freezes or shows a spinner indefinitely during an active gym session. Users see a broken experience at exactly the moment offline-first matters most.

**Why it happens:**
Developers port server-side patterns (await the write, then navigate) to mobile without understanding that Firestore's offline mode uses an optimistic local cache. The write is applied locally immediately, but the SDK does not resolve the promise until the server confirms — which may never happen offline.

**How to avoid:**
Never await Firestore write operations in user-interactive flows. Fire-and-forget: call the write without `await`, update local UI state optimistically, and let Firestore sync in the background. Use Firestore's `onSnapshot` listeners for real-time state rather than awaiting reads after writes.

**Warning signs:**
- UI "freezes" or shows loading spinner when device is in airplane mode
- Workout timers continue but the "save" action appears to hang
- Offline test: put device in airplane mode, complete a workout, observe save behavior

**Phase to address:** Phase covering workout execution and data persistence — before any end-to-end offline testing.

---

### Pitfall 3: Expo Managed Workflow Ceiling — Discovering Native Gaps Too Late

**What goes wrong:**
The project starts in Expo managed workflow for simplicity. Months into development, a required native capability (background task for workout timers, specific HealthKit entitlement, custom notification category, or a native SDK) hits a wall. Ejecting to bare workflow mid-project is disruptive: it invalidates existing EAS Build configurations, breaks OTA update channels, and requires manually managing `ios/` and `android/` directories.

**Why it happens:**
Managed workflow is attractive because it removes native complexity. The Expo docs show compatibility lists, but developers assume "will work eventually" for borderline cases without verifying. Fitness apps specifically have requirements (background audio, persistent timers, foreground service on Android) that push against managed workflow limits.

**How to avoid:**
Audit every required native capability against Expo's managed workflow compatibility list before starting. For this project specifically: background task for active workout timers, HealthKit integration on iOS, RevenueCat StoreKit integration, Sign in with Apple, Firebase Analytics/Crashlytics. If any require bare workflow or a custom Config Plugin not yet available, switch to bare workflow from the start rather than ejecting later. Using EAS Build with a Development Client is not the same as ejecting — prefer Development Client for native modules before considering bare workflow.

**Warning signs:**
- Discovering a library's README says "requires bare workflow" after install
- `expo-doctor` flagging incompatible plugins
- A required feature can only be found as a native-only library with no Expo Config Plugin

**Phase to address:** Phase 1 scaffold — final capability audit before committing to workflow.

---

### Pitfall 4: OTA Updates Breaking Native-Dependent Code

**What goes wrong:**
An OTA update (via Expo Updates / EAS Update) ships a JS bundle change to users. The change uses a dependency that added native code in a minor version bump. Users on the old binary crash silently because the native module the JS bundle references does not exist in the installed binary. This is particularly dangerous for fitness apps where crashes during an active workout are unacceptable.

**Why it happens:**
Teams use OTA updates as a fast-release shortcut without verifying whether dependencies changed their native surface area. A `yarn upgrade` followed by an OTA push is a common mistake. The native module is missing but no build error occurs — it fails only at runtime on user devices.

**How to avoid:**
Use Expo's fingerprint tooling (`expo-updates` fingerprint) to compare native surface area between commits before every OTA push. Establish a rule: if any dependency version changed, do a full EAS Build before pushing OTA. Use separate EAS Update channels (staging, production) and test against representative binaries before rolling out to 100% of users. Never use OTA updates to ship subscription/payment changes.

**Warning signs:**
- Spike in crash rates immediately after an OTA push
- `npx expo install --check` showing version mismatches after `yarn upgrade`
- A library changelog mentioning "added native module" in a minor update

**Phase to address:** CI/CD setup phase — establish policies before any OTA updates are pushed.

---

### Pitfall 5: Sign in with Apple — Missing User Data on Subsequent Logins

**What goes wrong:**
Apple only returns the user's full name and email address on the very first Sign in with Apple authorization. On all subsequent sign-ins, these fields are null. If the app does not persist name and email to Firestore on first login, users end up with no display name, and there is no recovery path short of the user revoking and re-granting Apple login (which most users will not know to do).

**Why it happens:**
Developers test the happy path (first login) and it works perfectly. The email and name appear in the credential. Subsequent logins during development reuse a cached token, masking the bug. It surfaces only after real users install the app and log in a second time on a new device or after revoking app access.

**How to avoid:**
On the very first successful Sign in with Apple, immediately write name and email to Firestore before doing anything else. Treat this write as the most critical step of onboarding. Test by: (1) sign in, (2) revoke Apple authorization in iOS Settings > Apple ID > Sign in with Apple, (3) sign in again, (4) verify the display name is still correct.

Additionally: Firebase does not store user tokens for Sign in with Apple — account deletion requires the user to sign in again before the token can be revoked. Build account deletion with this in mind from the start.

**Warning signs:**
- Display names missing for users who signed up via Apple after initial onboarding
- User complaints about profile showing blank name

**Phase to address:** Auth phase — make this a first-class acceptance criterion for the Apple sign-in implementation.

---

### Pitfall 6: Firestore Security Rules Left Open — Health Data Exposure

**What goes wrong:**
Firestore is initialized in test mode during development (`allow read, write: if true`). The app ships — or a staging environment is accidentally indexed — with open rules. Cycle data, health metrics, injury profiles, and workout history are accessible to anyone who knows the project ID (which is in the app binary and easily extracted via APK decompilation). Automated scanners actively target Firebase projects with open rules.

**Why it happens:**
Test mode is the default for new Firestore projects. Developers focus on features and defer security. Cycle health data and readiness survey responses are among the most sensitive personal health data categories — a breach carries significant regulatory and reputational risk.

**How to avoid:**
Write production security rules on day one, before writing any data. Never ship with test mode rules. Rules must enforce: (1) users can only read/write their own documents (`request.auth.uid == resource.data.userId`), (2) admin collections (programs, WODs) are read-only for users, (3) no user can write admin flag fields. Build a Firestore Rules test suite (`firebase-rules-unit-testing`) and run it in CI. Include rules testing in the definition of "done" for every data model phase.

**Warning signs:**
- Firebase console showing "your rules are insecure" banner
- Ability to query another user's document from a different account in the emulator
- `allow write: if true` anywhere in rules that reached production

**Phase to address:** Phase 1 data architecture — rules must be written alongside the first data model, not after.

---

### Pitfall 7: RevenueCat + Stripe Entitlement Sync — Users Paying Without Getting Access

**What goes wrong:**
A user subscribes via the Stripe web checkout but the mobile app still shows the paywall because RevenueCat has not been notified of the Stripe transaction. This happens because RevenueCat does not automatically poll Stripe — it requires an explicit POST to the RevenueCat REST API linking the Stripe subscription to the app user ID. Similarly, Stripe cancellation events can take up to two hours to reflect in RevenueCat, meaning users who cancelled may retain access and users who purchased may be denied.

**Why it happens:**
RevenueCat's Stripe integration documentation is not prominently featured in the React Native quick-start guides. Teams assume RevenueCat handles all payment sources automatically, as it does for in-app purchases.

**How to avoid:**
Build a Firebase Cloud Function Stripe webhook handler that, on `checkout.session.completed` and `customer.subscription.updated` events, immediately calls the RevenueCat REST API to sync the subscription. Ensure the same `appUserID` is used in both systems — Firebase Auth UID is the right choice as the RevenueCat user identifier. For one-time purchases through Stripe, sync is never automatic; always use the webhook approach.

Entitlement names must match exactly between RevenueCat dashboard and app code — case-sensitive.

**Warning signs:**
- Web subscribers seeing paywall in the mobile app
- Customer support tickets: "I paid but the app says I'm not subscribed"
- RevenueCat dashboard showing user with no active subscriptions despite Stripe showing active subscription

**Phase to address:** Payments phase — design the webhook sync before implementing the Stripe checkout, not after.

---

### Pitfall 8: Domain Logic Port — Floating Point and Date Semantics Differ from Swift

**What goes wrong:**
The iOS app's Domain layer (21+ Swift files) uses Swift's `Date`, integer division, and enum-based type safety. When ported to TypeScript, subtle numeric and date differences cause incorrect cycle phase calculations, wrong benchmark scores, or off-by-one errors in injury recovery phase transitions. JavaScript's `Date` does not distinguish between local and UTC, there is no integer division operator (use `Math.floor(a / b)`), and TypeScript enums behave differently from Swift enums in edge cases.

**Why it happens:**
Swift-to-TypeScript ports feel straightforward because both are statically typed. The differences are subtle: Swift's `Date` is always UTC, JavaScript's `Date.now()` is UTC but `new Date()` displays in local time. Swift uses integer division by default; JS divides to float. Benchmark `roundsAndReps` scoring (`rounds * 10000 + reps`) decodes correctly in Swift's integer math but silently produces floating-point noise in JavaScript without explicit `Math.floor`.

**How to avoid:**
Store all dates as Unix timestamps (seconds since epoch) in Firestore. Never use `new Date()` string representations in stored data. Port every Domain function with a corresponding TypeScript unit test that uses the same inputs as the Swift test suite. Pay specific attention to: benchmark score encoding/decoding, cycle day calculations (period log → phase inference), and injury recovery phase multiplier math. Use `date-fns` or `dayjs` rather than raw `Date` for calendar arithmetic.

**Warning signs:**
- Cycle phase showing "Follicular" when iOS app shows "Luteal" for the same log data
- Benchmark results off by small decimal amounts
- TypeScript tests passing but producing subtly wrong outputs compared to Swift baseline

**Phase to address:** Domain logic port phase — establish baseline parity tests against the Swift domain layer before any UI integration.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use Expo Go instead of dev client for development | Faster local iteration | Firebase native modules won't work; entire auth/Firestore stack unavailable | Never — build a dev client from day one |
| Skip Firestore security rules until "closer to launch" | Faster prototyping | Health data exposed; breach risk; rules written under pressure are buggy | Never — write rules alongside the data model |
| In-memory state for workout session (no persistence) | Simpler initial implementation | Crash mid-workout loses all data; users cannot recover | MVP only if you ship a "resume workout" feature in the same phase |
| Use Firebase JS SDK for early prototyping | Familiar API, no build required | Requires full SDK swap later; offline persistence and Crashlytics unavailable | Only for non-Firebase prototyping throwaway code |
| Skip RevenueCat Stripe webhook | Faster payment integration | Web subscribers never get entitlements | Never — the webhook is not optional for dual payments |
| Hardcode user ID as empty string in fallback | Avoids null check boilerplate | Data written with no owner; security rules cannot protect it | Never — mirrors the iOS CLAUDE.md prohibition |
| Bundle entire domain TypeScript in one file | Easier initial port | Untestable; impossible to unit test individual engines | Never — mirror iOS Domain/ structure from the start |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Firebase Auth + Sign in with Apple | Not storing name/email on first login | Persist to Firestore in the same auth callback, before navigation |
| Firebase Auth + Sign in with Apple (Android) | Skipping nonce SHA256 configuration on Android | Configure `appleAuthAndroid` with state + nonce; test on Android emulator with Play Services |
| RevenueCat + Firebase Auth | Using anonymous device ID as RevenueCat user ID | Use Firebase Auth UID as `appUserID`; call `logIn()` on RevenueCat after Firebase auth resolves |
| RevenueCat + Stripe | Assuming subscription sync is automatic | Build Stripe webhook → Firebase Cloud Function → RevenueCat REST API pipeline |
| Firestore + Expo | Assuming JS SDK offline persistence works same as native | Use `@react-native-firebase/firestore` for native SQLite persistence; JS SDK uses memory-only fallback |
| Firebase Cloud Functions | Assuming instant response for AI generation | Cloud Functions have cold start latency of 5-20s; show a loading state; set minimum instances for production |
| Expo EAS Build | Using Expo Go for testing native modules | Create a Development Build via `eas build --profile development`; distribute via EAS |
| Expo OTA Updates | Pushing after `yarn upgrade` without checking native changes | Run fingerprint diff before every OTA push; full build if any native dep changed |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Inline `renderItem` in FlatList (workout history, program catalog) | Janky scroll; excessive re-renders logged in Profiler | Extract `renderItem` to a named function; wrap in `useCallback`; wrap item component in `React.memo` | Visible from ~50+ items; severe at 200+ |
| No FlatList `keyExtractor` or non-stable keys | Items re-render on every list mutation; animated transitions break | Always provide a stable, unique `keyExtractor` using document ID | Immediate |
| Firestore `onSnapshot` without cleanup | Memory leak; ghost listeners accumulating across navigation | Always return the `unsubscribe` function from `useEffect` | Leaks compound over session length; critical for long workout sessions |
| Victory Native or Lottie imported globally | 600KB+ bundle size addition; slow initial load | Import chart/animation libraries lazily; audit bundle with `expo-bundle-analyzer` | Immediately at install; worsens with scale |
| All domain computation in component render | UI thread blocking during cycle phase calculation or injury engine run | Move heavy computation to `useMemo` with correct dependencies; or to a background thread via `react-native-worklets-core` | Noticeable on older Android devices |
| Firestore collection scans offline | Offline query scanning all cached documents | Enable local query index creation via persistent cache settings; design data model with query patterns in mind | Degrades as cache grows, especially for users who go offline for extended periods |
| Firebase Cloud Functions cold start for AI generation | First AI workout request takes 10-20s; user abandons | Set minimum instance count to 1 in production; implement loading state with progress indication and timeout fallback | Every cold start; worse in low-traffic periods overnight |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Shipping with Firestore test mode rules | Any user (or automated scanner) can read all health data, including cycle logs, injury profiles, readiness survey responses | Write production rules before first data write; add rules to CI test suite |
| Admin flag stored in user-writable document field | User can self-promote to admin | Store admin flags in a separate collection that only Cloud Functions can write |
| Firebase API key exposed without App Check | Key is trivially extractable from app binary; bots can make unlimited Auth/Firestore requests | Enable Firebase App Check with DeviceCheck (iOS) and Play Integrity (Android) |
| Stripe webhook not verified with webhook secret | Attacker POSTs fake subscription events to unlock premium access | Always verify Stripe webhook signature (`stripe.webhooks.constructEvent`) in Cloud Function |
| RevenueCat API key in client-side JS | Key exposed in bundle; attacker can query subscriber state | Public RevenueCat key is expected client-side; never embed the secret key |
| Health/cycle data in Firestore without field-level consideration | Users' menstrual cycle data visible to Firebase project admins with console access | Minimize data stored; do not log raw cycle data to Firebase Analytics events |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| KeyboardAvoidingView set to `behavior="padding"` (iOS-only fix applied everywhere) | Android inputs hidden under keyboard; submit buttons unreachable | Use `react-native-keyboard-controller` for consistent cross-platform handling; set different `behavior` per platform |
| No offline indicator during workout execution | Users unsure if workout saved; tap "save" repeatedly creating duplicate entries | Show connection status in workout header; optimistic save confirmation ("Saved locally, will sync when online") |
| Workout timer stops when screen locks (no background task) | Active workout timer resets mid-session | Implement `expo-task-manager` + `expo-background-fetch` for timer persistence; test explicitly with screen lock |
| Paywall interrupts first workout attempt | Users churn before experiencing value | Gate premium features; ensure core workout execution works in guest mode before upsell |
| Art Deco design not adapted for Android material conventions | Android users feel the app is unpolished; navigation feels wrong | Test navigation gestures, back button behavior, and bottom sheet behavior on physical Android device early |
| Platform-specific modal presentation differences | Modals that look native on iOS look wrong on Android (no bottom sheet) | Use `@gorhom/bottom-sheet` for sheet-style modals; test on both platforms before considering a component "done" |
| Cycle phase data shown to users who skipped cycle opt-in | Confusing, alienating experience | Gate all cycle UI behind the onboarding opt-in flag; never assume cycle tracking is active |

---

## "Looks Done But Isn't" Checklist

- [ ] **Offline workout save:** Works in airplane mode? Verify by: enable airplane mode, complete a full workout, kill app, restore connection, confirm workout appears in history.
- [ ] **Sign in with Apple persistence:** Second login returns correct display name? Verify by: sign in, revoke in iOS Settings, sign in again, check display name.
- [ ] **RevenueCat + Stripe sync:** Web subscriber sees premium in mobile app? Verify by: purchase via Stripe web checkout with a test card, open mobile app with same account, confirm entitlement unlocked.
- [ ] **Firestore security rules:** User A cannot read User B's data? Verify by: create two test accounts, attempt cross-account document read via Firebase emulator.
- [ ] **Cycle-aware adaptation on Android:** Phase multipliers apply correctly? Verify with same inputs as iOS domain unit tests.
- [ ] **AI workout generation with cold start:** First request on fresh function instance completes within timeout? Verify by: let function go idle 15 min, trigger generation, observe latency.
- [ ] **OTA update safety:** OTA push after dependency bump does not crash users on old binary? Verify fingerprint diff shows no native surface changes before pushing.
- [ ] **Workout timer survives screen lock:** Timer state preserved when phone locks mid-EMOM? Verify on physical device.
- [ ] **Guest mode:** Core workout execution works without any Firebase auth? Verify by: use app without signing in, complete workout, confirm local persistence.
- [ ] **Subscription state on app restart:** RevenueCat correctly restores entitlement without requiring re-purchase? Verify by: subscribe, force-kill app, reopen, confirm premium state.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Wrong Firebase SDK (JS vs native) discovered mid-project | HIGH | Audit all Firebase imports; swap to `@react-native-firebase`; rebuild all features that touch Auth/Firestore/Storage; re-test offline behavior end-to-end |
| Firestore rules breach discovered post-launch | HIGH | Lock rules immediately (emergency deploy); audit access logs in Firebase console; notify affected users per applicable privacy law; conduct full rules audit |
| Expo managed workflow ceiling hit mid-project | HIGH | Convert to Development Build (lower cost); only eject to bare workflow if a Config Plugin genuinely cannot cover the gap |
| Missing Apple user data discovered post-launch | MEDIUM | Prompt affected users (those with no display name) to update their profile manually; implement account repair flow in Settings |
| OTA update crash discovered in production | MEDIUM | Roll back to previous update channel immediately via `eas channel:edit`; issue full EAS Build with the fix; establish fingerprint policy to prevent recurrence |
| RevenueCat + Stripe sync not built | MEDIUM | Build webhook handler; retroactively sync existing Stripe subscribers via RevenueCat REST API batch import |
| AI Cloud Function cold start causing UX failures | LOW | Enable minimum instance count (1) via Cloud Functions config; update loading state to show progress |
| Firestore offline persistence in JS SDK (not native) | MEDIUM | Migrate to `@react-native-firebase/firestore`; test all offline scenarios after migration |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Wrong Firebase SDK (JS vs native) | Phase 1: Project scaffold | `@react-native-firebase` installed; Expo Go abandoned; dev client working with Firebase Auth |
| Firestore writes blocking UI offline | Phase covering workout execution | Airplane mode test: save workout, no UI freeze |
| Expo managed workflow ceiling | Phase 1: Project scaffold | Full native capability audit complete before first commit |
| OTA update breaking native modules | CI/CD setup phase | Fingerprint diff check runs in CI before every OTA push |
| Sign in with Apple missing user data | Auth phase | Second-login acceptance test in auth test suite |
| Firestore security rules open | Phase 1: Data architecture | Rules test suite passing in CI; no `allow read, write: if true` in any environment |
| RevenueCat + Stripe entitlement gap | Payments phase | Stripe webhook handler tested end-to-end with test card |
| Domain logic numeric/date drift | Domain port phase | TypeScript domain tests produce identical outputs to Swift test suite for same inputs |
| FlatList performance | History/programs list phase | Profiler shows no inline renderItem functions; scroll performance on 200+ item list measured |
| Cloud Function cold start | AI generation phase | Cold start latency measured; minimum instances configured; loading state handles 15s+ wait |
| Workout timer dies on screen lock | Workout execution phase | Physical device test: screen lock mid-EMOM, timer state preserved |
| Firestore App Check not enabled | Pre-launch security phase | App Check enforced in Firebase console; emulator bypass only in development |

---

## Sources

- [Expo Firebase Guide (Official)](https://docs.expo.dev/guides/using-firebase/)
- [Firebase Dual Package Hazard — Expo Issue #36598](https://github.com/expo/expo/issues/36598)
- [Expo SDK 53 Firebase Breaking Integration — Issue #36602](https://github.com/expo/expo/issues/36602)
- [Firestore Offline Mode Gotchas for React Native — Better Programming](https://betterprogramming.pub/a-few-gotchas-to-consider-when-working-with-firestores-offline-mode-and-react-native-42al)
- [Access Data Offline — Firebase Official Docs](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [React Native Firebase — Official Docs](https://rnfirebase.io/)
- [Firestore Insecure Rules — Firebase Official Docs](https://firebase.google.com/docs/firestore/security/insecure-rules)
- [Firebase Misconfigurations — Medium](https://medium.com/@mustafamohammed789mm/firebase-misconfigurations-from-discovery-to-exploitation-0a282b81ad4f)
- [RevenueCat Stripe Billing Integration](https://www.revenuecat.com/docs/web/integrations/stripe)
- [RevenueCat React Native Installation](https://www.revenuecat.com/docs/getting-started/installation/reactnative)
- [Sign in with Apple — React Native Firebase Social Auth](https://rnfirebase.io/auth/social-auth)
- [Making Apple Authentication Work with Firebase Auth in Expo](https://vandevliet.me/making-apple-authentication-work-with-firebase-auth-w-react-native/)
- [Firebase Cloud Functions Cold Start — Official Tips](https://firebase.google.com/docs/functions/tips)
- [Overcoming Cold Start Challenges in Firebase Cloud Functions](https://infinitejs.com/posts/overcoming-cold-start-firebase-functions/)
- [5 OTA Update Best Practices — Expo Blog](https://expo.dev/blog/5-ota-update-best-practices-every-mobile-team-should-know)
- [Expo OTA Update Troubleshooting — Mindful Chase](https://www.mindfulchase.com/explore/troubleshooting-tips/mobile-frameworks/troubleshooting-ota-updates-and-build-inconsistencies-in-expo-framework.html)
- [FlatList Performance Optimization — React Native Official](https://reactnative.dev/docs/optimizing-flatlist-configuration)
- [FlashList — Shopify's FlatList Replacement](https://expo.dev/blog/what-is-the-best-react-native-list-component)
- [Keyboard Handling in React Native — Expo Docs](https://docs.expo.dev/guides/keyboard-handling/)
- [react-native-keyboard-controller Platform Differences](https://kirillzyusko.github.io/react-native-keyboard-controller/docs/recipes/platform-differences)
- [EAS Build Signing Certificate Issues — expo-cli Issue #3192](https://github.com/expo/eas-cli/issues/3192)
- [Expo Managed to Bare Workflow Migration — OneUptime](https://oneuptime.com/blog/post/2026-01-15-expo-managed-to-bare-workflow/view)

---
*Pitfalls research for: React Native + Expo + Firebase fitness app (Sundee Fundee cross-platform rewrite)*
*Researched: 2026-03-14*
