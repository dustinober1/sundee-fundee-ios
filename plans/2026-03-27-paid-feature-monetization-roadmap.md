# Paid Feature Monetization Roadmap

## Objective

Transform Sundee Fundee from a mostly free tracker into a subscription product with a clear ladder:

- Free = tracker
- Plus = adaptive training
- Premium = personal coach

This plan assumes the app will re-enable real subscription gating, because the current runtime defaults in `SubscriptionManager` and `AppState` effectively unlock premium for everyone.

## Current-State Observations

- Subscription structure already exists in code through `SubscriptionTier`, `FeatureEntitlement`, `PaywallView`, and `ManageSubscriptionView`
- AI workout generation already has an extensible context model and a dedicated flow
- The app already captures strong personalization signals: maxes, cycle phase, injuries, pain logs, workout history, perceived effort, and user goals
- The app has existing forward-only migration constraints, so all new SwiftData schema work must preserve prior schema versions in the migration plan

## Strategic Product Packaging

### Packaging direction to validate
Your revised idea is viable:
- Free = on-device AI
- Plus = better remote LLM
- Premium = premium LLM plus personalized coaching

This is a stronger packaging story than feature-count gating, but only if each tier feels meaningfully better in workout quality, not just model branding.

### Free
Goal: create habit and let users experience useful AI immediately

Include:
- Workout logging
- Basic max tracking
- Structured programs and WOD browsing
- Limited recent history
- Basic cycle-aware recommendations
- On-device AI workout generation using the baseline model path
- Limited saved AI history or minimal memory

### Plus
Goal: sell noticeably better workout generation quality

Include:
- Higher-quality remote LLM workout generation
- Better reasoning for exercise selection and structure
- Smarter substitutions
- Unlimited history
- Pain and effort intelligence
- Readiness and benchmark recommendations
- Faster regeneration and richer workout explanations

### Premium
Goal: sell a true coaching relationship, not just a better model

Include:
- Premium LLM with personalized coaching memory
- Multi-week AI coaching blocks
- Symptom-informed planning and recovery recommendations
- Coach reports and exports
- Accountability workflows and premium challenges
- Saved preferences and deeper personalization memory
- Shareable progress summaries
- Post-workout follow-up guidance and weekly coaching summaries

### Tiering guardrail
Avoid positioning tiers as merely “small AI, medium AI, big AI.”

The user-facing promise should be:
- Free = instant AI workout help
- Plus = better workout intelligence
- Premium = personal coach that learns you

That framing is easier to understand and harder for competitors to commoditize.

## Workstream 1: Re-establish Monetization Foundation

### Scope
- Re-enable StoreKit-backed subscription state
- Align tiers with product packaging
- Rewrite paywall copy around outcomes, not feature counts
- Add instrumentation for paywall exposure, conversion, retention, and feature-triggered upsell

### App changes
- Restore real entitlement evaluation in `SubscriptionManager`
- Stop defaulting `AppState.subscriptionTier` to premium
- Expand `GatedFeature` and `FeatureEntitlement` to map new paid surfaces
- Update `PaywallView` tier cards, comparison table, and CTA language
- Update `ManageSubscriptionView` to reflect new tier promises and current benefits

### Deliverables
- Final tier matrix
- New StoreKit product mapping
- Trigger-to-paywall routing map
- Event taxonomy for monetization analytics

## Workstream 2: Adaptive Weekly Programming

### Product outcome
Generate and continuously refine a week of training instead of only generating a single session.

### Core capabilities
- Build a weekly planner that combines cycle phase, recent adherence, pain trend, energy, equipment, and current program
- Recalculate next sessions after missed workouts or symptom changes
- Produce user-facing rationale for each adaptation
- Preserve deterministic safety and progression rules around intensity, volume, and exercise class

### Architecture
Add a dedicated adaptive planning domain layer rather than overloading the current single-session AI flow.

Proposed additions:
- `AdaptiveTrainingContext`
- `AdaptiveWeekPlan`
- `AdaptiveSessionAdjustment`
- `AdaptiveProgrammingEngine`
- `AdaptiveProgrammingRepository`

### Data inputs already available
- User profile
- Cycle status
- Injury profile and pain logs
- Completed workouts and perceived effort
- Maxes and recent training history

