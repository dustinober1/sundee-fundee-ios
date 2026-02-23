# Stack Research (v1.1)

## Scope
Milestone v1.1 adds onboarding persistence, injury-aware plan adjustments, legal disclaimer handling, and enrolled-plan cancellation.

## Recommended Stack Additions/Changes
- **No new platform dependency required** for core scope.
- **Flutter + Riverpod + Firebase Auth/Firestore** remain sufficient.
- **Firestore schema extensions** should be introduced for:
  - persisted onboarding completion/profile state,
  - active injury profile and recovery preferences,
  - plan enrollment lifecycle status (`active`, `canceled`).
- **Optional but recommended:** `freezed`/`json_serializable` consistency for new value objects if current models already use generated serialization.

## Integration Points
- `Auth/session bootstrap` should hydrate persisted onboarding state after sign-in.
- `Program generation policy` should read injury profile and apply substitution/recovery rules before workout output is finalized.
- `Enrollment management` should support cancellation without deleting historical performance data.
- `Disclaimer rendering` should be versioned copy in app constants/content layer and shown where injury guidance is presented.

## What Not To Add
- No new backend service is needed for v1.1.
- No ML recommendation pipeline is needed for injury logic in this milestone.
- No social/community dependencies for cancellation UX.

## Notes
The highest-risk technical area is data-contract correctness across old users and new profile fields; migration-safe defaults are mandatory.
