# Subscription Feature Roadmap

Infrastructure complete (2026-03-28). Each item below needs its own brainstorm → spec → plan cycle.

## Code Updates (from pricing/model revision)

- [x] **Update pricing in code** — Changed from $6.99/$12.99 to $4.99/$9.99 (monthly), $39.99/$79.99 (annual).
- [x] **Switch AI model from Anthropic to Cloudflare Nemotron** — Replaced Haiku/Sonnet with `@cf/qwen/qwen3-30b-a3b-fp8` (Plus) and `@cf/nvidia/nemotron-3-120b-a12b` (Premium). User-facing branding: "Sundee AI" / "Sundee AI Pro".

## Prerequisites

- [x] **Cloudflare Worker AI Proxy** — Built `workers/ai-coach/` with JWT auth, KV rate limiting, and Workers AI routing (Qwen for Plus, Nemotron for Premium). Deploy with `cd workers/ai-coach && wrangler deploy`.
- [x] **Cloud AI Workout Integration** — Added CloudAIWorkoutService, CloudAIConfig (JWT), CloudAIUsageTracker, and cloud AI toggle in QuestionnaireView for Plus/Premium users. Falls back to on-device on failure.
- [x] **Re-enable StoreKit Entitlements** — Already complete: `AppState.subscriptionTier` defaults to `.free`, `SubscriptionManager.start()` calls `loadProducts()`/`refreshSubscriptionStatus()`, Subscription section present in SettingsView.

## Plus Tier Features ($4.99/mo)

- [x] **Custom Program Builder** — Hybrid guided builder with 3 templates (Strength/Hypertrophy/Full Body), CustomProgramRecord SwiftData model, session/exercise editing, Plus-gated.
- [ ] **Periodization Templates** — Pre-built linear, undulating, block periodization structures
- [ ] **Auto-Deload Scheduling** — AI suggests deload weeks based on training volume/fatigue
- [ ] **Advanced Analytics Dashboard** — Volume trends, intensity tracking, muscle group balance
- [ ] **Streaks & Achievements** — Consistency tracking, milestone badges

## Premium Tier Features ($9.99/mo)

- [ ] **AI Coach Memory** — Persistent training context across sessions
- [ ] **AI Mesocycle Plans** — Multi-week periodized plans tailored to cycle phase and goals
- [ ] **Progressive Overload Tracking** — Automatic load progression suggestions
- [ ] **Plateau Detection & Recommendations** — AI identifies stalls, suggests changes
- [ ] **Weekly AI Training Reports** — Volume, intensity, recovery summary + recommendations
- [ ] **Smart Exercise Substitutions** — Context-aware swaps based on equipment, injuries, fatigue
- [ ] **Custom AI Coaching Voice** — Personalized tone/style that adapts to how the user responds to motivation (tough love vs. encouraging)
- [ ] **Competition Prep Mode** — Peaking/tapering programs for powerlifting meets or CrossFit comps
- [ ] **Nutrition Timing Suggestions** — Pre/post workout nutrition windows tied to cycle phase (timing guidance, not full meal plans)
- [ ] **Live Workout Coaching** — Real-time AI suggestions between sets based on current session performance (RPE tracking, auto-adjusting next set weight)

## Future: Ultra Tier (2027)

- [ ] **AI Form Check** — User uploads video of a lift, AI analyzes form and provides cues

## Pricing Updates

- [ ] **App Store Connect** — Update subscription prices to $4.99/$9.99 (monthly). Recalculate annual pricing with ~34-36% savings.
