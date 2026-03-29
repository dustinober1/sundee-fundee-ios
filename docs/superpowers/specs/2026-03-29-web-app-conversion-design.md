# Sundee Fundee Web App Conversion — Design Spec

## Overview

Convert Sundee Fundee from a native iOS app to a Next.js web app with PWA support, hosted on Cloudflare. The web app lives at `sundeefundee.com` and provides the same strength training experience with hormonal-cycle-aware recommendations.

## Architecture

```
sundeefundee.com (Cloudflare Pages)
├── Next.js 15 App Router + @opennextjs/cloudflare
├── TypeScript + Tailwind CSS v4
├── Auth.js v5 (D1 adapter) — Email, Google, Apple
├── Cloudflare D1 (SQLite) — all user data
├── Cloudflare KV — session cache, rate limiting
├── Drizzle ORM — type-safe D1 queries
├── Stripe — subscriptions (webhook on Workers)
├── @serwist/next — PWA/offline support
└── MDX — /blog with SEO

api.sundeefundee.com (Cloudflare Worker)
├── Stripe webhook handler
├── Public data API (programs, WODs, benchmarks)
└── Proxies to existing workout-proxy worker
```

## Phases

### Phase 1: Web App Scaffold

Create `web-app/` at repo root with:

#### Next.js + Cloudflare Pages
- Next.js 15 with App Router, TypeScript strict mode
- `@opennextjs/cloudflare` adapter for Cloudflare Pages deployment
- Tailwind CSS v4 with design tokens as CSS custom properties
- Directory: `web-app/`

#### Design System
Port `SundeeFundee/Theme/AppTheme.swift` to CSS custom properties and Tailwind config:

**Colors:**
| Token | Hex | Usage |
|-------|-----|-------|
| `--color-cream` | `#f4f0df` | Background |
| `--color-navy` | `#0d1a40` | Text primary |
| `--color-orange` | `#f27319` | Accent, CTAs |
| `--color-gold` | `#d9b34d` | Secondary accent |
| `--color-card-bg` | `#fcfaf2` | Card backgrounds |
| `--color-separator` | `#e0d9c7` | Dividers |
| `--color-text-secondary` | `#596180` | Secondary text |
| `--color-error` | `#d92626` | Error states |
| `--color-warm-rose` | `#e68c80` | Cycle/wellness |

**Typography:**
- Headings: Playfair Display (serif), maps to Swift `heading`/`subheading`
- Body: Inter (system-like sans), maps to Swift `body`/`caption`
- Mono: JetBrains Mono, maps to Swift `mono`

**Spacing:** xs=4, sm=8, md=16, lg=24, xl=32, xxl=48 (px, matching Swift pt values)

**Radii:** sm=6, md=12, lg=20, card=12, button=8 (px)

**Components:**
- Primary button: orange bg, cream text, full width on mobile
- Secondary button: card bg, navy text, navy border
- Card: padding-md, card-bg, radius-card, subtle shadow
- Destructive button: error text on error/8% bg

#### PWA Configuration
- `manifest.json`: app name "Sundee Fundee", theme color navy, background cream, display standalone
- `@serwist/next` for service worker generation
- Offline support: cache app shell, domain logic works offline, data syncs on reconnect
- Icons: 192x192 and 512x512 PWA icons (placeholder initially)

#### Cloudflare Infrastructure
- **D1 database**: `sundee-fundee-db` — all user data (replaces SwiftData/CloudKit private)
- **KV namespace**: `sundee-fundee-sessions` — session storage for Auth.js
- **Workers**: API routes at `api.sundeefundee.com`
- Wrangler config in `web-app/wrangler.toml`

#### Auth (Auth.js v5)
- Providers: Email (magic link or credentials), Google OAuth, Sign in with Apple
- Session strategy: JWT stored in KV for fast edge reads
- D1 adapter for user/account/session tables
- Auth tables managed by Auth.js schema + Drizzle migrations

#### Database (Drizzle + D1)
Port all 18 SwiftData models to Drizzle SQLite schemas. Enums stored as TEXT.

