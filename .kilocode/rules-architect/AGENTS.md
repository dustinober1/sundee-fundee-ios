# Project Architecture Rules (Non-Obvious Only)

- The app and `wod-dashboard` share a checked-in local package, `SundeeFundeeShared`; it is the canonical cross-surface model/validation layer.
- Programs, benchmarks, and WOD content follow a bundled-JSON-plus-CloudKit-public-db model; app repos should prefer CloudKit implementations because they already include bundled fallback.
- SwiftData migration is forward-only in practice: old schema versions must remain in the migration plan for existing user stores.
- Main tab architecture intentionally wraps only the first four tabs in `NavigationStack` to avoid iOS More-tab double-navigation behavior.
- The AI workout flow is a state-driven navigation chain (questionnaire → preview → execution → summary); missing one state binding breaks navigation silently.
