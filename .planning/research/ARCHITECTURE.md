# Architecture Research

Typical structure for this domain:

- **Client app** (Flutter) containing UI layers per feature
- **Data layer**: repositories interfacing with Firestore
- **Domain layer**: business logic (cycle calculations, program logic)
- **Auth service** for user sessions and identity
- **Sync service** to handle offline and real-time updates
- **Program generator** module that creates workouts based on cycle phase and user progress

Data flow: user input → providers → domain logic → repository → Firestore → sync back to providers for UI.

Build order implications: start with auth and basic data models, then cycle tracking, then program generator, then UI screens.
