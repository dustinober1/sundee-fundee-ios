# Sundee Fundee: Cloudflare to Firebase Migration Design

**Date:** 2026-03-29
**Approach:** Big Bang Migration (Approach A)
**Hosting:** Vercel (Next.js) + Firebase (Auth, Firestore, Cloud Functions)
**Constraint:** Cloudflare retains DNS/domain only

---

## Architecture

```
Next.js App Router (Vercel)
    ↓
API Routes (/api/stripe, server actions)
    ↓
Firebase Admin SDK (server-side)
    ↓
Firebase Auth + Firestore
    ↓
Cloud Functions (AI workout generation via Vertex AI Gemini Flash)
    ↓
Domain/ (unchanged — pure TypeScript, zero dependencies)
```

**Unchanged layers:** Domain logic, UI components, blog/MDX, Stripe SDK, PWA/Serwist, Tailwind theme.

---

## 1. Firebase Auth

**Replaces:** Auth.js v5 + DrizzleAdapter + PBKDF2 password hashing

**Providers:** Email/Password, Google OAuth, Apple Sign-In

### Client-side
- Firebase Client SDK (`firebase/auth`)
- `signInWithPopup` for Google/Apple
- `createUserWithEmailAndPassword` + `signInWithEmailAndPassword` for credentials
- `AuthProvider` React context wraps the app, exposes `user` and `loading`

### Server-side
- Firebase Admin SDK (`firebase-admin`) verifies ID tokens
- `getAuthUser(request)` helper extracts and verifies `Authorization: Bearer <token>`
- Returns `{ uid, email, name }`

### Middleware
- Next.js middleware checks for Firebase auth cookie
- Protected routes: `/dashboard`, `/workouts`, `/programs`, `/maxes`, `/benchmarks`, `/cycle`, `/settings`
- Unauthenticated users redirect to `/sign-in`

### Pages affected
- `src/app/(auth)/sign-in/page.tsx` — rewritten for Firebase Auth SDK
- `src/app/(auth)/sign-up/page.tsx` — rewritten for Firebase Auth SDK
- `src/app/auth-error/page.tsx` — kept, minor updates

### Deleted
- `src/lib/auth.ts`, `src/lib/password.ts`
- `src/app/api/auth/register/route.ts`, `src/app/api/auth/[...nextauth]/route.ts`
- `@auth/drizzle-adapter`, `next-auth` dependencies

---

## 2. Firestore Data Model

**Replaces:** D1 SQLite (19 tables) + Drizzle ORM

### Top-level collections

**`users/{uid}`** — User profile
```
experienceLevel, primaryGoal, gender, weightUnit,
cycleTrackingEnabled, onboardingComplete, createdAt, profileUpdatedAt
```

**`benchmarkDefinitions/{id}`** — Shared benchmark catalog (not user-owned)

### Subcollections under `users/{uid}/`

| Subcollection | Source table(s) | Notes |
|---|---|---|
| `oneRepMaxes/{id}` | oneRepMaxes | exerciseId, weightKg, date, isEstimated |
| `personalRecords/{id}` | personalRecords | exerciseId, type, value, date |
| `liftMaxes/{id}` | liftMaxes | exerciseId, weightKg |
| `conditioningPrs/{id}` | conditioningPrs | benchmarkId, score, date |
| `completedWorkouts/{id}` | completedWorkouts + completedSets | Sets denormalized as array within workout doc |
| `enrolledPrograms/{id}` | enrolledPrograms | programId, status, startDate, currentWeek, currentDay |
| `enrollmentEvents/{id}` | enrollmentEvents | programId, type, timestamp |
| `injuryProfiles/{id}` | injuryProfiles | bodyPart, severity, type, onset, status |
| `painLogs/{id}` | painLogs | injuryId, level, context, date |
| `periodLogs/{id}` | periodLogs | startDate, endDate, flowLevel |
| `symptomLogs/{id}` | symptomLogs | date, symptoms, severity |
| `cycleSettings/default` | cycleSettings | Single doc |
| `cycleAdaptationPreferences/default` | cycleAdaptationPreferences | Single doc |
| `benchmarkResults/{id}` | benchmarkResults | benchmarkId, score, date |
| `generatedWorkoutRecords/{id}` | generatedWorkoutRecords | prompt, response, createdAt |
| `customProgramRecords/{id}` | customProgramRecords | name, data, createdAt |
| `subscription/current` | subscriptions | Single doc — stripeCustomerId, tier, status, priceId, expiresAt |

### Design decisions
- **CompletedSets denormalized** into completedWorkouts — always read together
- **Single-doc subcollections** for 1:1 relationships (cycleSettings, subscription)
- **Security rule:** `request.auth.uid == uid` on all user subcollections

---

## 3. AI Workout Generation

**Replaces:** Cloudflare AI Worker (`workers/ai-coach/`) + proxy route

### Cloud Function: `generateWorkout`
- **Runtime:** Node.js 20 (Firebase Cloud Functions v2)
- **Trigger:** HTTPS callable
- **Auth:** Automatically verified by callable function
- **Model:** Vertex AI Gemini Flash
- **Rate limiting:** Firestore-based — `users/{uid}/aiUsage/{YYYY-MM-DD}` counter doc
  - Free: 0/day, Plus: 1/day, Premium: 10/day

