# Phase 1: Web App Scaffold — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a fully configured Next.js web app scaffold at `web-app/` with Cloudflare Pages deployment, D1 database, Auth.js authentication, Stripe subscriptions, and PWA support — all using the Sundee Fundee Art Deco design system.

**Architecture:** Next.js 15 App Router deployed on Cloudflare Pages via `@opennextjs/cloudflare`. Drizzle ORM for D1 SQLite database. Auth.js v5 for authentication. Stripe for subscription billing. `@serwist/next` for PWA/service worker.

**Tech Stack:** Next.js 15, TypeScript, Tailwind CSS v4, Drizzle ORM, Auth.js v5, Stripe, @opennextjs/cloudflare, @serwist/next, Wrangler

---

### Task 1: Initialize Next.js Project

**Files:**
- Create: `web-app/package.json`
- Create: `web-app/tsconfig.json`
- Create: `web-app/next.config.ts`
- Create: `web-app/.gitignore`
- Create: `web-app/src/app/layout.tsx`
- Create: `web-app/src/app/page.tsx`

- [ ] **Step 1: Create the web-app directory and initialize Next.js**

```bash
cd /Users/dustinober/Projects/sundee-fundee
npx create-next-app@latest web-app --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --no-turbopack
```

Accept defaults. This creates the scaffold with Next.js 15, TypeScript, Tailwind v4, App Router.

- [ ] **Step 2: Verify project created successfully**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && ls -la
```

Expected: `package.json`, `tsconfig.json`, `next.config.ts`, `src/`, `public/`, etc.

- [ ] **Step 3: Verify it builds**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npm run build
```

Expected: Successful build output.

- [ ] **Step 4: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/
git commit -m "feat: initialize Next.js 15 web app scaffold"
```

---

### Task 2: Configure Cloudflare Pages Deployment

**Files:**
- Create: `web-app/wrangler.jsonc`
- Modify: `web-app/package.json` (add scripts)
- Modify: `web-app/next.config.ts` (add opennextjs config)

- [ ] **Step 1: Install Cloudflare dependencies**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app
npm install --save-dev @opennextjs/cloudflare wrangler
```

- [ ] **Step 2: Create `web-app/wrangler.jsonc`**

```jsonc
{
  "name": "sundee-fundee-web",
  "compatibility_date": "2025-12-01",
  "compatibility_flags": ["nodejs_compat"],
  "pages_build_output_dir": ".open-next",
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "sundee-fundee-db",
      "database_id": "placeholder-create-with-wrangler"
    }
  ],
  "kv_namespaces": [
    {
      "binding": "KV",
      "id": "placeholder-create-with-wrangler"
    }
  ],
  "vars": {
    "NEXT_PUBLIC_APP_URL": "https://sundeefundee.com"
  }
}
```

- [ ] **Step 3: Update `web-app/next.config.ts`**

Replace contents with:

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* Cloudflare Pages via opennextjs handles the build output */
};

export default nextConfig;
```

- [ ] **Step 4: Add build scripts to `web-app/package.json`**

Add to `"scripts"`:
```json
{
  "build:cf": "npx @opennextjs/cloudflare build",
  "preview": "npx wrangler dev",
  "deploy": "npx wrangler deploy"
}
```

- [ ] **Step 5: Verify Cloudflare build works**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npm run build:cf
```

Expected: Build completes, `.open-next/` directory created.

- [ ] **Step 6: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/wrangler.jsonc web-app/package.json web-app/next.config.ts web-app/package-lock.json
git commit -m "feat: configure Cloudflare Pages deployment with opennextjs"
```

---

### Task 3: Design System — CSS Custom Properties and Tailwind Config

**Files:**
- Create: `web-app/src/app/globals.css` (replace default)
- Modify: Tailwind config (in CSS for v4)
- Create: `web-app/src/lib/theme.ts`

- [ ] **Step 1: Replace `web-app/src/app/globals.css` with design tokens**

```css
@import "tailwindcss";

/* === Sundee Fundee Art Deco Design Tokens === */

@theme {
  /* Colors — from SundeeFundee/Theme/AppTheme.swift */
  --color-cream: #f4f0df;
  --color-navy: #0d1a40;
  --color-orange: #f27319;
  --color-gold: #d9b34d;
  --color-card-bg: #fcfaf2;
  --color-separator: #e0d9c7;
  --color-text-secondary: #596180;
  --color-error: #d92626;
  --color-warm-rose: #e68c80;

  /* Spacing — matches Swift pt values */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  --spacing-xxl: 48px;

  /* Border Radii */
  --radius-sm: 6px;
  --radius-md: 12px;
  --radius-lg: 20px;
  --radius-card: 12px;
  --radius-button: 8px;

  /* Typography sizes */
  --font-size-heading: 22px;
  --font-size-subheading: 17px;
  --font-size-body: 15px;
  --font-size-caption: 13px;
  --font-size-mono: 14px;

  /* Fonts */
  --font-heading: "Playfair Display", Georgia, serif;
  --font-body: "Inter", system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;
}

