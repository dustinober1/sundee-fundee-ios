# Codebase Concerns

**Analysis Date:** 2026-03-21

## Tech Debt

**Module-level shared state for workout preview (AI Workout):**
- Issue: `pwa/src/routes/AIWorkoutConfig.tsx` uses module-level `_sharedWorkout` variable to pass state between screens instead of React Router state management
- Files: `pwa/src/routes/AIWorkoutConfig.tsx` (lines 17-20), `pwa/src/routes/AIWorkoutPreview.tsx`
- Impact: State can be lost on page refresh, difficult to test, violates React state patterns
- Fix approach: Move to React Router `useLocation` state or context provider

**Broad localStorage.clear() on sign out (Auth):**
- Issue: `pwa/src/auth/AuthContext.tsx:47` clears ALL localStorage without filtering, which could wipe unrelated app state
- Files: `pwa/src/auth/AuthContext.tsx`
- Impact: May lose user settings, preferences, or other data not intended for logout
- Fix approach: Clear only auth-specific keys (prefixed with consistent naming convention)

**Silent error catching throughout codebase:**
- Issue: Many routes use `} catch { /* empty */ }` without logging or recovery
- Files: `pwa/src/routes/ExerciseDetail.tsx`, `pwa/src/routes/ProgramSession.tsx`, `pwa/src/routes/WODs.tsx`, `pwa/src/routes/Benchmarks.tsx`, `pwa/src/routes/WorkoutDetail.tsx`, `pwa/src/routes/Programs.tsx`, `pwa/src/routes/ProgramDetail.tsx` (35+ catch blocks found)
- Impact: Failures go unnoticed; hard to debug user-reported issues; no telemetry
- Fix approach: Implement structured error logging middleware; add console.error with context at minimum

**Unsafe JSON.parse in crash recovery (WorkoutSession):**
- Issue: `pwa/src/routes/WorkoutSession.tsx:76` parses localStorage JSON with try/catch but no validation of restored object structure
- Files: `pwa/src/routes/WorkoutSession.tsx`
- Impact: Corrupted data could crash the app; no validation that restored session has required fields
- Fix approach: Add TypeScript type guard; validate all required fields before using restored data

**Randomness in domain layer (Rehab session ID generation):**
- Issue: `pwa/src/domain/injury/rehab-session-generator.ts` uses `Math.random()` in ID generation; domain layer should be pure/deterministic
- Files: `pwa/src/domain/injury/rehab-session-generator.ts`
- Impact: Non-deterministic behavior makes testing harder; violates separation of concerns
- Fix approach: Inject ID generator as dependency from app layer; keep domain pure

**Weak type safety with "any" casts:**
- Issue: Found minimal `any` usage (`ex: any` in WorkoutDetail.tsx), but more concerning are dynamic exercise lookups without validation
- Files: `pwa/src/routes/WorkoutDetail.tsx`
- Impact: Could miss data type errors at runtime
- Fix approach: Use strict TypeScript; validate exercise lookups with type guards

## Known Bugs

**AI Workout generation uses offline fallback, not Cloud Functions:**
- Symptoms: Generated workouts do not benefit from Gemini API intelligence; always use template-based system
- Files: `pwa/src/routes/AIWorkoutConfig.tsx:106` (TODO comment)
- Trigger: Every AI workout generation
- Workaround: Cloud Functions not yet implemented; using offline generator as intended temporary measure
- Impact: Feature incomplete; reduced AI quality compared to legacy Swift version

**Readiness survey data not persisting correctly:**
- Symptoms: User readiness adjustments may not carry through to workout adaptation
- Files: Likely `pwa/src/repositories/FirestoreReadinessRepo.ts` and readiness synchronization logic
- Trigger: When users complete readiness survey → start workout
- Impact: Readiness tiers not affecting workout difficulty as designed

## Security Considerations

**IndexedDB not encrypted for sensitive data:**
- Risk: Firestore local cache in IndexedDB stores encrypted but user data is accessible via browser dev tools; no encryption for localStorage
- Files: `pwa/src/firebase/firestore.ts` (uses `persistentLocalCache`)
- Current mitigation: Firestore SDK handles network encryption (HTTPS); client-side data is unencrypted
- Recommendations: (1) Consider sensitive data encryption library for localStorage keys; (2) Document that users should not share devices; (3) Implement session timeout; (4) Clear IndexedDB on logout, not just localStorage

**Password stored in plain text (if email auth added later):**
- Risk: Email/password auth not currently used, but if implemented, ensure passwords hash/salt on backend only
- Files: Relevant when `pwa/src/auth/` expands beyond Apple/Google/guest
- Current mitigation: Only Apple/Google OAuth currently; no direct password handling
- Recommendations: Do not store passwords in localStorage or Firestore; use Firebase Auth exclusively

