# Launch Roadmap

Infrastructure complete (2026-03-28). Restructured tiers and pricing (2026-04-03).

## Tier Structure

- **Free** — Basic workout logging, 5 lifts, 1 injury, 30-day history, prebuilt benchmarks, basic cycle hints
- **Plus ($2.99/mo)** — Smarter planning on demand. Unlimited history/lifts/injuries, AI builder, advanced charts, custom benchmarks, templates, weekly planner, lighter-day adjustments
- **Pro ($4.99/mo)** — A coach that remembers and adapts. Coach memory, adaptive weekly plan, missed-workout reshuffle, plateau detection, smart substitutions, weekly recap, preference learning, export/share

Internal enum stays `.premium`; customer-facing name is "Pro".

## Phase 1: Membership Foundation

- [x] **Capability flags in SubscriptionTier** — Added hasAIBuilder, hasAdaptivePlanner, hasCoachMemory, hasSmartSubstitutions, hasAdvancedInsights, hasRecoveryAdjustments, hasPreferenceLearning, hasWeeklyRecap, hasExportShare. Added displayName/tagline.
- [x] **Update pricing** — Plus $2.99/mo, Pro $4.99/mo in RevenueCatClient stub.
- [x] **Live tier badge in SettingsView** — Replaced hardcoded "Free" with TierBadge reading from subscription state.
- [x] **SubscriptionView paywall** — Rebuilt with 3-tier comparison cards, Pro branding, feature lists, restore purchases.
- [x] **Locked-state cards in DashboardView** — Free users see AI builder promo, Free/Plus users see Pro adaptive coach promo. Cards link to subscription sheet.
- [ ] **App Store Connect** — Update subscription prices to $2.99/$4.99 (monthly). Recalculate annual pricing with ~34-36% savings.

## Phase 2: Deterministic Intelligence

- [ ] **Plateau detection** — Domain service that identifies stalled lifts from 1RM history and suggests changes
- [ ] **Weekly load analysis** — Volume/intensity/frequency trends as pure domain functions
- [ ] **Schedule reshuffling** — Deterministic missed-workout redistribution logic
- [ ] **Substitution ranking** — Score exercises by similarity, equipment match, injury compatibility
- [ ] **Auto-deload scheduling** — Suggest deload weeks based on training volume/fatigue accumulation

## Phase 3: On-Device AI Layer

- [ ] **OnDeviceCoachService** — Wrapper around Apple Foundation Models with structured outputs
- [ ] **Tool-calling orchestration** — AI fetches cycle phase, recent workouts, maxes, pain logs, equipment, goals
- [ ] **Compact context summaries** — Send rolling summaries, not raw full history
- [ ] **Graceful fallback** — Non-AI value for devices where Apple Intelligence is unavailable

## Phase 4: Memory & Sync

- [ ] **CoachProfile model** — Store training preferences, learned patterns, session summaries
- [ ] **WorkoutPreferences** — Track exercise swaps, skipped movements, preferred session length
- [ ] **Rolling coach memory** — Post-workout and weekly recap summaries
- [ ] **Preference learning** — Learn from edits, accepted/rejected swaps, low-energy patterns
- [ ] **CloudKit sync** — Sync memory models through existing data layer

## Phase 5: UX Surfaces

- [ ] **Upgrade AIWorkoutView** — Main Plus/Pro funnel with edit-before-save flow
- [ ] **Today's Plan / Adapt My Week card** — New dashboard card for Pro users
- [ ] **Settings membership flow** — Plan benefits, AI availability messaging, restore/manage
- [ ] **PainTracking → Pro substitutions** — Use pain logs to trigger smart substitution suggestions
- [ ] **Advanced analytics dashboard** — Volume trends, consistency, muscle balance, pain/effort trends

## Completed Prerequisites

- [x] Cloudflare Worker AI Proxy (workers/ai-coach/)
- [x] Cloud AI Workout Integration (CloudAIWorkoutService, CloudAIConfig, CloudAIUsageTracker)
- [x] StoreKit Entitlements (AppState.subscriptionTier, SubscriptionManager)
- [x] Account Deletion (App Store compliance)
- [x] Custom Program Builder (3 templates, Plus-gated)
- [x] Periodization Templates (Linear, DUP, Block)

## Future (post-launch)

- [ ] **AI Form Check** — Video upload + AI form analysis
- [ ] **Competition Prep Mode** — Peaking/tapering programs
- [ ] **Export & share** — Plan summaries as shareable images/PDFs
