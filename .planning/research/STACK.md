# Stack Research

For a cycle-aware strength training tracker in 2026, the standard technology stack includes:

- **Cross-platform UI**: Flutter with Dart 3.x (already used in repo). Supports mobile, web, desktop with same codebase.
- **State Management**: Riverpod or Provider; this code uses Riverpod which remains current.
- **Routing**: GoRouter or Flutter Navigator 2.0; GoRouter chosen for simplicity.
- **Backend**: Firebase (Firestore for real-time data, Auth for login, Storage for media). Works well for small‑to‑mid scale mobile apps without server maintenance.
- **Analytics/Crash**: Firebase Analytics + Crashlytics.
- **Optional**: Health or cycle data could integrate with HealthKit/Google Fit but the current focus is manual logging.

**Rationale:**
Flutter gives fastest startup for existing project. Firebase keeps serverless backend with free tier and built‑in auth. Riverpod is the de facto state pattern and integrates with GoRouter. This matches existing codebase.

**Confidence:** high (stack already chosen and well-suited for domain).
