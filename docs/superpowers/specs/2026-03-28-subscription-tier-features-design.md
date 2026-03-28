# Subscription Tier Features Design

**Date**: 2026-03-28
**Status**: Approved

## Overview

Sundee Fundee uses a three-tier subscription model (Free, Plus, Premium) differentiated by AI model quality, programming tools, and coaching intelligence. On-device AI is unlimited for all users; cloud AI (Anthropic) is the paid upgrade lever.

## AI Model Strategy

| Tier | Model | Delivery |
|------|-------|----------|
| Free | Apple Foundation Models (on-device) | Direct, no network |
| Plus | Anthropic Claude Haiku | Cloudflare Worker proxy |
| Premium | Anthropic Claude Sonnet | Cloudflare Worker proxy |

Cloud AI requests route through a Cloudflare Worker to keep the Anthropic API key server-side. The existing `workout-proxy.sundeefundee.workers.dev` pattern is extended for this purpose.

### Cost Analysis

**Haiku (Plus):**
- ~2,000 input tokens + ~800 output tokens per request
- ~$0.006/request
- 30 requests/month (1/day) = $0.18/user/month
- Revenue: $6.99/month = **97% margin**

**Sonnet (Premium):**
- ~2,000 input tokens + ~800 output tokens per request
- ~$0.018/request
- Heavy user (10/day × 30 days = 300/mo) = $5.40/user/month
- Realistic user (2/day × 30 days = 60/mo) = $1.08/user/month
- Coaching features (reports, memory context) add ~$1-2/user/month
- Revenue: $12.99/month = **77-92% margin**

## Tier Definitions

### Free Tier — "Get Started"

**Core promise**: A fully functional strength training app with cycle-aware intelligence. Free forever.

| Feature | Detail |
|---------|--------|
| On-device AI workouts | Unlimited, Apple Foundation Models |
| Workout logging & execution | Full workout tracking |
| Browse programs | View and follow all structured programs |
| Daily WOD execution | Full participation in daily WODs |
| Benchmark participation | Predefined benchmarks only |
| Cycle tracking | Full hormonal cycle phase tracking |
| Max lift tracking | 5 lifts |
| Injury profiles | 1 profile |
| Workout history | 30 days |

**Conversion hooks:**
- "Powered by on-device AI" label on generated workouts with subtle "Upgrade for cloud-powered workouts" prompt after each generation
- Locked program builder icon in the Programs tab
- Trend charts show 30-day window with blurred "full history" preview
- After generating 5+ on-device workouts, prompt: "Want workouts that know your training history? Try cloud AI."
- When a user hits the 5-lift cap, natural paywall moment
- After completing a benchmark, show "Track your progress over time with Plus"

### Plus Tier — "Smarter Training"

**Pricing**: $6.99/month, $54.99/year (save 34%)

**Core promise**: Cloud-powered AI workouts and tools to build your own programming.

| Feature | Detail |
|---------|--------|
| Everything in Free | |
| Haiku-powered cloud AI workouts | 1 per day (30/month), editable before starting |
| Custom program builder | Create multi-week programs |
| Periodization templates | Pre-built linear, undulating, block periodization structures |
| Auto-deload scheduling | AI suggests deload weeks based on training volume/fatigue |
| Advanced analytics dashboard | Volume trends, intensity tracking, muscle group balance |
| Custom benchmarks | Create and track custom benchmark WODs |
| Pain & effort trends | Trend analysis over time |
| Unlimited lift tracking | No 5-lift cap |
| Unlimited injury profiles | No 1-profile cap |
| Full workout history | No 30-day cap |
| Workout streaks & achievements | Consistency tracking, milestone badges |

**Edit-before-start flow**: After cloud AI generates a workout, the user can swap exercises, adjust sets/reps, or change focus before starting. This reduces "fishing" for a good workout and creates a natural Premium upgrade hook for unlimited regeneration.

### Premium Tier — "Personal AI Coach"

**Pricing**: $12.99/month, $99.99/year (save 36%)

**Core promise**: Sonnet-powered AI that knows your history, builds your programming, and coaches you through plateaus.

| Feature | Detail |
|---------|--------|
| Everything in Plus | |
| Sonnet-powered cloud AI workouts | Up to 10 per day (soft nudge at 7, hard cap at 10) |
| Persistent AI coach memory | Remembers training history, preferences, and progress across sessions |
| AI-generated mesocycle plans | Multi-week periodized plans tailored to cycle phase, goals, and recovery |
| Progressive overload tracking | Automatic load progression suggestions based on logged performance |
| Plateau detection & recommendations | AI identifies stalls and suggests programming changes |
| Weekly AI training reports | Summary of volume, intensity, recovery, and recommendations for next week |
| Rehab session generation | AI-guided injury rehab workouts based on injury profiles |
| Smart exercise substitutions | Context-aware swaps based on equipment, injuries, and fatigue |
| Data export | Export full training history (CSV/PDF) |

**Rate limiting**: Premium generation is capped at 10/day. A soft nudge appears at 7 generations: "You've generated a lot today — try editing your workout instead." Hard cap at 10 prevents abuse. Worst-case abusive user costs ~$0.18/day ($5.40/month), still profitable at $12.99.

