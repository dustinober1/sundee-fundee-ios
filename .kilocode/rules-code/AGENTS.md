# Project Coding Rules (Non-Obvious Only)

- Regenerate `SundeeFundee.xcodeproj` from `project.yml` after any settings/package/resource change or new `.swift` file; never hand-edit the project file.
- Treat `SundeeFundee/Packages/SundeeFundeeShared` as the contract between the app and `wod-dashboard`; change JSON shapes there first, then update both consumers.
- Any type that stores `ModelContext` must be `@MainActor`; caller-side isolation is not enough for SwiftData.
- For SwiftData migrations, update `AppSchemaMigrationPlan.schemas`, `AppSchemaMigrationPlan.stages`, and `AppModelContainer.allModels` together; missing one causes broken stores or silent data loss.
- Persist CloudKit-backed enum fields as raw strings, not enum-typed stored properties.
- Default app-facing remote data to `CloudKit*Repository` implementations; they already fall back to bundled JSON, while wiring bundled repos directly hides published content.
- Pass `appState.currentUserID` into all writes; it is the app user UUID, not the Apple account identifier.
- Use `wod-dashboard/src/lib/file-io.ts` for dashboard JSON persistence; direct `fs.writeFile` bypasses locking and backup creation.
