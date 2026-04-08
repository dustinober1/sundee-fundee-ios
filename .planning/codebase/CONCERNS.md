---
name: Concerns and Risks
type: codebase-map
focus: concerns
created: 2026-04-08
---

# Codebase Concerns

**Analysis Date:** 2026-04-08

## Security

### Middleware Only Checks Cookie Existence (HIGH)

- **Issue:** `src/middleware.ts` (line 4) checks only whether the `__session` cookie **exists**, not whether it is **valid**. An attacker who sets any arbitrary string as `__session` passes the middleware check and reaches protected route handlers. Validation only occurs downstream in server actions via `getAuthUser()`, which calls `adminAuth.verifySessionCookie()`.
- **Files:** `web-app/src/middleware.ts`
- **Impact:** Invalid sessions reach server-side rendering and API routes before being rejected. While the actual data operations are gated by `getAuthUser()`, the middleware guard is hollow — any request with a `__session` cookie bypasses the redirect. This also means invalid-session requests unnecessarily hit Firebase Admin for verification.
- **Mitigation in place:** All server actions and API routes call `getAuthUser()` or `requireAdmin()` which verify the session cookie server-side.
- **Fix approach:** Add lightweight JWT structure validation in middleware (check expiry claim without full Admin SDK verification), or accept the current design as a performance tradeoff with documentation.

### Stripe Webhook Missing Idempotency (MEDIUM)

- **Issue:** `src/app/api/stripe/webhook/route.ts` processes `checkout.session.completed` and `customer.subscription.updated` events without deduplication. Stripe may deliver the same webhook event multiple times. Each delivery calls `upsertSubscriptionByUserId` or `upsertSubscriptionByStripeId` with `{ merge: true }`, which is safe for single-field updates but could cause incorrect `updatedAt` timestamps or race conditions with concurrent events.
- **Files:** `web-app/src/app/api/stripe/webhook/route.ts`
- **Impact:** Duplicate webhook processing could overwrite subscription state with stale data in edge cases. The `merge: true` strategy prevents data loss but does not guarantee correctness under rapid event delivery.
- **Fix approach:** Store processed Stripe event IDs in Firestore and skip already-processed events before executing business logic.

### User Email Stored in AI Workout Records (MEDIUM)

- **Issue:** `src/app/api/ai/generate/route.ts` (lines 180, 207) stores `userEmail: user.email ?? null` in `generatedWorkoutRecords` documents. This embeds PII in a collection primarily intended for operational logging. The email is not needed for any query against these records.
- **Files:** `web-app/src/app/api/ai/generate/route.ts`
- **Impact:** PII exposure in Firestore documents that may be accessed by admin dashboards or data exports. Increases the blast radius of any Firestore read vulnerability.
- **Fix approach:** Remove `userEmail` from the stored record. If admin diagnostics need to identify users, join on `uid` to the `users` collection at display time.

### Session Cookie Not Secure in Development (LOW)

- **Issue:** `src/app/api/auth/session/route.ts` (line 22) sets `secure: process.env.NODE_ENV === "production"`. In development, the session cookie is sent over HTTP in plaintext.
- **Files:** `web-app/src/app/api/auth/session/route.ts`
- **Impact:** Local network eavesdroppers could hijack sessions during development. Acceptable for local-only development but worth noting.
- **Fix approach:** No action needed — this is standard practice for local development.

### Admin Auth Requires Firestore Read on Every Request (LOW)

- **Issue:** `src/lib/admin-auth.ts` calls `getAuthUser()` (verifies session cookie) then reads the `admins/{uid}` document. Every admin API call performs two round trips to Firebase/Firestore. There is no caching or in-memory admin allowlist.
- **Files:** `web-app/src/lib/admin-auth.ts`
- **Impact:** Performance penalty on all admin routes. Not a security concern but increases latency and Firestore read costs proportionally to admin traffic.
- **Fix approach:** Cache admin status in an edge-compatible store (e.g., session cookie custom claims or a short-lived in-memory cache within the serverless function lifecycle).

---

## Technical Debt

### Pervasive `as any` Type Assertions in Server Actions (HIGH)