### New data needed
- Session adherence status
- Planned-vs-completed comparison summary
- Optional fatigue and recovery check-in signal
- User preference profile for exercise likes, dislikes, and hard constraints

## Workstream 3: Smart Substitutions

### Product outcome
Offer one-tap substitutions when the planned exercise no longer fits the user’s body, equipment, or readiness.

### Core capabilities
- Swap by movement pattern, stimulus, and equipment compatibility
- Respect injury restrictions and cycle-phase sensitivity
- Explain why the swap was chosen
- Allow users to save preferred swaps for future reuse

### Architecture
Use the shared package as the canonical exercise metadata layer so both app and dashboard share substitution logic inputs.

Proposed additions:
- exercise taxonomy expansion in shared models
- substitution rule engine
- substitution reason model
- saved substitution preferences per user

### Dashboard impact
The dashboard will need editing support for exercise tags and substitution metadata if these rules are content-driven.

## Workstream 4: Progress Intelligence

### Product outcome
Turn logs into coaching insight.

### Core capabilities
- PR prediction for major lifts and selected benchmarks
- Plateau detection
- Readiness scoring
- Benchmark retest recommendations
- Weekly strength and recovery summary
- Insight explanations tied to cycle phase, adherence, pain, and effort

### Architecture
Create a pure analytics domain layer with deterministic scoring before adding AI narration.

Proposed additions:
- `ProgressSnapshot`
- `ReadinessScore`
- `PlateauSignal`
- `BenchmarkReadinessRecommendation`
- `ProgressIntelligenceService`

### UX surfaces
- Dashboard summary card
- Maxes detail insights
- Benchmarks recommendation CTA
- Weekly recap in settings or home

## Workstream 5: Premium AI Coach

### Product outcome
Upgrade AI from one-off generation to an ongoing coaching relationship.

### Core capabilities
- Generate 4-week and 8-week coaching blocks
- Maintain user memory for preferences, common pain triggers, equipment defaults, and favorite movements
- Provide post-workout follow-up guidance
- Explain why upcoming weeks changed
- Support conversational prompts constrained by deterministic safety rules

### Architecture
Keep state-driven navigation intact in the AI workout flow and add a separate coaching-plan branch rather than breaking the existing questionnaire-preview-execution-summary chain.

Proposed additions:
- `AICoachProfile`
- `AICoachPlan`
- `AICoachCheckIn`
- `AICoachRecommendation`
- repository support for favorites, memory, and plan history

### Guardrails
- deterministic rules must stay authoritative for injury and load safety
- AI output should be post-processed before presentation
- paid AI features should degrade gracefully to non-AI insights where possible

## Workstream 6: Recovery and Symptom Intelligence

### Product outcome
Make the app uniquely valuable for cycle- and symptom-aware training.

### Core capabilities
- Track symptoms beyond pain: cramps, sleep quality, energy, mood, bloating, appetite, soreness, recovery quality
- Detect longitudinal patterns across cycle phase and training outcomes
- Recommend training modifications before poor sessions happen
- Surface personalized “what tends to work for you” insights

### Data model additions
- daily recovery check-in model
- symptom event model or extension of current symptom logging
- derived recovery pattern snapshot
- opt-in correlation summaries for performance vs symptoms

### UX surfaces
- onboarding preferences
- daily readiness check-in
- dashboard insight card
- settings symptom profile and history

## Workstream 7: Reports, Exports, and Accountability

### Product outcome
Create tangible outputs and retention hooks outside the workout screen.

### Reports
- monthly progress report
- coach check-in report
- benchmark progress report
- cycle vs performance report
- rehab compliance report

### Accountability
- weekly commitment goals
- adherence reminders
- Sunday coaching summary
- premium guided challenges
- optional coach or partner share flow

### Architecture
Separate report generation from export delivery so PDF, share sheet, and future cloud delivery can use the same report models.

## Required Data and Schema Changes

### SwiftData
Plan a new schema version for monetization and coaching features.

Likely new models:
- adaptive plan
- adaptive plan session
- recovery check-in
- symptom trend snapshot
- exercise preference
- substitution preference
- AI coach plan
- AI coach memory item
- weekly insight snapshot
- accountability goal
- premium challenge enrollment
- generated report record

