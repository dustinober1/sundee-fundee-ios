# Subscription Feature Roadmap

Infrastructure complete (2026-03-28). Each item below needs its own brainstorm → spec → plan cycle.

## Prerequisites

- [ ] **Cloudflare Worker Anthropic Proxy** — Route cloud AI requests through the existing worker, add tier-based model selection (Haiku/Sonnet), server-side rate limiting via KV store, entitlement validation
- [ ] **Cloud AI Workout Integration** — Wire iOS app to call the proxy for Plus/Premium users, edit-before-start flow, fallback to on-device if network unavailable
- [ ] **Re-enable StoreKit Entitlements** — Revert `AppState.subscriptionTier` from `.free` default, restore `SubscriptionManager.start()` to call `loadProducts()`/`refreshSubscriptionStatus()`, re-add Subscription section in SettingsView

## Plus Tier Features ($6.99/mo)

- [ ] **Custom Program Builder** — Create multi-week training programs
- [ ] **Periodization Templates** — Pre-built linear, undulating, block periodization structures
- [ ] **Auto-Deload Scheduling** — AI suggests deload weeks based on training volume/fatigue
- [ ] **Advanced Analytics Dashboard** — Volume trends, intensity tracking, muscle group balance
- [ ] **Streaks & Achievements** — Consistency tracking, milestone badges

## Premium Tier Features ($12.99/mo)

- [ ] **AI Coach Memory** — Persistent training context across sessions (Sonnet)
- [ ] **AI Mesocycle Plans** — Multi-week periodized plans tailored to cycle phase and goals
- [ ] **Progressive Overload Tracking** — Automatic load progression suggestions
- [ ] **Plateau Detection & Recommendations** — AI identifies stalls, suggests changes
- [ ] **Weekly AI Training Reports** — Volume, intensity, recovery summary + recommendations
- [ ] **Smart Exercise Substitutions** — Context-aware swaps based on equipment, injuries, fatigue

## Pricing Updates

- [ ] **App Store Connect** — Update subscription prices to $6.99/$54.99 (Plus) and $12.99/$99.99 (Premium). StoreKit config already updated for local testing.
