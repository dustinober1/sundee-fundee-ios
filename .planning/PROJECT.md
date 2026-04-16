# Sundee Fundee v2

## What This Is

Sundee Fundee is a cycle-aware strength training iOS app built with SwiftUI, CloudKit, and HealthKit. v2 adds three major features: a daily Recovery Score that aggregates biometric and training data, intelligent deload detection with active recovery programming, and a social layer for sharing workouts with friends — all built on the existing Apple ecosystem.

## Core Value

Users always know whether today is a push day or a rest day — the recovery score is the single source of truth for training readiness.

## Requirements

### Validated

- ✓ Cycle-aware training adaptations — existing
- ✓ Workout tracking with exercise catalog — existing
- ✓ One-rep max tracking and plateau detection — existing
- ✓ Weekly load analysis and schedule reshuffling — existing
- ✓ Program templates and AI workout generation — existing
- ✓ Benchmarks with cycle-phase readiness — existing
- ✓ Challenge system with lifetime tracking — existing
- ✓ Pain/injury tracking with contraindications — existing
- ✓ On-device AI coach with memory — existing
- ✓ CloudKit persistence with offline sync — existing
- ✓ HealthKit integration (HRV reads wired) — existing
- ✓ Share cards for workouts/PRs — existing
- ✓ Apple Sign-In with guest mode — existing

### Active

- [ ] Daily recovery score (0-100) from cycle phase, training volume, pain logs, sleep, and HRV
- [ ] Recovery score dashboard card with tap-through to detailed breakdown screen
- [ ] Rest day active recovery suggestions (mobility, yoga, light cardio)
- [ ] Recovery score trends over time correlated with cycle phase
- [ ] HealthKit sleep data integration (new data type — HRV already wired)
- [ ] Auto-detect deload need from fatigue signals (load trends, recovery score, training frequency)
- [ ] Generate active recovery week replacing lifting with mobility/yoga/cardio suggestions
- [ ] Deload suggestion with user confirmation flow
- [ ] Friends system via CloudKit shared zones
- [ ] In-app friends feed showing PRs, workout completions, challenge achievements
- [ ] High-five reactions on friend activity
- [ ] User profiles with shareable stats

### Out of Scope

- Nutrition/macro tracking — separate domain, adds complexity without strengthening core value
- Body composition tracking — deferred to v3, recovery score is the priority
- Video form checking — requires ML models and camera work, too large for this milestone
- Leaderboards/competitive ranking — social should be supportive, not competitive
- External backend (Firebase/Supabase) — staying in Apple ecosystem with CloudKit sharing
- RPE per-set tracking — good idea but deferred; recovery score covers fatigue signal at a higher level

## Context

- The app is free with no subscriptions or IAPs — all features available to all users
- HealthKit already reads HRV (`heartRateVariabilitySDNN`); sleep reads need to be added
- CloudKit is the sole backend; CloudKit sharing zones enable the social features without a server
- The intelligence engine (plateau detector, weekly load analyzer) provides inputs for deload detection
- Existing multiplier-based adaptation system can inform recovery score weighting
- Art Deco theme (cream/navy/orange) with Playfair Display, Inter, and JetBrains Mono fonts
- Swift 6 strict concurrency throughout; actor-based data clients

## Constraints

- **Platform**: iOS 18+, SwiftUI only, Swift 6 strict concurrency
- **Backend**: CloudKit only — no external services or servers
- **Dependencies**: Zero external package dependencies (keep it that way)
- **Design**: Art Deco theme tokens via `AppTheme.*`
- **Privacy**: HealthKit sleep/HRV requires user authorization; handle denial gracefully
- **Social**: CloudKit sharing has limits on zone sharing — research capacity during planning

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Recovery score inputs: cycle + volume + pain + sleep + HRV | All four signals are available or nearly available; comprehensive picture | — Pending |
| Deload trigger: auto-detect only (no scheduled) | Users with varying cycle lengths need adaptive detection, not fixed 4-week blocks | — Pending |
| Deload style: active recovery swap | Full rest weeks lose momentum; swapping to mobility/yoga maintains habit | — Pending |
| Social backend: CloudKit shared zones | No server to maintain, stays in Apple ecosystem, consistent with existing data layer | — Pending |
| Social depth: friends + feed with reactions | Supportive community, not competitive; high-fives not leaderboards | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-15 after initialization*