**Tables:**
```
users                    — id, name, email, experience_level, primary_goal, gender, weight_unit
accounts                 — Auth.js provider accounts
sessions                 — Auth.js sessions
one_rep_maxes            — user_id, exercise_name, weight_kg, is_estimated, date
personal_records         — user_id, exercise_name, rep_max_type, estimated_1rm, date
lift_maxes               — user_id, exercise_name, weight_kg, source, date
conditioning_prs         — user_id, exercise_name, value, scoring_type, weight_kg, date
enrolled_programs        — user_id, program_id, status, current_week, current_day, started_at
enrollment_events        — enrolled_program_id, event_type, timestamp
completed_workouts       — user_id, program_name, session_name, duration_seconds, notes, effort, date
completed_sets           — workout_id, exercise_name, set_number, prescribed_reps/weight, actual_reps/weight, completed
injury_profiles          — user_id, location, recovery_phase, status, location_regions, movement_limitations
pain_logs                — user_id, injury_profile_id, pain_level, symptom_type, intensity_context, date
period_logs              — user_id, start_date, end_date, flow_level
symptom_logs             — user_id, date, symptom_type, severity
cycle_settings           — user_id, average_cycle_length, average_period_length
cycle_adaptation_prefs   — user_id, adaptation_enabled, fallback_phase
benchmark_definitions    — id, name, description, scoring_type, category, user_id
benchmark_results        — user_id, definition_id, score, notes, date
generated_workout_records — user_id, workout_json, is_favorite, date
custom_program_records   — user_id, program_json, date
subscriptions            — user_id, stripe_customer_id, stripe_subscription_id, tier, status, current_period_end
```

#### Stripe Subscriptions
Same tiers as iOS:
- Plus Monthly: $4.99/mo
- Plus Annual: $39.99/yr
- Premium Monthly: $9.99/mo
- Premium Annual: $79.99/yr

Stripe Products/Prices created in Stripe Dashboard. Webhook handler at `api.sundeefundee.com/stripe/webhook` syncs subscription status to D1 `subscriptions` table.

### Phase 2: Port Domain Logic

Port all 27 Swift Domain files to TypeScript in `web-app/src/lib/domain/`. Pure functions, zero framework dependencies.

**Directory structure mirrors Swift:**
```
src/lib/domain/
├── ai-workout/
│   ├── generated-workout.ts        — GeneratedWorkout, GeneratedExercise, QuestionnaireAnswers types
│   ├── offline-workout-generator.ts — Template-based generation (30+ exercise templates)
│   ├── workout-post-processor.ts    — Weight calc, energy/cycle multipliers, rest assignment
│   ├── workout-generation-context.ts — Input types (focus, energy, equipment enums)
│   ├── cloud-ai-config.ts          — Worker URL + JWT generation
│   └── cloud-ai-usage-tracker.ts   — Daily quota tracking (localStorage-backed)
├── subscription/
│   ├── subscription-tier.ts         — Free/Plus/Premium with product IDs
│   ├── feature-entitlement.ts       — 17 gated features with tier requirements
│   ├── ai-workout-limits.ts         — Cloud AI daily quotas
│   └── downgrade-policy.ts          — Read-only access on downgrade
├── weight-calculations.ts           — roundToNearestFive, targetWeight, nextRecommended, PR detection, plateau
├── epley-formula.ts                 — 1RM estimation from submaximal
├── weight-unit-conversion.ts        — kg ↔ lb conversion
├── plate-calculation.ts             — Barbell plate breakdown
├── cycle-calculations.ts            — Phase detection, boundaries, recommendations
├── cycle-adaptation-policy.ts       — Phase multipliers, readiness tiers, confidence
├── cycle-program-generator.ts       — Adapt programs for cycle phase
├── injury-adaptation-engine.ts      — Contraindications, regressions, recovery prep
├── load-adjustment-policy.ts        — Phase-specific load/sets/reps multipliers
├── pain-trend-analyzer.ts           — Trailing average, improvement detection
├── phase-transition-advisor.ts      — Recovery phase progression suggestions
├── rehab-session-generator.ts       — Standalone recovery sessions
├── recovery-phase.ts                — Five-phase enum
├── body-location.ts                 — 17 body regions with engine keys
├── benchmark-catalog.ts             — 23+ predefined benchmarks
├── celebration-event.ts             — PR/milestone event types
├── program-template-generator.ts    — 6 template types (linear, DUP, block, etc.)
└── index.ts                         — barrel export
```

