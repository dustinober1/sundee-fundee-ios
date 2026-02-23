# Research Summary

**Stack:** Flutter (Dart 3), Riverpod, GoRouter, Firebase backend. Existing stack is appropriate and current.

**Table Stakes:** Auth, cycle logging, program enrollment, dashboard, Firestore sync. These are already implemented in the codebase.

**Differentiators:** Cycle-aware program generator with adaptive plans for women and hard-coded 12-week flow for men. UI cues like sharkweek logo.

**Anti-features:** Social/sharing, real-time coaching.

**Watch Out For:**
- Handle irregular cycle data gracefully
- Keep program generator simple initially
- Update Firestore rules as schema changes
- Guarantee offline support
- Design user-friendly menstrual UI cues

Files: `.planning/research/STACK.md`, `FEATURES.md`, `ARCHITECTURE.md`, `PITFALLS.md`.
