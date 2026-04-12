---
name: add-view-feature
description: Adding a new UI feature with ViewModel and SwiftUI View. Use when building a new screen, tab, or feature area.
triggers:
  - "add view"
  - "new screen"
  - "new feature"
  - "add tab"
  - "ViewModel"
edges:
  - target: context/conventions.md
    condition: when checking naming and structure conventions
  - target: context/data-layer.md
    condition: when the feature needs to read or write data
  - target: context/architecture.md
    condition: when understanding where the feature fits in the system
  - target: patterns/add-domain-logic.md
    condition: when the feature requires new business logic in the domain layer
last_updated: 2026-04-11
---

# Add View Feature

## Context

Load `context/conventions.md` for naming and structure rules. Load `context/data-layer.md` if the feature reads/writes data.

Key files to reference:
- Existing ViewModels: `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/`
- Existing Views: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/`
- Data protocols: `SundeeFundee/Sources/SundeeFundeeKit/DataLayer/Protocols/`

## Steps

1. **Create the ViewModel** in `Sources/SundeeFundeeKit/UI/ViewModels/[Feature]ViewModel.swift`:
   - Class must be `@MainActor public class [Feature]ViewModel: ObservableObject`
   - Use `@Published` for all reactive state
   - Accept `DataClientProtocol` (and/or `ContentClientProtocol`, `HealthClientProtocol`) via constructor injection with factory defaults
   - Keep business logic out — delegate to domain layer services

2. **Create the View** in `Sources/SundeeFundeeKit/UI/Views/[Feature]/[Feature]View.swift`:
   - Use `@StateObject` for the ViewModel (owned by this view)
   - Use `@ObservedObject` if the ViewModel is passed in from a parent
   - Apply theme tokens via `AppTheme.*` (cream `#f4f0df`, navy `#0d1a40`, orange `#f27319`)
   - Fonts: Playfair Display (headings), Inter (body), JetBrains Mono (numbers)

3. **Create model types** if needed in `Sources/SundeeFundeeKit/Models/`:
   - Must conform to `Codable`, `Sendable`, `Identifiable`, `Equatable`
   - CloudKit record type name = PascalCase model name

4. **Write tests** in `Tests/SundeeFundeeKitTests/ViewModelTests/`:
   - Inject `MockCloudKitClient` (or `MockContentClient`) into the ViewModel
   - Test state transitions: initial state → load → loaded/error
   - Use private factory helpers for test data

5. **Wire into navigation** — add to the appropriate parent view or tab in `MainTabView`

## Gotchas

- **Do NOT use `@Observable` macro** — all ViewModels use `ObservableObject` with `@Published`
- **Do NOT hardcode data clients** — always use factory defaults in init parameters
- **Guest mode** — if the feature writes data, gate CloudKit operations with `!authViewModel.isGuest`
- **Sendable conformance** — any type that crosses an async boundary must be `Sendable`. The compiler will catch this but plan for it.
- **XcodeGen** — after adding new files, you may need to run `xcodegen generate` in `SundeeFundeeApp/` to update the Xcode project

## Verify

- [ ] ViewModel is `@MainActor ObservableObject` with `@Published` properties
- [ ] Data client injected via protocol with factory default
- [ ] New model types conform to `Codable`, `Sendable`, `Identifiable`, `Equatable`
- [ ] No business logic in the ViewModel — delegated to domain layer
- [ ] Theme tokens used consistently (AppTheme.*)
- [ ] Tests written with mock clients
- [ ] `swift test` passes

## Debug

If build fails after adding a new feature:
1. Run `xcodebuild build` (not SourceKit) — SourceKit gives false positives for cross-module types
2. Check `Sendable` conformance on all new types
3. Ensure `@MainActor` is on the ViewModel class declaration
4. If Xcode can't find the file, re-run `xcodegen generate`

## Update Scaffold
- [ ] Update `.mex/ROUTER.md` "Current Project State" if what's working/not built has changed
- [ ] Update any `.mex/context/` files that are now out of date
- [ ] If this is a new task type without a pattern, create one in `.mex/patterns/` and add to `INDEX.md`
