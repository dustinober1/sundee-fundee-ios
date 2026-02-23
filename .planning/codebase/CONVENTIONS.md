# Coding Conventions

Common style and project rules:

- **Dart formatting**: `dart format` (2‑space indentation)
- **File naming**: `snake_case.dart` for files; classes in `PascalCase`
- **Directory layout**: feature modules as described in `STRUCTURE.md`
- **Enums**: use extension methods if needed; store raw string in Firestore
- **Serialization**: `fromJson`/`toJson` in models for Firestore
- **Dependency injection**: Riverpod providers scoped per feature and combined
- **Tests**: Use `flutter_test`; mirror hierarchy; use `setUp`/`tearDown` for common fixtures
- **Commits**: use conventional commit prefixes (`feat:`, `fix:`, `docs:` etc.)
- **Firebase gating**: wrap calls with `ENABLE_FIREBASE` compile-time flag

Lint analysis config in `analysis_options.yaml` with Flutter recommended rules.
