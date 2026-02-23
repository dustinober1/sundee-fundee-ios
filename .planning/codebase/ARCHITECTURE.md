# System Architecture

The project follows a feature-first clean architecture with layers:

1. **App Shell** (`lib/app/`) - entry point, routing, theme, global providers
2. **Features** (`lib/features/*/`)
   - Each feature has its own `data/`, `domain/`, `presentation/`, `providers.dart`
   - Examples: auth, cycle, dashboard, programs, storage, migration, admin, etc.
3. **Domain** (`lib/domain/`) - shared models, calculation utilities, enums, interfaces
4. **Firebase** (`lib/firebase/`) - platform-specific initialization and helpers

Dependencies flow inward; presentation widgets depend on domain models and providers.

- **State management**: Riverpod providers defined per feature; composed in `providers.dart` files.
- **Routing**: GoRouter config lives near app shell, with route guard logic based on auth state.

Data layer:

- Repositories interfaces defined in domain
- Firestore-backed implementations in `features/repositories/data/firestore_repositories.dart`

Business logic are pure Dart classes/functions often under `domain/calculations/`.

Testing and migrations are orchestrated via dedicated services under features.
