# App Store Discovery Runbook

Use this before deciding that metadata copy is the main discovery problem.

## Baseline Evidence

- Public lookup for App Store ID `6759870888` returns `Sundee Fundee Strength`.
- Public search API finds `Sundee Fundee Strength` for:
  - `Sundee Fundee`
  - `Sundee Fundee Strength`
  - `sundeefundee`
- Public search API does not find Sundee Fundee in the top 10 for:
  - `cycle-aware workout coach`

## On-Device Search Checks

Run these in the App Store app on a normal iPhone signed into the intended storefront:

- `Sundee Fundee`
- `Sundee Fundee Strength`
- `sundeefundee`
- `cycle-aware workout coach`
- `Period & Strength Coach`

Record whether the app appears, its rank, screenshots shown, rating count, and any competing apps above it.

## App Store Connect Checks

- Confirm distribution is public, not unlisted.
- Confirm Pricing and Availability includes the intended countries and regions.
- Confirm the live version uses the expected name, subtitle, keywords, promotional text, screenshots, and description.
- Confirm the primary category remains Health & Fitness.

## App Analytics Baseline

Capture these before and after metadata or screenshot changes:

- App Store Search impressions
- Product page views
- Conversion rate
- First-time downloads
- Ratings count and average rating
- Top search terms if available

## Next Experiments

- Rework first three screenshots around benefits before running paid search.
- Use Apple Ads search campaigns for keyword research only after attribution links are consistent.
- Create custom product pages later for cycle/period, women who lift, and recovery/pain intents.

## Experiment Log

Every store-page change gets a row here. Capture the App Analytics Baseline numbers
(via the `asc-analytics-reports` skill and the lookup API below) the week the change
ships and again 2–4 weeks later, so each row reads as a before/after.

### Baseline: 2026-09-13 (pre-change)

- Version live: 2.0.2 (released 2026-08-10).
- Ratings: 1 total, 5.0 average (public lookup API for ID `6759870888`).
- Search: findable only by brand terms; not top 10 for `cycle-aware workout coach`.
- ASC analytics impressions / page views / conversion: pending first capture —
  run `asc analytics view` + `asc analytics download` per the `asc-analytics-reports`
  skill before the next release, and fill the row in below.

### Change 1: 2026-09-13 — store page conversion rework (Phase 1)

- Promotional text set: leads with audience and differentiator ("Strength training
  for women who lift. Workouts adapt to your cycle, pain, and energy. 100% free,
  private by design."). Can go live without a version submission.
- Keywords reworked (both `fastlane/metadata` and canonical `metadata/`): dropped
  zero-volume terms (readiness, bands, menstrual); added `tracker`, `training`,
  `gym`, `plan` so the indexed fields can form "strength training", "period
  tracker", "cycle tracker", "kettlebell/dumbbell workout". Requires next version.
- Screenshots reordered benefit-first: 01 Today ("Lift with your cycle, not
  against it."), 02 Coach Plan ("A plan that adapts to your energy, pain, and
  phase."), 03 Progress ("Watch your strength climb, week by week."). Captions
  render via the screenshot-mode banner; the Cycle settings screen moved from
  slot 2 to slot 4. Requires next version.
- Review prompts widened (active-recovery sessions, Return to Training sessions)
  and gated behind an in-app satisfaction check so Apple's ~3-per-year prompt
  budget concentrates on happy users. Requires next version.

Success signal after the next release: product page views-to-download conversion
and search impressions both up vs. the baseline row; rating count moving above 1.

### Change 2: 2026-09-13 — acquisition loop inside the product (Phase 2)

- Weekly recap, coach summary, and monthly review share cards now carry the
  attributed App Store QR badge (completed-workout, PR, cycle-insight, and
  selfie cards already did). Every public share card now survives
  image-only sharing (stories strip caption text).
- Challenge invites became a closed loop: invite text includes a
  `sundeefundee://invite/CODE` tap-to-join link next to the code; opening it
  routes to the existing join flow with the code prefilled and auto-looked-up,
  then the prefilled create-challenge form. Manual entry remains in
  Challenges (person.badge.plus toolbar action).
- Ops note: invite lookup queries the PUBLIC CloudKit database
  (`ChallengeInvite`, predicate on `inviteToken`). Verify that field is a
  QUERYABLE index in CloudKit Dashboard (Development AND Production) before
  relying on deep-link redemption; the join sheet shows an actionable error if
  the lookup fails.
- Deferred-install attribution (a brand-new user tapping the store link and
  landing directly in the join flow) still needs either a universal link +
  server handoff or Apple Ads attribution; out of scope for this slice.
