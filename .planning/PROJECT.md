# Sundee Fundee

## What This Is

A native iOS strength training app with hormonal-cycle-aware training recommendations. Built with Swift 6 + SwiftUI, targeting iOS 17+. Offers program-based and AI-generated workouts with injury adaptation, menstrual cycle integration, benchmark tracking, and HealthKit readiness scoring. Art Deco themed (cream/navy/orange).

## Core Value

Personalized strength training that adapts to the user's body, equipment, and readiness — making every workout optimally productive without needing a human coach.

## Current Milestone: v1.0 Elite Tier

**Goal:** Add a $19.99/month Elite subscription tier with five premium features that deliver a personal-coach experience through AI, computer vision, and biometric integration.

**Target features:**
- Predictive PR Forecasting & Advanced Analytics (GH #97)
- Advanced Bar Path & Form Analysis (GH #96)
- Travel Mode & Multi-Gym Equipment Profiles (GH #95/#102)
- Conversational AI Coach with Voice (GH #94)
- Hyper-Personalized Readiness & Auto-Regulation (GH #93)

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- Signed in with Apple + guest mode authentication
- Program discovery, enrollment, and workout execution
- AI workout generation via Gemini (Cloudflare Worker proxy)
- Menstrual cycle tracking with load/rep/set adaptations
- Injury tracking with exercise modification engine
- One-rep max tracking
- Benchmark catalog with custom benchmarks
- Unified workout history (program + AI sources)
- WOD feed (bundled + CloudKit)
- StoreKit 2 subscription paywall (Free / Plus / Pro tiers)
- HealthKit readiness data fetching (HRV, sleep, resting HR)
- Readiness survey questionnaire
- CloudKit sync (private DB for users, public DB for programs)
- Art Deco theme system

### Active

<!-- Current scope. Building toward these. -->

- [ ] Elite subscription tier ($19.99/mo) with StoreKit 2 integration
- [ ] Predictive PR forecasting with e1RM trend analysis
- [ ] Muscle fatigue heatmap visualization
- [ ] On-device bar path tracking (Apple Vision framework)
- [ ] AI form coaching via Gemini multimodal (monthly cap)
- [ ] Multi-gym equipment profiles
- [ ] Travel Mode with instant workout adaptation
- [ ] Conversational AI Coach weekly check-ins
- [ ] Voice coach integration (speech-to-text + text-to-speech)
- [ ] Readiness score auto-regulation of workout volume/intensity

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Android app — iOS-only for launch; may outsource later
- Web payment system — revisit at ~500+ subscribers
- Real-time video streaming for form analysis — on-device processing + post-set analysis only
- Always-on background HealthKit monitoring — fetch on app open or workout start
- Human coach marketplace — AI-only coaching for this milestone

## Context

- Existing 3-tier structure: Free / Plus ($4.99) / Pro ($9.99). Elite adds a 4th tier at $19.99.
- HealthKit readiness infrastructure already exists (`HealthKitReadinessRepository`, `ReadinessSurvey`) — #93 builds on this.
- Gemini proxy already handles AI workout generation — extends to form analysis (#96) and coach chat (#94).
- `CycleAdaptationPolicy` and `InjuryAdaptationEngine` patterns provide the template for readiness-based auto-regulation.
- Form analysis API costs require monthly usage caps for elite users.
- Issues #95 and #102 merged — #95's Travel Mode is the full vision including #102's equipment profiles.

## Constraints

- **Platform**: iOS 17.0+ only, Swift 6, SwiftUI
- **AI Backend**: Gemini via Cloudflare Worker proxy (not direct API calls from device)
- **Data Storage**: SwiftData + CloudKit (enums as raw strings)
- **Vision Framework**: Apple Vision for on-device bar path; no third-party CV libraries
- **API Costs**: Form check calls to Gemini multimodal must be capped per month per user
- **Project Generation**: XcodeGen from project.yml — never edit .xcodeproj directly
- **Test Coverage**: 100% line coverage enforced in CI

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| $19.99/mo elite tier above existing Pro | Premium features justify premium price; keeps existing tiers intact | -- Pending |
| Merge GH #95 + #102 into single Travel Mode feature | #102 is a subset of #95; avoids duplicate work | -- Pending |
| Monthly cap on AI form checks | Gemini multimodal video analysis has real per-call costs | -- Pending |
| Include voice in AI Coach for v1.0 | Full coach experience is the differentiator at this price point | -- Pending |
| On-device Vision for bar path, Gemini for coaching cues | Keeps real-time tracking fast and local; AI interpretation is async | -- Pending |

---
*Last updated: 2026-03-14 after milestone v1.0 initialization*
