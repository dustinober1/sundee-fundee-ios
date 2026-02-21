# Repository Guidelines

## Project Structure & Module Organization

- `SundeeFundee/`: SwiftUI app source
  - `App/`: app entry + root views
  - `Models/`: SwiftData `@Model` types + Codable models
  - `Views/`: SwiftUI views organized by feature
  - `ViewModels/`: `@Observable` view models (MVVM)
  - `Services/`, `Utilities/`, `Extensions/`
  - `Resources/`: assets + training program JSON (`Resources/Programs/*.json`)
- `SundeeFundeeTests/`: XCTest unit tests
- `SundeeFundeeUITests/`: XCTest UI tests
- `project.yml`: XcodeGen source-of-truth for `SundeeFundee.xcodeproj`
- `.github/`: CI + agent prompts (some workflows are legacy stacks)

## Build, Test, and Development Commands

```bash
# Generate Xcode project (run after cloning or editing project.yml)
xcodegen generate

# Build
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Test (unit + UI)
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run a specific test class
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:SundeeFundeeTests/WeightCalculationsTests
```

## Coding Style & Naming Conventions

- Indentation: 4 spaces; avoid tabs; match existing SwiftUI formatting.
- Naming: types/files in `PascalCase` (for example, `CompletedSet.swift`), members in `lowerCamelCase`.
- Patterns: prefer MVVM (`Views/` + `ViewModels/`) and keep business logic in `Services/`/`Utilities/`.
- SwiftData: new `@Model` types must be registered in `SundeeFundee/App/SundeeFundeeApp.swift`.

## Testing Guidelines

- Framework: XCTest (`SundeeFundeeTests/` for unit tests, `SundeeFundeeUITests/` for UI tests).
- Conventions: `*Tests.swift`, `final class FooTests: XCTestCase`, methods start with `test...`.
- Prefer targeted unit tests for calculations/parsing (for example `SundeeFundee/Utilities/` and program JSON models).

## Commit & Pull Request Guidelines

- Commits follow Conventional Commits: `feat: ...`, `fix: ...`, `docs(scope): ...` (see `git log` for examples).
- PRs include: short description, how you tested (paste the `xcodebuild` command), and screenshots for UI changes.
- Call out any changes to signing, entitlements, or CloudKit configuration explicitly.

## Security & Configuration Tips

- CloudKit container: `iCloud.com.sundeefundee.app`; use your own signing team and Apple ID when running locally.
- Do not commit certificates, provisioning profiles, or other sensitive key material.
- Assistant notes: see `CLAUDE.md`, `GEMINI.md`, and `.github/copilot-instructions.md`.