### Flow
```
Client (Firebase callable SDK)
  → Cloud Function (verify auth, check rate limit)
    → Vertex AI Gemini Flash (prompt + structured output)
      → Validate response
        → Save to users/{uid}/generatedWorkoutRecords
          → Return workout to client
```

### Domain logic preserved
All functions in `src/lib/domain/ai-workout.ts` remain unchanged:
`energyMultiplier()`, `cyclePhaseMultiplier()`, `defaultPercentage()`, `assignRestMinutes()`, `applyWeights()`, `findMatchingMax()`

Client applies weights/rest using domain functions after receiving raw AI response.

---

## 4. Stripe Integration

**Minimal changes** — Stripe SDK is cloud-agnostic.

### Unchanged
- `src/lib/stripe.ts` — price IDs, `createStripeClient()`, `tierFromPriceId()`
- `src/lib/domain/subscription.ts` — tier definitions, feature gates
- Checkout → redirect → webhook flow pattern

### Changed
- **Webhook route:** Writes to `users/{uid}/subscription/current` in Firestore (was D1)
- **Checkout route:** Auth via `getAuthUser(request)` (was NextAuth `auth()`)
- **Portal route:** Reads `stripeCustomerId` from Firestore (was D1)
- **Env vars:** Move to Vercel dashboard

---

## 5. Server Actions Migration

Current server actions in `src/app/(features)/*/actions.ts` use `getBindings()` → `createDb(env.DB)` → Drizzle queries.

All migrate to Firebase Admin SDK → Firestore queries:

| Feature | Current pattern | New pattern |
|---|---|---|
| Workouts | `db.select().from(schema.completedWorkouts)` | `firestore.collection('users/${uid}/completedWorkouts').get()` |
| Maxes | `db.insert(schema.oneRepMaxes)` | `firestore.collection('users/${uid}/oneRepMaxes').add(data)` |
| Cycle | Drizzle CRUD on cycle tables | Firestore CRUD on cycle subcollections |
| Programs | Drizzle CRUD on program tables | Firestore CRUD on program subcollections |
| Benchmarks | Drizzle CRUD on benchmark tables | Firestore CRUD on benchmark subcollections |
| Settings | `db.update(schema.users)` | `firestore.doc('users/${uid}').update(data)` |

Auth in each action: verify Firebase ID token from request cookies/headers.

---

## 6. Deployment & Infrastructure

### Vercel
- Standard Next.js deployment, no adapter
- GitHub repo → auto-deploy on push to `main`
- Root directory: `web-app/`

### Firebase
- New Firebase project
- Enable: Authentication, Firestore, Cloud Functions
- Auth providers: Email/Password, Google, Apple
- Cloud Functions source: `firebase/functions/` in repo

### Cloudflare
- DNS only — CNAME to Vercel
- Delete: Pages project, D1 database, KV namespace, AI Worker

### Environment variables (Vercel)

| Variable | Purpose |
|---|---|
| `FIREBASE_PROJECT_ID` | Admin SDK |
| `FIREBASE_CLIENT_EMAIL` | Admin SDK |
| `FIREBASE_PRIVATE_KEY` | Admin SDK |
| `NEXT_PUBLIC_FIREBASE_API_KEY` | Client SDK |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | Client SDK |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | Client SDK |
| `STRIPE_SECRET_KEY` | Stripe API |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Stripe.js |
| `NEXT_PUBLIC_APP_URL` | Redirects |

---

## 7. Files Deleted

- `wrangler.jsonc`, `open-next.config.ts`
- `src/lib/bindings.ts`, `src/env.d.ts`
- `src/lib/auth.ts`, `src/lib/password.ts`
- `src/app/api/auth/register/route.ts`, `src/app/api/auth/[...nextauth]/route.ts`
- `src/db/` directory (schema, index)
- `drizzle/` directory (migrations)
- `drizzle.config.ts`
- `workers/ai-coach/` directory
- `functions/` directory

## 8. Files Added

- `firebase.json`, `.firebaserc` — Firebase project config
- `firebase/functions/` — Cloud Functions (AI generation)
- `src/lib/firebase.ts` — Client SDK initialization
- `src/lib/firebase-admin.ts` — Admin SDK initialization
- `src/lib/firestore.ts` — Firestore helper functions

## 9. Dependencies

### Added
- `firebase` (client SDK)
- `firebase-admin` (server SDK)
- `firebase-functions` (Cloud Functions, in `firebase/functions/`)
- `@google-cloud/vertexai` (Gemini, in `firebase/functions/`)

### Removed
- `@opennextjs/cloudflare`
- `@cloudflare/workers-types`
- `wrangler`
- `drizzle-orm`, `drizzle-kit`
- `@auth/drizzle-adapter`
- `next-auth`

## 10. Out of Scope

- **`wod-dashboard/`** — Separate admin app, uses CloudKit. Unaffected by this migration.
- **Blog/MDX** — Purely file-based, no database dependency. Unchanged.
- **Domain layer** (`src/lib/domain/`) — Pure TypeScript, no framework imports. Unchanged.