**Porting rules:**
- Swift enums → TypeScript const objects + union types (or string literal unions)
- Swift structs (Codable) → TypeScript interfaces
- Swift static methods → exported functions
- `ExerciseValue` discriminated union preserved with tagged union pattern
- Benchmark `roundsAndReps` scoring: `rounds * 10000 + reps` encoding preserved
- All multipliers, thresholds, and constants copied exactly from Swift source

**Testing:**
- Every Swift test file gets a corresponding `.test.ts` file
- Use Vitest with the same test cases and expected values
- Target 100% coverage of domain logic (matching iOS CI requirement)

### Phase 3: Build Features

Server components for data loading, client components for interactivity. Each feature is a route group.

**Route structure:**
```
app/
├── (auth)/
│   ├── sign-in/page.tsx
│   └── sign-up/page.tsx
├── (features)/
│   ├── dashboard/page.tsx
│   ├── workouts/
│   │   ├── page.tsx              — workout history
│   │   ├── execute/[id]/page.tsx — workout execution
│   │   └── ai/page.tsx           — AI workout flow
│   ├── programs/
│   │   ├── page.tsx              — browse & enroll
│   │   ├── [id]/page.tsx         — program detail
│   │   └── create/page.tsx       — program builder
│   ├── maxes/page.tsx
│   ├── benchmarks/
│   │   ├── page.tsx
│   │   └── [id]/page.tsx
│   ├── cycle/page.tsx
│   └── settings/page.tsx
├── (marketing)/
│   └── blog/
│       ├── page.tsx              — blog index
│       └── [slug]/page.tsx       — individual posts
├── api/
│   ├── auth/[...nextauth]/route.ts
│   ├── stripe/webhook/route.ts
│   └── ai/generate/route.ts     — proxies to workout-proxy worker
├── layout.tsx
├── page.tsx                      — landing/marketing page
└── manifest.json
```

**Build order:**
1. Auth (sign up/in, session, protected routes)
2. Dashboard (today's WOD, recent workouts, quick stats)
3. Workout execution & logging (set tracking, timer, completion)
4. Programs (browse, enroll, progress tracking)
5. Max lifts (1RM tracking, PR detection, Epley estimation)
6. Benchmarks (predefined + custom, scoring, history)
7. Cycle tracking (period logging, phase display, adaptation preferences)
8. Settings (profile, units, injuries, subscription management)
9. AI workout generation (questionnaire → proxy to existing worker → preview → execute)

**Shared components:**
- Bottom navigation bar (mobile PWA) / sidebar (desktop)
- Card component with Art Deco styling
- SpicyRating component (effort rating)
- CelebrationOverlay (confetti/animation for PRs)
- FeatureGate wrapper (subscription tier checks)

### Phase 4: Blog / SEO Engine

- MDX files in `web-app/content/blog/` with frontmatter (title, description, date, tags, author)
- `next-mdx-remote` for rendering
- Auto-generated SEO: Open Graph tags, JSON-LD structured data for articles
- Sitemap generation via `next-sitemap`
- Blog index at `/blog`, posts at `/blog/[slug]`
- File structure supports automated content generation (commit MDX files to repo)

## DNS / Domain Setup

| Domain | Target | Type |
|--------|--------|------|
| `sundeefundee.com` | Cloudflare Pages project | CNAME |
| `www.sundeefundee.com` | redirect to apex | Page Rule |
| `api.sundeefundee.com` | Cloudflare Worker | Custom Route |
| `workout-proxy.sundeefundee.workers.dev` | Existing worker | Unchanged |

## Non-Goals (Phase 1-4)

- Native push notifications (web push can be added later)
- Real-time sync between iOS and web (separate data stores for now)
- Migrating existing iOS user data to web
- HealthKit integration (iOS-only feature)
- Apple Intelligence on-device AI (web uses cloud worker only)

## Reference Files

| Purpose | Path |
|---------|------|
| Design tokens | `SundeeFundee/Theme/AppTheme.swift`, `ButtonStyles.swift` |
| Domain logic (port source) | `SundeeFundee/Domain/**/*.swift` (27 files) |
| Data models | `SundeeFundee/Models/**/*.swift` (14 files) |
| Shared types | `SundeeFundee/Packages/SundeeFundeeShared/` |
| UI reference | `SundeeFundee/Features/**/*.swift` |
| Existing Next.js patterns | `wod-dashboard/` |
| App config | `project.yml` |
