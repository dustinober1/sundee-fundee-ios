# Repository Structure

Top-level directories:

```
flutter_app/        # Flutter project
  lib/              # Application source code
    app/
    domain/
    features/
    firebase/
  test/             # Unit and widget tests
  android/ ios/ web/ build/ etc.

plans/              # Planning documents (including this codebase map)

firebase.json
firestore.rules
storage.rules
...                # build scripts, CI config, etc.
```

Within `lib/features`: each feature modularized with its own subfolders:
```
features/<feature>/
  data/             # repositories, services
  domain/           # models, interfaces
  presentation/     # screens, widgets
  providers.dart    # Riverpod provider definitions
```

`lib/domain` contains cross-cutting entities:
- `models`, `calculations`, `enums`, utilities

Tests mirror the `lib/` hierarchy under `test/`.

Configuration files (analysis, pubspec, firebase) at root of flutter_app.