/* Base styles */
body {
  font-family: var(--font-body);
  font-size: var(--font-size-body);
  color: var(--color-navy);
  background-color: var(--color-cream);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

h1, h2, h3, h4 {
  font-family: var(--font-heading);
}

h1 {
  font-size: var(--font-size-heading);
  font-weight: 700;
}

h2 {
  font-size: var(--font-size-subheading);
  font-weight: 600;
}

/* Utility classes matching Swift button/card styles */
.card {
  background-color: var(--color-card-bg);
  border-radius: var(--radius-card);
  padding: var(--spacing-md);
  box-shadow: 0 1px 3px rgba(13, 26, 64, 0.08);
}

/* PWA standalone mode adjustments */
@media (display-mode: standalone) {
  body {
    padding-top: env(safe-area-inset-top);
    padding-bottom: env(safe-area-inset-bottom);
  }
}
```

- [ ] **Step 2: Create `web-app/src/lib/theme.ts` with typed token constants**

```typescript
/** Design tokens from SundeeFundee/Theme/AppTheme.swift — TypeScript constants for programmatic access */

export const colors = {
  cream: "#f4f0df",
  navy: "#0d1a40",
  orange: "#f27319",
  gold: "#d9b34d",
  cardBg: "#fcfaf2",
  separator: "#e0d9c7",
  textSecondary: "#596180",
  error: "#d92626",
  warmRose: "#e68c80",
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

export const radii = {
  sm: 6,
  md: 12,
  lg: 20,
  card: 12,
  button: 8,
} as const;
```

- [ ] **Step 3: Verify the styles render**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npm run build
```

Expected: Build passes with custom theme.

- [ ] **Step 4: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/app/globals.css web-app/src/lib/theme.ts
git commit -m "feat: add Art Deco design system with CSS custom properties"
```

---

### Task 4: Google Fonts (Playfair Display + Inter)

**Files:**
- Modify: `web-app/src/app/layout.tsx`

- [ ] **Step 1: Update `web-app/src/app/layout.tsx` with fonts and base layout**

```tsx
import type { Metadata, Viewport } from "next";
import { Playfair_Display, Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const playfair = Playfair_Display({
  subsets: ["latin"],
  variable: "--font-heading",
  display: "swap",
});

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-body",
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Sundee Fundee — Strength Training",
  description:
    "Personalized strength training with hormonal-cycle-aware recommendations.",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Sundee Fundee",
  },
};

export const viewport: Viewport = {
  themeColor: "#0d1a40",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={`${playfair.variable} ${inter.variable} ${jetbrainsMono.variable}`}
    >
      <body>{children}</body>
    </html>
  );
}
```

- [ ] **Step 2: Update `web-app/src/app/page.tsx` with placeholder landing page**

```tsx
export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-spacing-lg">
      <h1 className="text-4xl mb-spacing-md">Sundee Fundee</h1>
      <p className="text-text-secondary text-center max-w-md">
        Personalized strength training with hormonal-cycle-aware recommendations.
      </p>
    </main>
  );
}
```

- [ ] **Step 3: Verify fonts load and styles apply**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npm run build
```

Expected: Build passes.

- [ ] **Step 4: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/app/layout.tsx web-app/src/app/page.tsx
git commit -m "feat: add Google Fonts and root layout with Art Deco typography"
```

---

### Task 5: PWA Configuration with Serwist

**Files:**
- Create: `web-app/public/manifest.json`
- Create: `web-app/src/app/sw.ts`
- Create: `web-app/src/lib/serwist.ts`
- Modify: `web-app/next.config.ts`

- [ ] **Step 1: Install serwist dependencies**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app
npm install @serwist/next
npm install --save-dev serwist
```

- [ ] **Step 2: Create `web-app/public/manifest.json`**

```json
{
  "name": "Sundee Fundee",
  "short_name": "Sundee Fundee",
  "description": "Personalized strength training with hormonal-cycle-aware recommendations.",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#f4f0df",
  "theme_color": "#0d1a40",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

- [ ] **Step 3: Create placeholder PWA icons**

```bash
mkdir -p /Users/dustinober/Projects/sundee-fundee/web-app/public/icons
```

Create simple placeholder SVG-based icons (these will be replaced with real assets later). For now, create a minimal valid PNG:

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app
# Create placeholder icon files — will be replaced with real branding later
npx --yes sharp-cli -i /dev/null -o public/icons/icon-192.png -- resize 192 192 --background "#0d1a40" --flatten 2>/dev/null || echo "placeholder" > public/icons/icon-192.png
npx --yes sharp-cli -i /dev/null -o public/icons/icon-512.png -- resize 512 512 --background "#0d1a40" --flatten 2>/dev/null || echo "placeholder" > public/icons/icon-512.png
```

Note: Real icons will be added later. Placeholders are fine for development.

- [ ] **Step 4: Create `web-app/src/app/sw.ts` (service worker entry)**

```typescript
import { defaultCache } from "@serwist/next/worker";
import type { PrecacheEntry, SerwistGlobalConfig } from "serwist";
import { Serwist } from "serwist";

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
  runtimeCaching: defaultCache,
});

serwist.addEventListeners();
```