Likely model extensions:
- `User` for coaching preferences and subscription-related onboarding flags
- `CompletedWorkout` for adherence state and richer outcome signals
- `PainLog` or companion symptom models for broader symptom tracking
- AI workout history records for coach memory and saved plans

### Migration requirements
- keep all historic schema versions in the migration plan
- update migration plan stages and model container registration together
- use raw string-backed enums for new persisted enums

### CloudKit and shared package
- keep user-private coaching data in private storage
- decide which metadata belongs in the shared package versus app-only models
- if the dashboard authors adaptive templates or exercise metadata, extend the shared package and dashboard APIs together

## UI and Navigation Changes

### Onboarding
- capture goals, coaching style, symptom tracking consent, equipment defaults, and accountability preferences
- add clear explanation of free vs paid value early without blocking core activation

### Dashboard
- replace generic AI CTA emphasis with adaptive plan, readiness, and weekly summary modules
- add premium insight cards with clear locked states and rationale

### AI Flow
- preserve current state-driven navigation
- branch into new flows for coach plan generation and post-workout coaching follow-up

### Programs and Workouts
- show adaptive changes inline with reasons
- expose substitution suggestions in workout preview and execution
- allow save-preference actions on substitutions

### Settings and Subscription
- expand subscription management to show active benefits
- add reports/export history, accountability settings, and coach profile management

## Entitlement Map

### Free
- basic logging
- basic cycle recommendations
- limited recent insights

### Plus
- adaptive programming
- smart substitutions
- unlimited history
- advanced readiness and progress intelligence
- benchmark recommendations

### Premium
- AI coaching blocks
- symptom intelligence
- advanced reports and exports
- accountability tools and challenges
- deeper saved memory and preference layers

## Analytics and Success Metrics

Track at minimum:
- paywall viewed
- paywall trigger source
- trial started
- subscription started
- subscription renewed
- downgrade and cancel signals
- adaptive plan generated
- substitution accepted
- readiness card viewed
- weekly summary viewed
- report exported
- accountability goal created
- challenge started and completed

North-star outcomes:
- improved free-to-paid conversion
- improved week-4 retention
- higher workout completion rate
- repeated usage of adaptive planning and readiness surfaces
- lower churn for users engaging with accountability features

## Recommended Execution Phases

### Phase 1: Monetization and packaging reset
- restore real gating
- finalize product matrix
- update paywall and subscription management
- instrument conversion funnel

### Phase 2: Adaptive programming core
- add data structures and planner
- build weekly adaptation rules
- show adaptive rationale in UI

### Phase 3: Smart substitutions
- extend exercise metadata
- implement substitution engine
- add saved preference loop

### Phase 4: Progress intelligence
- add analytics snapshots and readiness scoring
- expose dashboard and benchmark insights

### Phase 5: Recovery and symptom intelligence
- add broader recovery inputs
- generate personalized pattern insights

### Phase 6: Premium AI coach
- multi-week plans
- coaching memory
- follow-up guidance

### Phase 7: Reports and accountability
- report generation
- coach sharing
- goals, summaries, and challenges

## Test Strategy

- unit tests for all pure domain engines: adaptation, substitution, readiness, progress, symptom correlation, report composition
- migration tests for new schema versions
- repository tests for persistence and CloudKit-safe serialization
- UI tests for paywall triggers, locked states, onboarding branch selection, and adaptive session flows
- snapshot or coverage tests for dashboard cards and subscription messaging
- analytics verification for key monetization and retention events

## Open Decisions To Confirm Before Execution

1. Whether the app remains on the current Apple Intelligence baseline or broadens support for non-AI premium users
2. Whether AI coaching is on-device only, remote-enabled, or hybrid
3. Whether adaptive weekly programming is generated fully on-device or template-plus-rules
4. Whether the dashboard will own exercise metadata and adaptive template authoring
5. Whether premium includes a trial and whether Plus and Premium both ship at launch
6. Whether coach sharing is export-only first or collaborative from day one

## First Implementation Slice

If execution starts immediately, the best first slice is:
- restore real subscription gating
- redefine entitlements
- update paywall messaging
- build adaptive weekly planning domain models and a deterministic planner MVP
- expose one dashboard card and one weekly plan screen

That slice creates a real paid foundation and introduces the most defensible value layer first.