- **Issue:** Seven server action files use `doc.data() as any` to deserialize Firestore documents. This disables TypeScript checking on the data flowing from Firestore to client components. Any schema change in Firestore will not produce compile-time errors.
- **Files:**
  - `web-app/src/app/(features)/maxes/actions.ts` (line 15)
  - `web-app/src/app/(features)/workouts/actions.ts` (line 21)
  - `web-app/src/app/(features)/settings/actions.ts` (line 15)
  - `web-app/src/app/(features)/programs/actions.ts` (lines 15, 21, 50, 81)
  - `web-app/src/app/(features)/benchmarks/actions.ts` (line 130, via eslint-disable)
  - `web-app/src/app/(features)/cycle/actions.ts` (line 130, via eslint-disable)
  - `web-app/src/app/api/admin/programs/route.ts` (line 13)
- **Impact:** Type safety is lost at the data layer boundary. Schema changes can silently break client components. No compile-time protection against accessing non-existent fields.
- **Fix approach:** Define typed interfaces for each Firestore collection and create a generic `typedDoc<T>()` helper that validates/casts Firestore document data.

### Duplicated Rate Limiting Logic (MEDIUM)

- **Issue:** Rate limiting exists in two separate implementations:
  1. `web-app/src/lib/subscription-state.ts` — `incrementDailyAIUsage()` used by the web app API route
  2. `firebase/functions/src/rate-limit.ts` — `checkRateLimit()` used by the Cloud Function

  Both read and increment a daily counter in `aiUsage/{YYYY-MM-DD}` but use different tier limit values. The Cloud Function hardcodes `{ plus: 1, premium: 10 }` while the web app uses `dailyCloudAILimit()` from the domain layer (which returns `{ plus: 1, premium: 25 }`). They are out of sync.
- **Files:**
  - `web-app/src/lib/subscription-state.ts` (lines 154-165)
  - `firebase/functions/src/rate-limit.ts` (lines 3-6, 14-36)
- **Impact:** Premium users get 25 AI generations via the web app API but only 10 via the Cloud Function. The inconsistency means which endpoint is called determines the user's actual limit.
- **Fix approach:** Centralize rate limit configuration in a shared location or Firestore `adminSettings` document. Remove the Cloud Function implementation if it is no longer the primary path.

### Leftover `console.log` in Production Code (LOW)

- **Issue:** `src/app/(features)/programs/actions.ts` (line 14) contains `console.log(...)` that fires on every published programs fetch. This is debug logging left in production server action code.
- **Files:** `web-app/src/app/(features)/programs/actions.ts` (line 14)
- **Impact:** Unnecessary server-side logging noise. Not a performance concern but clutters server logs.
- **Fix approach:** Remove the `console.log` statement or replace with a conditional debug logger.

### Default Stripe Price IDs Hardcoded in Source (LOW)

- **Issue:** `src/lib/stripe.ts` (lines 6-14) contains hardcoded Stripe price IDs as defaults: `DEFAULT_STRIPE_PRICES`. While env var overrides exist, the fallback values are production price IDs committed to the repository.
- **Files:** `web-app/src/lib/stripe.ts`
- **Impact:** If env vars are misconfigured, the app silently uses the hardcoded production price IDs. Not a secret exposure (price IDs are semi-public) but could lead to billing confusion in test environments.
- **Fix approach:** Remove defaults and require env vars, or use test-mode price IDs as defaults.

---

## Performance

### Dashboard Actions Execute Multiple Sequential Firestore Queries (MEDIUM)

- **Issue:** `src/app/(features)/dashboard/actions.ts` `getDashboardStats()` (lines 95-153) executes three separate Firestore queries: `completedWorkouts`, `oneRepMaxes`, and `enrolledPrograms`. The `getRecentWins()` function (lines 193-297) executes four more queries. These run sequentially because each depends on `getAuthUser()`, but after authentication they could be parallelized.
- **Files:** `web-app/src/app/(features)/dashboard/actions.ts`
- **Impact:** Dashboard page load time scales with Firestore latency multiplied by query count. The `getRecentWins()` function fetches up to 50 max records and 20 benchmark results into memory for client-side comparison.
- **Fix approach:** Parallelize independent queries with `Promise.all()`. For `getRecentWins()`, consider Firestore aggregation or pre-computed win documents.

### Full Collection Scan for Admin User Detail (MEDIUM)