**No CSRF protection on Stripe webhooks:**
- Risk: Firestore Security Rules may allow unauthorized webhook writes if not properly validated
- Files: Cloud Functions `functions/src/stripeWebhook.ts` (not in PWA but affects billing)
- Current mitigation: Stripe SDK validates signatures
- Recommendations: Verify webhook signatures server-side before applying state changes

**Gemini API key exposure:**
- Risk: Cloudflare Worker proxy (`workout-proxy.sundeefundee.workers.dev`) must protect API key
- Files: External (not in PWA repo)
- Current mitigation: Key in Cloudflare Worker secret
- Recommendations: Transition to Cloud Functions so key stays in Firebase only; revoke if exposed

## Performance Bottlenecks

**Unbounded workout history queries:**
- Problem: No pagination on workout history; fetches all records at once
- Files: `pwa/src/repositories/FirestoreWorkoutRepo.ts` (needs implementation review)
- Cause: No limit on Firestore query; scales poorly with 100+ workouts
- Improvement path: Implement pagination (50 per page); lazy-load next page on scroll

**Rest timer polling at 1-second intervals:**
- Problem: `pwa/src/routes/WorkoutSession.tsx:96` uses `setInterval(..., 1000)` for both elapsed timer AND rest timer
- Files: `pwa/src/routes/WorkoutSession.tsx`
- Cause: Could cause CPU wake-up on every interval; multiple intervals if multiple sessions
- Improvement path: Consolidate to single interval; use `requestAnimationFrame` for smoother updates; clear timers on unmount

**Full page re-renders on minor state changes:**
- Problem: Parent components (Dashboard, Programs) may re-render all children on data fetch
- Files: `pwa/src/routes/Dashboard.tsx`, `pwa/src/routes/Programs.tsx`
- Cause: No component memoization; state management not granular
- Improvement path: Memoize child components; split state into smaller contexts

**Offline workout generator templates loaded at module level:**
- Problem: `pwa/src/domain/ai-workout/offline-workout-generator.ts` has ~200+ exercise templates as module-level constants
- Files: `pwa/src/domain/ai-workout/offline-workout-generator.ts`
- Cause: Templates never need to be updated, but entire file parsed/loaded on import
- Improvement path: Extract to separate JSON file; lazy-load when needed

## Fragile Areas

**Exercise substitution logic (Injury adaptation):**
- Files: `pwa/src/domain/injury/injury-adaptation-engine.ts` (334 lines)
- Why fragile: Hard-coded regression tables and contraindication rules; adding new exercises or injury types requires manual updates to multiple tables; no validation that substitutes exist
- Safe modification: (1) Add tests for new injury/exercise combinations; (2) Refactor tables into data-driven format; (3) Add validation that regression table entries reference valid exercises
- Test coverage: Injury adaptation tested in `pwa/src/domain/__tests__/injury.test.ts` (980 lines); gaps: missing scenarios for edge case injury combinations

**Weight calculation and unit conversion:**
- Files: `pwa/src/domain/calculations/weight-calculations.ts`, conversions across repos
- Why fragile: Weight unit threading required in every calculation; no centralized unit context; room for lbs/kg mix-ups
- Safe modification: (1) Always pass weightUnit parameter explicitly; (2) Add TypeScript type aliases (`WeightInLbs`, `WeightInKg`); (3) Test all weight-dependent workflows in both units
- Test coverage: Calculations tested (`pwa/src/domain/__tests__/calculations.test.ts` - 451 lines); should audit all repos for unit correctness

**Firestore schema evolution (no migrations):**
- Files: `pwa/src/repositories/Firestore*.ts` (17 files)
- Why fragile: No document schema versioning; if shape changes (e.g., adding required fields), old documents break
- Safe modification: (1) Add `schemaVersion` field to documents; (2) Create migration layer in repos; (3) Test with old data on startup
- Test coverage: Minimal; no integration tests against real Firestore

**Session persistence across page reloads:**
- Files: `pwa/src/routes/WorkoutSession.tsx:74-87`, `pwa/src/routes/AIWorkoutConfig.tsx:17-20`
- Why fragile: localStorage serialization can fail silently; JSON.parse expects exact shape; no validation
- Safe modification: (1) Add fallback for parsing errors (start fresh session); (2) Validate restored object with type guard; (3) Add test for crash recovery
- Test coverage: None; no tests for session persistence or recovery

## Scaling Limits

