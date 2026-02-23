# Architecture Research (v1.1)

## Existing Architecture Fit
Current Flutter feature modules plus Firestore repositories can support v1.1 with additive changes.

## New/Modified Components
- **Profile persistence module updates**
  - Add onboarding completion + stored onboarding answers.
- **Injury profile domain model**
  - Track injury region/type, severity/self-reported status, and recovery goals.
- **Program adaptation policy extension**
  - Pre-output pass that substitutes contraindicated movements and inserts recovery-support work.
- **Enrollment lifecycle service updates**
  - Introduce cancellation transition and guard rails for active plan state.
- **Legal disclaimer presenter**
  - Shared component/content source used by plan generation outputs and injury setup screens.

## Data Flow Changes
1. User logs in.
2. Session bootstrap loads onboarding + injury profile + enrollment state.
3. Plan generation consumes profile signals and returns adapted plan with disclaimer metadata.
4. UI renders adapted plan, alternatives, recovery additions, and disclaimer.
5. Cancellation request updates enrollment state to `canceled` while preserving prior logs.

## Suggested Build Order
1. Data contracts and repository updates (onboarding/injury/enrollment fields).
2. Onboarding persistence read/write path.
3. Injury-aware adaptation policy and test fixtures.
4. Disclaimer propagation through injury-related surfaces.
5. Cancellation UX and lifecycle transitions.
6. Regression verification for unaffected flows.
