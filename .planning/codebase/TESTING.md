# Testing Strategy

- **Unit Tests**: located under `test/domain/`, `test/features/` corresponding to logic and models.
  - Calculation helpers (e.g., weight calculations) get thorough coverage.
  - Repository mocks are used for service layer tests.
- **Widget Tests**: `flutter_test` for UI components and screens.
- **Integration / E2E**: none present in repo currently.
- **Static Analysis**: `flutter analyze` enforce lint rules before commits.
- **Running tests**: `flutter test` or `flutter test test/path/to/file.dart`.

All new features require accompanying unit tests; test style follows examples in existing files.