**Firestore storage for exercise maxes:**
- Current capacity: No practical limit (Firestore allows 1GB+ per document)
- Limit: Single user with 500+ exercises could have large max documents; reading all maxes on every workout loads entire array
- Scaling path: Paginate or filter exercise maxes by muscle group; cache frequently-used maxes in React state

**Web push notification delivery:**
- Current capacity: Firebase Cloud Messaging can handle thousands of devices
- Limit: No batching or retry logic for notification failures
- Scaling path: Implement queue for failed notifications; track delivery status

**AI workout generation latency:**
- Current capacity: Offline generator runs instantly (~ms)
- Limit: Cloud Functions (when added) will have cold start (1-5s) and Gemini API call time (~3-5s)
- Scaling path: Cache generated workouts; offer offline option while Cloud Function runs in background

## Dependencies at Risk

**Firebase SDK (`firebase@^12.11.0`):**
- Risk: Major version updates could break Firestore offline persistence or Auth API
- Impact: Users unable to sign in or sync data
- Migration plan: Pin to `~12.11.0` for stability; test carefully before minor/major version bumps; have rollback plan

**Recharts (`recharts@^3.8.0`):**
- Risk: Library not as actively maintained as alternatives (e.g., Chart.js); SVG rendering could have performance issues with large datasets
- Impact: Progress charts slow on 100+ workouts; possible rendering bugs
- Migration plan: Keep eye on library; if issues arise, migrate to lightweight alternative (e.g., Visx)

**Vite PWA plugin (`vite-plugin-pwa@^1.2.0`):**
- Risk: PWA plugin maturity; service worker registration could fail silently
- Impact: Users don't get offline support; app crashes without internet
- Migration plan: Implement fallback offline indicator; test PWA features in CI; monitor service worker registration errors

## Missing Critical Features

**Cloud Functions for AI workout generation:**
- Problem: Gemini integration only works through Cloudflare Worker proxy; no serverless function in Firebase yet
- Blocks: Cannot use Gemini context (cycle phase, recent workouts, injuries) effectively
- Implementation needed: `functions/src/generateWorkout.ts` needs to query Firestore for user context before calling Gemini

**Offline support for program/WOD data:**
- Problem: Programs and WODs bundled in `pwa/resources/` but not synced to IndexedDB
- Blocks: Users cannot view programs/WODs if offline after initial load
- Implementation needed: Sync bundled data to IndexedDB on first load; implement service worker cache strategy

**Readiness survey → adaptation wiring:**
- Problem: Readiness survey collected but not integrated into cycle adaptation or AI workout generation
- Blocks: Feature incomplete; users complete survey but see no effect
- Implementation needed: Thread readiness tier through `WorkoutGenerationContext`; test with different readiness levels

## Test Coverage Gaps

**Integration tests (Firestore ↔ UI):**
- What's not tested: Full workflow from sign-in → create workout → save → load history (no tests)
- Files: All repository and route files lack integration tests
- Risk: Data corruption on sync; lost workouts unnoticed
- Priority: High — add integration test suite with test Firestore instance

**Offline → Online sync:**
- What's not tested: Guest mode (localStorage) → authenticated sync (Firestore) data migration
- Files: `pwa/src/repositories/migration.ts` (data migration logic)
- Risk: Data loss when users create account after using as guest
- Priority: High — implement and test guest→auth migration flow

**Weight unit edge cases:**
- What's not tested: All calculations in both lbs and kg; unit conversion accuracy; mixed-unit workflows
- Files: `pwa/src/domain/calculations/*.ts`, repository layer
- Risk: Weight calculations off by unit; users track wrong numbers
- Priority: Medium — add parameterized tests for all calculation functions in both units

**Injury substitution comprehensive coverage:**
- What's not tested: All injury combinations with all exercises; edge case injuries (e.g., "lower back" not in synonym table)
- Files: `pwa/src/domain/__tests__/injury.test.ts`
- Risk: Users with uncommon injuries get no substitutions
- Priority: Medium — expand test matrix to cover all injury/exercise pairs

**Cycle adaptation logic:**
- What's not tested: Different cycle phases (follicular, ovulation, luteal, menstrual); readiness tiers; phase transitions
- Files: `pwa/src/domain/__tests__/cycle.test.ts` (527 lines)
- Risk: Cycle recommendations incorrect; users see wrong adaptations
- Priority: High — audit existing tests; add scenarios for phase transitions and readiness interaction

**Crash recovery (session persistence):**
- What's not tested: Page reload during active workout; corrupted localStorage data; concurrent app instances (multiple tabs)
- Files: `pwa/src/routes/WorkoutSession.tsx`
- Risk: Lost workout data; app crashes on page reload
- Priority: High — add tests for localStorage edge cases; validate restored data

---

*Concerns audit: 2026-03-21*
