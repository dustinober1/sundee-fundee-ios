# Pitfalls Research (v1.1)

## 1) Re-onboarding regressions for existing users
- **Warning signs:** returning users still hit onboarding despite stored profile.
- **Prevention:** gate onboarding from persisted completion flag with explicit fallback rules.
- **Phase to address:** foundation/data-contract phase.

## 2) Unsafe or irrelevant exercise substitutions
- **Warning signs:** substitutions change primary movement pattern or overload injured region.
- **Prevention:** define substitution matrix by movement pattern and contraindicated regions; require deterministic tests.
- **Phase to address:** injury-adaptation phase.

## 3) “Recovery” recommendations interpreted as treatment advice
- **Warning signs:** copy implies diagnosis, cure, or professional replacement.
- **Prevention:** central legal disclaimer and conservative language policy across all injury-related outputs.
- **Phase to address:** injury UX/legal phase.

## 4) Cancellation corrupts progression/enrollment history
- **Warning signs:** canceled users lose completed sessions or cannot re-enroll cleanly.
- **Prevention:** soft-state transition (`active` -> `canceled`) with immutable history.
- **Phase to address:** enrollment lifecycle phase.

## 5) Schema drift and missing defaults in Firestore docs
- **Warning signs:** null errors or inconsistent behavior for pre-v1.1 accounts.
- **Prevention:** use backward-compatible defaults and repository-level normalization.
- **Phase to address:** foundation/data-contract phase.