- **Issue:** `src/app/api/admin/users/[uid]/route.ts` (lines 15-21) calls `userSubcollection(uid, ...)` for four collections (`subscription`, `completedWorkouts`, `benchmarkResults`, `oneRepMaxes`). Each call reads the **entire subcollection** without limits. For power users with hundreds of workouts, this transfers all data to the server only to count it.
- **Files:** `web-app/src/app/api/admin/users/[uid]/route.ts`
- **Impact:** Admin user detail page performance degrades linearly with user activity. Firestore read costs increase. Large collections cause slow response times.
- **Fix approach:** Use Firestore `CountQuery` for count-only fields (`completedWorkoutCount`, `benchmarkResultCount`). Limit `oneRepMaxes` to recent entries.

### Program Enrollment Fetches Full Program on Every Enrollment (LOW)

- **Issue:** `src/app/(features)/programs/actions.ts` `enrollInProgram()` (line 60) calls `getProgramById()` to retrieve the program name. `getProgramById()` deserializes the entire program including all weeks and exercises, only to extract `program.name`.
- **Files:** `web-app/src/app/(features)/programs/actions.ts`
- **Impact:** Unnecessary data transfer from Firestore. A simple field projection or a lightweight query would suffice.
- **Fix approach:** Add a Firestore field projection or create a `getProgramNameById()` helper that reads only the `name` field.

### Large Admin Page Components (LOW)

- **Issue:** The admin programs page (`web-app/src/app/(admin)/admin/workouts/programs/page.tsx`) is 710 lines. Other admin pages are 280-500+ lines. These are single-file components mixing data fetching, state management, and complex UI rendering.
- **Files:**
  - `web-app/src/app/(admin)/admin/workouts/programs/page.tsx` (710 lines)
  - `web-app/src/app/(admin)/admin/content/blog/page.tsx` (501 lines)
  - `web-app/src/app/(admin)/admin/workouts/wods/page.tsx` (422 lines)
  - `web-app/src/app/(admin)/admin/catalog/page.tsx` (394 lines)
- **Impact:** Hard to maintain and test. No code splitting within admin pages. Changes to one section risk breaking others.
- **Fix approach:** Extract reusable admin components (data tables, form editors, modal patterns). Consider splitting each admin page into a page shell + separate editor/list components.

---

## Scalability

### No Pagination on User Subcollection Reads (HIGH)

- **Issue:** Multiple server actions read user subcollections without pagination:
  - `src/app/(features)/programs/actions.ts` `getEnrolledPrograms()` — reads all enrolled programs
  - `src/app/(features)/benchmarks/actions.ts` `getBenchmarkResults()` — reads all benchmark results
  - `src/app/(features)/cycle/actions.ts` `getPeriodLogs()` — reads all period logs
  - `src/app/api/admin/users/[uid]/route.ts` — reads entire subcollections for counts
- **Files:**
  - `web-app/src/app/(features)/programs/actions.ts` (line 48)
  - `web-app/src/app/(features)/benchmarks/actions.ts` (line 23)
  - `web-app/src/app/(features)/cycle/actions.ts` (line 32)
  - `web-app/src/lib/admin-firestore.ts` `userSubcollection()` (lines 41-47)
- **Impact:** As users accumulate data, these queries return increasingly large result sets. Firestore charges per document read. A user with 500 workouts will transfer all 500 documents on every page load of the benchmarks or cycle page.
- **Fix approach:** Add `limit()` to all user subcollection queries. Implement cursor-based pagination for list views. For admin counts, use Firestore aggregation queries.

### Rate Limit Not Atomic (MEDIUM)

- **Issue:** `src/lib/subscription-state.ts` `incrementDailyAIUsage()` (lines 154-165) reads the current count, increments it in application code, and writes it back. This is a read-modify-write pattern without a transaction. Two concurrent requests could both read count=4, both write count=5, allowing 6 requests against a limit of 5.
- **Files:** `web-app/src/lib/subscription-state.ts` (lines 154-165)
- **Impact:** Race condition allows exceeding the daily AI generation limit under concurrent requests. The Cloud Function implementation in `firebase/functions/src/rate-limit.ts` has the same issue.
- **Fix approach:** Use a Firestore transaction or atomic `FieldValue.increment(1)` with a precondition check. Alternatively, use Firestore `set` with `mergeFields` and a precondition on the count.

### Full Exercise Catalog Fetched on Every AI Generation (LOW)

