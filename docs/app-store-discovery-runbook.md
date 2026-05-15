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