- [ ] **Step 5: Update `web-app/next.config.ts` with serwist**

```typescript
import type { NextConfig } from "next";
import withSerwistInit from "@serwist/next";

const withSerwist = withSerwistInit({
  swSrc: "src/app/sw.ts",
  swDest: "public/sw.js",
  disable: process.env.NODE_ENV === "development",
});

const nextConfig: NextConfig = {};

export default withSerwist(nextConfig);
```

- [ ] **Step 6: Verify build with PWA**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npm run build
```

Expected: Build passes, `sw.js` generated in `public/` (only in production builds).

- [ ] **Step 7: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/public/manifest.json web-app/public/icons/ web-app/src/app/sw.ts web-app/next.config.ts
git commit -m "feat: add PWA configuration with serwist service worker"
```

---

### Task 6: Drizzle ORM + D1 Database Schema

**Files:**
- Create: `web-app/src/db/schema.ts`
- Create: `web-app/src/db/index.ts`
- Create: `web-app/drizzle.config.ts`

- [ ] **Step 1: Install Drizzle dependencies**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app
npm install drizzle-orm
npm install --save-dev drizzle-kit
```

- [ ] **Step 2: Create `web-app/drizzle.config.ts`**

```typescript
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dialect: "sqlite",
});
```

- [ ] **Step 3: Create `web-app/src/db/schema.ts` — full database schema**

This ports all 18 SwiftData models to Drizzle SQLite tables:

```typescript
import { sqliteTable, text, integer, real } from "drizzle-orm/sqlite-core";

// ============================================================
// Auth.js tables
// ============================================================

export const users = sqliteTable("users", {
  id: text("id").primaryKey(),
  name: text("name"),
  email: text("email").notNull().unique(),
  emailVerified: integer("email_verified", { mode: "timestamp" }),
  image: text("image"),
  // App-specific user fields
  experienceLevel: text("experience_level").default("beginner"),
  primaryGoal: text("primary_goal").default("strength"),
  gender: text("gender").default("prefer_not_to_say"),
  weightUnit: text("weight_unit").default("lb"),
  cycleTrackingEnabled: integer("cycle_tracking_enabled", { mode: "boolean" }).default(false),
  onboardingComplete: integer("onboarding_complete", { mode: "boolean" }).default(false),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull().$defaultFn(() => new Date()),
  profileUpdatedAt: integer("profile_updated_at", { mode: "timestamp" }),
});

export const accounts = sqliteTable("accounts", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  type: text("type").notNull(),
  provider: text("provider").notNull(),
  providerAccountId: text("provider_account_id").notNull(),
  refreshToken: text("refresh_token"),
  accessToken: text("access_token"),
  expiresAt: integer("expires_at"),
  tokenType: text("token_type"),
  scope: text("scope"),
  idToken: text("id_token"),
  sessionState: text("session_state"),
});

export const sessions = sqliteTable("sessions", {
  id: text("id").primaryKey(),
  sessionToken: text("session_token").notNull().unique(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  expires: integer("expires", { mode: "timestamp" }).notNull(),
});

export const verificationTokens = sqliteTable("verification_tokens", {
  identifier: text("identifier").notNull(),
  token: text("token").notNull(),
  expires: integer("expires", { mode: "timestamp" }).notNull(),
});

// ============================================================
// Maxes & Personal Records
// ============================================================

export const oneRepMaxes = sqliteTable("one_rep_maxes", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  exerciseId: text("exercise_id").notNull(),
  weightKg: real("weight_kg").notNull(),
  date: integer("date", { mode: "timestamp" }).notNull(),
  isEstimated: integer("is_estimated", { mode: "boolean" }).default(false),
});

export const personalRecords = sqliteTable("personal_records", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  exerciseId: text("exercise_id").notNull(),
  repMaxType: text("rep_max_type").notNull(), // "1RM", "3RM", "5RM"
  weightKg: real("weight_kg").notNull(),
  reps: integer("reps").notNull(),
  achievedAt: integer("achieved_at", { mode: "timestamp" }).notNull(),
  workoutId: text("workout_id"),
});

export const liftMaxes = sqliteTable("lift_maxes", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  exerciseId: text("exercise_id").notNull(),
  weightKg: real("weight_kg").notNull(),
  date: integer("date", { mode: "timestamp" }).notNull(),
});

export const conditioningPrs = sqliteTable("conditioning_prs", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  exerciseId: text("exercise_id").notNull(),
  scoringType: text("scoring_type").notNull(), // "time" or "reps"
  bestValue: real("best_value").notNull(),
  weightKg: real("weight_kg"),
  achievedAt: integer("achieved_at", { mode: "timestamp" }).notNull(),
  workoutId: text("workout_id"),
});

// ============================================================
// Programs & Enrollment
// ============================================================

