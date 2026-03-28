# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Commands
- Regenerate the Xcode project after any `project.yml` change or new `.swift` file: `xcodegen generate`
- Build iOS app: `xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGNING_ALLOWED=NO`
- Run all iOS tests with CI settings: `xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:SundeeFundeTests -enableCodeCoverage YES -resultBundlePath SundeeFundeeTests.xcresult CODE_SIGNING_ALLOWED=NO`
- Run one iOS test class or method: append `-only-testing:SundeeFundeTests/BusinessLogicTests` or `-only-testing:SundeeFundeTests/BusinessLogicTests/testExample`
- Dashboard commands must run inside `wod-dashboard/` because `src/lib/paths.ts` resolves app JSON via `process.cwd()`: `npm run dev`, `npm run lint`, `npx jest --runTestsByPath __tests__/validation.test.ts`

## Project-specific rules
- Never edit `SundeeFundee.xcodeproj` directly; it is generated from `project.yml`.
- `SundeeFundee/Packages/SundeeFundeeShared` is a checked-in local package shared by the iOS app and `wod-dashboard`; keep its schema/JSON contracts aligned across both codebases.
- Any service or repository holding a `ModelContext` must be `@MainActor`; otherwise SwiftData can hop off the main queue and fail silently.
- When adding a SwiftData schema version, update all three: `AppSchemaMigrationPlan.schemas`, `AppSchemaMigrationPlan.stages`, and `AppModelContainer.allModels`. Never remove old schema versions.
- Persist enums on `@Model` types as raw `String` values with computed typed accessors; CloudKit-backed SwiftData models do not store Swift enums directly.
- `AppState.currentUserID` is the app `User.id` UUID string, not the Sign in with Apple identifier; thread it through all user-owned writes.
- CloudKit repository setup is guard-sensitive: bypassing the entitlement check before `CKContainer(identifier:)` crashes with SIGTRAP instead of throwing.
- Decode CloudKit integer fields as `Int64` first; `as? Int` silently misses values.
- In tab screens, use `.onAppear` for refresh-on-return behavior; `.task` only runs once per tab lifetime.
- Only the first 4 tabs should be wrapped in `NavigationStack`; overflow tabs live under the system More controller.
- Use `NavigationLink(destination:)` for views that can be pushed from multiple stacks; value-based links only resolve at the root stack.
- In production code, prefer graceful repository failure paths such as `(try? ...)` over crashes; this repo intentionally avoids `try!` for data operations.
- Dashboard JSON writes must go through `wod-dashboard/src/lib/file-io.ts` so writes serialize and create `.bak` backups.
- Adding a new dashboard entity requires coordinated updates in `wod-dashboard/src/lib/types.ts`, `src/lib/paths.ts`, `src/app/api/<entity>/route.ts`, CloudKit publish routing, UI components, page, and sidebar.
- AI generation routes in `wod-dashboard/src/app/api/generate/*/route.ts` must preserve the worker pattern: build prompt, call worker, strip markdown fences, parse JSON, then validate/return.