- **Issue:** `src/app/api/ai/generate/route.ts` `fetchCatalog()` (lines 26-45) reads the entire `exerciseCatalog` collection on every AI workout generation request. There is no caching.
- **Files:** `web-app/src/app/api/ai/generate/route.ts` (lines 26-45)
- **Impact:** Unnecessary Firestore reads for a collection that changes infrequently. Adds latency to every AI generation request.
- **Fix approach:** Cache the exercise catalog in memory with a TTL (e.g., 5 minutes) or use Next.js `unstable_cache`/`revalidateTag`.

---

## Reliability

### Empty Catch Blocks Swallow Errors Silently (MEDIUM)

- **Issue:** Several catch blocks discard error details without logging or rethrowing:
  - `src/lib/firestore.ts` (line 22) — `catch { return null; }` on session verification failure
  - `src/lib/firebase.ts` (line 25) — `catch { /* fall through */ }` on auth domain resolution
  - `src/components/providers/auth-provider.tsx` (line 39) — `catch {}` on persistence setup
  - `src/lib/subscription-state.ts` (line 123) — `catch { return {}; }` on rate limit override fetch
- **Files:**
  - `web-app/src/lib/firestore.ts`
  - `web-app/src/lib/firebase.ts`
  - `web-app/src/components/providers/auth-provider.tsx`
  - `web-app/src/lib/subscription-state.ts`
- **Impact:** Failures in these code paths are invisible during debugging. A misconfigured Firebase project or network issue will silently degrade to defaults with no diagnostic trail.
- **Fix approach:** Add `console.warn` or structured logging to all catch blocks that swallow errors. For the session verification catch, log the failure reason at minimum.

### No Error Boundary in Feature Layout (MEDIUM)

- **Issue:** The features layout (`src/app/(features)/layout.tsx`) renders `<BottomNav />` with children but has no React error boundary. A runtime error in any feature page will crash the entire features shell, including the bottom navigation.
- **Files:** `web-app/src/app/(features)/layout.tsx`
- **Impact:** Users see a blank white screen instead of a recoverable error state when any feature page throws.
- **Fix approach:** Wrap the children in a React error boundary component that shows a retry UI while preserving the bottom navigation.

### AI Workout Parsing Can Throw on Malformed JSON (LOW)

- **Issue:** `src/lib/ai-generation.ts` `parseAIWorkoutResponse()` (line 243) calls `JSON.parse(cleaned)` without a try-catch. If the AI returns malformed JSON that survives the `extractJSON()` cleanup, the error propagates unhandled. The caller in `src/app/api/ai/generate/route.ts` does catch this, but the error message will be the raw JSON parse error, not user-friendly.
- **Files:** `web-app/src/lib/ai-generation.ts` (line 243)
- **Impact:** Unhelpful error messages returned to the client when AI generates invalid JSON.
- **Fix approach:** Wrap `JSON.parse` in a try-catch that throws a descriptive "AI returned invalid JSON" error.

---

## Maintainability

### Admin Pages Are Monolithic Client Components (HIGH)

- **Issue:** All admin pages under `src/app/(admin)/admin/` are single-file `"use client"` components ranging from 280 to 710 lines. They mix data fetching (via fetch calls), state management (useState/useEffect), form handling, and complex UI rendering in one file. There is no shared admin UI component library.
- **Files:**
  - `web-app/src/app/(admin)/admin/workouts/programs/page.tsx` (710 lines)
  - `web-app/src/app/(admin)/admin/content/blog/page.tsx` (501 lines)
  - `web-app/src/app/(admin)/admin/workouts/wods/page.tsx` (422 lines)
  - `web-app/src/app/(admin)/admin/catalog/page.tsx` (394 lines)
- **Impact:** Adding new admin features requires duplicating patterns. Bug fixes must be applied across multiple files. No unit testing possible for admin logic.
- **Fix approach:** Extract a shared admin component library: `AdminDataTable`, `AdminForm`, `AdminModal`. Move data fetching into server actions. Target max 150-200 lines per page component.

### Inconsistent Error Handling Pattern in Admin API Routes (MEDIUM)

- **Issue:** Every admin API route repeats the same error handling boilerplate:
  ```typescript
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
  ```
  This pattern appears in 15+ admin route files. String comparison on error messages (`msg === "UNAUTHORIZED"`) is fragile.
- **Files:** All files in `web-app/src/app/api/admin/*/route.ts`
- **Impact:** Error handling inconsistencies if any route forgets the pattern. String-based error discrimination breaks if error messages change in `requireAdmin()`.
- **Fix approach:** Create an `withAdminAuth()` wrapper function that handles authentication, error catching, and response formatting. Use error codes (not message strings) for discrimination.