export const enrolledPrograms = sqliteTable("enrolled_programs", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  programId: text("program_id").notNull(),
  startDate: integer("start_date", { mode: "timestamp" }).notNull(),
  currentWeek: integer("current_week").default(1),
  currentDay: integer("current_day").default(1),
  status: text("status").default("active"), // "active", "canceled", "completed"
  completedAt: integer("completed_at", { mode: "timestamp" }),
  canceledAt: integer("canceled_at", { mode: "timestamp" }),
  completedWeeksRaw: text("completed_weeks_raw").default(""),
  lastSyncedAt: integer("last_synced_at", { mode: "timestamp" }),
});

export const enrollmentEvents = sqliteTable("enrollment_events", {
  id: text("id").primaryKey(),
  enrollmentId: text("enrollment_id").notNull().references(() => enrolledPrograms.id, { onDelete: "cascade" }),
  eventType: text("event_type").notNull(), // "enrolled", "canceled", "completed", "restored", "auto_healed"
  occurredAt: integer("occurred_at", { mode: "timestamp" }).notNull(),
  programId: text("program_id"),
});

// ============================================================
// Workouts
// ============================================================

export const completedWorkouts = sqliteTable("completed_workouts", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  activeCycleId: text("active_cycle_id"),
  programId: text("program_id"),
  enrollmentId: text("enrollment_id"),
  week: integer("week"),
  day: integer("day"),
  sessionId: text("session_id"),
  completedAt: integer("completed_at", { mode: "timestamp" }).notNull(),
  durationSeconds: integer("duration_seconds").default(0),
  notes: text("notes"),
  perceivedEffort: integer("perceived_effort"),
});

export const completedSets = sqliteTable("completed_sets", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  workoutId: text("workout_id").notNull().references(() => completedWorkouts.id, { onDelete: "cascade" }),
  exerciseName: text("exercise_name").notNull(),
  setIndex: integer("set_index").notNull(),
  prescribedReps: text("prescribed_reps").notNull(),
  actualReps: integer("actual_reps"),
  prescribedWeightKg: real("prescribed_weight_kg"),
  actualWeightKg: real("actual_weight_kg"),
  isCompleted: integer("is_completed", { mode: "boolean" }).default(false),
  completedAt: integer("completed_at", { mode: "timestamp" }).notNull(),
  actualTimeSeconds: real("actual_time_seconds"),
  scoringType: text("scoring_type"),
});

// ============================================================
// Injuries & Pain
// ============================================================

export const injuryProfiles = sqliteTable("injury_profiles", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  location: text("location").default(""),
  movementLimitations: text("movement_limitations").default(""),
  recoveryGoal: text("recovery_goal").default(""),
  status: text("status").default("active"), // "active", "resolved"
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
  updatedAt: integer("updated_at", { mode: "timestamp" }).notNull(),
  resolvedAt: integer("resolved_at", { mode: "timestamp" }),
  recoveryPhase: text("recovery_phase").default("acute"),
  locationRegionsRaw: text("location_regions_raw").default(""),
  acknowledgedDisclaimerIdsRaw: text("acknowledged_disclaimer_ids_raw").default(""),
});

export const painLogs = sqliteTable("pain_logs", {
  id: text("id").primaryKey(),
  injuryProfileId: text("injury_profile_id").notNull().references(() => injuryProfiles.id, { onDelete: "cascade" }),
  painLevel: integer("pain_level").notNull(),
  workoutId: text("workout_id"),
  notes: text("notes"),
  recordedAt: integer("recorded_at", { mode: "timestamp" }).notNull(),
  triggerExercise: text("trigger_exercise"),
  symptomType: text("symptom_type"), // "sharp", "dull", "stiffness", "instability"
  intensityContext: text("intensity_context"), // "during_warmup", "during_work_set", "post_workout"
});

// ============================================================
// Cycle Tracking
// ============================================================

export const periodLogs = sqliteTable("period_logs", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  startDate: integer("start_date", { mode: "timestamp" }).notNull(),
  endDate: integer("end_date", { mode: "timestamp" }),
  flowLevel: text("flow_level").default("medium"), // "light", "medium", "heavy", "spotting"
  notes: text("notes"),
});

export const symptomLogs = sqliteTable("symptom_logs", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  date: integer("date", { mode: "timestamp" }).notNull(),
  symptomId: text("symptom_id").notNull(),
  severity: integer("severity").notNull(), // 1-5
  notes: text("notes"),
});

export const cycleSettings = sqliteTable("cycle_settings", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  averageCycleLengthDays: integer("average_cycle_length_days").default(28),
  averagePeriodLengthDays: integer("average_period_length_days").default(5),
  lutealPhaseLengthDays: integer("luteal_phase_length_days").default(14),
  isTrackingEnabled: integer("is_tracking_enabled", { mode: "boolean" }).default(true),
  updatedAt: integer("updated_at", { mode: "timestamp" }).notNull(),
});

export const cycleAdaptationPreferences = sqliteTable("cycle_adaptation_preferences", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  adaptationEnabled: integer("adaptation_enabled", { mode: "boolean" }).default(true),
  fallbackPhase: text("fallback_phase").default("follicular"),
  updatedAt: integer("updated_at", { mode: "timestamp" }).notNull(),
});

