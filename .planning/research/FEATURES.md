# Features Research (v1.1)

## Table Stakes
- Persist onboarding completion and responses so returning users are not re-onboarded.
- Allow users to declare current injuries in profile or planning flow.
- Generate safe alternate exercises when a planned movement conflicts with injury context.
- Add recovery-support movements/routines appropriate to selected injury context.
- Present legal disclaimer text that guidance is not medical advice or physical therapy.
- Provide an explicit cancel action for an enrolled plan.

## Differentiators
- Injury-aware substitutions that preserve progression intent (pattern-equivalent replacements).
- Contextual recovery additions integrated into the plan rather than shown as disconnected tips.
- Cancellation flow that preserves historical logs and allows future re-enrollment without corruption.

## Anti-Features
- Diagnosing injuries or assigning medical treatment plans.
- Automatic return-to-lift clearance claims.
- Destructive cancellation that erases completed sessions and progression history.

## Complexity + Dependencies
- **Onboarding persistence:** low-medium complexity; depends on auth bootstrap and profile storage.
- **Injury-aware generation:** medium-high complexity; depends on exercise taxonomy/tagging and generator policy hooks.
- **Disclaimer/legal copy:** low complexity; depends on all injury-facing surfaces.
- **Plan cancellation:** medium complexity; depends on enrollment state model and UI entry points.