### Landing Page Hardcodes All Content (LOW)

- **Issue:** `src/app/page.tsx` (520 lines) hardcodes features, pricing tiers, and steps data directly in the component. Any copy change requires a code deployment.
- **Files:** `web-app/src/app/page.tsx`
- **Impact:** Marketing content changes require developer involvement and a full Vercel deploy.
- **Fix approach:** Extract content into a CMS or at minimum a separate data file. This is low priority since the landing page is relatively stable.

---

## Deployment Risks

### No CI/CD Pipeline (HIGH)

- **Issue:** Deployment is entirely manual: `vercel deploy --prod` for the web app, `firebase deploy --only functions` for Cloud Functions. There is no GitHub Actions workflow, no pre-deploy validation, no automated testing on push. The `CLAUDE.md` explicitly states "No CI/CD pipeline in GitHub."
- **Files:** N/A — infrastructure gap
- **Impact:** Regressions can be deployed directly to production. No enforced quality gate. Deployments depend on a single developer remembering to run tests and linting locally first.
- **Fix approach:** Add a GitHub Actions workflow that runs `npm test`, `npm run lint`, and `npm run build` on every push and PR. Add a deployment workflow triggered by tags or manual approval.

### Firestore Indexes May Be Missing in Production (MEDIUM)

- **Issue:** `firestore.indexes.json` exists at the project root but the admin routes perform queries with `orderBy` and `where` combinations (e.g., `where("status", "==", "active")` without `orderBy`, or `where("completedAt", ">=", date)` with `orderBy`). Firestore requires composite indexes for these queries, which are not visible in the source code.
- **Files:** `firestore.indexes.json`, various `actions.ts` files
- **Impact:** Queries that work locally with small datasets may fail in production with "query requires an index" errors. These only surface under real traffic conditions.
- **Fix approach:** Audit all Firestore queries with `where` + `orderBy` combinations and ensure composite indexes are declared in `firestore.indexes.json`. Deploy indexes with `firebase deploy --only firestore:indexes`.

### Cloud Function and Web App AI Rate Limits Out of Sync (MEDIUM)

- **Issue:** (Also noted in Technical Debt) The Cloud Function in `firebase/functions/src/rate-limit.ts` hardcodes `premium: 10` while the domain layer in `web-app/src/lib/domain/subscription.ts` returns `premium: 25`. If the Cloud Function path is still active, premium users will experience inconsistent limits.
- **Files:**
  - `firebase/functions/src/rate-limit.ts` (line 4)
  - `web-app/src/lib/domain/subscription.ts` (line 164)
- **Impact:** User confusion when switching between platforms. The Cloud Function may reject valid requests that the web app would allow.
- **Fix approach:** Either decommission the Cloud Function AI endpoint (if the web app API route is the canonical path) or centralize the rate limit configuration.

---

## Privacy and Compliance

### User Period Data Stored Without Encryption (MEDIUM)

- **Issue:** Menstrual cycle tracking data (period logs, cycle settings, symptoms) is stored in Firestore subcollections (`periodLogs`, `cycleSettings`) with no additional encryption beyond Firestore's default at-rest encryption. Firestore security rules restrict access to the owning user, but the data is readable by anyone with Firestore Admin SDK access (server-side code, admin dashboard).
- **Files:**
  - `web-app/src/app/(features)/cycle/actions.ts`
  - `web-app/firestore.rules` (lines 7-13)
- **Impact:** Health-related data (period tracking is classified as health data in many jurisdictions) is stored alongside general training data. Admin users viewing user detail pages can see cycle tracking data implicitly through subcollection access. The admin user detail endpoint (`src/app/api/admin/users/[uid]/route.ts`) does not fetch period logs, but the `userSubcollection()` helper makes it trivially accessible.
- **Fix approach:** Consider application-level encryption for sensitive health fields. Add explicit documentation about health data handling. Ensure admin interfaces do not display health data without explicit consent mechanisms. Consider data residency requirements for health data.

### Benchmark Definitions Auto-Created from Client (LOW)