// ============================================================
// Benchmarks
// ============================================================

export const benchmarkDefinitions = sqliteTable("benchmark_definitions", {
  id: text("id").primaryKey(),
  userId: text("user_id").default(""), // Empty for predefined
  name: text("name").notNull(),
  category: text("category").notNull(),
  workoutDescription: text("workout_description").notNull(),
  scoringType: text("scoring_type").notNull(), // "time", "reps", "weight", "distance", "roundsAndReps"
  isPredefined: integer("is_predefined", { mode: "boolean" }).default(false),
  sortOrder: integer("sort_order").default(0),
});

export const benchmarkResults = sqliteTable("benchmark_results", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  definitionId: text("definition_id").notNull().references(() => benchmarkDefinitions.id),
  scoreValue: real("score_value").notNull(),
  notes: text("notes").default(""),
  performedAt: integer("performed_at", { mode: "timestamp" }).notNull(),
});

// ============================================================
// AI Workouts
// ============================================================

export const generatedWorkoutRecords = sqliteTable("generated_workout_records", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  workoutJson: text("workout_json").notNull(),
  isFavorite: integer("is_favorite", { mode: "boolean" }).default(false),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

export const customProgramRecords = sqliteTable("custom_program_records", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  programJson: text("program_json").notNull(),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

// ============================================================
// Subscriptions (Stripe)
// ============================================================

export const subscriptions = sqliteTable("subscriptions", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  stripeCustomerId: text("stripe_customer_id").notNull(),
  stripeSubscriptionId: text("stripe_subscription_id"),
  tier: text("tier").default("free"), // "free", "plus", "premium"
  status: text("status").default("active"), // "active", "canceled", "past_due", "trialing"
  currentPeriodEnd: integer("current_period_end", { mode: "timestamp" }),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull().$defaultFn(() => new Date()),
  updatedAt: integer("updated_at", { mode: "timestamp" }).notNull().$defaultFn(() => new Date()),
});
```

- [ ] **Step 4: Create `web-app/src/db/index.ts`**

```typescript
import { drizzle } from "drizzle-orm/d1";
import * as schema from "./schema";

export function createDb(d1: D1Database) {
  return drizzle(d1, { schema });
}

export type Database = ReturnType<typeof createDb>;
export { schema };
```

- [ ] **Step 5: Generate initial migration**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app
npx drizzle-kit generate
```

Expected: Migration SQL file created in `web-app/drizzle/` directory.

- [ ] **Step 6: Verify migration SQL looks correct**

```bash
cat /Users/dustinober/Projects/sundee-fundee/web-app/drizzle/*.sql | head -50
```

Expected: `CREATE TABLE` statements for all tables defined in schema.

- [ ] **Step 7: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/db/ web-app/drizzle.config.ts web-app/drizzle/ web-app/package.json web-app/package-lock.json
git commit -m "feat: add Drizzle ORM schema with all 20 database tables"
```

---

### Task 7: Cloudflare Bindings Type Definitions

**Files:**
- Create: `web-app/src/env.d.ts`
- Create: `web-app/src/lib/bindings.ts`

- [ ] **Step 1: Create `web-app/src/env.d.ts`**

```typescript
/// <reference types="@cloudflare/workers-types" />

interface CloudflareEnv {
  DB: D1Database;
  KV: KVNamespace;
  AUTH_SECRET: string;
  AUTH_GOOGLE_ID: string;
  AUTH_GOOGLE_SECRET: string;
  AUTH_APPLE_ID: string;
  AUTH_APPLE_SECRET: string;
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string;
  NEXT_PUBLIC_APP_URL: string;
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: string;
}
```

- [ ] **Step 2: Install Cloudflare Workers types**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app
npm install --save-dev @cloudflare/workers-types
```

- [ ] **Step 3: Create `web-app/src/lib/bindings.ts` helper**

```typescript
import { getRequestContext } from "@cloudflare/next-on-pages";

/** Get Cloudflare bindings (D1, KV, env vars) in server components / route handlers */
export function getCloudflareBindings(): CloudflareEnv {
  return getRequestContext<CloudflareEnv>().env;
}
```

Wait — we're using `@opennextjs/cloudflare`, not `@cloudflare/next-on-pages`. The API is different:

```typescript
import { getCloudflareContext } from "@opennextjs/cloudflare";

/** Get Cloudflare bindings (D1, KV, env vars) in server components / route handlers */
export async function getBindings(): Promise<CloudflareEnv> {
  const { env } = await getCloudflareContext();
  return env as CloudflareEnv;
}
```

- [ ] **Step 4: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/env.d.ts web-app/src/lib/bindings.ts web-app/package.json web-app/package-lock.json
git commit -m "feat: add Cloudflare bindings type definitions and helpers"
```

---

### Task 8: Auth.js v5 Configuration

**Files:**
- Create: `web-app/src/lib/auth.ts`
- Create: `web-app/src/app/api/auth/[...nextauth]/route.ts`
- Create: `web-app/src/middleware.ts`

- [ ] **Step 1: Install Auth.js dependencies**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app
npm install next-auth@beta @auth/drizzle-adapter
```

- [ ] **Step 2: Create `web-app/src/lib/auth.ts`**

```typescript
import NextAuth from "next-auth";
import Google from "next-auth/providers/google";
import Apple from "next-auth/providers/apple";
import Credentials from "next-auth/providers/credentials";
import { DrizzleAdapter } from "@auth/drizzle-adapter";
import { createDb } from "@/db";
import { getBindings } from "@/lib/bindings";

export const { handlers, signIn, signOut, auth } = NextAuth(async () => {
  const env = await getBindings();
  const db = createDb(env.DB);

  return {
    adapter: DrizzleAdapter(db),
    providers: [
      Google({
        clientId: env.AUTH_GOOGLE_ID,
        clientSecret: env.AUTH_GOOGLE_SECRET,
      }),
      Apple({
        clientId: env.AUTH_APPLE_ID,
        clientSecret: env.AUTH_APPLE_SECRET,
      }),
      Credentials({
        name: "Email",
        credentials: {
          email: { label: "Email", type: "email" },
          password: { label: "Password", type: "password" },
        },
        async authorize(credentials) {
          // Email/password auth will be implemented in Phase 3
          return null;
        },
      }),
    ],
    session: {
      strategy: "jwt",
    },
    pages: {
      signIn: "/sign-in",
    },
    callbacks: {
      jwt({ token, user }) {
        if (user) {
          token.id = user.id;
        }
        return token;
      },
      session({ session, token }) {
        if (token.id) {
          session.user.id = token.id as string;
        }
        return session;
      },
    },
  };
});
```

- [ ] **Step 3: Create `web-app/src/app/api/auth/[...nextauth]/route.ts`**

```typescript
import { handlers } from "@/lib/auth";

export const { GET, POST } = handlers;
```

- [ ] **Step 4: Create `web-app/src/middleware.ts`**

```typescript
export { auth as middleware } from "@/lib/auth";

export const config = {
  matcher: [
    // Protect all routes under (features)
    "/dashboard/:path*",
    "/workouts/:path*",
    "/programs/:path*",
    "/maxes/:path*",
    "/benchmarks/:path*",
    "/cycle/:path*",
    "/settings/:path*",
  ],
};
```

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/auth.ts web-app/src/app/api/auth/ web-app/src/middleware.ts web-app/package.json web-app/package-lock.json
git commit -m "feat: add Auth.js v5 with Google, Apple, and credentials providers"
```

---

### Task 9: Stripe Subscription Setup

**Files:**
- Create: `web-app/src/lib/stripe.ts`
- Create: `web-app/src/app/api/stripe/webhook/route.ts`
- Create: `web-app/src/app/api/stripe/checkout/route.ts`
- Create: `web-app/src/app/api/stripe/portal/route.ts`

- [ ] **Step 1: Install Stripe**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app
npm install stripe
```

- [ ] **Step 2: Create `web-app/src/lib/stripe.ts`**

```typescript
import Stripe from "stripe";

/** Stripe product/price mapping — same tiers as iOS app */
export const STRIPE_PRICES = {
  plus: {
    monthly: "price_plus_monthly", // Replace with actual Stripe price IDs
    annual: "price_plus_annual",
  },
  premium: {
    monthly: "price_premium_monthly",
    annual: "price_premium_annual",
  },
} as const;

/** Maps Stripe price IDs back to subscription tier */
export function tierFromPriceId(priceId: string): "plus" | "premium" | null {
  for (const [tier, prices] of Object.entries(STRIPE_PRICES)) {
    if (prices.monthly === priceId || prices.annual === priceId) {
      return tier as "plus" | "premium";
    }
  }
  return null;
}

export function createStripeClient(secretKey: string): Stripe {
  return new Stripe(secretKey, {
    apiVersion: "2025-03-31.basil",
  });
}
```

- [ ] **Step 3: Create `web-app/src/app/api/stripe/checkout/route.ts`**

```typescript
import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { createStripeClient, STRIPE_PRICES } from "@/lib/stripe";
import { getBindings } from "@/lib/bindings";

export async function POST(req: NextRequest) {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json();
  const { tier, interval } = body as {
    tier: "plus" | "premium";
    interval: "monthly" | "annual";
  };

  if (!tier || !interval || !STRIPE_PRICES[tier]?.[interval]) {
    return NextResponse.json({ error: "Invalid tier or interval" }, { status: 400 });
  }

  const env = await getBindings();
  const stripe = createStripeClient(env.STRIPE_SECRET_KEY);

  const checkoutSession = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer_email: session.user.email ?? undefined,
    line_items: [{ price: STRIPE_PRICES[tier][interval], quantity: 1 }],
    success_url: `${env.NEXT_PUBLIC_APP_URL}/settings?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${env.NEXT_PUBLIC_APP_URL}/settings`,
    metadata: {
      userId: session.user.id,
    },
  });

  return NextResponse.json({ url: checkoutSession.url });
}
```

- [ ] **Step 4: Create `web-app/src/app/api/stripe/webhook/route.ts`**

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createStripeClient, tierFromPriceId } from "@/lib/stripe";
import { getBindings } from "@/lib/bindings";
import { createDb } from "@/db";
import { subscriptions } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function POST(req: NextRequest) {
  const env = await getBindings();
  const stripe = createStripeClient(env.STRIPE_SECRET_KEY);
  const body = await req.text();
  const sig = req.headers.get("stripe-signature")!;

  let event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, env.STRIPE_WEBHOOK_SECRET);
  } catch {
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  const db = createDb(env.DB);

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object;
      const userId = session.metadata?.userId;
      if (!userId || !session.subscription) break;

      const sub = await stripe.subscriptions.retrieve(session.subscription as string);
      const priceId = sub.items.data[0]?.price.id;
      const tier = tierFromPriceId(priceId ?? "") ?? "free";

      await db.insert(subscriptions).values({
        id: crypto.randomUUID(),
        userId,
        stripeCustomerId: session.customer as string,
        stripeSubscriptionId: session.subscription as string,
        tier,
        status: "active",
        currentPeriodEnd: new Date(sub.current_period_end * 1000),
        createdAt: new Date(),
        updatedAt: new Date(),
      }).onConflictDoUpdate({
        target: subscriptions.userId,
        set: {
          stripeSubscriptionId: session.subscription as string,
          tier,
          status: "active",
          currentPeriodEnd: new Date(sub.current_period_end * 1000),
          updatedAt: new Date(),
        },
      });
      break;
    }

    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const sub = event.data.object;
      const priceId = sub.items.data[0]?.price.id;
      const tier = sub.status === "active" ? (tierFromPriceId(priceId ?? "") ?? "free") : "free";

      await db.update(subscriptions)
        .set({
          tier,
          status: sub.status === "active" ? "active" : "canceled",
          currentPeriodEnd: new Date(sub.current_period_end * 1000),
          updatedAt: new Date(),
        })
        .where(eq(subscriptions.stripeSubscriptionId, sub.id));
      break;
    }
  }

  return NextResponse.json({ received: true });
}
```

- [ ] **Step 5: Create `web-app/src/app/api/stripe/portal/route.ts`**

```typescript
import { NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { createStripeClient } from "@/lib/stripe";
import { getBindings } from "@/lib/bindings";
import { createDb } from "@/db";
import { subscriptions } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function POST() {
  const session = await auth();
  if (!session?.user?.id) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const env = await getBindings();
  const db = createDb(env.DB);
  const stripe = createStripeClient(env.STRIPE_SECRET_KEY);

  const sub = await db.query.subscriptions.findFirst({
    where: eq(subscriptions.userId, session.user.id),
  });

  if (!sub?.stripeCustomerId) {
    return NextResponse.json({ error: "No subscription found" }, { status: 404 });
  }

  const portalSession = await stripe.billingPortal.sessions.create({
    customer: sub.stripeCustomerId,
    return_url: `${env.NEXT_PUBLIC_APP_URL}/settings`,
  });

  return NextResponse.json({ url: portalSession.url });
}
```

- [ ] **Step 6: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/lib/stripe.ts web-app/src/app/api/stripe/ web-app/package.json web-app/package-lock.json
git commit -m "feat: add Stripe subscription checkout, webhooks, and billing portal"
```

---

### Task 10: Shared UI Components

**Files:**
- Create: `web-app/src/components/ui/button.tsx`
- Create: `web-app/src/components/ui/card.tsx`
- Create: `web-app/src/components/ui/input.tsx`
- Create: `web-app/src/components/layout/bottom-nav.tsx`

- [ ] **Step 1: Create `web-app/src/components/ui/button.tsx`**

```tsx
import { ButtonHTMLAttributes, forwardRef } from "react";

type Variant = "primary" | "secondary" | "destructive";

const variantStyles: Record<Variant, string> = {
  primary:
    "bg-orange text-cream hover:opacity-90 active:opacity-80",
  secondary:
    "bg-card-bg text-navy border border-navy hover:bg-separator/30 active:bg-separator/50",
  destructive:
    "bg-error/8 text-error hover:bg-error/15 active:bg-error/20",
};

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  fullWidth?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", fullWidth = false, className = "", children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={`
          inline-flex items-center justify-center
          px-spacing-md py-spacing-sm
          rounded-button font-medium text-[15px]
          transition-opacity duration-150
          disabled:opacity-40 disabled:cursor-not-allowed
          ${fullWidth ? "w-full" : ""}
          ${variantStyles[variant]}
          ${className}
        `}
        {...props}
      >
        {children}
      </button>
    );
  }
);
Button.displayName = "Button";
```

- [ ] **Step 2: Create `web-app/src/components/ui/card.tsx`**

```tsx
import { HTMLAttributes, forwardRef } from "react";

interface CardProps extends HTMLAttributes<HTMLDivElement> {}

export const Card = forwardRef<HTMLDivElement, CardProps>(
  ({ className = "", children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={`card ${className}`}
        {...props}
      >
        {children}
      </div>
    );
  }
);
Card.displayName = "Card";
```

- [ ] **Step 3: Create `web-app/src/components/ui/input.tsx`**

```tsx
import { InputHTMLAttributes, forwardRef } from "react";

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, className = "", id, ...props }, ref) => {
    const inputId = id ?? label?.toLowerCase().replace(/\s+/g, "-");
    return (
      <div className="flex flex-col gap-spacing-xs">
        {label && (
          <label htmlFor={inputId} className="text-[13px] font-medium text-navy">
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={inputId}
          className={`
            w-full px-spacing-sm py-spacing-sm
            bg-card-bg border border-separator rounded-sm
            text-navy text-[15px]
            placeholder:text-text-secondary/50
            focus:outline-none focus:ring-2 focus:ring-orange/40 focus:border-orange
            ${error ? "border-error" : ""}
            ${className}
          `}
          {...props}
        />
        {error && <p className="text-[13px] text-error">{error}</p>}
      </div>
    );
  }
);
Input.displayName = "Input";
```

- [ ] **Step 4: Create `web-app/src/components/layout/bottom-nav.tsx`**

```tsx
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" },
  { href: "/programs", label: "Programs", icon: "M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" },
  { href: "/workouts", label: "Workouts", icon: "M13 10V3L4 14h7v7l9-11h-7z" },
  { href: "/maxes", label: "Maxes", icon: "M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" },
  { href: "/settings", label: "More", icon: "M4 6h16M4 12h16M4 18h16" },
] as const;

export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-cream border-t border-separator pb-[env(safe-area-inset-bottom)] z-50">
      <div className="flex justify-around items-center h-14">
        {navItems.map((item) => {
          const isActive = pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex flex-col items-center gap-0.5 py-1 px-3 ${
                isActive ? "text-orange" : "text-text-secondary"
              }`}
            >
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d={item.icon} />
              </svg>
              <span className="text-[10px] font-medium">{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
```

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/components/
git commit -m "feat: add shared UI components (button, card, input, bottom nav)"
```

---

### Task 11: App Shell Layout (Authenticated Routes)

**Files:**
- Create: `web-app/src/app/(features)/layout.tsx`
- Create: `web-app/src/app/(features)/dashboard/page.tsx`

- [ ] **Step 1: Create authenticated layout at `web-app/src/app/(features)/layout.tsx`**

```tsx
import { BottomNav } from "@/components/layout/bottom-nav";

export default function FeaturesLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen pb-16">
      <main className="max-w-lg mx-auto px-spacing-md py-spacing-md">
        {children}
      </main>
      <BottomNav />
    </div>
  );
}
```

- [ ] **Step 2: Create placeholder dashboard at `web-app/src/app/(features)/dashboard/page.tsx`**

```tsx
import { Card } from "@/components/ui/card";

export default function DashboardPage() {
  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Dashboard</h1>
      <Card>
        <h2 className="mb-spacing-sm">Welcome to Sundee Fundee</h2>
        <p className="text-text-secondary text-[13px]">
          Your personalized strength training companion.
        </p>
      </Card>
    </div>
  );
}
```

- [ ] **Step 3: Verify build**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npm run build
```

Expected: Build passes with all routes.

- [ ] **Step 4: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/src/app/\(features\)/
git commit -m "feat: add app shell layout with bottom nav and placeholder dashboard"
```

---

### Task 12: Environment Variables and README

**Files:**
- Create: `web-app/.env.example`
- Create: `web-app/.dev.vars.example`

- [ ] **Step 1: Create `web-app/.env.example`**

```bash
# Auth.js
AUTH_SECRET=generate-with-openssl-rand-base64-32
AUTH_GOOGLE_ID=
AUTH_GOOGLE_SECRET=
AUTH_APPLE_ID=
AUTH_APPLE_SECRET=

# Stripe
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

- [ ] **Step 2: Create `web-app/.dev.vars.example` (Cloudflare local dev)**

```bash
# These variables are used by wrangler dev for local development
# Copy this to .dev.vars and fill in values
AUTH_SECRET=generate-with-openssl-rand-base64-32
AUTH_GOOGLE_ID=
AUTH_GOOGLE_SECRET=
AUTH_APPLE_ID=
AUTH_APPLE_SECRET=
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

- [ ] **Step 3: Ensure `.dev.vars` and `.env.local` are in `.gitignore`**

Verify `web-app/.gitignore` contains:
```
.env.local
.dev.vars
```

- [ ] **Step 4: Final Phase 1 build verification**

```bash
cd /Users/dustinober/Projects/sundee-fundee/web-app && npm run build
```

Expected: Clean build with all components, routes, and configuration.

- [ ] **Step 5: Commit**

```bash
cd /Users/dustinober/Projects/sundee-fundee
git add web-app/.env.example web-app/.dev.vars.example web-app/.gitignore
git commit -m "feat: add environment variable templates and complete Phase 1 scaffold"
```