**Upgrade triggers from Plus:**
- After 4+ weeks of consistent training: "Ready for a personalized mesocycle plan? Upgrade to Premium."
- When a user's lift progress stalls: "Your bench has plateaued — Premium can help you break through."
- After editing a generated workout heavily: "Want workouts that nail it the first time? Premium's Sonnet AI learns your preferences."

## Pricing Summary

| Tier | Monthly | Annual | Annual Savings |
|------|---------|--------|----------------|
| Free | $0 | $0 | — |
| Plus | $6.99 | $54.99 | 34% |
| Premium | $12.99 | $99.99 | 36% |

## Feature Comparison Matrix

| Feature | Free | Plus | Premium |
|---------|------|------|---------|
| AI Model | On-device | Haiku | Sonnet |
| AI workout generation | Unlimited on-device | 1 cloud/day, editable | 10 cloud/day (nudge at 7) |
| Workout logging | Full | Full | Full |
| WOD execution | Yes | Yes | Yes |
| Benchmark participation | Predefined | Predefined + Custom | Predefined + Custom |
| Cycle tracking | Full | Full | Full |
| Programs | Browse | Browse + Custom builder | Browse + Custom builder |
| Max lift tracking | 5 lifts | Unlimited | Unlimited |
| Injury profiles | 1 | Unlimited | Unlimited |
| Workout history | 30 days | Full | Full |
| Periodization templates | — | Yes | Yes |
| Auto-deload scheduling | — | Yes | Yes |
| Analytics dashboard | — | Advanced | Advanced |
| Pain & effort trends | — | Yes | Yes |
| Streaks & achievements | — | Yes | Yes |
| AI coach memory | — | — | Persistent |
| AI mesocycle plans | — | — | Yes |
| Progressive overload tracking | — | — | Yes |
| Plateau detection | — | — | Yes |
| Weekly AI reports | — | — | Yes |
| Rehab sessions | — | — | Yes |
| Smart substitutions | — | — | Yes |
| Data export | — | — | Yes |

## Backend Architecture

### Cloudflare Worker Proxy

The existing `workout-proxy.sundeefundee.workers.dev` is extended to:
1. Accept a `tier` parameter from the app (validated against the user's StoreKit entitlement)
2. Route to Haiku or Sonnet based on tier
3. Enforce rate limits server-side (1/day for Plus, 10/day for Premium) as a backstop to client-side enforcement
4. Track usage per user for analytics

### Rate Limiting

Rate limits are enforced at two levels:
- **Client-side**: `AIWorkoutLimits` checks local generation count before making a request
- **Server-side**: Cloudflare Worker validates against a per-user counter (KV store) as a backstop against client tampering

### Entitlement Validation

The app sends the StoreKit transaction ID or receipt with cloud AI requests. The Cloudflare Worker validates the entitlement before routing to the Anthropic API. This prevents free users from accessing cloud AI by spoofing requests.

## Changes to Existing Code

### SubscriptionTier.swift
- Update `monthlyProductID` and `annualProductID` with new pricing
- Add `aiModel` computed property returning the model identifier per tier
- Add `dailyCloudAILimit` computed property (nil for Free, 1 for Plus, 10 for Premium)

### FeatureEntitlement.swift
- Add new `GatedFeature` cases: `programBuilder`, `periodizationTemplates`, `autoDeload`, `advancedAnalytics`, `streaksAchievements`, `aiCoachMemory`, `mesocyclePlans`, `progressiveOverload`, `plateauDetection`, `weeklyReports`, `smartSubstitutions`
- Update `canAccess` mappings

### AIWorkoutLimits.swift
- Replace monthly limits with daily limits
- Add soft nudge threshold (7) for Premium
- Remove on-device generation limits (unlimited for all tiers)

### PaywallView.swift
- Update pricing display ($6.99/$12.99)
- Update feature comparison table with new features
- Update marketing copy to reflect AI model differentiation

### SundeeFundee.storekit
- Update product pricing to match new tiers
- Update product descriptions

### AppState.swift
- Revert `subscriptionTier` from `.premium` default to `.free`
- Re-enable real StoreKit entitlement evaluation

## StoreKit Product IDs

Existing product IDs are retained (changing IDs in App Store Connect is destructive):
- `com.sundeefundee.sub.plus.monthly` — price updated to $6.99
- `com.sundeefundee.sub.plus.annual` — price updated to $54.99
- `com.sundeefundee.sub.premium.monthly` — price updated to $12.99
- `com.sundeefundee.sub.premium.annual` — price updated to $99.99

Price changes are made in App Store Connect, not in code. The `.storekit` file is updated for local testing only.

## Analytics Events

New events to track tier-specific behavior:
- `cloudAIWorkoutGenerated(tier:model:)` — tracks which model generated the workout
- `cloudAIDailyLimitReached(tier:)` — user hit their daily cap
- `cloudAISoftNudgeShown` — Premium user saw the 7/10 nudge
- `workoutEditedBeforeStart(changesCount:)` — tracks how much users edit cloud AI workouts
- `programBuilderUsed(action:)` — create, edit, delete custom programs
- `mesocyclePlanGenerated(weeksCount:)` — Premium mesocycle creation
- `weeklyReportViewed` — Premium report engagement
- `plateauAlertShown(exercise:)` — Premium plateau detection fired