- **Issue:** `src/app/(features)/benchmarks/actions.ts` `logBenchmarkResult()` (lines 49-63) auto-creates `benchmarkDefinitions` documents in Firestore when a user logs a predefined benchmark that does not yet exist on the server. This writes to a top-level shared collection from user-facing server action code.
- **Files:** `web-app/src/app/(features)/benchmarks/actions.ts` (lines 49-63)
- **Impact:** A malicious client could potentially trigger writes to the `benchmarkDefinitions` collection by sending arbitrary `definitionId` values. The `PREDEFINED_BENCHMARKS` check provides some protection, but the list is checked client-side (imported from domain code).
- **Fix approach:** Move benchmark definition seeding to an admin-only script or migration. Remove the auto-creation logic from user-facing server actions.

---

## Dependency Risks

### Firebase SDK as Single Point of Failure (MEDIUM)

- **Issue:** The entire backend depends on Firebase: `firebase-admin` for server-side auth and Firestore, `firebase` for client-side auth. There is no abstraction layer between the application and Firebase. Migration would require rewriting all data access, authentication, and server-side logic.
- **Files:**
  - `web-app/src/lib/firebase.ts` (client SDK)
  - `web-app/src/lib/firebase-admin.ts` (admin SDK)
  - `web-app/src/lib/firestore.ts` (data access)
- **Impact:** Complete vendor lock-in. Firebase outages affect all functionality. Pricing changes cannot be negotiated.
- **Fix approach:** (Long-term) Create a data access abstraction layer that could be backed by alternative providers. This is a strategic decision, not a code fix.

### Google GenAI SDK for AI Workouts (LOW)

- **Issue:** AI workout generation uses `@google/genai` (imported dynamically in `src/app/api/ai/generate/route.ts` line 135). The Cloud Function uses `@google-cloud/vertexai`. Two different Google AI SDKs for the same logical feature.
- **Files:**
  - `web-app/src/app/api/ai/generate/route.ts` (uses `@google/genai`)
  - `firebase/functions/src/ai.ts` (uses `@google-cloud/vertexai`)
- **Impact:** Divergent API patterns for the same feature. SDK version conflicts possible. Knowledge split across two implementations.
- **Fix approach:** Standardize on one SDK. If the Cloud Function path is deprecated, remove it. Otherwise, align both to `@google/genai`.

---

## Test Coverage Gaps

### Server Actions Have No Tests (HIGH)

- **Issue:** All seven server action files (`src/app/(features)/*/actions.ts`) contain zero tests. These files handle authentication, input validation, Firestore reads/writes, and business logic. They are the primary integration surface between the UI and the data layer.
- **Files:**
  - `web-app/src/app/(features)/benchmarks/actions.ts`
  - `web-app/src/app/(features)/cycle/actions.ts`
  - `web-app/src/app/(features)/dashboard/actions.ts`
  - `web-app/src/app/(features)/maxes/actions.ts`
  - `web-app/src/app/(features)/programs/actions.ts`
  - `web-app/src/app/(features)/settings/actions.ts`
  - `web-app/src/app/(features)/workouts/actions.ts`
- **Impact:** Input validation regressions, auth bypass, and Firestore query bugs can reach production undetected. The `write-validation.ts` helpers are tested via domain tests, but the server action integration layer is not.
- **Fix approach:** Add integration tests using Firebase emulator. Test at minimum: auth rejection, input validation, and successful CRUD for each action file.

### API Routes Have No Tests (MEDIUM)

- **Issue:** None of the API routes under `src/app/api/` have associated test files. This includes critical paths: Stripe webhooks, session management, AI generation, and admin endpoints.
- **Files:** All files in `web-app/src/app/api/`
- **Impact:** Webhook handling errors, auth edge cases, and admin authorization bypasses can go undetected. The Stripe webhook route is particularly critical — incorrect handling could cause subscription state corruption.
- **Priority:** High for webhook and auth routes; Medium for admin routes.

### No E2E Tests (MEDIUM)

- **Issue:** No end-to-end tests exist for any user flow: sign-up, subscription purchase, workout logging, cycle tracking. The test suite covers only the pure domain layer (`src/lib/domain/__tests__/`).
- **Files:** N/A — no E2E test infrastructure
- **Impact:** Breaking changes to page routing, form submission, or Firebase integration can reach production without detection.
- **Fix approach:** Add Playwright or similar E2E tests for critical user flows: sign-in, workout creation, subscription purchase, cycle logging.

---

*Concerns audit: 2026-04-08*
